
package com.getnomor.wa_contact_collector

import android.app.Notification
import android.content.SharedPreferences
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import java.security.MessageDigest
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

class WhatsAppNotificationListener : NotificationListenerService() {

    private val preferencesName = "wa_contact_collector"
    private val databaseName = "detected_numbers.db"

    private val supportedPackages = setOf(
        "com.whatsapp",
        "com.whatsapp.w4b"
    )

    override fun onNotificationPosted(
        statusBarNotification: StatusBarNotification
    ) {
        val preferences = getSharedPreferences(
            preferencesName,
            MODE_PRIVATE
        )

        if (!preferences.getBoolean("monitoring_enabled", false)) {
            return
        }

        if (statusBarNotification.packageName !in supportedPackages) {
            return
        }

        val title = statusBarNotification.notification.extras?.let { extras ->
            listOfNotNull(
                extras.getCharSequence(Notification.EXTRA_TITLE)?.toString(),
                extras.getCharSequence(Notification.EXTRA_TITLE_BIG)?.toString()
            ).joinToString(" ")
        }.orEmpty()

        if (title.isBlank()) {
            return
        }

        val numbers = extractIndonesianNumbers(title)

        if (numbers.isEmpty()) {
            return
        }

        val source = if (
            statusBarNotification.packageName == "com.whatsapp.w4b"
        ) {
            "WhatsApp Business"
        } else {
            "WhatsApp"
        }

        val notificationKey = statusBarNotification.key
            ?: statusBarNotification.id.toString()

        val timestamp = isoNow()

        val database = CollectorDatabase(
            this,
            databaseName
        ).writableDatabase

        try {
            for (phone in numbers) {

                val dedupeKey = sha256(
                    "$notificationKey|$phone"
                )

                if (wasRecentlySeen(preferences, dedupeKey)) {
                    continue
                }

                database.execSQL(
                    """
                    INSERT OR IGNORE INTO detected_numbers
                    (
                        phone_number,
                        source,
                        first_detected_at,
                        last_detected_at,
                        is_saved_contact
                    )
                    VALUES (?, ?, ?, ?, 0)
                    """.trimIndent(),
                    arrayOf(
                        phone,
                        source,
                        timestamp,
                        timestamp
                    )
                )

                database.execSQL(
                    """
                    UPDATE detected_numbers
                    SET source = ?, last_detected_at = ?
                    WHERE phone_number = ?
                    """.trimIndent(),
                    arrayOf(
                        source,
                        timestamp,
                        phone
                    )
                )

                markSeen(
                    preferences,
                    dedupeKey
                )
            }
        } finally {
            database.close()
        }
    }

    private fun extractIndonesianNumbers(
        text: String
    ): Set<String> {

        val result = linkedSetOf<String>()

        val matcher = Regex(
            "(?<!\\d)(?:\\+62|62|0)[0-9\\s().-]{8,18}"
        ).findAll(text)

        for (match in matcher) {

            val normalized = normalize(
                match.value
            )

            if (normalized != null) {
                result.add(normalized)
            }
        }

        return result
    }

    private fun normalize(
        value: String
    ): String? {

        var number = value.replace(
            Regex("[^0-9+]"),
            ""
        )

        if (number.startsWith("+")) {
            number = number.substring(1)
        }

        if (number.startsWith("0")) {
            number = "62${number.substring(1)}"
        }

        if (!number.startsWith("62")) {
            return null
        }

        if (!Regex("^628\\d{7,12}$").matches(number)) {
            return null
        }

        return number
    }

    private fun wasRecentlySeen(
        preferences: SharedPreferences,
        key: String
    ): Boolean {

        val now = System.currentTimeMillis()

        val seen = preferences.getStringSet(
            "seen_notifications",
            emptySet()
        ).orEmpty()

        return seen.any { entry ->

            val separator = entry.lastIndexOf('|')

            separator > 0 &&
                entry.substring(0, separator) == key &&
                now - entry.substring(separator + 1)
                    .toLongOrNull()
                    .orZero() < 120_000
        }
    }

    private fun markSeen(
        preferences: SharedPreferences,
        key: String
    ) {

        val now = System.currentTimeMillis()

        val entries = preferences.getStringSet(
            "seen_notifications",
            emptySet()
        ).orEmpty()
            .filter { entry ->

                val separator = entry.lastIndexOf('|')

                separator > 0 &&
                    now - entry.substring(separator + 1)
                        .toLongOrNull()
                        .orZero() < 120_000
            }
            .toMutableSet()

        entries.add("$key|$now")

        // MutableSet diubah menjadi List agar takeLast didukung.
        val recentEntries = entries
            .toList()
            .takeLast(500)
            .toSet()

        preferences.edit()
            .putStringSet(
                "seen_notifications",
                recentEntries
            )
            .apply()
    }

    private fun isoNow(): String {

        return SimpleDateFormat(
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            Locale.US
        ).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }.format(Date())
    }

    private fun sha256(
        value: String
    ): String {

        return MessageDigest.getInstance("SHA-256")
            .digest(value.toByteArray())
            .joinToString("") { byte ->
                "%02x".format(byte)
            }
    }

    private fun Long?.orZero(): Long {
        return this ?: 0L
    }
}
