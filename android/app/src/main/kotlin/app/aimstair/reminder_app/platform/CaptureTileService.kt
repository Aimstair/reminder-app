package app.aimstair.reminder_app.platform

import android.annotation.SuppressLint
import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import app.aimstair.reminder_app.MainActivity

/** S-62 Quick Settings tile "+ Reminder": opens the capture sheet. */
class CaptureTileService : TileService() {
    override fun onStartListening() {
        qsTile?.apply {
            state = Tile.STATE_INACTIVE
            updateTile()
        }
    }

    @SuppressLint("StartActivityAndCollapseDeprecated")
    override fun onClick() {
        if (Build.VERSION.SDK_INT >= 34) {
            startActivityAndCollapse(ReminderWidget.launchIntent(this, PendingLaunch.ACTION_CAPTURE, 3))
        } else {
            val intent = Intent(this, MainActivity::class.java)
                .putExtra(PendingLaunch.EXTRA_LAUNCH_ACTION, PendingLaunch.ACTION_CAPTURE)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }
}
