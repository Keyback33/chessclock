# Compilación y firma

El proyecto Flutter se encuentra directamente en la raíz `chessclock`. Nombre de aplicación y paquete Flutter: `chessclock`; applicationId y namespace Android: `ar.com.chessclock.chessclock`. Versión actual: `1.1.1+3`.

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
flutter test integration_test -d emulator-5554
./scripts/Build-Release.ps1
```

`Build-Release.ps1` analiza, prueba, compila, copia el APK universal a `dist` y comprueba firma, versión, mínimo Android y ausencia de permisos de red. `Verify-Apk.ps1` permite repetir la verificación sin recompilar. El APK incluye las ABI ARM de 32 bits (`armeabi-v7a`), ARM de 64 bits (`arm64-v8a`) y x86 de 64 bits (`x86_64`).

Los scripts obtienen nombre y código de versión de `pubspec.yaml`. La entrega actual es `dist/chessclock-1.1.1.apk`, con su `.sha256` y los informes públicos de firma y manifiesto en `dist/1.1.1/`. Los artefactos 1.0.0 se conservan como entrega histórica.

El JDK global del equipo es antiguo; Flutter utiliza el JDK de Android Studio. Los scripts seleccionan ese mismo JDK. Para otra instalación, pasar `-JavaHome` y `-AndroidSdk` a los scripts. Las rutas de `android/local.properties` son locales y se excluyen del control de versiones.

La primera preparación puede descargar artefactos de Flutter, Gradle, Maven y Android. La aplicación instalada no descarga nada. Una compilación sin red requiere que todas las dependencias y herramientas estén previamente en caché; no se afirma que una máquina vacía pueda compilar sin Internet.

## Firma de producción

Se usa una clave RSA de 3072 bits propia, alias `chessclock`, con una validez de 10000 días. No se utiliza la clave de depuración. Los datos privados quedan en:

- `.signing/chessclock-release.jks`: clave de firma.
- `android/key.properties`: referencia local y contraseñas.

Ambos están excluidos del repositorio y de `dist`, y protegidos con permisos de Windows. **Conservar una copia segura de ambos fuera del proyecto**: las actualizaciones necesitan la misma clave. Los scripts nunca imprimen la contraseña. `New-SigningKey.ps1` genera la firma solo para una instalación nueva y se niega a reemplazar material existente. No regenerarla para futuras versiones. El certificado público y el resultado de `apksigner` se entregan en `dist/<versión>/signature.txt`.

Para otra versión, incrementar `version` en `pubspec.yaml` y mantener el identificador y la clave. Los scripts usan automáticamente la nueva versión. `dist/` y `PLAN_IMPLEMENTACION.md` son archivos locales excluidos de Git.

## Arquitectura

- `lib/domain`: motor Dart puro, reloj monotónico inyectable, modelos y protección de contactos.
- `lib/controllers`: transiciones, un temporizador de vencimiento y persistencia por transición. Cada cancelación invalida callbacks anteriores.
- `lib/ui`: pantalla de juego adaptable, configuración y esfera vectorial original con `CustomPainter`. `Ticker` activo solo mientras corre la partida.
- `lib/platform` y `MainActivity.kt`: canal propio para ruta privada, pantalla encendida, tonos, vibración y orientación por sensor o eje manual.
- `lib/storage`: JSON con esquema validado, cola de escrituras y reemplazo mediante archivo temporal. Datos en `noBackupFilesDir`; recuperación explícita en pausa.

La hora civil no participa en los relojes ni en la recuperación. La precisión del motor no depende de la frecuencia de los fotogramas.

### Orientación

`ClockOrientation` se guarda en la configuración local; los datos anteriores usan Automática por defecto. El canal Android aplica `FULL_SENSOR`, `SENSOR_PORTRAIT` o `SENSOR_LANDSCAPE`. `RotatedBox` mantiene Jugador 2 a 180° y Jugador 1 a 0° dentro de la ventana, tanto en vertical como en horizontal. Android realiza el giro de la ventana; no se añade un cuarto de vuelta que lo compense. Se giran juntos esfera, números y controles, sin reiniciar el motor. En ventanas cuyo lado corto disponible es de al menos 600 dp, la disposición manual también se aplica dentro de la ventana si Android ignora el giro solicitado.

Validación de 1.1.1: análisis sin incidencias, 36 pruebas unitarias/widgets e integración en Pixel_10 (API 37). Se verifican los ejes visibles de esfera y números, persistencia y conservación de la partida. APK firmado instalado y rotación automática revisada visualmente en ese emulador; comprobación en teléfono físico pendiente.

Referencias oficiales consultadas: [distribución Android de Flutter](https://docs.flutter.dev/deployment/android), [canales de plataforma](https://docs.flutter.dev/platform-integration/platform-channels) y [Stopwatch](https://api.flutter.dev/flutter/dart-core/Stopwatch-class.html).
