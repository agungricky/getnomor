# WA Contact Collector

Aplikasi Flutter Android untuk membantu CS mengumpulkan nomor Indonesia yang benar-benar tampil pada judul notifikasi baru WhatsApp dan WhatsApp Business, lalu menyimpannya sebagai kontak Android setelah konfirmasi.

## Menjalankan

1. Pasang Flutter SDK, Android SDK API 35, JDK 17, dan Android device/emulator.
2. Jalankan `flutter pub get`.
3. Jalankan `flutter analyze` dan `flutter test`.
4. Hubungkan HP Android dengan USB debugging, lalu jalankan `flutter run`.
5. Di aplikasi, aktifkan akses notifikasi Android dan akses kontak.

APK debug dapat dibuat dengan `flutter build apk --debug`; hasilnya berada di `build/app/outputs/flutter-apk/app-debug.apk`.

## Build cloud dengan GitHub Actions

Workflow [build-apk.yml](.github/workflows/build-apk.yml) berjalan di `ubuntu-latest`, memasang JDK 17, Flutter stable, dan Gradle 8.9. Workflow kemudian menjalankan `flutter pub get`, `flutter analyze`, `flutter test`, dan `flutter build apk --debug`.

Gradle Wrapper yang belum tersedia di checkout akan dibuat di runner sebelum build. File `android/local.properties` juga dibuat sementara di runner dan tidak disimpan ke repository.

Workflow dapat dijalankan otomatis melalui push ke branch `main`/`master`, pull request, atau manual melalui tab **Actions** → **Build WA Contact Collector APK** → **Run workflow**. Setelah job berhasil, unduh artifact `wa-contact-collector-debug-apk` dari halaman workflow.

Untuk repository private:

```powershell
git init
git add .
git commit -m "Add WA Contact Collector Flutter app"
git branch -M main
git remote add origin https://github.com/USERNAME/REPOSITORY.git
git push -u origin main
```

Jangan commit `android/local.properties`, signing key, atau secret. APK debug tidak membutuhkan signing secret.

## Batasan privasi

Notification Listener hanya menerima notifikasi baru yang tersedia untuk aplikasi. Implementasi ini hanya mengambil nomor dari `EXTRA_TITLE`/judul besar notifikasi, bukan isi pesan, chat lama, database WhatsApp, root, atau Accessibility Service. Semua daftar dan status disimpan lokal di SQLite.
