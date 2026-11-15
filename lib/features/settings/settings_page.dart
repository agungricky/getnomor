
import 'package:flutter/material.dart';

import '../../app/app.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController nameController;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(
      text: widget.controller.defaultContactName,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        Text(
          'Pengaturan',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 20),

        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Format nama kontak',
            helperText: 'Contoh: LEAD WA menjadi LEAD WA 001',
          ),
          onSubmitted: (value) {
            widget.controller.saveDefaultContactName(value);
          },
        ),

        const SizedBox(height: 6),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () async {
              await widget.controller.saveDefaultContactName(
                nameController.text,
              );

              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Format nama disimpan.'),
                ),
              );
            },
            child: const Text('Simpan format'),
          ),
        ),

        const Divider(height: 32),

        ListTile(
          leading: const Icon(Icons.notifications_active_outlined),
          title: const Text('Akses notifikasi'),
          subtitle: Text(
            widget.controller.notificationAccess
                ? 'Aktif'
                : 'Belum diaktifkan',
          ),
          trailing: const Icon(Icons.open_in_new),
          onTap: () {
            widget.controller.openNotificationSettings();
          },
        ),

        ListTile(
          leading: const Icon(Icons.contacts_outlined),
          title: const Text('Akses kontak'),
          subtitle: Text(
            widget.controller.contactsAccess
                ? 'Aktif'
                : 'Belum diaktifkan',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            widget.controller.requestContactsPermission();
          },
        ),

        const Divider(height: 32),

        ListTile(
          leading: const Icon(Icons.delete_sweep_outlined),
          title: const Text('Hapus riwayat nomor'),
          subtitle: const Text(
            'Menghapus daftar lokal, tidak menghapus kontak Android',
          ),
          onTap: () => _clearHistory(context),
        ),

        const SizedBox(height: 16),

        const Text(
          'Notification Listener hanya menerima notifikasi baru '
          'yang diizinkan Android. Aplikasi tidak dapat membaca '
          'daftar chat atau nomor lama WhatsApp, tidak membaca '
          'isi pesan untuk disimpan, dan tidak menggunakan root, '
          'Accessibility Service, atau scraping database WhatsApp.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Future<void> _clearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus riwayat?'),
          content: const Text(
            'Semua nomor dari daftar lokal akan dihapus.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await widget.controller.clearHistory();
    }
  }
}
