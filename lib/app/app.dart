import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/contact_service.dart';
import '../core/services/notification_service.dart';
import '../data/database/app_database.dart';
import '../data/models/detected_number.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/detected_numbers/detected_numbers_page.dart';
import '../features/settings/settings_page.dart';

class WaContactCollectorApp extends StatefulWidget {
  const WaContactCollectorApp({super.key, required this.database});

  final AppDatabase database;

  @override
  State<WaContactCollectorApp> createState() => _WaContactCollectorAppState();
}

class _WaContactCollectorAppState extends State<WaContactCollectorApp>
    with WidgetsBindingObserver {
  late final AppController controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    controller = AppController(widget.database);
    unawaited(controller.initialize());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'WA Contact Collector',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff168c4b),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xfff7faf8),
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
            ),
          ),
          home: HomeShell(controller: controller),
        );
      },
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(controller: widget.controller),
      DetectedNumbersPage(controller: widget.controller),
      SettingsPage(controller: widget.controller),
    ];

    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.contacts_outlined),
            selectedIcon: Icon(Icons.contacts),
            label: 'Nomor',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}

class AppController extends ChangeNotifier {
  AppController(this.database);

  final AppDatabase database;
  final NotificationService notificationService = NotificationService();
  final ContactService contactService = ContactService();

  List<DetectedNumber> numbers = [];
  bool isLoading = true;
  bool notificationAccess = false;
  bool contactsAccess = false;
  bool monitoringEnabled = false;
  String defaultContactName = 'LEAD WA';
  Timer? _refreshTimer;

  int get totalCount => numbers.length;
  int get savedCount => numbers.where((item) => item.isSavedContact).length;
  int get unsavedCount => numbers.length - savedCount;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    defaultContactName = preferences.getString('default_contact_name') ?? 'LEAD WA';
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) => refresh());
    await refresh();
  }

  Future<void> refresh() async {
    notificationAccess = await notificationService.isAccessGranted();
    monitoringEnabled = await notificationService.isMonitoringEnabled();
    contactsAccess = await Permission.contacts.isGranted;
    numbers = await database.getDetectedNumbers();
    if (contactsAccess) {
      await refreshContactStatuses();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> refreshContactStatuses() async {
    final contacts = await contactService.getContacts();
    final byNumber = <String, ContactRecord>{
      for (final contact in contacts) contact.phoneNumber: contact,
    };
    for (final number in numbers) {
      final contact = byNumber[number.phoneNumber];
      final saved = contact != null;
      if (number.isSavedContact != saved || number.contactName != contact?.name) {
        await database.updateContactStatus(
          id: number.id,
          isSaved: saved,
          contactName: contact?.name,
        );
      }
    }
    numbers = await database.getDetectedNumbers();
  }

  Future<bool> requestContactsPermission() async {
    final status = await Permission.contacts.request();
    contactsAccess = status.isGranted;
    notifyListeners();
    if (contactsAccess) await refresh();
    return contactsAccess;
  }

  Future<void> setMonitoring(bool enabled) async {
    await notificationService.setMonitoringEnabled(enabled);
    monitoringEnabled = enabled;
    notifyListeners();
  }

  Future<void> saveNumbers(List<DetectedNumber> selected, Map<int, String> names) async {
    if (!contactsAccess) {
      final granted = await requestContactsPermission();
      if (!granted) return;
    }
    final records = <ContactToSave>[];
    for (var i = 0; i < selected.length; i++) {
      final item = selected[i];
      final fallbackName = '$defaultContactName ${(i + 1).toString().padLeft(3, '0')}';
      final requestedName = names[item.id]?.trim();
      records.add(ContactToSave(
        phoneNumber: item.phoneNumber,
        name: requestedName == null || requestedName.isEmpty ? fallbackName : requestedName,
      ));
    }
    await contactService.saveContacts(records);
    await refresh();
  }

  Future<void> deleteNumber(int id) async {
    await database.deleteDetectedNumber(id);
    await refresh();
  }

  Future<void> clearHistory() async {
    await database.clearDetectedNumbers();
    await refresh();
  }

  Future<void> saveDefaultContactName(String value) async {
    final clean = value.trim().isEmpty ? 'LEAD WA' : value.trim();
    defaultContactName = clean;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('default_contact_name', clean);
    notifyListeners();
  }

  Future<void> openNotificationSettings() => notificationService.openAccessSettings();

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
