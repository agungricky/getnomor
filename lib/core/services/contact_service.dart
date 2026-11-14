import 'package:flutter/services.dart';

import '../utils/phone_normalizer.dart';

class ContactRecord {
  const ContactRecord({required this.phoneNumber, this.name});

  final String phoneNumber;
  final String? name;
}

class ContactToSave {
  const ContactToSave({required this.phoneNumber, required this.name});

  final String phoneNumber;
  final String name;

  Map<String, String> toMap() => {'phoneNumber': phoneNumber, 'name': name};
}

class ContactService {
  static const _channel = MethodChannel('com.getnomor.wa_contact_collector/native');

  Future<List<ContactRecord>> getContacts() async {
    final result = await _channel.invokeMethod<List<dynamic>>('getContacts') ?? [];
    final contacts = <ContactRecord>[];
    for (final item in result) {
      final map = Map<String, dynamic>.from(item as Map);
      final number = PhoneNormalizer.normalize(map['phoneNumber'] as String? ?? '');
      if (number != null) {
        contacts.add(ContactRecord(
          phoneNumber: number,
          name: map['name'] as String?,
        ));
      }
    }
    return contacts;
  }

  Future<void> saveContacts(List<ContactToSave> contacts) async {
    await _channel.invokeMethod<void>(
      'saveContacts',
      contacts.map((contact) => contact.toMap()).toList(),
    );
  }
}
