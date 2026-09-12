package ar.com.chessclock.chessclock

import android.content.Context
import android.content.pm.ActivityInfo
import android.media.AudioAttributes
import android.media.SoundPool
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.WindowManager
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val handler = Handler(Looper.getMainLooper())
    private var endgamePlayer: MediaPlayer? = null
    private var endgameResult: MethodChannel.Result? = null
    private var vibrator: Vibrator? = null
    private var channel: MethodChannel? = null
    private var clickPool: SoundPool? = null
    private var clickSound = 0
    private var clickStream = 0
    private var clickReady = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        prepareClick()
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ar.com.chessclock/device")
        channel!!.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "privateDirectory" -> result.success(noBackupFilesDir.absolutePath)
                    "orientation" -> {
                        requestedOrientation = when (call.arguments as? String) {
                            "automatic" -> ActivityInfo.SCREEN_ORIENTATION_FULL_SENSOR
                            "portrait" -> ActivityInfo.SCREEN_ORIENTATION_SENSOR_PORTRAIT
                            "landscape" -> ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
                            else -> { result.error("INVALID_ORIENTATION", "Orientación inválida", null); return@setMethodCallHandler }
                        }
                        result.success(null)
                    }
                    "keepAwake" -> {
                        if (call.arguments == true) window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        else window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        result.success(null)
                    }
                    "alarm" -> {
                        playAlarm(
                            call.argument<Boolean>("sound") == true,
                            call.argument<Boolean>("vibration") == true,
                            call.argument<String>("asset"),
                            result
                        )
                    }
                    "moveClick" -> {
                        // Never queue a late click: feedback belongs to this move.
                        if (clickReady) {
                            clickStream = clickPool?.play(clickSound, 0.8f, 0.8f, 1, 0, 1f) ?: 0
                        }
                        result.success(null)
                    }
                    "silence" -> { silence(); result.success(null) }
                    else -> result.notImplemented()
                }
            } catch (exception: Exception) {
                result.error("DEVICE_ERROR", exception.message, null)
            }
        }
    }

    private fun prepareClick() {
        try {
            val pool = SoundPool.Builder()
                .setMaxStreams(1)
                .setAudioAttributes(AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_GAME)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build())
                .build()
            clickPool = pool
            pool.setOnLoadCompleteListener { loadedPool, _, status ->
                if (clickPool === loadedPool) clickReady = status == 0
            }
            val assetKey = FlutterInjector.instance().flutterLoader()
                .getLookupKeyForAsset("assets/audio/move_click.mp3")
            assets.openFd(assetKey).use { descriptor ->
                clickSound = pool.load(descriptor, 1)
            }
        } catch (_: Exception) {
            // Optional feedback must never prevent starting the clock.
            clickPool?.release()
            clickPool = null
            clickReady = false
        }
    }

    private fun playAlarm(sound: Boolean, vibrate: Boolean, asset: String?, result: MethodChannel.Result) {
        silence()
        // The result completes on playback completion, cancellation or error.
        endgameResult = result
        try {
            if (vibrate) {
                vibrator = if (Build.VERSION.SDK_INT >= 31)
                    (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager).defaultVibrator
                else @Suppress("DEPRECATION") (getSystemService(Context.VIBRATOR_SERVICE) as Vibrator)
                if (vibrator?.hasVibrator() == true) {
                    val pattern = longArrayOf(0, 250, 450, 250, 450, 250, 450, 250, 450, 250)
                    if (Build.VERSION.SDK_INT >= 26) vibrator?.vibrate(VibrationEffect.createWaveform(pattern, -1))
                    else @Suppress("DEPRECATION") vibrator?.vibrate(pattern, -1)
                }
                // Vibration has its own duration; never truncate the selected MP3.
                handler.postDelayed({ stopVibration() }, 3500)
            }
            if (!sound) {
                releaseEndgame()
                return
            }
            require(asset != null && Regex("assets/audio/endgame_[1-5]\\.mp3").matches(asset)) {
                "Audio de fin de partida inválido"
            }
            val player = MediaPlayer()
            endgamePlayer = player
            player.setAudioAttributes(AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .build())
            player.isLooping = false
            player.setOnPreparedListener { prepared ->
                if (endgamePlayer === prepared) {
                    try { prepared.start() }
                    catch (exception: Exception) { releaseEndgame(exception.message ?: "No se pudo iniciar el audio") }
                }
            }
            player.setOnCompletionListener { completed ->
                if (endgamePlayer === completed) releaseEndgame()
            }
            player.setOnErrorListener { failed, what, extra ->
                if (endgamePlayer === failed) releaseEndgame("Error de reproducción: $what / $extra")
                true
            }
            val assetKey = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(asset)
            assets.openFd(assetKey).use { descriptor ->
                player.setDataSource(descriptor.fileDescriptor, descriptor.startOffset, descriptor.length)
            }
            player.prepareAsync()
        } catch (exception: Exception) {
            releaseEndgame(exception.message ?: "No se pudo cargar el audio")
        }
    }

    private fun releaseEndgame(error: String? = null) {
        val player = endgamePlayer
        endgamePlayer = null
        player?.release()
        val pending = endgameResult
        endgameResult = null
        if (error == null) pending?.success(null)
        else pending?.error("AUDIO_ERROR", error, null)
    }

    private fun stopVibration() {
        vibrator?.cancel()
        vibrator = null
    }

    private fun silence() {
        clickPool?.stop(clickStream)
        clickStream = 0
        handler.removeCallbacksAndMessages(null)
        releaseEndgame()
        stopVibration()
    }

    override fun onPause() {
        silence()
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        super.onPause()
    }

    override fun onDestroy() {
        silence()
        clickReady = false
        clickPool?.release()
        clickPool = null
        channel?.setMethodCallHandler(null)
        channel = null
        super.onDestroy()
    }
}
