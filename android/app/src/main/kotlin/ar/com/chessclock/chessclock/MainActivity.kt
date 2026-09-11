package ar.com.chessclock.chessclock

import android.content.Context
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val handler = Handler(Looper.getMainLooper())
    private var tone: ToneGenerator? = null
    private var vibrator: Vibrator? = null
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ar.com.chessclock/device")
        channel!!.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "privateDirectory" -> result.success(noBackupFilesDir.absolutePath)
                    "keepAwake" -> {
                        if (call.arguments == true) window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        else window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        result.success(null)
                    }
                    "alarm" -> {
                        playAlarm(call.argument<Boolean>("sound") == true, call.argument<Boolean>("vibration") == true)
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

    private fun playAlarm(sound: Boolean, vibrate: Boolean) {
        silence()
        var audioError: Exception? = null
        if (sound) {
            try {
                tone = ToneGenerator(AudioManager.STREAM_ALARM, 90)
                tone?.startTone(ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD, 350)
                for (delay in listOf(700L, 1400L, 2100L, 2800L)) {
                    handler.postDelayed({ tone?.startTone(ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD, 350) }, delay)
                }
            } catch (exception: Exception) { audioError = exception }
        }
        if (vibrate) {
            vibrator = if (Build.VERSION.SDK_INT >= 31)
                (getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager).defaultVibrator
            else @Suppress("DEPRECATION") (getSystemService(Context.VIBRATOR_SERVICE) as Vibrator)
            if (vibrator?.hasVibrator() == true) {
                val pattern = longArrayOf(0, 250, 450, 250, 450, 250, 450, 250, 450, 250)
                if (Build.VERSION.SDK_INT >= 26) vibrator?.vibrate(VibrationEffect.createWaveform(pattern, -1))
                else @Suppress("DEPRECATION") vibrator?.vibrate(pattern, -1)
            }
        }
        handler.postDelayed({ silence() }, 3500)
        audioError?.let { throw it }
    }

    private fun silence() {
        handler.removeCallbacksAndMessages(null)
        tone?.stopTone()
        tone?.release()
        tone = null
        vibrator?.cancel()
        vibrator = null
    }

    override fun onPause() {
        silence()
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        super.onPause()
    }

    override fun onDestroy() {
        silence()
        channel?.setMethodCallHandler(null)
        channel = null
        super.onDestroy()
    }
}
