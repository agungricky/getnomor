package com.getnomor.wa_contact_collector

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

class CollectorDatabase(context: Context, name: String) : SQLiteOpenHelper(context, name, null, 1) {
    override fun onCreate(database: SQLiteDatabase) {
        database.execSQL(
            """CREATE TABLE IF NOT EXISTS detected_numbers (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                phone_number TEXT NOT NULL UNIQUE,
                source TEXT NOT NULL,
                first_detected_at TEXT NOT NULL,
                last_detected_at TEXT NOT NULL,
                is_saved_contact INTEGER NOT NULL DEFAULT 0,
                contact_name TEXT
            )"""
        )
        database.execSQL("CREATE INDEX IF NOT EXISTS idx_detected_numbers_last_detected ON detected_numbers(last_detected_at DESC)")
    }

    override fun onUpgrade(database: SQLiteDatabase, oldVersion: Int, newVersion: Int) = Unit
}
