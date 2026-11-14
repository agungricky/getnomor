import 'package:flutter/material.dart';

import '../../app/app.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          Text('WA Contact Collector', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Kumpulkan nomor dari notifikasi WhatsApp secara lokal.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _StatCard(label: 'Terdeteksi', value: controller.totalCount, icon: Icons.phone_in_talk_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(label: 'Belum tersimpan', value: controller.unsavedCount, icon: Icons.person_add_alt_1_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(label: 'Tersimpan', value: controller.savedCount, icon: Icons.person_outline)),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _StatusRow(label: 'Akses notifikasi', granted: controller.notificationAccess, onTap: () => controller.openNotificationSettings()),
                  const Divider(height: 24),
                  _StatusRow(label: 'Akses kontak', granted: controller.contactsAccess, onTap: () => controller.requestContactsPermission()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Monitoring', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(controller.monitoringEnabled ? 'Aktif — nomor dari notifikasi baru akan diproses.' : 'Nonaktif — layanan tidak akan memproses notifikasi.'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: controller.notificationAccess
                        ? () => controller.setMonitoring(!controller.monitoringEnabled)
                        : () => controller.openNotificationSettings(),
                    icon: Icon(controller.monitoringEnabled ? Icons.stop_circle_outlined : Icons.play_circle_outline),
                    label: Text(controller.monitoringEnabled ? 'Hentikan Monitoring' : 'Mulai Monitoring'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Catatan privasi\n\nAplikasi hanya memeriksa nomor yang tampil pada judul notifikasi baru WhatsApp/WhatsApp Business. Isi pesan, chat lama, dan database internal WhatsApp tidak dibaca atau dikirim ke server.'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});
  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 10),
          Text('$value', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.granted, required this.onTap});
  final String label;
  final bool granted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(granted ? Icons.check_circle : Icons.warning_amber_rounded, color: granted ? Colors.green : Colors.orange),
      const SizedBox(width: 12),
      Expanded(child: Text('$label: ${granted ? 'Aktif' : 'Belum aktif'}')),
      if (!granted) TextButton(onPressed: onTap, child: const Text('Atur')),
    ]);
  }
}
