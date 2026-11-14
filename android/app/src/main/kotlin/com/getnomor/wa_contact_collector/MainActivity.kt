package com.getnomor.wa_contact_collector

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.getnomor.wa_contact_collector/native"
    private val preferencesName = "wa_contact_collector"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isNotificationAccessGranted" -> result.success(
                        NotificationManagerCompat.getEnabledListenerPackages(this).contains(packageName)
                    )
                    "openNotificationAccessSettings" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        result.success(null)
                    }
                    "isMonitoringEnabled" -> result.success(
                        getSharedPreferences(preferencesName, MODE_PRIVATE)
                            .getBoolean("monitoring_enabled", false)
                    )
                    "setMonitoringEnabled" -> {
                        getSharedPreferences(preferencesName, MODE_PRIVATE).edit()
                            .putBoolean("monitoring_enabled", call.arguments as Boolean)
                            .apply()
                        result.success(null)
                    }
                    "getContacts" -> getContacts(result)
                    "saveContacts" -> saveContacts(call.arguments, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasReadContactsPermission(): Boolean {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CONTACTS) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun hasWriteContactsPermission(): Boolean {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_CONTACTS) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun getContacts(result: MethodChannel.Result) {
        if (!hasReadContactsPermission()) {
            result.error("CONTACT_PERMISSION", "Akses kontak belum diberikan", null)
            return
        }
        result.success(ContactContract.readContacts(this))
    }

    private fun saveContacts(arguments: Any?, result: MethodChannel.Result) {
        if (!hasReadContactsPermission() || !hasWriteContactsPermission()) {
            result.error("CONTACT_PERMISSION", "Akses kontak belum diberikan", null)
            return
        }
        @Suppress("UNCHECKED_CAST")
        val contacts = (arguments as? List<Map<String, Any?>>).orEmpty()
        try {
            ContactContract.insertContacts(this, contacts)
            result.success(null)
        } catch (error: Exception) {
            result.error("CONTACT_WRITE_FAILED", error.message, null)
        }
    }
}
