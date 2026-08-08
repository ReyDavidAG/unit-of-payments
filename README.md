# Vence

Te avisa antes de cada cobro y te muestra en un solo lugar todo lo que estás pagando:
suscripciones, meses sin intereses y la deuda que alguien más te está pagando en tu tarjeta.

iOS y Android. Sin servidor propio: Supabase guarda los datos, Postgres hace las cuentas y el
teléfono dispara los avisos por su cuenta, con la app cerrada y sin internet.

`com.davidag.unit_of_payments` · **v1.0.0 build 1** · paquete `unit_of_payments`

---

## Qué hace

- **Tarjetas** — alias, marca, últimos 4, color, día de corte y día límite de pago.
  Nunca un número de tarjeta, un CVV ni una fecha de vencimiento: no existe la columna.
- **Suscripciones** — semanal, mensual, anual o cada N días. Se pueden pausar y cancelar.
- **Meses sin intereses** — das el precio total y el plazo, la app calcula el pago mensual.
  El plan se apaga solo al saldarse. **Contado** es un plan de un pago.
- **Deuda de terceros** — quién te paga qué, cuánto falta y cuándo cae el siguiente cargo.
- **Estado de cuenta** — qué cierra en este corte de cada tarjeta, cuándo hay que pagarlo y
  cuánto de ese total es tuyo después de reembolsos.
- **Avisos** — notificación local N días antes de cada cobro, a las 9:00 de tu zona horaria,
  con historial de lo que se programó y lo que ya venció.

## Cómo está armado

| | |
|---|---|
| Flutter 3.44 · Dart 3.12 | iOS y Android únicamente |
| Riverpod 3 | estado |
| go_router 17 | rutas, con guard de sesión |
| Supabase | Postgres 17, RLS activo en las cinco tablas y forzado en las tres con datos tuyos |
| flutter_local_notifications + timezone | avisos en el dispositivo |

**La lógica de negocio vive en Postgres, no en Dart.** La próxima fecha de cobro, el costo
mensualizado, el avance de un MSI y la ventana del estado de cuenta son funciones y vistas. El
cliente lee vistas y escribe tablas; no reimplementa ninguna de esas cuentas.

---

## Correrlo

```bash
cp .env.example .env       # y pega la publishable key del dashboard de Supabase
flutter pub get
flutter run --dart-define-from-file=.env
```

Los secretos son **de tiempo de compilación**, nunca un asset empaquetado. `--dart-define-from-file`
va en cada `run` y en cada `build`; sin él las credenciales compilan vacías y la app truena en el
primer frame. Se leen solo a través de
[`Environment`](lib/core/constants/environment.dart).

La `publishable key` es pública por diseño: viaja dentro de la app y no sirve de nada sin sesión,
porque RLS niega todo por defecto. La `service_role` **nunca** entra a este proyecto.

```bash
flutter test            # 103 en verde, 1 en rojo — ver Estado
./scripts/format.sh     # dart format + flutter analyze — debe salir en cero
```

## Base de datos

Las migraciones van con `--db-url` explícito; `supabase link` está roto en el CLI 2.112. El
procedimiento completo, con las trampas del pooler, está en [CLAUDE.md](CLAUDE.md#commands).

```bash
supabase db push     --db-url "$DB"
supabase db query    --db-url "$DB" --file supabase/tests/smoke.sql   # end-to-end, se revierte solo
supabase db advisors --type security --db-url "$DB"                   # tiene que reportar cero
```

## Publicar

```bash
flutter clean
flutter pub get
flutter build appbundle --release --dart-define-from-file=.env
```

La firma sale de `android/key.properties`, que está en `.gitignore` y apunta a un keystore
guardado **fuera del repositorio**. Si el archivo no existe el build cae a la llave de debug, y
Play rechaza ese bundle en vez de publicarlo en silencio.

---

## Los tres documentos

Este README es la puerta de entrada. Lo que manda está en otro lado:

| | |
|---|---|
| [CLAUDE.md](CLAUDE.md) | Cómo se trabaja aquí: capas, nombres, tope de 300 líneas por archivo, idioma, comandos |
| [DESIGN.md](DESIGN.md) | Cómo se ve: paleta, contrastes medidos, tipografía, voz de cada componente, y §10 con las desviaciones abiertas |
| [PLAN.md](PLAN.md) | Qué se construye y en qué orden: esquema completo, lógica en Postgres, fases |

Dos reglas que explican casi todo el código:

**Español para quien usa, inglés para quien programa.** Cada etiqueta, error y aviso está en
es-MX con tuteo. Cada clase, variable, archivo y comentario está en inglés.

**Un archivo nunca pasa de 300 líneas.** Cuando se acerca, se parte en pantalla, vista y widget.
Es la falla que este proyecto existe para evitar.

---

## Estado

Todo lo listado arriba está construido y funcionando. Tres cosas siguen abiertas, y están escritas
aquí en vez de descubrirse solas:

1. **`test/app_theme_test.dart` falla.** Afirma que `colorScheme.primary` es `ink`; el tema usa
   `primary` (terracota) desde `032f4d0`. O se alinea la prueba con la realidad, o se revierte el
   relleno para recuperar 4.5:1 en la etiqueta del botón. Es una decisión, no un olvido — ver
   [DESIGN.md §10](DESIGN.md), punto 1.
2. **El keep-alive nunca ha corrido.**
   [`.github/workflows/keepalive.yml`](.github/workflows/keepalive.yml) le hace ping a Supabase cada
   tres días para que el proyecto gratis no se pause a los siete, pero sus secrets no están
   configurados en GitHub.
3. **Diez desviaciones de diseño medidas** en [DESIGN.md §10](DESIGN.md), cada una con su ratio de
   contraste y su costo. Las más caras: la paleta por letra del avatar falla contraste en los dos
   temas, y los botones del perfil son los controles menos legibles de la app.
