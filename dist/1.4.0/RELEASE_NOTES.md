# chessclock 1.4.0+6

- Pulsadores lisos de mayor tamaño, encastrados en un aro metálico con reflejos y sin color visible por debajo de la base al presionar.
- Esfera grande y fila inferior con tiempo y estado alineados a la izquierda del pulsador, adaptable a ambas orientaciones.
- Presión de 90 ms, retorno de 160 ms tras 70 ms de desfase y posición conservada durante la pausa. La animación no demora el cambio de turno y respeta la preferencia de movimiento reducido.
- Capturas del README actualizadas en vertical, horizontal y configuración.

- El clic de jugada usa `assets/audio/move_click.mp3`, en reemplazo del WAV anterior, con precarga mediante SoundPool.
- Al agotarse el tiempo, se reproduce una sola vez uno de los cinco MP3 endgame_1 a endgame_5, elegido al azar. Reemplaza el tono anterior.
- Los audios se reproducen completos, sin bucle y sin el corte anterior a los 3,5 segundos. La vibración conserva su duración independiente.
- Se respeta Sonido y el volumen de alarma de Android. Probar alarma usa la misma selección aleatoria.
- Silenciar, reiniciar o interrumpir la aplicación cancela la reproducción, incluso mientras el archivo está cargando.
- Recuperar una partida finalizada no vuelve a reproducir audio. Una pulsación de Pausar justo al vencer ya no cancela la alarma recién iniciada.
- Audios centralizados en assets/audio/. La carpeta dist vuelve a incluirse en Git y conserva solo la última versión generada y verificada (1.4.0), con su checksum e informes.
