# Informe de validación · chessclock 1.0.0+1

Fecha de implementación: 10 de septiembre de 2026. Código en la raíz del proyecto. APK universal de producción en `dist/chessclock-1.0.0.apk`.

## Alcance y dispositivos

| Entorno | Identificación | Uso |
| --- | --- | --- |
| Host | Windows 11, Flutter 3.41.9 / Dart 3.11.5 | Análisis, pruebas deterministas y de widgets, compilación y firma |
| Android mínimo | Emulador `chessclock_api24`, Nexus 5, Android 7.0 / API 24, x86_64, 1080×1920 | Instalación del APK de producción, modo avión, configuración, partida, alarma nativa, pausa, recuperación y actualización |
| Android moderno | Emulador `Pixel_10`, Android 17 / API 37, x86_64, 1080×2424 | Integración, APK de producción, modo avión, bloqueo y orientación horizontal |
| Teléfono físico | No conectado ni disponible durante esta ejecución | Validación física pendiente |

Los emuladores se ejecutaron sin ventana ni salida audible del host. Una llamada nativa correcta y una pista de audio activa no equivalen a escuchar el altavoz de un teléfono ni a sentir su vibrador.

## Comprobaciones automatizadas

`flutter analyze`: sin incidencias. `flutter test`: **26 pruebas satisfactorias**.

| Área | Evidencia y resultado |
| --- | --- |
| Motor | Modo por jugada con límites distintos, renovación completa y sobrante conservado; tiempo total sin reiniciar reservas; cronómetro sin vencimiento y última duración visible. |
| Tiempo | Pausas excluidas exactamente; límite alcanzado resuelto antes del toque; valor cero sin negativos; fotogramas retrasados sin deriva. |
| Sesión larga simulada | 30 minutos de tiempo monotónico simulado, con cambios de turno de duración variable y semilla 42. Diferencia exacta de 0 microsegundos frente a la suma de los intervalos activos de cada jugador. Es una prueba matemática del motor, no una sesión física de 30 minutos. |
| Estado | Inicio con participante elegido, rechazo de acciones inválidas, contador de jugadas, reinicio y sesión nueva, recuperación que exige continuar. |
| Contactos | Panel inactivo ignorado; dos contactos simultáneos no alternan dos veces; bloqueo hasta levantar todos los contactos y sin demora fija posterior. |
| Alarmas y callbacks | Una alarma por sesión; pausa, reinicio y disposición cancelan tareas anteriores; pantalla encendida solo mientras el estado está activo. |
| Persistencia | Cola de escrituras, último estado conservado, archivo temporal reemplazado, recuperación ante JSON roto y esquemas inválidos. |
| Interfaz | Inicio, alternancia, pausa, continuación, confirmación de reinicio y validación de campos. Dimensiones lógicas 320×568, 412×892, 1024×600 y 800×1280, con escalas de texto 1 y 2; preparado, activo e interrupción sin excepciones de diseño. |

Registros: [análisis](evidence/analyze.txt), [pruebas unitarias y widgets](evidence/unit-widget-tests.txt), [compilación release](evidence/release-build.txt).

La prueba de integración `integration_test/game_flow_test.dart` utiliza el canal Android real, la ruta privada, escritura y lectura, los tres modos, un cambio por toque, pausa/continuación, vencimiento, prueba de alarma y limpieza. El test separa el flujo de interacción del vencimiento breve: el emulador API 24 en depuración puede tardar varios segundos en dibujar sus primeros fotogramas, por lo que un límite inicial de 2 segundos vencía antes del primer toque automatizado. La interacción usa ahora 30/45 segundos y el vencimiento se prueba por separado con 1 segundo. Esto no cambia el motor ni relaja las aserciones del vencimiento.

Resultado final: **1 prueba de integración satisfactoria en cada versión**. Registros: [integración API 24](evidence/integration-api24.txt) y [integración API 37](evidence/integration-api37.txt). Una transferencia ADB del runner quedó bloqueada en API 24; se reconectó ese emulador y se reinstaló con `adb install --no-streaming`. La repetición final pasó sin fallos.

## APK de producción

- Nombre visible y paquete Dart: `chessclock`; applicationId: `ar.com.chessclock.chessclock`.
- Versión: `1.0.0`, versionCode `1`; minSdk 24; targetSdk/compileSdk 36.
- Arquitecturas: `armeabi-v7a`, `arm64-v8a` y `x86_64`.
- Tamaño final: **48.230.608 bytes** (46,00 MiB; 48,23 MB decimales).
- SHA-256: `732bf3653018320bb907f8a2caea6b027dd76abb8f76829b42a523885c8ea793`.
- Firma comprobada con `apksigner`: esquema v2 válido, certificado propio RSA de 3072 bits, distinto del de depuración.
- Permiso de sistema solicitado: `VIBRATE`. AndroidX incorpora además un permiso interno de nivel firma para sus receptores; no es acceso a datos personales ni requiere solicitud al usuario.
- El manifiesto combinado no contiene `INTERNET` ni `ACCESS_NETWORK_STATE`; no habilita depuración. `allowBackup=false`, exclusiones de extracción y almacenamiento en `noBackupFilesDir`.

Los informes y el APK de esta validación inicial ya no se conservan en `dist`, que contiene únicamente la última entrega. Consultar la [guía de compilación](BUILD.md) para los artefactos vigentes. La clave privada y sus contraseñas no forman parte de `dist`.

## Flujos comprobados sobre el APK instalado

1. Instalación limpia y apertura en los dos niveles Android. Se probó primer inicio sin conexión después de borrar exclusivamente los datos de la app de prueba o reinstalarla limpia. Modo avión activo, Wi-Fi y datos móviles deshabilitados; [estado de Wi-Fi API 24](evidence/api24-wifi-state.txt).
2. En API 24, selección de 15 segundos, prueba y detención de alarma, guardado, inicio, toque del panel activo y cambio de turno. El estado guardado registró una jugada del Jugador 1 y actividad del Jugador 2.
3. Ir al inicio de Android durante la partida dejó ambos tiempos congelados y mostró «Partida pausada por interrupción». [Estado guardado](evidence/api24-saved-state.json) y [interfaz](evidence/api24-interruption.xml).
4. Reinstalación con `install -r` y la misma firma conservó la configuración y la instantánea. Tras cerrar el proceso y abrirlo, se ofreció recuperar; el usuario debe pulsar «Continuar». [Actualización API 24](evidence/api24-release-update.txt), [recuperación](evidence/api24-recovery.xml) y [actualización final API 37](evidence/api37-final-update.txt).
5. Continuar la partida recuperada llevó a cero al Jugador 2, congeló ambos relojes y presentó bandera, texto y botones para silenciar desde ambos extremos. [Captura de resultado](evidence/api24-expired.png), [estado final](evidence/api24-expired-state.json).
6. La prueba de alarma creó una pista activa de tipo 4 (`STREAM_ALARM`) en el mezclador de Android. [Diagnóstico de audio](evidence/api24-alarm-audio.txt). El emulador API 24 no proporciona evidencia de vibración física; no se declara validada.
7. En API 37, suspender explícitamente la pantalla produjo `mWakefulness=Asleep`; al despertarla la partida siguió en pausa. [Estado accesible al volver](evidence/api37-lock.xml).
8. Se giró la ventana sin perder el motor. Los paneles enfrentados se adaptaron a los extremos izquierdo y derecho. Se corrigió el texto partido del botón central detectado al inspeccionar el primer APK. [Captura horizontal final](evidence/api37-final-landscape.png).

Las evidencias anteriores registran también iteraciones previas a la corrección visual final. La firma y el motor permanecen iguales. La copia final se instaló limpia y se comprobó por hash en ambos emuladores: [registro del artefacto instalado](evidence/final-artifact-installation.txt). Se extrajo `base.apk` de cada instalación y se comparó su SHA-256 con `dist/chessclock-1.0.0.apk`; ambos coinciden. También se repitió la partida completa sin conexión en API 24 sobre esa copia final: [resultado final](evidence/api24-final-expired.png). [Instalación final API 24](evidence/api24-final-install.txt), [instalación final API 37](evidence/api37-final-install.txt) y [primer inicio final API 37](evidence/api37-final-first-start.xml).

## Pendientes en teléfono físico

No se considera completada la validación física. Quedan por medir o comprobar:

- Respuesta real de la superficie táctil, contactos múltiples, TalkBack, recortes particulares, llamadas entrantes y preferencias de animación del dispositivo.
- Audibilidad y vibración percibidas con volumen habilitado, silencio, volumen cero y «No molestar». El código no altera volumen global ni omite esas políticas.
- Sesión real de 30 minutos para estabilidad, temperatura y recursos. La simulación de 30 minutos ya pasó, pero no mide rendimiento sostenido del teléfono.
- Desviación visible inferior a 100 ms y comienzo audible de alarma dentro de 250 ms. No se midieron en hardware ni se presentan como garantías.
- Ejecución nativa ARM de 32 y 64 bits. El APK incluye ambas bibliotecas, pero la instalación ejecutada fue x86_64 en emuladores.

Método propuesto para completar las latencias: teléfono de referencia identificado por modelo, versión de Android y frecuencia de pantalla; registro monotónico en una compilación de medición del instante límite y de emisión del tono, más filmación de alta velocidad del contador y registro de audio. Separar latencia de despacho a Android de comienzo audible; repetir con volumen de alarma habilitado, varias partidas y carga normal. Para la sesión sostenida, jugar o automatizar 30 minutos en primer plano y comparar intervalos monotónicos, recursos y bloqueos. Registrar resultados sin extrapolarlos a todos los Android.
