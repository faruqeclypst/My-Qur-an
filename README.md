# My Qur'an

Aplikasi Al-Quran untuk semua usia: **Lansia**, **Normal**, dan **Anak**.
Tanpa login wajib, tanpa backend — semua data tersimpan di perangkat
(`shared_preferences`; otomatis menjadi `localStorage` di versi web).

- Package: `id.examku.quranku`
- Versi web: https://perseverance.my.id/quran/

## Fitur

- **Onboarding** — pilih mode (Lansia / Normal / Anak) + nama opsional. Mode bisa diganti kapan saja di Pengaturan.
- **Baca Al-Quran** — 114 surah + pencarian.
  - Dua tampilan: **Per Ayat** (kartu per ayat: Arab + latin + terjemahan) dan **Mushaf** (teks Arab satu surah mengalir utuh seperti mushaf cetak, tanpa latin/terjemahan).
  - **Tanda warna tajwid** berbasis aturan (ikhfa, idgham, iqlab, qalqalah, mad), bisa dinyalakan/dimatikan dari halaman baca.
  - **Audio**: per ayat, putar seluruh surah, tombol ayat sebelumnya/berikutnya, dan otomatis lanjut ke surah berikutnya saat putar full surah selesai.
  - Slider ukuran huruf Arab; posisi terakhir dibaca tersimpan otomatis.
- **Belajar Hijaiyah** — 28 huruf + variasi harakat, ketuk untuk mendengar (TTS).
- **Belajar Iqro** — Jilid 1–3, halaman per halaman, ketuk baris untuk mendengar; sapaan ramah anak di mode Anak.
- **Kisah 25 Nabi** — serial per episode, bahasa ramah anak, progres baca tersimpan.
- **Kompas Kiblat** — arah kiblat dari GPS (bearing great-circle ke Ka'bah) + sensor kompas HP; tampilkan jarak ke Ka'bah; panduan manual bila sensor tidak tersedia (web/laptop).
- **Pengingat Ngaji** — notifikasi lokal harian (Android); pengingat dalam aplikasi di web.
- **Challenge Harian** — kuis harian untuk mode Normal dan Anak (bank soal lokal), skor + streak + badge. Disembunyikan penuh di mode Lansia.
- **Terakhir Dibaca** — akses cepat melanjutkan bacaan terakhir.

## Tech Stack

- **Flutter** (Android, iOS, Web, tablet)
- **Data Quran**: API equran.id v2 (teks Arab, latin, terjemahan Kemenag, audio per ayat) — di-cache lokal
- **Penyimpanan lokal**: `shared_preferences`
- **Font Arab**: Scheherazade New (OFL, SIL) dibundel lokal + fallback Amiri Quran
- **Audio**: `just_audio` · **TTS**: `flutter_tts` · **Lokasi**: `geolocator` · **Kompas**: `flutter_compass` · **Notifikasi**: `flutter_local_notifications`

## Cara Menjalankan

```bash
flutter pub get
flutter run
```

## Cara Build

```bash
# Web (release)
flutter build web --release

# Android APK (release) — butuh Android SDK
flutter build apk --release
```

Deploy versi web ke server memakai `./deploy.sh` (idempoten; mengunggah hasil
build ke VPS dan me-reload Caddy).

## Struktur Folder (ringkas)

```
lib/
  main.dart                # entry point
  core/                    # theme, AppStore (state), dekorasi, sync_model
  features/
    home/                  # beranda + navigasi per mode
    quran/                 # daftar surah, halaman baca, API, tajwid
    hijaiyah/              # belajar huruf hijaiyah
    iqro/                  # belajar iqro jilid 1-3
    kisah/                 # kisah 25 nabi
    kiblat/                # kompas kiblat
    challenge/             # challenge harian
    reminder/              # pengingat ngaji
    settings/              # pengaturan
assets/
  data/                    # iqro.json, kisah_nabi.json, challenge.json
  fonts/                   # font Arab lokal (OFL)
  icon/                    # ikon aplikasi
```

## Sinkronisasi Cloud (rencana, belum aktif)

Login tetap opsional. Bila ingin progres (terakhir dibaca, skor, progres
belajar) tersimpan online dan sinkron antar-perangkat, rencananya memakai
**Firebase Authentication (Google Sign-In) + Firebase Realtime Database**.
Model data di `lib/core/sync_model.dart` sudah dirancang siap-Realtime-Database
(struktur JSON tree + strategi last-write-wins via `meta.updatedAt`).

## Lisensi & Kredit

- Font **Scheherazade New** dan **Amiri Quran**: SIL Open Font License (OFL).
- Data teks, terjemahan, dan audio Al-Quran: **equran.id** (API v2).
- Kode aplikasi: milik pengembang.
