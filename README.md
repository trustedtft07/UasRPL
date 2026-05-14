# Aplikasi POS UMKM

Aplikasi Point of Sale (POS) berbasis Flutter untuk UMKM Indonesia. Mendukung pembayaran QRIS via Midtrans, manajemen kasir, dan penarikan dana.

## Fitur

- Login dua peran: **Merchant** (owner) dan **Kasir** (PIN-based)
- Generate QRIS pembayaran via Midtrans Snap
- Sinkronisasi status pembayaran otomatis
- Wallet saldo merchant real-time
- Manajemen tim kasir
- Penarikan dana ke rekening bank / dompet digital
- Riwayat transaksi & penarikan
- Settings profil toko

## Tech Stack

- Flutter 3.x
- Firebase (Auth + Firestore)
- Midtrans Payment Gateway (Sandbox)

## Setup

### 1. Clone repo

```bash
git clone https://github.com/trustedtft07/UasRPL.git
cd UasRPL
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Konfigurasi Firebase

File `lib/firebase_options.dart` tidak disertakan di repo karena berisi API key.

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Generate konfigurasi (login ke Firebase project Anda)
flutterfire configure
```

Atau salin `lib/firebase_options.example.dart` → `lib/firebase_options.dart` dan isi manual.

### 4. Jalankan

```bash
flutter run --dart-define=MIDTRANS_SERVER_KEY=your_midtrans_server_key
```

### 5. Build APK

```bash
flutter build apk --split-per-abi --dart-define=MIDTRANS_SERVER_KEY=your_midtrans_server_key
```

APK tersedia di `build/app/outputs/flutter-apk/`.

## Struktur Proyek

```
lib/
├── core/           # Konstanta warna, tema, formatter, helper
├── models/         # Data model Firestore
├── screens/        # UI screens
│   ├── home/       # Dashboard utama + tabs
│   └── ...
├── services/       # Firebase & Midtrans service
└── widgets/        # Shared reusable widgets
```

## Catatan

- Midtrans menggunakan mode **Sandbox** — gunakan simulator pembayaran di dashboard Midtrans.
- Server key Midtrans dibaca lewat `--dart-define=MIDTRANS_SERVER_KEY=...` agar tidak tersimpan di source code.
