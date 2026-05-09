package com.example.minimax

import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val locationChannel = "baigalaa/location"
    private val locationPermissionCode = 8842
    private var pendingLocationResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, locationChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "getCurrent" -> startGetCurrentLocation(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun startGetCurrentLocation(result: MethodChannel.Result) {
        if (hasLocationPermission()) {
            fetchFusedLocation(result)
            return
        }
        pendingLocationResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION,
            ),
            locationPermissionCode,
        )
    }

    private fun hasLocationPermission(): Boolean {
        val fine = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
        val coarse = ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
        return fine || coarse
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != locationPermissionCode) {
            return
        }
        val pending = pendingLocationResult
        pendingLocationResult = null
        if (pending == null) {
            return
        }
        if (hasLocationPermission()) {
            fetchFusedLocation(pending)
        } else {
            pending.success(null)
        }
    }

    private fun fetchFusedLocation(result: MethodChannel.Result) {
        try {
            val client = LocationServices.getFusedLocationProviderClient(this)
            client.lastLocation
                .addOnSuccessListener { location ->
                    if (location != null) {
                        result.success(
                            mapOf(
                                "lat" to location.latitude,
                                "lng" to location.longitude,
                            ),
                        )
                        return@addOnSuccessListener
                    }
                    val token = CancellationTokenSource().token
                    client.getCurrentLocation(Priority.PRIORITY_BALANCED_POWER_ACCURACY, token)
                        .addOnSuccessListener { loc ->
                            if (loc != null) {
                                result.success(
                                    mapOf(
                                        "lat" to loc.latitude,
                                        "lng" to loc.longitude,
                                    ),
                                )
                            } else {
                                result.success(null)
                            }
                        }
                        .addOnFailureListener { result.success(null) }
                }
                .addOnFailureListener { result.success(null) }
        } catch (_: Throwable) {
            result.success(null)
        }
    }
}
