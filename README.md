# chessclock

Reloj de ajedrez Android para dos participantes, implementado en Flutter y Kotlin. El proyecto está directamente en esta raíz; no requiere una subcarpeta adicional.

**Versión:** 1.0.0+1 · **Android mínimo:** 7.0 (API 24) · **Funcionamiento:** completamente sin conexión.

## Instalar

El APK universal de producción firmado está en [dist/chessclock-1.0.0.apk](dist/chessclock-1.0.0.apk). Su integridad se comprueba con [SHA-256](dist/chessclock-1.0.0.apk.sha256). La firma propia, permisos y metadatos se incluyen en `dist`.

## Funciones

- Tres modos: límite por jugada, reserva total y cronómetro por jugada.
- Tiempos independientes, nombres, primer participante y preferencias persistentes.
- Paneles enfrentados, esferas originales, pulsadores grandes y protección contra contactos simultáneos.
- Pausa exacta, pausa por interrupción, alarma y vibración configurables, recuperación explícita del último estado guardado.
- Sin cuentas, publicidad, red, servicios externos ni paquetes de terceros agregados para ejecución.

## Documentación y validación

- [Uso e instalación](docs/USO.md).
- [Entorno, arquitectura, compilación y firma](docs/BUILD.md).
- [Pruebas, evidencia y limitaciones pendientes](docs/VALIDACION.md).
- [Plan corregido para la raíz chessclock](PLAN_IMPLEMENTACION.md).

Se generó e instaló el APK de producción en emuladores API 24 y API 37. Las comprobaciones sobre un teléfono físico, percepción de sonido/vibración y latencias reales quedan pendientes y se detallan en el informe. No se presentan como realizadas.

Para compilar, usar Flutter 3.41.9 y la combinación de herramientas documentada. Ejecutar `flutter analyze`, `flutter test` y `./scripts/Build-Release.ps1`. La firma privada está excluida del repositorio y de `dist`; conservarla para actualizaciones.
