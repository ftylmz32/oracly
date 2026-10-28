package app.oracly

import android.media.AudioManager
import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Always install so LaunchTheme attrs apply; keepCondition false so
        // Flutter's FinalOraclySplash owns the only branded moment.
        val splash = installSplashScreen()
        splash.setKeepOnScreenCondition { false }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "oracly/debug")
            .setMethodCallHandler { call, result ->
                if (call.method == "encounterPreview") {
                    result.success(intent?.getBooleanExtra("encounter_preview", false) == true)
                } else if (call.method == "premiumPreview") {
                    result.success(intent?.getStringExtra("premium_preview"))
                } else if (call.method == "homeDaypart") {
                    result.success(intent?.getStringExtra("home_daypart"))
                } else if (call.method == "homeInvitePreview") {
                    result.success(intent?.getStringExtra("home_invite_preview"))
                } else {
                    result.notImplemented()
                }
            }
        // Fincan Haritası photos + map file: app-private, never evicted, and
        // under getNoBackupFilesDir(), which Auto Backup and device transfer
        // skip. Dart derives the same path; a file is reported excluded only
        // when its canonical path is inside THIS directory.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.oracly/cup_map_storage")
            .setMethodCallHandler { call, result ->
                val dir = File(noBackupFilesDir, "coffee_cup_map")
                when (call.method) {
                    "excludeFromBackup", "isExcludedFromBackup" -> {
                        val path = call.argument<String>("path")
                        result.success(path != null && isInside(dir, File(path)))
                    }
                    else -> result.notImplemented()
                }
            }
        // Ambient music yields to calls and other apps' audio. Read-only
        // AudioManager state; no permission, never touches other apps.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "oracly/audio")
            .setMethodCallHandler { call, result ->
                val audio = getSystemService(AUDIO_SERVICE) as AudioManager
                when (call.method) {
                    "otherAudioActive" -> result.success(audio.isMusicActive)
                    "callActive" -> result.success(
                        audio.mode == AudioManager.MODE_RINGTONE ||
                            audio.mode == AudioManager.MODE_IN_CALL ||
                            audio.mode == AudioManager.MODE_IN_COMMUNICATION,
                    )
                    else -> result.notImplemented()
                }
            }
    }

    private fun isInside(dir: File, file: File): Boolean {
        val root = dir.canonicalPath + File.separator
        return file.canonicalPath.startsWith(root)
    }
}
