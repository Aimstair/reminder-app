package app.aimstair.reminder_app

import android.content.Intent
import android.os.Bundle
import app.aimstair.reminder_app.alarms.AlarmHostApi
import app.aimstair.reminder_app.alarms.AlarmHostApiImpl
import app.aimstair.reminder_app.alarms.Notifications
import app.aimstair.reminder_app.platform.PendingLaunch
import app.aimstair.reminder_app.platform.PlatformFlutterApi
import app.aimstair.reminder_app.platform.PlatformHostApi
import app.aimstair.reminder_app.platform.PlatformHostApiImpl
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MainActivity : FlutterActivity() {
    private var platform: PlatformHostApiImpl? = null
    private var flutterApi: PlatformFlutterApi? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Notifications.ensureChannels(this)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        AlarmHostApi.setUp(messenger, AlarmHostApiImpl(this))
        platform = PlatformHostApiImpl(this).also { PlatformHostApi.setUp(messenger, it) }
        flutterApi = PlatformFlutterApi(messenger)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState == null) readLaunchIntent(intent, push = false) // Dart takes it on start
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        readLaunchIntent(intent, push = true)
    }

    /** S-63 share target, S-61/S-62 capture, NTF-3 notification tap. */
    private fun readLaunchIntent(intent: Intent?, push: Boolean) {
        intent ?: return
        if (intent.action == Intent.ACTION_SEND && intent.type?.startsWith("text/") == true) {
            val text = listOfNotNull(
                intent.getStringExtra(Intent.EXTRA_SUBJECT),
                intent.getStringExtra(Intent.EXTRA_TEXT),
            ).filter { it.isNotBlank() }.joinToString("\n")
            if (text.isNotEmpty()) {
                PendingLaunch.sharedText = text
                if (push) deliver { api -> api.onSharedText(text); PendingLaunch.sharedText = null }
            }
        }
        intent.getStringExtra(PendingLaunch.EXTRA_LAUNCH_ACTION)?.let { action ->
            intent.removeExtra(PendingLaunch.EXTRA_LAUNCH_ACTION)
            PendingLaunch.action = action
            if (push) deliver { api -> api.onLaunchAction(action); PendingLaunch.action = null }
        }
    }

    /** Push to a running Dart side; if it isn't listening yet, the pending value stays for take*(). */
    private fun deliver(block: suspend (PlatformFlutterApi) -> Unit) {
        val api = flutterApi ?: return
        CoroutineScope(Dispatchers.Main).launch { runCatching { block(api) } }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (platform?.onActivityResult(requestCode, resultCode, data) == true) return
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        if (platform?.onPermissionResult(requestCode, grantResults) == true) return
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }
}
