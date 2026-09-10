# Tarot para Android (Kotlin + Jetpack Compose)

Port nativo de **Nicole´s Tarot** a Android. Reutiliza los mismos datos que la app iOS
(`cards.json` con las 78 cartas, ilustraciones Rider-Waite y dorso del mazo).

## Qué incluye

- **Tiradas** — las 22 tiradas de la app iOS (incluidas las esotéricas: Árbol de la Vida,
  Espejo del Alma, Gran Obra Alquímica, Ciclo Lunar, etc.) con reparto, revelación
  carta a carta, interpretación por posición y guardado en el diario.
- **Carta del día** — servicio determinista portado de `DeterministicDailyCardService`
  (misma semilla `año·366 + día`, combinada con la fase lunar) y revelación persistente.
- **Biblioteca** — las 78 cartas con filtros (Mayores / por palo), significados
  derecho e invertido, lecturas contextuales, aspectos (Amor/Salud/Carrera/Economía),
  correspondencias esotéricas y el contenido del libro *Guía Definitiva del Tarot*.
- **Diario** — lecturas guardadas con fase lunar, notas de hasta 2000 caracteres,
  edición y borrado; persistencia en JSON dentro de `filesDir`.
- **Ajustes** — nombre de usuario, cartas invertidas, número de cartas de la tirada
  libre y borrado de datos. Bienvenida de primer arranque incluida.

## Requisitos

- Android Studio (Koala/Ladybug o más reciente) con SDK de Android 35.
- JDK 17 (incluido en Android Studio).

## Cómo compilar

1. Abre Android Studio → **File ▸ Open** → selecciona la carpeta `android/` de este repo.
2. Deja que Gradle sincronice (descargará Gradle 8.9 y las dependencias la primera vez).
3. ▶︎ Run sobre un dispositivo o emulador con Android 8.0 (API 26) o superior.

Desde consola (con el SDK instalado y `local.properties` apuntando a él):

```bash
cd android
gradle wrapper --gradle-version 8.9   # solo la primera vez, si falta el wrapper JAR
./gradlew :app:assembleDebug
```

El APK queda en `app/build/outputs/apk/debug/app-debug.apk`.

## Arquitectura

```
app/src/main/
├── assets/                  # cards.json + 79 ilustraciones (78 cartas + dorso)
├── java/com/arcana/tarot/
│   ├── core/models/         # Card, SpreadType (22 tiradas), JournalEntry
│   ├── data/                # CardRepository, DailyCardService, JournalStore, SettingsStore
│   ├── ui/                  # AppViewModel, MainActivity, theme/, components/, screens/
│   └── ...
└── res/                     # tema oscuro, icono adaptativo
```

- **UI**: Jetpack Compose + Material 3, tema oscuro con la paleta mística de iOS
  (púrpura `#0F0A21`, oro lavanda `#9986FF`).
- **Datos**: `kotlinx-serialization` sobre `assets/cards.json` (mismo archivo que iOS).
- **Imágenes**: Coil leyendo los PNG de `assets/cards/`.

## Pendientes para futuras iteraciones

- Salas de audio ambiente (los WAV de 396/432/528 Hz de iOS) y vibraciones.
- Biblioteca de libros PDF, chat con IA y bóveda secreta.
- Widget de carta del día para la pantalla de inicio.
