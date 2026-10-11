package app.aimstair.reminder_app.places

import android.Manifest
import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.Build
import app.aimstair.reminder_app.alarms.NativeDb
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices
import com.google.android.gms.tasks.Task
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

/**
 * Registers place geofences with Play services (LOC-13…15). The set lives in native.db so it can be
 * registered again after a reboot or app update without Flutter.
 */
object GeofenceRegistrar {
    /** LOC-14: Android allows 100 geofences per app. */
    const val MAX_GEOFENCES = 100

    private fun pendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, GeofenceReceiver::class.java).setAction(GeofenceReceiver.ACTION)
        // Play services fills in the event, so the intent must be mutable (Android 12+).
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0)
        return PendingIntent.getBroadcast(context, 0, intent, flags)
    }

    fun hasForeground(context: Context): Boolean =
        granted(context, Manifest.permission.ACCESS_FINE_LOCATION) ||
            granted(context, Manifest.permission.ACCESS_COARSE_LOCATION)

    fun hasBackground(context: Context): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) granted(context, Manifest.permission.ACCESS_BACKGROUND_LOCATION)
        else hasForeground(context)

    fun hasPrecise(context: Context): Boolean = granted(context, Manifest.permission.ACCESS_FINE_LOCATION)

    fun servicesOn(context: Context): Boolean =
        context.getSystemService(LocationManager::class.java)?.let {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) it.isLocationEnabled
            else @Suppress("DEPRECATION") it.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        } ?: false

    fun playServices(context: Context): Boolean =
        GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(context) == ConnectionResult.SUCCESS

    private fun granted(context: Context, permission: String) =
        context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    /** Save [list] and register it. */
    suspend fun sync(context: Context, list: List<NativeDb.Geofence>): GeofenceSyncResult {
        NativeDb.get(context).replaceGeofences(list)
        return registerAll(context)
    }

    /** (Re-)register everything in native.db (LOC-15: after boot, update, location back on, app open). */
    @SuppressLint("MissingPermission")
    suspend fun registerAll(context: Context): GeofenceSyncResult {
        val all = NativeDb.get(context).geofences()
        val error = when {
            !playServices(context) -> "play_services"
            !hasForeground(context) || !hasBackground(context) -> "permission"
            !servicesOn(context) -> "location_off"
            else -> null
        }
        val client = LocationServices.getGeofencingClient(context)
        val pi = pendingIntent(context)
        if (error != null) {
            if (playServices(context)) runCatching { client.removeGeofences(pi).await() }
            return GeofenceSyncResult(0, all.size.toLong(), error)
        }
        runCatching { client.removeGeofences(pi).await() }
        if (all.isEmpty()) return GeofenceSyncResult(0, 0, null)

        // LOC-14: over the limit → the places closest to the last known location.
        val chosen = if (all.size <= MAX_GEOFENCES) all else {
            val here = runCatching { LocationServices.getFusedLocationProviderClient(context).lastLocation.await() }.getOrNull()
            if (here == null) all.take(MAX_GEOFENCES)
            else all.sortedBy { distance(here, it.lat, it.lng) }.take(MAX_GEOFENCES)
        }
        val fences = chosen.map { g ->
            var transitions = 0
            if (g.arrive) transitions = transitions or Geofence.GEOFENCE_TRANSITION_ENTER
            if (g.leave) transitions = transitions or Geofence.GEOFENCE_TRANSITION_EXIT
            Geofence.Builder()
                .setRequestId(g.placeId)
                .setCircularRegion(g.lat, g.lng, g.radius.toFloat())
                .setExpirationDuration(Geofence.NEVER_EXPIRE)
                .setTransitionTypes(transitions)
                .build()
        }
        // LOC-7: no initial trigger — being inside when it's saved doesn't count as arriving.
        val request = GeofencingRequest.Builder().setInitialTrigger(0).addGeofences(fences).build()
        return runCatching { client.addGeofences(request, pi).await() }.fold(
            onSuccess = { GeofenceSyncResult(fences.size.toLong(), all.size.toLong(), null) },
            onFailure = { GeofenceSyncResult(0, all.size.toLong(), "register_failed") },
        )
    }

    private fun distance(from: Location, lat: Double, lng: Double): Float {
        val out = FloatArray(1)
        Location.distanceBetween(from.latitude, from.longitude, lat, lng, out)
        return out[0]
    }
}

/** Play services Task → coroutine (no extra dependency). */
suspend fun <T> Task<T>.await(): T = suspendCancellableCoroutine { cont ->
    addOnCompleteListener { t ->
        if (t.isSuccessful) cont.resume(t.result)
        else cont.resumeWith(Result.failure(t.exception ?: IllegalStateException("Task failed")))
    }
}
