# Veda — Guía de configuración e instalación

## Estructura del proyecto

```
Veda/
├── Veda/                         ← Target principal (app)
│   ├── App/
│   │   ├── VedaApp.swift
│   │   └── Info.plist
│   ├── Models/                   (vacío; modelos en VedaShared)
│   ├── Views/
│   │   ├── RootView.swift
│   │   ├── AuthorizationRequestView.swift
│   │   ├── HomeView.swift
│   │   ├── GroupRowView.swift
│   │   └── GroupEditView.swift
│   └── ViewModels/
│       ├── AuthorizationViewModel.swift
│       └── BlockGroupsViewModel.swift
│
├── VedaMonitor/                  ← Target extensión DeviceActivityMonitor
│   ├── VedaMonitorExtension.swift
│   └── Info.plist
│
├── VedaShared/                   ← Código compartido (añadir a ambos targets)
│   ├── AppGroup.swift
│   ├── BlockGroup.swift
│   └── ScheduleManager.swift
│
└── Configuration/
    ├── Veda.entitlements
    └── VedaMonitor.entitlements
```

---

## Paso 1 — Crear el proyecto en Xcode

1. **File › New › Project** → App → SwiftUI, Swift, iOS 16+.
2. Nombre: `Veda`, Bundle ID: `com.TUAPPLEID.veda`  
   (reemplaza `TUAPPLEID` con el prefijo de tu Apple ID, ej. `com.ivan.veda`).
3. Guarda en la carpeta del repositorio clonado.

---

## Paso 2 — Crear el target de extensión

1. **File › New › Target** → **DeviceActivity Monitor Extension**.
2. Nombre del producto: `VedaMonitor`.
3. Bundle ID resultante: `com.TUAPPLEID.veda.monitor`.
4. Xcode crea automáticamente el target y un archivo de extensión base;  
   **reemplaza** su contenido con `VedaMonitor/VedaMonitorExtension.swift`.

---

## Paso 3 — Añadir archivos al proyecto

### VedaShared (añadir a AMBOS targets)

1. Arrastra los tres archivos de `VedaShared/` al navigator de Xcode.
2. En el diálogo **"Add to targets"**, marca **Veda** y **VedaMonitor**.

### VedaMonitor/VedaMonitorExtension.swift

Asegúrate de que solo pertenece al target `VedaMonitor`.

---

## Paso 4 — Configurar el App Group

### En el portal de Apple (developer.apple.com)

1. Ve a **Certificates, IDs & Profiles › Identifiers**.
2. Selecciona tu App ID `com.TUAPPLEID.veda` y activa **App Groups**.
3. Crea el grupo: `group.com.TUAPPLEID.veda`.
4. Repite para `com.TUAPPLEID.veda.monitor` y añade el mismo grupo.

### En Xcode — Target Veda

1. Selecciona el target **Veda** → **Signing & Capabilities**.
2. **+ Capability** → **App Groups**.
3. Añade `group.com.TUAPPLEID.veda`.

### En Xcode — Target VedaMonitor

Mismos pasos para el target **VedaMonitor**.

---

## Paso 5 — Habilitar Family Controls

### Opción A — Desde Xcode (recomendada para uso personal)

1. Target **Veda** → **Signing & Capabilities** → **+ Capability** → **Family Controls**.
2. Repite para **VedaMonitor**.

> Xcode añade automáticamente `com.apple.developer.family-controls` al entitlements.

### Opción B — Manualmente

Asegúrate de que ambos archivos `.entitlements` contienen:
```xml
<key>com.apple.developer.family-controls</key>
<true/>
```
Y en **Build Settings** de cada target, ajusta:
- `CODE_SIGN_ENTITLEMENTS` → ruta al archivo `.entitlements` correspondiente.

---

## Paso 6 — Actualizar Bundle IDs y App Group ID en el código

Busca y reemplaza `com.tuappleid` y `group.com.tuappleid.veda` en:

| Archivo | Campo |
|---------|-------|
| `VedaShared/AppGroup.swift` | `identifier` |
| `Veda/App/Info.plist` | `CFBundleIdentifier` |
| `VedaMonitor/Info.plist` | `CFBundleIdentifier` |
| `Configuration/Veda.entitlements` | App Groups array |
| `Configuration/VedaMonitor.entitlements` | App Groups array |

---

## Paso 7 — Frameworks (Build Phases › Link Binary With Libraries)

### Target Veda
- `FamilyControls.framework`
- `ManagedSettings.framework`
- `DeviceActivity.framework`

### Target VedaMonitor
- `FamilyControls.framework`
- `ManagedSettings.framework`
- `DeviceActivity.framework`

---

## Paso 8 — Firma y despliegue en tu iPhone

1. Conecta tu iPhone al Mac.
2. En **Signing & Capabilities** de cada target:
   - **Team**: selecciona tu Apple ID personal.
   - **Automatically manage signing**: activado.
3. Selecciona tu iPhone como destino en la barra de Xcode.
4. **Product › Run** (⌘R).
5. En tu iPhone: **Ajustes › General › VPN y gestión de dispositivos** →  
   confía en tu certificado de desarrollador.

---

## Paso 9 — Autorizar Screen Time en el dispositivo

La primera vez que abras Veda, aparecerá la pantalla de autorización.  
Toca **Autorizar Screen Time** y acepta el diálogo del sistema.

---

## Funcionamiento interno

```
Ventana de disponibilidad:  [07:00 ──────────── 15:00]
                                ↑                   ↑
                        intervalDidStart     intervalDidEnd
                        clearShield()        applyShield()

Fuera de ventana:       [00:00 ──── 07:00] y [15:00 ──── 24:00]
                              BLOQUEADO              BLOQUEADO
```

Al arrancar la app, `ScheduleManager.applyCurrentState()` evalúa la hora
actual y aplica o quita los shields inmediatamente, sin esperar al siguiente
evento del schedule.

---

## Limitaciones conocidas del Screen Time API

| Limitación | Detalle |
|------------|---------|
| **Privacidad de tokens** | `ApplicationToken`, `CategoryToken` y `WebDomainToken` son opacos; no puedes leer el nombre de la app en tiempo de ejecución en la extensión. |
| **Sin distribución en App Store** | Las apps con `com.apple.developer.family-controls` **no pueden publicarse** en el App Store; solo sideload / TestFlight con perfil de capacidades especial. Para uso personal con tu Apple ID esto es correcto. |
| **Latencia del shield** | El sistema puede tardar algunos segundos en mostrar/ocultar el shield tras aplicar `ManagedSettingsStore`. |
| **Modo de autorización `.individual`** | Solo puede autorizar el usuario del dispositivo; no admite cuentas de menores gestionadas desde otro dispositivo. |
| **Persistencia de schedules** | Los schedules de `DeviceActivityCenter` se pierden si el usuario reinstala la app; siempre llama a `syncSchedules()` en `onAppear`. |
| **Background execution** | La extensión DeviceActivityMonitor tiene tiempo de CPU limitado; evita operaciones costosas en `intervalDidStart/intervalDidEnd`. |
| **No se bloquean notificaciones directamente** | ManagedSettings shieldea el acceso visual a la app, pero las notificaciones del sistema (banners, sonidos) pueden seguir llegando. Para suprimir notificaciones habría que configurar también `notificationSettings` en el `ManagedSettingsStore` — ver nota abajo. |

### Suprimir notificaciones durante el bloqueo (opcional)

Añade esto en `ScheduleManager.applyShield()`:

```swift
// Silenciar notificaciones de las apps bloqueadas
store.notifications.badgingEnabled = false
// No hay API pública para silenciar banners por app individual en iOS 16;
// el silenciado de notificaciones requiere gestión de perfiles MDM para casos avanzados.
```

> Para un bloqueo completo de notificaciones (sin MDM), la alternativa más
> robusta es usar **Focus filters** (App Intents + Focus modes) combinados
> con esta solución.
