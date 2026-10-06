package app.aimstair.reminder_app

import app.aimstair.reminder_app.alarms.AlarmHostApi
import app.aimstair.reminder_app.alarms.AlarmHostApiImpl
import app.aimstair.reminder_app.alarms.Notifications
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Notifications.ensureChannels(this)
        AlarmHostApi.setUp(flutterEngine.dartExecutor.binaryMessenger, AlarmHostApiImpl(this))
    }
}
