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
create type public.charge_kind  as enum ('subscription', 'installment');
create type public.notice_kind  as enum ('charge', 'cutoff', 'payment_due');
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
  cutoff_day      smallint,                   -- statement cutoff day, optional
  payment_due_day smallint,                   -- payment deadline, optional
  color        text not null default '#4A5568',
  archived     boolean not null default false,
  created_at   timestamptz not null default now(),

  constraint cards_alias_len  check (char_length(alias) between 1 and 40),
  constraint cards_last4_fmt  check (last4 is null or last4 ~ '^[0-9]{4}$'),
  constraint cards_cutoff_rng check (cutoff_day is null or cutoff_day between 1 and 31),
  constraint cards_due_rng    check (payment_due_day is null or payment_due_day between 1 and 31),
  constraint cards_alias_uniq unique (user_id, alias)
);
```

`cards_last4_fmt` acepta 4 dígitos y **nada más**: la constraint es la que impide que alguien
pegue un PAN completo en ese campo.

**Son dos fechas distintas y las dos importan.** El *corte* cierra el estado de cuenta: lo que
compres después cae en el siguiente. La *fecha límite de pago* es la que tiene consecuencia — si no
pagas, hay intereses y se pierden los meses sin intereses. El aviso accionable es el del límite; el
corte solo determina **cuáles** cargos entran en ese estado de cuenta.

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
  ends_on             date,                    -- derived by trigger for installments
  reminder_days_before smallint not null default 1,
  category            text,
  active              boolean not null default true,
  notes               text,
  kind                public.charge_kind not null default 'subscription',
  installments_total  smallint,                -- 12 = "12 MSI"
  owed_by             text,                    -- someone else repays this charge
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),

  constraint subs_name_len    check (char_length(name) between 1 and 60),
  constraint subs_amount_pos  check (amount > 0),
  constraint subs_reminder_rng check (reminder_days_before between 0 and 30),
  constraint subs_custom_days check (
    (cycle = 'custom' and custom_days between 1 and 365) or
    (cycle <> 'custom' and custom_days is null)
  ),
  constraint subs_ends_after  check (ends_on is null or ends_on >= first_charge_date),
  constraint subs_installments check (
    (kind = 'installment' and installments_total between 2 and 60 and cycle = 'monthly') or
    (kind = 'subscription' and installments_total is null)
  ),
  constraint subs_owed_by_len check (owed_by is null or char_length(owed_by) between 1 and 40)
);
```

`numeric(12,2)`, nunca `float`. Dinero en punto flotante es un bug esperando su turno.

`subs_custom_days` es la regla que impide el estado imposible "ciclo mensual con 45 días de período".
Esa clase de validación vive acá, no en Dart.

#### Los MSI viven en esta tabla, no en una propia

Un plan a meses sin intereses **es** un cargo mensual a una tarjeta con fecha de fin. Reusando esta
tabla, `next_charge_date`, los totales por tarjeta, las 14 políticas RLS y el programador de
notificaciones siguen funcionando sin un solo cambio. Una tabla aparte duplicaría RLS y convertiría
cada total en un `union` para siempre.

`amount` sigue siendo **lo que se cobra cada mes**. La deuda total es `amount × installments_total`;
no se guarda aparte porque dos columnas que dicen lo mismo terminan discrepando.

**No hay columna de mensualidades pagadas.** El cargo es automático, así que "pagada" es "la fecha ya
pasó" — se deriva con `installments_paid()`. Es la misma regla que ya rige a `next_charge_date`: un
valor guardado se queda viejo solo, y un contador exigiría que el usuario palomee casillas.

`owed_by` cubre el caso de prestar la tarjeta para que alguien pague a MSI, y también el Netflix
compartido: aplica a los dos `kind`. Es texto y no una tabla de deudores porque agrupar por texto ya
responde "cuánto me debe X", y una tabla compraría integridad referencial sobre un campo que teclea
una sola persona.

### 3.5 `notification_log` — historial

```sql
create table public.notification_log (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null default auth.uid() references auth.users(id) on delete cascade,
  subscription_id uuid references public.subscriptions(id) on delete cascade,
  card_id         uuid,                        -- cutoff / payment_due notices
  kind            public.notice_kind not null default 'charge',
  charge_date     date not null,
  scheduled_for   timestamptz not null,
  delivered_at    timestamptz,
  opened_at       timestamptz,
  acknowledged_at timestamptz,                 -- "enterado"
  amount          numeric(12,2) not null,
  title           text not null,
  created_at      timestamptz not null default now(),

  constraint notif_target_xor check ((subscription_id is not null) <> (card_id is not null)),
  constraint notif_card_fk foreign key (card_id, user_id)
    references public.cards (id, user_id) on delete cascade
);

create unique index notif_once_sub  on public.notification_log (subscription_id, charge_date);
create unique index notif_once_card on public.notification_log (card_id, charge_date, kind);
```

Los índices únicos son lo que hace el registro **idempotente**: el cliente reprograma notificaciones
en cada arranque y evitan duplicados sin que lleve la cuenta. `on conflict do nothing`. Reemplazaron a
`notif_once`, que asumía que todo aviso tenía suscripción.

**No llevan `where`, y eso no es un descuido.** `ON CONFLICT` solo puede inferir un índice único
**no parcial**, así que un predicado aquí rompe el upsert del programador con `42P10`. La garantía es
la misma sin él: los nulos son distintos entre sí en un índice único, de modo que un aviso de tarjeta
(`subscription_id` nulo) nunca choca en la llave de suscripción, ni al revés. `smoke.sql` reproduce
ese upsert exacto para que la regresión no vuelva.

Como las notificaciones locales disparan con la app cerrada, `delivered_at` se marca cuando el
cliente arranca y ve que la fecha ya pasó, y `opened_at` cuando el usuario toca la notificación.

**`acknowledged_at` es timestamp, no booleano.** Contesta lo mismo con `is not null` y además dice
*cuándo* — que es el dato que sirve para saber si te enteraste antes o después de la fecha límite.
Un bool tira esa información sin ahorrar nada. No es lo mismo que `opened_at`: abrir es haber visto,
`acknowledged_at` es haberse hecho cargo.

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
- `set_installment_end` en `subscriptions` — `before insert or update`, deriva
  `ends_on = first_charge_date + (installments_total - 1) meses` cuando `kind = 'installment'`.
  Es lo que hace que un MSI **se apague solo** al saldarse: `v_subscriptions` ya filtra por `ends_on`.

### 4.5 MSI y estado de cuenta

| Función | Devuelve |
|---|---|
| `installments_paid(first, total, on)` | Mensualidades ya cobradas, tope en `total` |
| `cutoff_on(day, in_month)` | El día de corte acotado al mes: 31 en febrero es 28 |
| `statement_close(day, from)` | El corte que cierra en o después de `from` |
| `payment_due_after(due_day, close)` | El primer día límite estrictamente posterior al corte |
| `charge_dates_between(first, cycle, custom, from, to)` | Las fechas de cobro **reales** en una ventana |

`charge_dates_between` existe porque `monthly_amount()` **no sirve** para un estado de cuenta:
normaliza semanal y anual a un promedio comparable, y aquí hace falta saber cuántos cobros caen de
verdad entre dos fechas. Repite la aritmética `n * step` desde la fecha original en vez de sumar
sobre el resultado anterior — el mismo error de arrastre en fin de mes que evita `next_charge_date`.

| Vista | Contesta |
|---|---|
| `v_debtors` | Cuánto te debe cada persona y en cuántos pagos |
| `v_card_statement` | Ventana abierta por tarjeta, fecha límite, total a pagar y cuánto te reembolsan |

`v_card_totals` gana `outstanding_total` (deuda MSI pendiente), `installment_count` y
`monthly_owed_by_others`. `v_subscriptions` gana `installments_paid`, `installments_left` y
`outstanding` — cero en las suscripciones abiertas, para que sumar deuda por tarjeta sea una suma.

Las cinco funciones toman `int`, no `smallint`: Postgres no reduce `integer` a `smallint` al
resolver una llamada, así que un `smallint` las volvía invocables solo desde columnas.

Verificación en `supabase/tests/`: `checks.sql` afirma sobre las funciones puras, `smoke.sql`
inserta filas reales, comprueba trigger, vistas y el XOR de avisos, y revierte con un `raise`.
Sus expectativas son relativas a `current_date` — fijar fechas literales hacía que el archivo
pasara hoy y se rompiera solo en dos semanas.

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
  config/theme/                             # colors, typography, spacing, motion, theme, mode enum
  core/constants/environment.dart           # SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY
  core/helpers/money_helper.dart            # moneda y etiquetas de fecha, en uno
  data/models/cards/card_model.dart, card_total_model.dart, card_assets.dart
  data/models/subscriptions/subscription_model.dart
  data/models/notifications/notification_log_model.dart
  data/models/profile/profile_model.dart
  data/services/supabase/supabase_service.dart
  data/services/notifications/local_notification_service.dart, notification_scheduler.dart
  data/providers/<feature>/
  ui/screens/<feature>/, ui/views/<feature>/, ui/widgets/<feature>/
```

Sin capa de repositorio sobre el cliente de Supabase: ya es el cliente de datos. Una interfaz con
una sola implementación es la abstracción que CLAUDE.md prohíbe.

**Dependencias** (agregar una nueva requiere tu OK, según CLAUDE.md):

| Paquete | Para qué | Estado |
|---|---|---|
| `supabase_flutter` | cliente + auth + sesión persistida | ✅ |
| `go_router` | rutas + guard de sesión | ✅ |
| `flutter_riverpod` | estado compartido | ✅ |
| `flutter_local_notifications` + `timezone` | recordatorios locales | ✅ |
| `intl` + `flutter_localizations` | formato de moneda, fechas y strings de Material en es-MX | ✅ |
| `shared_preferences` | persistir el modo de tema sin sesión ni red | ✅ |
| `animate_do` | entradas fade-up / fade-down envueltas en `ui/widgets/common/motion/` | ✅ |
| `shimmer` | skeletons de carga | ✅ |
| `flutter_launcher_icons` + `flutter_native_splash` (dev) | icono y splash generados desde un PNG | ✅ |

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
| 5 | `feature/subscriptions` | CRUD de suscripciones ligadas a tarjeta ✅ |
| 6 | `feature/dashboard` | Totales por tarjeta y próximos cobros, desde las vistas ✅ |
| 7 | `feature/notifications` | Programación local + `notification_log` ✅ |
| 8 | `feature/notification-history` | Pantalla de historial ✅ |
| 9 | `feature/profile` | Preferencias de moneda y zona horaria, cambiar y recuperar contraseña ✅ |
| 10 | `feature/theme-mode` | Selector claro / oscuro / sistema con persistencia local, paleta oscura Wayfare ✅ |
| 11 | `feature/animations` | Envoltorios de movimiento, skeletons por pantalla, shell con swipe entre tabs ✅ |
| 12 | `feature/app-icon-and-splash` | Icono, splash, marca Vence, WebPs de marca de tarjeta, identidad cromática por tab ✅ |
| 13 | `feature/mob-debpts` | **Base de datos**: MSI, deuda de terceros, fecha límite de pago y estado de cuenta por tarjeta ✅ aplicado, advisors en cero |
| 13.1 | `feature/mob-debpts` | **Capa Flutter**: modelos, formularios de MSI y de día límite, progreso en la lista, corte y reembolsos en el resumen ✅ |

Las fases 1 y 2 no tocan Dart. La 3 no se empieza hasta que la 1 esté probada: si el esquema cambia
después, se rehace el cliente.

Lo único abierto es la fase 2: los secrets `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY` no están
configurados en GitHub, así que el workflow de keep-alive nunca ha corrido.

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

Descartado a propósito al diseñar los MSI:

- **Tabla de gastos generales o "saldo de la tarjeta".** La app solo conoce la deuda que le
  contaron. Un campo de saldo estaría mal desde el primer café comprado fuera de la app, y un número
  equivocado es peor que uno ausente.
- **Una fila por mensualidad.** Doce renglones para representar lo que dos fechas ya dicen.
- **Reembolso parcial** (*"me paga la mitad"*). Exige separar `amount` de lo adeudado; se agrega
  cuando haga falta.
- **MSI con intereses.** No son MSI.

Ninguna de estas cambia el esquema de forma incompatible, así que no se diseña para ellas hoy.
