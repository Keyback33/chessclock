# chessclock · Guía de uso

## Instalar

1. Copiar `dist/chessclock-1.1.1.apk` al teléfono Android 7.0 o posterior.
2. Abrir el archivo y permitir a esa aplicación de archivos instalar aplicaciones desde esa fuente si Android lo solicita.
3. Confirmar la instalación y abrir **chessclock**. No necesita Internet ni cuenta, tampoco en su primer inicio.

El archivo `.sha256` contiene el SHA-256 para comprobar la integridad. En Windows se obtiene con `Get-FileHash -Algorithm SHA256` sobre el APK. Para actualizar, abrir una versión posterior firmada con la misma clave sin desinstalar antes: así se conservan las preferencias. Desinstalar borra los datos locales. Las preferencias y partidas no se respaldan en la nube.

## Preparar y jugar

Apoyá el celular entre ambos jugadores. En vertical, Jugador 1 usa el extremo inferior y Jugador 2 el superior. Cada mitad se lee desde su lado. En horizontal, los paneles quedan lado a lado: Jugador 2 a la izquierda, invertido, y Jugador 1 a la derecha. Los números se leen horizontalmente desde lados opuestos de la mesa.

En **Configuración → Orientación**, antes de empezar o durante una pausa, elegí **Automática** (sigue el sensor incluso con la rotación de Android bloqueada), **Vertical** u **Horizontal**. La selección se aplica y guarda inmediatamente. Al girar, los relojes y controles de cada jugador quedan enfrentados, sin perder tiempos, turno ni jugadas; los controles centrales son compartidos.

Tocá **Configurar partida** (ícono de ajustes del centro) para elegir modo, tiempos, nombres y quién empieza. El valor inicial es 30 segundos por jugada para cada participante. Los límites admitidos son de 1 segundo a 180 minutos; los segundos se ingresan de 0 a 59. Podés usar atajos y desactivar «Mismo tiempo para ambos» para dar límites diferentes.

| Modo | Uso |
| --- | --- |
| Por jugada | Cada turno empieza con todo el límite. El sobrante queda visible mientras esperás y no se acumula. |
| Tiempo total | Tu reserva disminuye solo durante tu turno y se conserva entre jugadas. |
| Cronómetro | Cada turno cuenta desde cero; al esperar muestra tu última jugada. No tiene vencimiento. |

Tocá **Iniciar** para activar al participante elegido. Cuando terminás una jugada, tocá cualquier parte de tu panel. Se detiene tu tiempo y empieza el del rival. El panel en espera no cambia el turno. Levantá todos los dedos antes de hacer otro cambio de turno; mantener contactos sobre la pantalla bloquea cambios repetidos.

El reloj activo muestra **Tu turno**, el borde destacado y el pulsador levantado. El contador digital es la referencia precisa: minutos y segundos, horas cuando corresponda y décimas en los últimos 10 segundos. La aguja y el arco indican la proporción restante. El cronómetro completa una vuelta cada minuto.

## Pausa, resultado y alarma

**Pausar** detiene ambos tiempos. **Continuar** retoma al mismo jugador con el saldo exacto. En pausa se puede ajustar sonido, vibración y orientación. Para cambiar modo o duración, reiniciá primero; se pide confirmación antes de borrar la partida.

Si el teléfono se bloquea, cambia de aplicación o pierde interacción, la partida se pausa. Al regresar muestra «Partida pausada por interrupción» y exige continuar explícitamente. No hay reloj ni alarma en segundo plano.

Al llegar a cero, ambos relojes se detienen. Aparecen la bandera y **Tiempo agotado** en el panel del jugador afectado. La señal de alarma dura hasta 3,5 segundos; los botones **Silenciar** de ambos lados la detienen sin borrar el resultado. **Nueva partida** (flecha circular central) vuelve a la preparación.

Sonido y vibración se configuran por separado. **Probar alarma** permite comprobarlos antes de jugar. El sonido usa el volumen de alarma de Android; no cambia el volumen global ni omite «No molestar». La bandera y el texto aparecen siempre, aunque no se oiga sonido.

## Recuperar una partida

Las preferencias y el estado se guardan al iniciar, cambiar turno, pausar, continuar, vencer o reiniciar. Después de un cierre inesperado se ofrece recuperar el último estado guardado. Una partida en curso vuelve en pausa; no se reconstruye el tiempo posterior a la última instantánea. Un resultado ya terminado conserva su resultado y no repite la alarma. Podés descartar la instantánea y preparar una partida nueva.

Si el archivo local está dañado se recuperan los valores predeterminados y se informa en pantalla.
