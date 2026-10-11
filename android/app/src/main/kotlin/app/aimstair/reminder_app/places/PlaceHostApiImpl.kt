package app.aimstair.reminder_app.places

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Address
import android.location.Geocoder
import android.net.Uri
import android.os.Build
import android.provider.Settings
import app.aimstair.reminder_app.alarms.NativeDb
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull

/** Places bridge (pigeons/place_api.dart): geofences, location permission, picker location + search. */
class PlaceHostApiImpl(private val activity: Activity) : PlaceHostApi {
    private var permissionResult: CompletableDeferred<Boolean>? = null

    override suspend fun syncGeofences(specs: List<GeofenceSpec>): GeofenceSyncResult =
        GeofenceRegistrar.sync(activity, specs.map {
            NativeDb.Geofence(it.placeId, it.latitude, it.longitude, it.radiusMeters.toInt(), it.arrive, it.leave, it.payloadJson)
        })

    override fun getLocationState(): LocationState = LocationState(
        foreground = GeofenceRegistrar.hasForeground(activity),
        background = GeofenceRegistrar.hasBackground(activity),
        precise = GeofenceRegistrar.hasPrecise(activity),
        servicesOn = GeofenceRegistrar.servicesOn(activity),
        playServices = GeofenceRegistrar.playServices(activity),
    )

    // ---- permission (PRM-9) ----

    override suspend fun requestForegroundLocation(): Boolean {
        if (GeofenceRegistrar.hasPrecise(activity)) return true
        val result = CompletableDeferred<Boolean>()
        permissionResult = result
        activity.requestPermissions(
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION),
            REQ_LOCATION,
        )
        return result.await()
    }

    fun onPermissionResult(requestCode: Int, grantResults: IntArray): Boolean {
        if (requestCode != REQ_LOCATION && requestCode != REQ_BACKGROUND) return false
        permissionResult?.complete(grantResults.any { it == PackageManager.PERMISSION_GRANTED })
        permissionResult = null
        return true
    }

    override fun openAppLocationSettings() {
        // Android 11+: asking for background location opens the app's location page ("Allow all the time").
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && GeofenceRegistrar.hasForeground(activity) &&
            !GeofenceRegistrar.hasBackground(activity)
        ) {
            activity.requestPermissions(arrayOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION), REQ_BACKGROUND)
            return
        }
        activity.startActivity(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:" + activity.packageName))
        )
    }

    override fun openLocationSettings() {
        activity.startActivity(Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS))
    }

    // ---- picker (S-24) ----

    @SuppressLint("MissingPermission")
    override suspend fun currentLocation(): LatLng? {
        if (!GeofenceRegistrar.hasForeground(activity)) return null
        val client = LocationServices.getFusedLocationProviderClient(activity)
        val fresh = withTimeoutOrNull(4_000) {
            runCatching {
                client.getCurrentLocation(Priority.PRIORITY_BALANCED_POWER_ACCURACY, CancellationTokenSource().token).await()
            }.getOrNull()
        }
        val loc = fresh ?: runCatching { client.lastLocation.await() }.getOrNull() ?: return null
        return LatLng(loc.latitude, loc.longitude)
    }

    override suspend fun searchPlaces(query: String, near: LatLng?): List<PlaceResult> = withContext(Dispatchers.IO) {
        if (!Geocoder.isPresent() || query.isBlank()) return@withContext emptyList()
        val geocoder = Geocoder(activity)
        runCatching {
            @Suppress("DEPRECATION")
            val list = if (near != null) {
                // Prefer results around the user (about ±50 km), then anywhere.
                geocoder.getFromLocationName(
                    query, MAX_RESULTS, near.latitude - 0.5, near.longitude - 0.5, near.latitude + 0.5, near.longitude + 0.5,
                )?.takeIf { it.isNotEmpty() } ?: geocoder.getFromLocationName(query, MAX_RESULTS)
            } else {
                geocoder.getFromLocationName(query, MAX_RESULTS)
            }
            list.orEmpty().map { it.toResult(query) }
        }.getOrDefault(emptyList())
    }

    override suspend fun reverseGeocode(latitude: Double, longitude: Double): PlaceResult? = withContext(Dispatchers.IO) {
        if (!Geocoder.isPresent()) return@withContext null
        runCatching {
            @Suppress("DEPRECATION")
            Geocoder(activity).getFromLocation(latitude, longitude, 1)?.firstOrNull()?.toResult(null)
        }.getOrNull()
    }

    /** A business name when the geocoder has one ("Trader Joe's"), else the street line. */
    private fun Address.toResult(query: String?): PlaceResult {
        val line = getAddressLine(0) ?: listOfNotNull(thoroughfare, locality).joinToString(", ")
        val feature = featureName?.takeIf { f -> f.isNotBlank() && f.any { it.isLetter() } && f != thoroughfare }
        val name = feature ?: line.substringBefore(',').ifBlank { query ?: line }
        return PlaceResult(name, line, latitude, longitude)
    }

    companion object {
        private const val REQ_LOCATION = 4711
        private const val REQ_BACKGROUND = 4712
        private const val MAX_RESULTS = 8
    }
}
