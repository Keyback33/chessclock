# Compilación y firma

El proyecto Flutter se encuentra directamente en la raíz `chessclock`. Nombre de aplicación y paquete Flutter: `chessclock`; applicationId y namespace Android: `ar.com.chessclock.chessclock`. Versión actual: `1.4.0+6`.

## Entorno fijado

| Componente | Versión utilizada |
| --- | --- |
| Flutter estable | 3.41.9, revisión 00b0c91f06209d9e4a41f71b7a512d6eb3b9c694 |
| Dart | 3.11.5 |
| JDK de Android Studio | OpenJDK 21.0.10, build 21.0.10+-14961533-b1163.108 |
| Gradle | 8.14 |
| Android Gradle Plugin | 8.11.1 |
| Kotlin | 2.2.20 |
| Android compileSdk / targetSdk | 36 / 36 |
| Android minSdk | 24: Android 7.0 Nougat |
| NDK | 28.2.13676358 |
| SDK Build Tools para verificación | 36.1.0 |
| Java/Kotlin bytecode target | 17 |

No actualizar esta combinación durante una reproducción. `pubspec.lock` fija las dependencias transitivas del SDK. Las únicas dependencias declaradas son Flutter y sus SDK de pruebas; no hay paquetes externos de ejecución agregados. Las transitivas de Flutter y sus herramientas forman parte de la cadena de compilación.

## Reproducir

En PowerShell 7, desde la raíz:

```powershell
flutter --version
flutter doctor -v
flutter pub get
flutter analyze
flutter test
flutter test integration_test/endgame_audio_test.dart -d emulator-5554
flutter test integration_test/game_flow_test.dart -d emulator-5554
flutter test integration_test/orientation_flow_test.dart -d emulator-5554
./scripts/Build-Release.ps1
```

`Build-Release.ps1` analiza, prueba, compila, copia el APK universal a `dist` y comprueba firma, versión, mínimo Android y ausencia de permisos de red. `Verify-Apk.ps1` permite repetir la verificación sin recompilar. El APK incluye las ABI ARM de 32 bits (`armeabi-v7a`), ARM de 64 bits (`arm64-v8a`) y x86 de 64 bits (`x86_64`).

Los scripts obtienen nombre y código de versión de `pubspec.yaml`. La entrega actual es `dist/chessclock-1.4.0.apk`, con su `.sha256` y los informes públicos de firma y manifiesto en `dist/1.4.0/`. Después de verificar el APK nuevo, `Remove-OldReleases.ps1` conserva únicamente la versión recién generada y verificada (actualmente 1.4.0), junto con su checksum e informes. Elimina artefactos anteriores y los informes históricos de la raíz. Si falla la compilación o verificación, no se ejecuta la limpieza. `scripts/Test-ReleaseRetention.ps1` comprueba esta política con archivos temporales.

El JDK global del equipo es antiguo; Flutter utiliza el JDK de Android Studio. Los scripts seleccionan ese mismo JDK. Para otra instalación, pasar `-JavaHome` y `-AndroidSdk` a los scripts. Las rutas de `android/local.properties` son locales y se excluyen del control de versiones.

La primera preparación puede descargar artefactos de Flutter, Gradle, Maven y Android. La aplicación instalada no descarga nada. Una compilación sin red requiere que todas las dependencias y herramientas estén previamente en caché; no se afirma que una máquina vacía pueda compilar sin Internet.

## Firma de producción

Se usa una clave RSA de 3072 bits propia, alias `chessclock`, con una validez de 10000 días. No se utiliza la clave de depuración. Los datos privados quedan en:

- `.signing/chessclock-release.jks`: clave de firma.
- `android/key.properties`: referencia local y contraseñas.

Ambos están excluidos del repositorio y de `dist`, y protegidos con permisos de Windows. **Conservar una copia segura de ambos fuera del proyecto**: las actualizaciones necesitan la misma clave. Los scripts nunca imprimen la contraseña. `New-SigningKey.ps1` genera la firma solo para una instalación nueva y se niega a reemplazar material existente. No regenerarla para futuras versiones. El certificado público y el resultado de `apksigner` se entregan en `dist/<versión>/signature.txt`.

Para otra versión, incrementar `version` en `pubspec.yaml` y mantener el identificador y la clave. Los scripts usan automáticamente la nueva versión. `dist/` se incluye en Git con una sola entrega; al preparar el commit, incluir también las eliminaciones de los artefactos anteriores (`git add -A dist`). Esto actualiza el contenido de la rama sin reescribir el historial de Git. `PLAN_IMPLEMENTACION.md` permanece excluido.

## Arquitectura

- `lib/domain`: motor Dart puro, reloj monotónico inyectable, modelos y protección de contactos.
- `lib/controllers`: transiciones, un temporizador de vencimiento y persistencia por transición. Cada cancelación invalida callbacks anteriores.
- `lib/ui`: pantalla de juego adaptable, configuración y esfera vectorial original con `CustomPainter`. `Ticker` activo solo mientras corre la partida.
- `lib/platform` y `MainActivity.kt`: canal propio para ruta privada, pantalla encendida, clic mecánico precargado con SoundPool, MP3 de fin de partida con MediaPlayer, vibración y orientación por sensor o eje manual.
- `lib/storage`: JSON con esquema validado, cola de escrituras y reemplazo mediante archivo temporal. Datos en `noBackupFilesDir`; recuperación explícita en pausa.

La hora civil no participa en los relojes ni en la recuperación. La precisión del motor no depende de la frecuencia de los fotogramas.

### Orientación

`ClockOrientation` se guarda en la configuración local; los datos anteriores usan Automática por defecto. El canal Android aplica `FULL_SENSOR`, `SENSOR_PORTRAIT` o `SENSOR_LANDSCAPE`. `RotatedBox` mantiene Jugador 2 a 180° y Jugador 1 a 0° dentro de la ventana, tanto en vertical como en horizontal. Android realiza el giro de la ventana; no se añade un cuarto de vuelta que lo compense. Se giran juntos esfera, números y controles, sin reiniciar el motor. En ventanas cuyo lado corto disponible es de al menos 600 dp, la disposición manual también se aplica dentro de la ventana si Android ignora el giro solicitado.

Validación de 1.1.1: análisis sin incidencias, 36 pruebas unitarias/widgets e integración en Pixel_10 (API 37). Se verifican los ejes visibles de esfera y números, persistencia y conservación de la partida. APK firmado instalado y rotación automática revisada visualmente en ese emulador; comprobación en teléfono físico pendiente.

Referencias oficiales consultadas: [distribución Android de Flutter](https://docs.flutter.dev/deployment/android), [canales de plataforma](https://docs.flutter.dev/platform-integration/platform-channels) y [Stopwatch](https://api.flutter.dev/flutter/dart-core/Stopwatch-class.html).

### Sonido de jugada

Los archivos de sonido se ubican en `assets/audio/`, en la raíz del proyecto. La carpeta está declarada en `pubspec.yaml`; Flutter la incluye en la aplicación y Android obtiene la ruta empaquetada mediante `FlutterLoader.getLookupKeyForAsset`. SoundPool carga el descriptor del archivo desde `AssetManager`, sin mantener una copia en `android/app/src/main/res/raw/`.

El clic actual es `assets/audio/move_click.mp3`. Android lo precarga al iniciar y libera SoundPool al destruir la actividad. Se reproduce una vez por jugada aceptada, sin esperar el audio para alternar relojes; no se encolan clics si la carga todavía no terminó. La opción Sonido controla clic y alarma. El clic usa volumen multimedia y la alarma usa volumen de alarma. Referencia: [SoundPool de Android](https://developer.android.com/reference/android/media/SoundPool).

El script `python scripts/Generate-MoveClick.py` conserva el generador del WAV original (PCM mono de 16 bits, 44,1 kHz, 115 ms). No genera ni reemplaza el MP3 actual; su salida `assets/audio/move_click.wav` no se utiliza para reproducir el clic.

Validación de 1.2.0: análisis sin incidencias y 41 pruebas unitarias/widgets aprobadas; integraciones de juego y orientación aprobadas por separado en API 24. En API 37 pasó el flujo de juego; la integración de orientación se interrumpió por inestabilidad del emulador y queda pendiente allí. APK de producción instalado y revisado visualmente en API 24, con ambos pulsadores activos y cambio de turno. Audio incluido en el APK y PCM sin saturación; percepción y latencia en teléfono físico pendientes. Retención comprobada con fixtures y con la distribución real: solo 1.1.1 y 1.2.0, con checksums correctos.

### Audio de fin de partida

AndroidServices elige uniformemente uno de los cinco archivos assets/audio/endgame_1.mp3 a endgame_5.mp3 al solicitar una alarma con sonido. El controlador solicita una sola alarma por partida finalizada; recuperar un resultado guardado no la repite. Cada sorteo es independiente y puede repetir el audio de la partida anterior. Probar alarma usa el mismo mecanismo.

Android reproduce exclusivamente el archivo elegido con MediaPlayer, preparación asíncrona, sin bucle y hasta su final. Se conserva el volumen de alarma. La vibración termina por separado, sin cortar el MP3 a los 3,5 segundos. Silenciar, reiniciar o pasar a segundo plano libera el reproductor y cancela incluso una carga pendiente. El canal completa la operación al finalizar, cancelarse o fallar la reproducción. Referencia: [MediaPlayer](https://developer.android.com/media/platform/mediaplayer/basics).

Validación de 1.3.0: análisis sin incidencias, 44 pruebas unitarias/widgets aprobadas e integraciones de audio y juego aprobadas en API 24. Los cinco MP3 se reprodujeron hasta completar la operación nativa; se comprobaron cancelación durante la preparación, reemplazo de reproducción, sonido desactivado y rechazo de una ruta inválida. El APK firmado contiene los seis audios originales sin modificaciones y accesibles por descriptor. Distribución verificada con únicamente 1.2.0 y 1.3.0. La percepción del audio en teléfono físico sigue pendiente.

### Pulsador encastrado y capturas

`MoveButton` usa 17 posiciones por jugador de `assets/images/move_button.png` (atlas de 6 × 6 celdas, 296 × 250 px por celda). El atlas conserva la geometría y los reflejos del diseño aprobado, con el cuerpo limitado al interior de la base. Flutter comparte la imagen decodificada y anima solo el recorte visible; no ejecuta un motor 3D ni incorpora dependencias nuevas de ejecución. El margen transparente vertical se recorta para reservar más espacio a la esfera.

La presión dura 90 ms; el retorno comienza tras 70 ms y dura 160 ms. Los temporizadores de retorno se cancelan al cambiar de estado o desmontar el control. `MediaQuery.disableAnimations` aplica el estado final de inmediato. La lógica de contactos y el cambio de turno permanecen en el controlador y no esperan la animación.

El recurso ya está incluido: no hace falta regenerarlo para compilar. Para modificar el acabado, ejecutar `node scripts/Generate-MoveButton.cjs` en un entorno de desarrollo con Node.js, Playwright y Microsoft Edge; si Playwright está en una instalación compartida, indicar su directorio de paquetes en `NODE_PATH`. El generador usa `scripts/move_button_renderer.js` y produce las 34 posiciones de ambos jugadores.

Las capturas del README se obtienen desde la aplicación Android mediante:

```powershell
flutter drive --driver=test_driver/screenshots.dart --target=integration_test/visual_flow_test.dart -d emulator-5554
```

El flujo prepara una partida de 10 minutos sin modificar las preferencias guardadas, acciona ambos pulsadores, verifica el cambio de orientación y captura vertical, horizontal y configuración. El driver guarda los PNG en `docs/images/`.

Validación de 1.4.0: análisis sin incidencias, 47 pruebas unitarias/widgets aprobadas y flujo visual aprobado en Android API 24. Se comprobaron contacto inmediato, bloqueo de contactos simultáneos, animación, cancelación del retorno, movimiento reducido y distribución adaptable, incluido el estado final con texto ampliado. Las capturas verifican las posiciones finales de ambos pulsadores. El APK firmado tiene versión 1.4.0+6, mínimo API 24 y no declara permisos de red. Los seis MP3 y el atlas coinciden byte por byte con los recursos originales; el WAV anterior no está incluido. Distribución conservada: únicamente 1.4.0; retención de una entrega comprobada con fixtures y con los artefactos reales. Percepción de audio, vibración y latencia en teléfono físico pendientes.
