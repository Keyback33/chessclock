# <img src="docs/images/icon.svg" width="40" height="40" alt="Ícono de chessclock"> chessclock

Reloj de ajedrez Android para dos participantes, implementado en Flutter y Kotlin. El proyecto está directamente en esta raíz; no requiere una subcarpeta adicional.

**Versión:** 1.2.0+4 · **Android mínimo:** 7.0 (API 24) · **Funcionamiento:** completamente sin conexión.

## 📱 Vista de la aplicación

| Relojes en vertical | Configuración |
| :---: | :---: |
| <img src="docs/images/relojes.png" width="300" alt="Pantalla principal de chessclock en vertical con los relojes enfrentados"> | <img src="docs/images/configuracion.png" width="300" alt="Parte superior de la configuración de chessclock"> |

## 📥 Instalar

Generá el APK siguiendo la [guía de compilación](docs/BUILD.md). El archivo firmado se crea localmente en `dist/chessclock-1.2.0.apk`, junto con su checksum SHA-256 y los metadatos de verificación. Se conservan las dos versiones más recientes. La carpeta `dist` no se incluye en el repositorio.

## ⏱️ Funciones

- Tres modos: límite por jugada, reserva total y cronómetro por jugada.
- Tiempos independientes, nombres, primer participante y preferencias persistentes.
- Orientación automática por sensor o manual (vertical/horizontal), guardada entre aperturas.
- Paneles enfrentados, esferas originales, pulsadores con relieve 3D y clic mecánico, y protección contra contactos simultáneos.
- Pausa exacta, pausa por interrupción, alarma y vibración configurables, recuperación explícita del último estado guardado.
- Sin cuentas, publicidad, red, servicios externos ni paquetes de terceros agregados para ejecución.

## 📚 Documentación y validación

Los sonidos están en [`assets/audio/`](assets/audio/). El clic actual es `move_click.wav`. Podés colocar allí nuevos `.ogg` o `.wav` con nombres descriptivos; agregarlos no cambia el sonido activo, cuya ruta se selecciona en `MainActivity.kt`. El generador `scripts/Generate-MoveClick.py` recrea únicamente el clic original.

- [Uso e instalación](docs/USO.md).
- [Entorno, arquitectura, compilación y firma](docs/BUILD.md).
- [Validación de la versión inicial](docs/VALIDACION.md).

Se generó e instaló el APK de producción en emuladores API 24 y API 37. Las comprobaciones sobre un teléfono físico, percepción de sonido/vibración y latencias reales quedan pendientes y se detallan en el informe. No se presentan como realizadas.

Para compilar, usar Flutter 3.41.9 y la combinación de herramientas documentada. Ejecutar `flutter analyze`, `flutter test` y `./scripts/Build-Release.ps1`. La firma privada está excluida del repositorio y de `dist`; conservarla para actualizaciones.
