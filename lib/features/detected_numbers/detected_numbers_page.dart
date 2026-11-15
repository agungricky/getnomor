import 'package:flutter/material.dart';

import '../../app/app.dart';
import '../../data/models/detected_number.dart';

enum NumberFilter { all, unsaved, saved }

class DetectedNumbersPage extends StatefulWidget {
  const DetectedNumbersPage({super.key, required this.controller});
  final AppController controller;

  @override
  State<DetectedNumbersPage> createState() => _DetectedNumbersPageState();
}

class _DetectedNumbersPageState extends State<DetectedNumbersPage> {
  final searchController = TextEditingController();
  final selectedIds = <int>{};
  NumberFilter filter = NumberFilter.all;

  List<DetectedNumber> get filtered {
    final query = searchController.text.trim();
    return widget.controller.numbers.where((item) {
      final matchesQuery = query.isEmpty || item.phoneNumber.contains(query);
      final matchesFilter = switch (filter) {
        NumberFilter.all => true,
        NumberFilter.unsaved => !item.isSavedContact,
        NumberFilter.saved => item.isSavedContact,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Daftar Nomor', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari nomor...', isDense: true),
            ),
            const SizedBox(height: 8),
            SegmentedButton<NumberFilter>(
              segments: const [
                ButtonSegment(value: NumberFilter.all, label: Text('Semua')),
                ButtonSegment(value: NumberFilter.unsaved, label: Text('Belum')),
                ButtonSegment(value: NumberFilter.saved, label: Text('Tersimpan')),
              ],
              selected: {filter},
              onSelectionChanged: (value) => setState(() => filter = value.first),
            ),
          ]),
        ),
        if (selectedIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(children: [
              Text('${selectedIds.length} dipilih'),
              const Spacer(),
              FilledButton.icon(onPressed: () => _saveSelected(items), icon: const Icon(Icons.save_outlined), label: const Text('Simpan Terpilih')),
            ]),
          ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('Belum ada nomor yang cocok.'))
              : RefreshIndicator(
                  onRefresh: widget.controller.refresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                    itemCount: items.length,
                    itemBuilder: (context, index) => _NumberTile(
                      item: items[index],
                      selected: selectedIds.contains(items[index].id),
                      onSelected: (value) => setState(() => value ? selectedIds.add(items[index].id) : selectedIds.remove(items[index].id)),
                      onSave: () => _saveOne(items[index]),
                      onDelete: () => widget.controller.deleteNumber(items[index].id),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _saveOne(DetectedNumber item) async {
    final name = await _askName(item, '${widget.controller.defaultContactName} 001');
    if (!mounted || name == null) return;
    await widget.controller.saveNumbers([item], {item.id: name});
  }

  Future<void> _saveSelected(List<DetectedNumber> visible) async {
    final selected = visible.where((item) => selectedIds.contains(item.id) && !item.isSavedContact).toList();
    if (selected.isEmpty) return;
    final names = await _askBatchNames(selected);
    if (!mounted || names == null) return;
    await widget.controller.saveNumbers(selected, names);
    setState(() => selectedIds.clear());
  }

  Future<String?> _askName(DetectedNumber item, String suggestedName) async {
    final textController = TextEditingController(text: suggestedName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simpan sebagai kontak'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.phoneNumber),
          const SizedBox(height: 12),
          TextField(controller: textController, autofocus: true, decoration: const InputDecoration(labelText: 'Nama kontak')),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')), FilledButton(onPressed: () => Navigator.pop(context, textController.text.trim()), child: const Text('Simpan'))],
      ),
    );
    textController.dispose();
    return result;
  }

  Future<Map<int, String>?> _askBatchNames(List<DetectedNumber> selected) async {
    final controllers = <int, TextEditingController>{
      for (var index = 0; index < selected.length; index++)
        selected[index].id: TextEditingController(
          text: '${widget.controller.defaultContactName} ${(index + 1).toString().padLeft(3, '0')}',
        ),
    };
    final result = await showDialog<Map<int, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Simpan ${selected.length} kontak?'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(shrinkWrap: true, children: selected.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(controller: controllers[item.id], decoration: InputDecoration(labelText: item.phoneNumber)),
          )).toList()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, {for (final entry in controllers.entries) entry.key: entry.value.text.trim()}), child: const Text('Konfirmasi')),
        ],
      ),
    );
    for (final controller in controllers.values) {
  controller.dispose();
}

return result;
  }
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({required this.item, required this.selected, required this.onSelected, required this.onSave, required this.onDelete});
  final DetectedNumber item;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = item.isSavedContact ? Colors.green : Colors.orange;
    return Card(
      child: ListTile(
        leading: Checkbox(value: selected, onChanged: (value) => onSelected(value ?? false)),
        title: Text(item.phoneNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${item.source} • ${_formatDate(item.firstDetectedAt)}\n${item.isSavedContact ? 'SUDAH TERSIMPAN${item.contactName == null ? '' : ': ${item.contactName}'}' : 'BELUM TERSIMPAN'}'),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'save') onSave();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            if (!item.isSavedContact) const PopupMenuItem(value: 'save', child: Text('Simpan Kontak')),
            const PopupMenuItem(value: 'delete', child: Text('Hapus dari daftar')),
          ],
          icon: Icon(Icons.more_vert, color: color),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
