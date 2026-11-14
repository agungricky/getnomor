package com.getnomor.wa_contact_collector

import android.content.ContentProviderOperation
import android.content.ContentResolver
import android.content.Context
import android.provider.ContactsContract

object ContactContract {
    fun readContacts(context: Context): List<Map<String, String?>> {
        val result = mutableListOf<Map<String, String?>>()
        val resolver = context.contentResolver
        val projection = arrayOf(
            ContactsContract.CommonDataKinds.Phone.NUMBER,
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
        )
        resolver.query(
            ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
            projection,
            null,
            null,
            null,
        )?.use { cursor ->
            val numberIndex = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
            val nameIndex = cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
            while (cursor.moveToNext()) {
                result.add(
                    mapOf(
                        "phoneNumber" to cursor.getString(numberIndex),
                        "name" to cursor.getString(nameIndex),
                    )
                )
            }
        }
        return result
    }

    fun insertContacts(context: Context, contacts: List<Map<String, Any?>>) {
        val operations = ArrayList<ContentProviderOperation>()
        for (contact in contacts) {
            val phone = contact["phoneNumber"]?.toString() ?: continue
            val name = contact["name"]?.toString()?.ifBlank { "LEAD WA" } ?: "LEAD WA"
            val rawContactIndex = operations.size
            operations.add(
                ContentProviderOperation.newInsert(ContactsContract.RawContacts.CONTENT_URI)
                    .withValue(ContactsContract.RawContacts.ACCOUNT_TYPE, null)
                    .withValue(ContactsContract.RawContacts.ACCOUNT_NAME, null)
                    .build()
            )
            operations.add(
                ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, rawContactIndex)
                    .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE)
                    .withValue(ContactsContract.CommonDataKinds.StructuredName.DISPLAY_NAME, name)
                    .build()
            )
            operations.add(
                ContentProviderOperation.newInsert(ContactsContract.Data.CONTENT_URI)
                    .withValueBackReference(ContactsContract.Data.RAW_CONTACT_ID, rawContactIndex)
                    .withValue(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.Phone.CONTENT_ITEM_TYPE)
                    .withValue(ContactsContract.CommonDataKinds.Phone.NUMBER, phone)
                    .withValue(ContactsContract.CommonDataKinds.Phone.TYPE, ContactsContract.CommonDataKinds.Phone.TYPE_MOBILE)
                    .build()
            )
            if (operations.size >= 300) {
                applyBatch(context.contentResolver, operations)
                operations.clear()
            }
        }
        if (operations.isNotEmpty()) applyBatch(context.contentResolver, operations)
    }

    private fun applyBatch(resolver: ContentResolver, operations: ArrayList<ContentProviderOperation>) {
        resolver.applyBatch(ContactsContract.AUTHORITY, operations)
    }
}
