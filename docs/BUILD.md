# Compilación y firma

El proyecto Flutter se encuentra directamente en la raíz `chessclock`. Nombre de aplicación y paquete Flutter: `chessclock`; applicationId y namespace Android: `ar.com.chessclock.chessclock`. Versión inicial: `1.0.0+1`.

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

El JDK global del equipo es antiguo; Flutter utiliza el JDK de Android Studio. Los scripts seleccionan ese mismo JDK. Para otra instalación, pasar `-JavaHome` y `-AndroidSdk` a los scripts. Las rutas de `android/local.properties` son locales y se excluyen del control de versiones.

La primera preparación puede descargar artefactos de Flutter, Gradle, Maven y Android. La aplicación instalada no descarga nada. Una compilación sin red requiere que todas las dependencias y herramientas estén previamente en caché; no se afirma que una máquina vacía pueda compilar sin Internet.

## Firma de producción

Se usa una clave RSA de 3072 bits propia, alias `chessclock`, con una validez de 10000 días. No se utiliza la clave de depuración. Los datos privados quedan en:

- `.signing/chessclock-release.jks`: clave de firma.
- `android/key.properties`: referencia local y contraseñas.

Ambos están excluidos del repositorio y de `dist`, y protegidos con permisos de Windows. **Conservar una copia segura de ambos fuera del proyecto**: las actualizaciones necesitan la misma clave. Los scripts nunca imprimen la contraseña. `New-SigningKey.ps1` genera la firma solo para una instalación nueva y se niega a reemplazar material existente. No regenerarla para futuras versiones. El certificado público y el resultado de `apksigner` se entregan en `dist/signature.txt`.

Para otra versión, incrementar `version` en `pubspec.yaml`, mantener el identificador y la clave, y adaptar el nombre/versiones esperadas en los scripts de distribución.

## Arquitectura

- `lib/domain`: motor Dart puro, reloj monotónico inyectable, modelos y protección de contactos.
- `lib/controllers`: transiciones, un temporizador de vencimiento y persistencia por transición. Cada cancelación invalida callbacks anteriores.
- `lib/ui`: pantalla de juego adaptable, configuración y esfera vectorial original con `CustomPainter`. `Ticker` activo solo mientras corre la partida.
- `lib/platform` y `MainActivity.kt`: canal propio para ruta privada, pantalla encendida, tonos y vibración.
- `lib/storage`: JSON con esquema validado, cola de escrituras y reemplazo mediante archivo temporal. Datos en `noBackupFilesDir`; recuperación explícita en pausa.

La hora civil no participa en los relojes ni en la recuperación. La precisión del motor no depende de la frecuencia de los fotogramas.

Referencias oficiales consultadas: [distribución Android de Flutter](https://docs.flutter.dev/deployment/android), [canales de plataforma](https://docs.flutter.dev/platform-integration/platform-channels) y [Stopwatch](https://api.flutter.dev/flutter/dart-core/Stopwatch-class.html).
