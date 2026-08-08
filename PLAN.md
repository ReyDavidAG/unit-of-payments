# PLAN.md — Implementación con Supabase

Plan de implementación de `unit_of_payments`. Las reglas de código están en [CLAUDE.md](CLAUDE.md).
Este documento define **qué** se construye y en qué orden; no se escribe código fuera de las fases.

---

## 1. Decisiones cerradas

| Tema | Decisión |
|---|---|
| Backend | **Supabase** (Postgres + Auth + RLS), plan Free |
| Lógica de negocio | **En la base de datos**: constraints, funciones, vistas y RLS. El cliente no valida nada crítico |
| Notificaciones | **Locales en el dispositivo** (`flutter_local_notifications`). Sin FCM, sin servidor despierto |
| Historial | Tabla `notification_log` en Postgres, sincronizada desde el cliente |
| Migraciones | Supabase CLI, versionadas en `supabase/migrations/` dentro del repo |
| Keep-alive | GitHub Actions cada 3 días para que el proyecto free no se pause |
| Moneda | **Una sola por usuario** (MXN por defecto). Sin conversión de divisas |

### Restricciones del plan Free asumidas

500 MB de base, 50.000 MAU, 2 proyectos activos por organización, y **pausa a los 7 días sin queries**.
El keep-alive de la fase 2 cubre la pausa. El cupo de 2 proyectos hay que confirmarlo en el dashboard
antes de la fase 1.

---

## 2. Seguridad — reglas no negociables

Esto es lo primero porque el dominio toca tarjetas.

1. **Nunca se guarda un número de tarjeta.** Ni PAN completo, ni CVV, ni fecha de expiración.
   La tabla `cards` guarda **alias** (`"BBVA Oro"`), **marca** y, opcionalmente, **últimos 4 dígitos**.
   Nada de eso es dato de pago: no procesamos cobros, solo recordamos cuándo tocan.
   Con esto el proyecto queda **fuera del alcance de PCI-DSS**, y así se queda.
2. **RLS activo y `FORCE` en todas las tablas**, sin excepción. Deny by default.
3. Toda política filtra por `auth.uid()`. Ningún endpoint recibe un `user_id` desde el cliente:
   se toma de la sesión con `DEFAULT auth.uid()` y se verifica en el `WITH CHECK`.
4. **Las vistas se crean con `security_invoker = true`**, si no, saltan RLS y filtran datos entre usuarios.
5. La `service_role` key **jamás** entra en la app. Solo la `anon` key, que sin sesión no ve nada.
6. `anon` no tiene permisos salvo sobre la tabla `keepalive`, que está vacía a propósito.

---

## 3. Modelo de datos

### 3.1 Tipos

```sql
create type public.billing_cycle as enum ('weekly', 'monthly', 'yearly', 'custom');
create type public.card_brand   as enum ('visa', 'mastercard', 'amex', 'other');
```

### 3.2 `profiles`

Extiende `auth.users` con preferencias. Se crea por trigger al registrarse.

```sql
create table public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  display_name  text,
  currency      char(3)     not null default 'MXN',
  timezone      text        not null default 'America/Mexico_City',
  created_at    timestamptz not null default now()
);
```

### 3.3 `cards` — los alias

```sql
create table public.cards (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  alias        text not null,                 -- "BBVA Oro", "Nómina Santander"
  brand        public.card_brand not null default 'other',
  last4        char(4),                       -- optional, display only
  cutoff_day   smallint,                      -- statement cutoff day, optional
  color        text not null default '#4A5568',
  archived     boolean not null default false,
  created_at   timestamptz not null default now(),

  constraint cards_alias_len  check (char_length(alias) between 1 and 40),
  constraint cards_last4_fmt  check (last4 is null or last4 ~ '^[0-9]{4}$'),
  constraint cards_cutoff_rng check (cutoff_day is null or cutoff_day between 1 and 31),
  constraint cards_alias_uniq unique (user_id, alias)
);
```

`cards_last4_fmt` acepta 4 dígitos y **nada más**: la constraint es la que impide que alguien
pegue un PAN completo en ese campo.

### 3.4 `subscriptions`

```sql
create table public.subscriptions (
  id                  uuid primary key default gen_random_uuid(),
  user_id             uuid not null default auth.uid() references auth.users(id) on delete cascade,
  card_id             uuid references public.cards(id) on delete set null,
  name                text not null,
  amount              numeric(12,2) not null,
  cycle               public.billing_cycle not null default 'monthly',
  custom_days         smallint,
  first_charge_date   date not null,
  ends_on             date,
  reminder_days_before smallint not null default 1,
  category            text,
  active              boolean not null default true,
  notes               text,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),

  constraint subs_name_len    check (char_length(name) between 1 and 60),
  constraint subs_amount_pos  check (amount > 0),
  constraint subs_reminder_rng check (reminder_days_before between 0 and 30),
  constraint subs_custom_days check (
    (cycle = 'custom' and custom_days between 1 and 365) or
    (cycle <> 'custom' and custom_days is null)
  ),
  constraint subs_ends_after  check (ends_on is null or ends_on >= first_charge_date)
);
```

`numeric(12,2)`, nunca `float`. Dinero en punto flotante es un bug esperando su turno.

`subs_custom_days` es la regla que impide el estado imposible "ciclo mensual con 45 días de período".
Esa clase de validación vive acá, no en Dart.

### 3.5 `notification_log` — historial

```sql
create table public.notification_log (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null default auth.uid() references auth.users(id) on delete cascade,
  subscription_id uuid references public.subscriptions(id) on delete cascade,
  charge_date     date not null,
  scheduled_for   timestamptz not null,
  delivered_at    timestamptz,
  opened_at       timestamptz,
  amount          numeric(12,2) not null,
  title           text not null,
  created_at      timestamptz not null default now(),

  constraint notif_once unique (subscription_id, charge_date)
);
```

`notif_once` es lo que hace el registro **idempotente**: el cliente reprograma notificaciones en cada
arranque y la constraint evita duplicados sin que el cliente lleve la cuenta. `on conflict do nothing`.

Como las notificaciones locales disparan con la app cerrada, `delivered_at` se marca cuando el
cliente arranca y ve que la fecha ya pasó, y `opened_at` cuando el usuario toca la notificación.

---

## 4. Lógica de negocio en Postgres

### 4.1 Próxima fecha de cobro

```sql
create or replace function public.next_charge_date(
  p_first date,
  p_cycle public.billing_cycle,
  p_custom_days int,
  p_from date default current_date
) returns date
language plpgsql immutable as $$
declare
  step interval := case p_cycle
    when 'weekly'  then interval '7 days'
    when 'monthly' then interval '1 month'
    when 'yearly'  then interval '1 year'
    when 'custom'  then make_interval(days => p_custom_days)
  end;
  n int := 0;
begin
  -- Always n*step from the original date; iterative addition drifts on month ends.
  -- ponytail: loop runs once per elapsed cycle, upgrade to closed form if it ever shows up in a plan
  while p_first + (n * step) < p_from loop
    n := n + 1;
  end loop;
  return p_first + (n * step);
end $$;
```

Se **calcula**, no se guarda. Una columna `next_charge_date` almacenada queda obsoleta sola y hay que
mantenerla con un trigger y un cron. La función no se desincroniza nunca.

Sumar `n * interval '1 month'` desde la fecha original hace que Postgres resuelva el fin de mes
solo: un cobro del 31 de enero cae el 28 de febrero y **vuelve al 31 en marzo**. Iterar sumando de
mes en mes se quedaría clavado en el 28.

### 4.2 Costo mensualizado

```sql
create or replace function public.monthly_amount(
  p_amount numeric, p_cycle public.billing_cycle, p_custom_days int
) returns numeric
language sql immutable as $$
  select round(p_amount * case p_cycle
    when 'weekly'  then 52.0 / 12
    when 'monthly' then 1
    when 'yearly'  then 1.0 / 12
    when 'custom'  then 30.4375 / p_custom_days
  end, 2);
$$;
```

Sin esto no se pueden sumar peras con manzanas: una suscripción anual y una semanal solo son
comparables normalizadas a mes.

### 4.3 Vistas

```sql
create view public.v_subscriptions with (security_invoker = true) as
select s.*,
       c.alias  as card_alias,
       c.brand  as card_brand,
       c.color  as card_color,
       public.next_charge_date(s.first_charge_date, s.cycle, s.custom_days) as next_charge_date,
       public.monthly_amount(s.amount, s.cycle, s.custom_days)              as monthly_amount
from public.subscriptions s
left join public.cards c on c.id = s.card_id
where s.active
  and (s.ends_on is null or s.ends_on >= current_date);
```

```sql
-- "¿Cuánto pago por cada tarjeta?"
create view public.v_card_totals with (security_invoker = true) as
select c.id as card_id, c.alias, c.brand, c.color,
       count(v.id)                    as subscription_count,
       coalesce(sum(v.monthly_amount), 0) as monthly_total,
       min(v.next_charge_date)        as next_charge_date
from public.cards c
left join public.v_subscriptions v on v.card_id = c.id
where not c.archived
group by c.id;
```

```sql
-- Cobros de los próximos 30 días, para la pantalla principal
create view public.v_upcoming with (security_invoker = true) as
select * from public.v_subscriptions
where next_charge_date <= current_date + 30
order by next_charge_date;
```

**`security_invoker = true` no es opcional.** Sin eso la vista corre con los permisos de quien la
creó y devuelve las filas de todos los usuarios.

### 4.4 Triggers

- `set_updated_at` en `subscriptions` — `before update`, pone `updated_at = now()`.
- `handle_new_user` en `auth.users` — `after insert`, crea el `profiles` correspondiente.
  Va con `security definer` y `search_path = ''` (si no, es un vector de escalada de privilegios).

---

## 5. Políticas RLS

Mismo patrón en las cuatro tablas:

```sql
alter table public.cards enable row level security;
alter table public.cards force  row level security;

create policy cards_select on public.cards for select using (auth.uid() = user_id);
create policy cards_insert on public.cards for insert with check (auth.uid() = user_id);
create policy cards_update on public.cards for update using (auth.uid() = user_id)
                                                 with check (auth.uid() = user_id);
create policy cards_delete on public.cards for delete using (auth.uid() = user_id);
```

El `with check` en `update` es el que impide **regalarle** una fila a otro usuario cambiándole el
`user_id`. Sin él, el `using` solo protege la lectura.

Índices necesarios para que RLS no haga seq scan:
`cards(user_id)`, `subscriptions(user_id)`, `subscriptions(card_id)`, `notification_log(user_id)`.

---

## 6. Keep-alive con GitHub Actions

### 6.1 Tabla señuelo

Es la única superficie que `anon` puede tocar, y está vacía a propósito.

```sql
create table public.keepalive (id smallint primary key default 1, pinged_at timestamptz);
alter table public.keepalive enable row level security;
create policy keepalive_read on public.keepalive for select to anon using (true);
```

### 6.2 `.github/workflows/keepalive.yml`

```yaml
name: keepalive
on:
  schedule:
    - cron: '0 12 */3 * *'   # every 3 days, well inside the 7-day pause window
  workflow_dispatch:

jobs:
  ping:
    runs-on: ubuntu-latest
    steps:
      - name: Query Supabase
        run: |
          curl -fsS "${SUPABASE_URL}/rest/v1/keepalive?select=id&limit=1" \
            -H "apikey: ${SUPABASE_ANON_KEY}" \
            -H "Authorization: Bearer ${SUPABASE_ANON_KEY}" > /dev/null
        env:
          SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
          SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
```

`curl -f` hace que el job **falle** si Supabase responde error — así te enterás por correo de que algo
pasó, en vez de que el ping falle en silencio durante un mes.

### 6.3 Dos avisos sobre esto

- **GitHub deshabilita los workflows programados tras 60 días sin actividad en el repo.** Llega un
  correo antes. Mientras estés desarrollando no pasa; si el repo se enfría, hay que reactivarlo a mano
  o correr `workflow_dispatch`. Es el mismo problema que el keep-alive resuelve, un nivel más arriba.
- El cron de GitHub Actions **no es puntual**: puede retrasarse bastante en horas pico. Con cada 3
  días contra una ventana de 7, sobra margen.

Secrets a cargar en el repo: `SUPABASE_URL` y `SUPABASE_ANON_KEY`. La `anon` key es pública por
diseño (va dentro del APK), así que esto no filtra nada.

---

## 7. Notificaciones — cómo funciona sin servidor

1. Al arrancar y tras cada cambio, el cliente pide `v_upcoming` (30 días).
2. Por cada cobro futuro, programa una notificación local en
   `next_charge_date - reminder_days_before`, en la zona horaria de `profiles.timezone`.
3. Inserta la fila en `notification_log` con `on conflict (subscription_id, charge_date) do nothing`.
4. Al arrancar, marca `delivered_at` en las que ya vencieron y `opened_at` si la app se abrió desde
   la notificación.

Límite conocido: **iOS permite 64 notificaciones locales pendientes por app.** Se programan solo las
de los próximos 30 días y se reprograma en cada arranque. Si un usuario llega a 64 cobros en 30 días,
se priorizan las más cercanas.

Reprogramar todo en cada arranque es más barato que llevar un diff de qué está programado y qué no.

---

## 8. Estructura Flutter

Siguiendo [CLAUDE.md](CLAUDE.md):

```
lib/
  config/router/app_router.dart
  config/theme/app_theme.dart, app_colors.dart
  core/constants/environment.dart          # SUPABASE_URL, SUPABASE_ANON_KEY
  core/helpers/date_helper.dart, currency_helper.dart
  data/models/cards/card_model.dart
  data/models/subscriptions/subscription_model.dart
  data/models/notifications/notification_log_model.dart
  data/services/supabase/supabase_service.dart
  data/services/notifications/local_notification_service.dart
  data/providers/<feature>/
  ui/screens/<feature>/, ui/views/<feature>/, ui/widgets/<feature>/
```

Sin capa de repositorio sobre el cliente de Supabase: ya es el cliente de datos. Una interfaz con
una sola implementación es la abstracción que CLAUDE.md prohíbe.

**Dependencias** (agregar una nueva requiere tu OK, según CLAUDE.md):

| Paquete | Para qué | Estado |
|---|---|---|
| `supabase_flutter` | cliente + auth + sesión persistida | ✅ instalado |
| `go_router` | rutas + guard de sesión | ✅ instalado |
| `flutter_riverpod` | estado compartido | ✅ instalado |
| `flutter_local_notifications` + `timezone` | recordatorios | pendiente, fase 7 |
| `intl` | formato de moneda y fechas | pendiente, fase 6 |

Sin `flutter_dotenv`: `--dart-define-from-file` es nativo del SDK y acepta formato `.env`. El
paquete además empaquetaría el archivo como asset legible dentro del APK; `String.fromEnvironment`
lo compila dentro del binario.

---

## 9. Fases

Una rama por fase. Cada una termina con `./scripts/format.sh` limpio.

| # | Rama | Entrega |
|---|---|---|
| 1 | `feature/supabase-schema` | Migraciones SQL: tipos, tablas, constraints, funciones, vistas, RLS, índices. Verificado con dos usuarios de prueba: A no ve nada de B ✅ |
| 2 | `feature/keepalive-workflow` | Tabla `keepalive` + workflow + secrets ⏳ |
| 2.5 | `feature/design-system` | [DESIGN.md](DESIGN.md) + tokens en `config/theme/` + fuentes Geist ✅ |
| 3 | `feature/supabase-auth` | `supabase_flutter`, `.env`, login/registro, sesión persistida, guard en el router ✅ |
| 4 | `feature/cards` | CRUD de alias de tarjeta ✅ |
| 5 | `feature/subscriptions` | CRUD de suscripciones ligadas a tarjeta |
| 6 | `feature/dashboard` | Totales por tarjeta y próximos cobros, desde las vistas |
| 7 | `feature/notifications` | Programación local + `notification_log` |
| 8 | `feature/notification-history` | Pantalla de historial |

Las fases 1 y 2 no tocan Dart. La 3 no se empieza hasta que la 1 esté probada: si el esquema cambia
después, se rehace el cliente.

---

## 10. Riesgos

| Riesgo | Mitigación |
|---|---|
| Proyecto pausado a los 7 días | Keep-alive (fase 2). Restaurar es manual pero no se pierde nada |
| Cupo de 2 proyectos activos en el free tier | **Confirmar en el dashboard antes de la fase 1.** Salida: organización nueva |
| Workflow programado deshabilitado a los 60 días | Aviso por correo, `workflow_dispatch` manual |
| 64 notificaciones locales en iOS | Ventana de 30 días, reprogramación en cada arranque |
| Publicar en iOS | Apple Developer Program, 99 USD/año. Independiente de Supabase |
| Multi-moneda | Fuera de alcance. Una moneda por perfil, sin FX |

---

## 11. Fuera de alcance por ahora

Compartir suscripciones entre usuarios, exportar a CSV, cobro real o vinculación bancaria,
presupuestos, widgets de home screen, modo web/escritorio.

Ninguna de estas cambia el esquema de forma incompatible, así que no se diseña para ellas hoy.
