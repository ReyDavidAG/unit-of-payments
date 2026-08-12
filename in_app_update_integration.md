# `in_app_update_integration.md` — Actualización in‑app para Android

Plan para integrar el flujo de actualización in‑app de **Vence** en Android. Las reglas de
código están en [CLAUDE.md](CLAUDE.md) y los tokens visuales en [DESIGN.md](DESIGN.md). El
documento general del proyecto está en [PLAN.md](PLAN.md); este archivo es la propuesta de
**una sola fase** que se añade a las que ya existen.

La implementación de referencia vive en `flutter_project_example/`
(`lib/data/services/update/app_update_service.dart`,
`lib/data/providers/update/app_update_provider.dart`,
`lib/ui/widgets/update/app_update_wrapper.dart`,
`lib/ui/widgets/update/update_bottom_sheet.dart`,
`lib/ui/widgets/update/update_download_toast.dart`). Aquí se reescribe con los tokens y
convenciones de Vence.

---

## 1. Decisiones cerradas

| Tema | Decisión |
|---|---|
| Plataforma | **Android únicamente.** iOS queda fuera: Vence hoy no está en TestFlight ni en App Store |
| API fuente de verdad | **Google Play Store**, vía una **Supabase Edge Function** que devuelve `versionCode`, `versionName`, `releaseNotes` y `forceUpdate`. La app **no** consulta la API de Google directamente |
| Tipo de update | **Flexible.** Permite descargar en segundo plano y mostrar UI propia. El immediate update de Play rompe el flujo de 3 pasos que pide el usuario |
| Dependencias nuevas | `in_app_update` y `package_info_plus` (sujeto a tu OK, según CLAUDE.md). Sin `dio`: la llamada HTTP sale por `supabase_flutter.functions.invoke`, que ya está |
| Persistencia de estado | `shared_preferences` ya está; se usa para "el usuario ya eligió Después en esta versión" |
| Alcance de la UI | Un bottom sheet (dos voces), un panel de descarga pegado al tabbar, y un wrapper que orquesta todo |
| Idioma | **Español (es‑MX, tuteo)** para todo texto que vea el usuario |

### Por qué flexible y no immediate

El usuario pidió un flujo de 3 pantallas: hoja → descarga → hoja de instalación. El update
immediate de Play abre su propia UI a pantalla completa y mata cualquier widget de Flutter. No
hay forma de intercalar nuestro panel informativo ni de re‑mostrar el bottom sheet cuando el APK
ya está descargado. Flexible es la única opción.

### Por qué una Edge Function y no la API directa

La Google Play Developer API exige autenticación de servidor (`service account` + JSON key).
Meter esa credencial en el APK la filtra. Una Edge Function de Supabase actúa como proxy: la app
la llama con la `publishable_key` que ya carga, y la función consulta a Google con la credencial
privada guardada como secret. Cero secretos nuevos en el cliente.

---

## 2. Fuera de alcance

- **iOS.** No hay rama `ios/` en este flujo. El wrapper y los widgets son Android‑only; el
  provider detecta `Platform.isAndroid` y en `iOS` simplemente no hace nada.
- **Update inmediato.** Solo flexible.
- **Traducción del release notes.** Vence es monolingüe (es‑MX). Si el release viene en inglés,
  la Edge Function lo traduce o lo devuelve tal cual; en el cliente no hay toggle de idioma.
- **Pantalla de "qué hay de nuevo"**. La hoja ya lo dice. No se abre otra ruta.

---

## 3. Modelo de estado

```dart
enum UpdateStatus { idle, updateAvailable, downloading, readyToInstall, error }

class AppUpdateState {
  final UpdateStatus status;
  final String? releaseNotes;     // de la Edge Function, ya en es-MX
  final bool forceUpdate;         // si true, el sheet no es descartable
  final String? latestVersion;    // para mostrar "v1.2.0"
  final String? installedVersion; // de package_info_plus, útil para logs

  const AppUpdateState({
    this.status = UpdateStatus.idle,
    this.releaseNotes,
    this.forceUpdate = false,
    this.latestVersion,
    this.installedVersion,
  });

  AppUpdateState copyWith({...});
}
```

Cinco estados, mismo orden que el ejemplo. `downloading` lo usa solo el provider — el panel
visual lo lee directo del stream de `InstallStatus` de `in_app_update`, no de este enum.

---

## 4. Flujo de 3 pasos

```
┌─────────────────────────────────────────────────────────────────────────┐
│ AppShellScreen.initState ─► postFrame ─► checkForUpdate()              │
└────────────┬────────────────────────────────────────────────────────────┘
             │
             ▼
   ┌─────────────────────┐
   │  Edge Function      │ ──► status = updateAvailable + releaseNotes
   │  + InAppUpdate      │     forceUpdate, latestVersion
   │    .checkForUpdate()│
   └─────────┬───────────┘
             │
   ┌─────────▼────────────┐    ┌──────────────────────────────────────────┐
   │ Paso 1: hoja         │    │ UpdateBottomSheet                         │
   │ "Hay una nueva       │    │  - título + releaseNotes o mensaje       │
   │  versión"            │ ─► │  - "Actualizar ahora" (primary)           │
   │ "Actualizar /        │    │  - "Después" (text) si !forceUpdate       │
   │  Después"            │    └─────────────┬────────────────────────────┘
   └─────────┬────────────┘                  │ onUpdate
             │ onLater                       │ onLater (esconde, persiste)
             ▼                               ▼
     [persist: dismissadoEn=V]   startFlexibleUpdate()
                                          │
                                          ▼
                ┌──────────────────────────────────────────┐
                │ Paso 2: panel pegado al tabbar            │
                │  - ícono + título "Descargando"           │
                │  - subtítulo "Se instalará al terminar"   │
                │  - barra indeterminada (sweep)            │
                │ Se cierra solo cuando InstallStatus       │
                │ reporta downloaded                        │
                └─────────────┬────────────────────────────┘
                              │ InstallStatus.downloaded
                              ▼
                ┌──────────────────────────────────────────┐
                │ Paso 3: hoja de instalación               │
                │  - misma forma, sin "Después"              │
                │  - texto del botón: "Instalar ahora"      │
                │  - isDismissible: false                   │
                │ onUpdate ► completeFlexibleUpdate()       │
                └──────────────────────────────────────────┘
```

El wrapper (`AppUpdateWrapper`) usa `ref.listen` sobre el provider para reaccionar a
transiciones de estado. Cuando el listener detecta `updateAvailable` muestra la hoja; cuando
detecta `readyToInstall` muestra la hoja de instalación; el panel de descarga se monta y se
desmonta con `OverlayEntry` mirando `installUpdateStatusStream`.

---

## 5. Diseño — tokens de DESIGN.md

Toda la UI usa tokens. Cero colores, radios, espacios o duraciones hardcodeadas.

| Elemento | Token |
|---|---|
| Fondo de hoja / panel | `surface` |
| Fondo del overlay del panel | `surface` con borde superior 1px `rule` |
| Título de hoja | `titleLarge` (25 / 700), `ink` |
| Cuerpo de hoja | `bodyLarge` (16 / 400), `muted` |
| Botón principal | `primary` fill, `paper` label, `labelLarge` (13 / 500), `radiusCard` (12), 48 px alto |
| Botón "Después" | `labelLarge` `muted`, sin fondo |
| Drag handle | 48 × 5, `rule`, radio 999 |
| Sombra del panel | `elevation: 0` (la línea `rule` hace el trabajo de borde) |
| Ícono "Actualizar" | `Icons.system_update` (Material, ya en el paquete) |
| Radio de hoja | `radiusCard` (12) en la esquina superior — **no** 28 del ejemplo |
| Padding interno | `screenPadding md` lateral, `lg` arriba/abajo |
| Entrada de hoja | `AppMotion.long` (420 ms) con `easeOut` |
| Entrada del panel | slide vertical 220 ms `easeOut` desde detrás del tabbar |

El copy (todo es‑MX, tuteo):

| Slot | Texto |
|---|---|
| Título hoja paso 1 | `Hay una nueva versión de Vence` |
| Cuerpo paso 1 (con releaseNotes) | `Qué hay de nuevo:\n<releaseNotes>` |
| Cuerpo paso 1 (sin releaseNotes) | `Una nueva versión está disponible con mejoras y correcciones.` |
| Botón principal paso 1 | `Actualizar ahora` |
| Botón secundario paso 1 | `Después` |
| Título paso 2 | `Descargando actualización` |
| Subtítulo paso 2 | `Se instalará cuando termine` |
| Título hoja paso 3 | `Listo para instalar` |
| Cuerpo paso 3 | `La nueva versión ya está descargada. Instálala para seguir usando Vence.` |
| Botón principal paso 3 | `Instalar ahora` |

---

## 6. Estructura de archivos

Todo lo nuevo vive bajo `lib/data/.../update/` y `lib/ui/widgets/update/`, agrupado por feature
según CLAUDE.md.

```
lib/
  data/
    models/update/app_update_state.dart          # UpdateStatus enum + AppUpdateState
    services/update/app_update_service.dart      # wrapper InAppUpdate + llamada a Edge Function
    providers/update/app_update_provider.dart    # StateNotifier<AppUpdateState>
  ui/
    widgets/update/
      update_bottom_sheet.dart                  # hoja (dos voces vía props)
      update_download_panel.dart                # panel de descarga (OverlayEntry)
      app_update_wrapper.dart                   # orquesta estado → UI
```

Cuatro archivos nuevos, sin tocar `lib/main.dart` ni los providers existentes. `app_shell_screen.dart`
se modifica solo en su `build()`: envolver el `Scaffold` en `AppUpdateWrapper`.

Ningún archivo superará 300 líneas:
- `app_update_service.dart` ~ 120 líneas
- `app_update_provider.dart` ~ 100 líneas
- `update_bottom_sheet.dart` ~ 150 líneas (uso pesado de props para reutilizar la misma hoja en paso 1 y 3)
- `update_download_panel.dart` ~ 130 líneas
- `app_update_wrapper.dart` ~ 110 líneas

---

## 7. Detalle por archivo

### `app_update_service.dart`

Tres responsabilidades:

1. `Future<RemoteUpdateConfig?> fetchRemoteConfig()` — llama a la Edge Function vía
   `Supabase.instance.client.functions.invoke('app-version-android', method: HttpMethod.get)`.
   Devuelve `null` si la red falla o el body es inválido. **No lanza.**
2. `Future<AppUpdateInfo?> checkPlayStoreUpdate()` — envuelve `InAppUpdate.checkForUpdate()`.
   Devuelve `null` en error.
3. `startFlexibleUpdate()`, `completeFlexibleUpdate()` — pasamanos a `InAppUpdate.*`.
4. `Stream<InstallStatus> installStatusStream()` — pasamanos a
   `InAppUpdate.installUpdateStatusStream`. El panel se suscribe aquí.

### `app_update_provider.dart`

`StateNotifierProvider<AppUpdateNotifier, AppUpdateState>` (Riverpod legacy, igual que el
resto del proyecto). Métodos públicos:

- `checkForUpdate()` — orquesta el chequeo. Lee `package_info_plus` para `installedVersion`,
  consulta la Edge Function, consulta Play Store. Si Play Store reporta update disponible,
  combina con la config remota (`forceUpdate`, `releaseNotes`) y emite
  `updateAvailable`.
- `startFlexibleUpdate()` — llama a `service.startFlexibleUpdate()`, emite `downloading`. El
  panel escucha el stream independientemente.
- `completeUpdate()` — llama a `service.completeFlexibleUpdate()`. No emite estado: el SO mata
  la app para reiniciar.
- `dismissForThisVersion()` — persiste en `shared_preferences` el `versionCode` descartado.
  `checkForUpdate()` lo respeta si `forceUpdate` es `false`.

### `update_bottom_sheet.dart`

Un widget, dos voces. Props:

```dart
final String title;
final String body;
final String actionLabel;
final VoidCallback onAction;
final VoidCallback? onDismiss;   // null en paso 3 → no "Después"
final bool isDismissible;        // false en paso 3
```

`show()` estático con `showModalBottomSheet`. El drag handle se oculta cuando
`!isDismissible`. El botón "Después" solo se renderiza si `onDismiss != null`.

### `update_download_panel.dart`

`OverlayEntry` posicionado a `bottom: navBarHeight` para sentarse pegado al borde superior del
`ColoredNavBar`. Animación de entrada/salida con `AnimationController` (220 ms `easeOut`).
Suscripción al `installStatusStream`: cuando llega `InstallStatus.downloaded`, dispara el
reverse y se elimina. Sweep indeterminado en la barra (mismo patrón que el ejemplo, sin
bytesDownloaded porque `in_app_update` no los expone en el listener).

### `app_update_wrapper.dart`

`ConsumerStatefulWidget` con un `ref.listen<AppUpdateState>` que dispara:

| Transición | Acción |
|---|---|
| → `updateAvailable` (sin `downloadedThisSession`) | `showUpdateSheet()` |
| → `downloading` | `UpdateDownloadPanel.show(context)` |
| → `readyToInstall` | `showInstallSheet()` |
| → `error` | log + no UI (no castiga al usuario por un fallo de red) |

Guardas:
- `_sheetVisible` para evitar abrir dos hojas si el estado oscila.
- `Platform.isAndroid` en todos los entry points; en iOS el wrapper es no‑op.
- Se monta **una sola vez** en `app_shell_screen.dart` envolviendo el `Scaffold` completo.

---

## 8. Manifiesto y dependencias

### `pubspec.yaml`

Añadir (sujeto a tu OK):

```yaml
in_app_update: ^4.2.5
package_info_plus: ^9.0.1
```

El plugin `in_app_update` declara su propio `<queries>` para el intent de Play Store — el
`AndroidManifest.xml` no necesita cambios. Verificar tras `flutter pub get` con
`grep "in_app_update" android/app/build/intermediates/.../AndroidManifest.xml`.

### `lib/core/constants/environment.dart`

Una sola constante nueva:

```dart
static const String appVersionFunctionUrl = String.fromEnvironment(
  'APP_VERSION_FUNCTION_URL',
);
```

`Supabase.functions.invoke` usa el cliente global, no una URL separada; este string es
**solo** un flag de feature flag para apagar el chequeo de updates en builds internas sin tocar
código. Si está vacío, `checkForUpdate()` retorna sin hacer nada.

### `.env.example`

Añadir:

```
APP_VERSION_FUNCTION_URL=
```

### `android/app/src/main/AndroidManifest.xml`

Sin cambios. `in_app_update` no requiere permisos nuevos.

---

## 9. La Edge Function (referencia, vive en `supabase/`)

La función se llama `app-version-android` y vive en
`supabase/functions/app-version-android/index.ts`. No es código Flutter, pero el plan la
describe porque el cliente depende de su contrato.

**Request:** `GET` con header `Authorization: Bearer <publishable_key>`. Sin body.

**Response (200):**

```json
{
  "versionCode": 3,
  "versionName": "1.0.2",
  "releaseNotes": "Mejoras en el resumen y corrección de errores al archivar tarjetas.",
  "forceUpdate": false
}
```

**Response (503):** falla de Google Play → el cliente trata como no‑hay‑update.

**Campos:**

| Campo | Fuente |
|---|---|
| `versionCode` / `versionName` | `GooglePlayDeveloperAPI.edits.get` sobre el track interno, o `bundleDetails` |
| `releaseNotes` | "What's new" del último release en el Play Console (campo "Release notes" en el formulario de publicación) |
| `forceUpdate` | Tabla `app_update_config` en Supabase, editable desde el dashboard. Default `false` |

Si `releaseNotes` viene vacío, la Edge Function rellena con `"Nueva versión disponible."`
para que el cliente no tenga que decidir. El cliente trata `null` como ausente y muestra el
mensaje por defecto de Vence.

---

## 10. Plan de implementación

Una sola rama: `feature/in-app-update`. Toca archivos nuevos + una línea en
`app_shell_screen.dart` + una constante en `environment.dart` + una línea en `.env.example`.

| Paso | Acción | Termina cuando |
|---|---|---|
| 1 | Crear `app_update_state.dart` + `app_update_service.dart` con su interfaz pública | `flutter analyze` limpio |
| 2 | Crear `app_update_provider.dart` | `flutter analyze` limpio, el provider se lee en un `Consumer` de prueba sin lanzar |
| 3 | Crear `update_bottom_sheet.dart` | `flutter analyze` limpio |
| 4 | Crear `update_download_panel.dart` | `flutter analyze` limpio, animación verificada con un `OverlayEntry` de prueba |
| 5 | Crear `app_update_wrapper.dart` y montarlo en `app_shell_screen.dart` | `./scripts/format.sh` limpio |
| 6 | Edge Function `app-version-android` desplegada en Supabase | La función responde 200 con un body válido |
| 7 | Subir versión 1.0.2+3 a Play Console con "What's new" lleno y la función devolviendo `forceUpdate: false` | Build AAB subido al track interno |
| 8 | Instalación lado a lado: instalar 1.0.1+2 desde APK local, abrir la app, ver la hoja, tocar "Actualizar ahora" | El panel aparece pegado al tabbar, descarga termina, hoja de instalación aparece |
| 9 | Repetir con `forceUpdate: true` | La hoja de paso 1 no tiene "Después" y no cierra con drag |
| 10 | Borrar el APK 1.0.1+2, abrir 1.0.2+3 instalada | El provider no muestra hoja (no hay update disponible) |

Una vez los 10 pasos pasan, se reporta y se mergea a `develop`. Sin commits del agente.

---

## 11. Riesgos y cosas que no se prueban

| Riesgo | Mitigación |
|---|---|
| Play Store no reporta update en cuentas de prueba internas | El wrapper hace un solo intento; si la Edge Function devuelve 503 o `checkForUpdate` devuelve null, no se muestra UI. No se molesta al usuario |
| `in_app_update` falla en algún OEM con skin | Capturamos todas las llamadas en `try / catch (e)` y dejamos al provider en `error`. Sin UI, sin crash |
| `InstallStatus.downloaded` no llega | El panel tiene un timeout duro de 5 min: si no recibe `downloaded` ni `failed`, se auto‑elimina y vuelve a abrir la hoja de paso 1 (estado `updateAvailable` otra vez). No se queda pegado |
| El usuario oprime "Después" dos veces | El wrapper no vuelve a mostrar la hoja en la misma sesión. Persistimos `dismissedAt` con la versión actual; `checkForUpdate()` lo respeta si `forceUpdate` es false |
| Release notes vienen en inglés | La Edge Function tiene un paso de traducción opcional (Whisper o LLM barato). Si no hay release notes, mensaje por defecto |

### Lo que no se prueba en CI

El flujo completo requiere una versión anterior instalada y una nueva disponible en Play Store
interno. Eso solo se prueba a mano, en pasos 8 y 9. CI valida con `flutter test` solo que el
servicio expone la firma esperada y que el provider emite los estados correctos con mocks de
`InAppUpdate` y de la Edge Function.

---

## 12. Resumen de cambios por archivo

```
A  lib/core/constants/environment.dart           +1 línea (appVersionFunctionUrl)
A  .env.example                                  +1 línea
M  lib/ui/screens/shell/app_shell_screen.dart    wrap Scaffold en AppUpdateWrapper
A  lib/data/models/update/app_update_state.dart
A  lib/data/services/update/app_update_service.dart
A  lib/data/providers/update/app_update_provider.dart
A  lib/ui/widgets/update/update_bottom_sheet.dart
A  lib/ui/widgets/update/update_download_panel.dart
A  lib/ui/widgets/update/app_update_wrapper.dart
A  supabase/functions/app-version-android/index.ts
A  supabase/functions/app-version-android/deno.json (si no existe ya)
A  test/services/update/app_update_service_test.dart
A  test/providers/update/app_update_provider_test.dart
```

Ningún archivo modificado existente crece más de 10 líneas. Ningún archivo nuevo pasa de 200.