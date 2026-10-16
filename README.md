# Quranku

Teman ngaji harian: aplikasi Al-Quran untuk **Lansia**, **Normal**, dan **Anak**.
Tanpa login wajib, tanpa backend. Semua data tersimpan di perangkat
(`shared_preferences`, otomatis menjadi `localStorage` di web).

Package: `id.examku.quranku`

## Fitur

- **Onboarding**: pilih mode (Lansia / Normal / Anak) + nama opsional.
- **Al-Quran**: 114 surah + pencarian. Teks Arab (Amiri Quran), latin,
  terjemahan Indonesia (data: equran.ninja v2, di-cache lokal).
  Audio per ayat + putar full surah. Penanda warna tajwid berbasis aturan
  (ikhfa, idgham, iqlab, qalqalah, mad). Slider ukuran font.
  Posisi terakhir dibaca tersimpan otomatis.
- **Belajar Hijaiyah**: 28 huruf + 7 harakat, ketuk untuk dengar (TTS ar-SA).
- **Belajar Iqro**: Jilid 1-3, halaman per halaman, ketuk baris untuk dengar.
- **Kisah 25 Nabi**: tiap nabi 3-5 episode, progres tersimpan.
- **Kompas Kiblat**: bearing great-circle ke Ka'bah dari GPS + sensor kompas;
  fallback manual bila sensor tidak ada (web).
- **Pengingat Ngaji**: notifikasi lokal harian (Android); fallback dalam
  aplikasi di web.
- **Challenge Harian**: 10 soal per sesi (bank soal lokal), skor + streak
  harian + badge.
- **Pengaturan**: ganti mode, ukuran font, toggle tajwid/latin/terjemahan,
  info sinkronisasi cloud (segera hadir, via Firebase + login Google).

## Sinkronisasi Cloud (rencana, belum aktif)

Keputusan: **Firebase Authentication (Google Sign-In) + Realtime Database**.
Tanpa Firestore. Login tetap opsional; tanpa login aplikasi lokal penuh.

Struktur JSON tree di Realtime Database (`users/{uid}`):

```
users/{uid}/
  meta:           { updatedAt, appVersion, schema }
  profile:        { mode, nama, fontScale }
  tampilan:       { tajwid, latin, terjemahan }
  terakhirDibaca: { surah, namaSurah, ayat, waktu }
  reminder:       { on, hour, minute }
  challenge:      { streak, lastDate, score, badges: [...] }
  iqro:           { "1": halaman, "2": halaman, "3": halaman }
  kisah:          { "0": episodeIdx, ... }
  hijaiyah:       [ "بَ", "تَ", ... ]
```

Lapisan data sudah siap: `lib/core/sync_model.dart` (`export()` /
`rtdbPath(uid)` / `remoteLebihBaru()` untuk last-write-wins) dan
`AppStore.restoreFromSync()` (pulihkan defensif dari tree, tanpa crash
bila tree tidak lengkap). Test: `test/sync_model_test.dart` (`flutter test`).

Langkah setup (~30 menit setelah proyek Firebase siap):
1. Firebase Console → buat proyek (gratis) → daftarkan aplikasi Android
   (`id.examku.quranku`) + Web.
2. Authentication → aktifkan provider **Google**.
3. Realtime Database → buat database → atur rules per-user:
   ```json
   { "rules": { "users": { "$uid": {
     ".read": "auth != null && auth.uid == $uid",
     ".write": "auth != null && auth.uid == $uid"
   } } } }
   ```
4. Tambah paket `firebase_auth`, `google_sign_in`, `firebase_database`;
   pasang `google-services.json` (Android) sesuai dokumentasi Firebase.
5. Alur: setelah login Google → baca `users/{uid}` → bandingkan
   `meta.updatedAt` dengan lokal (`SyncModel.remoteLebihBaru`) → yang baru
   menang → tulis balik bila lokal lebih baru. Tombol "Sinkronkan sekarang"
   + sinkronisasi otomatis tiap perubahan penting.

## Menjalankan

```bash
export PATH="$HOME/workspace/tools/flutter/bin:$PATH"
flutter pub get
flutter run                    # debug (pilih perangkat)
flutter build web --release    # output: build/web
```

## Deploy web ke VPS

Lihat `deploy.sh`. Ringkasnya:

```bash
./deploy.sh
```

Script membangun web release, mengunggah ke `/var/www/quranku` di VPS
`43.134.175.87` lewat `~/workspace/tools/vps-ssh`, lalu menambah blok
`quran.examku.my.id` ke Caddy dan me-reload. Butuh tunnel SSH aktif dan
DNS `quran.examku.my.id` mengarah ke `43.134.175.87` (atur di Cloudflare).

## Struktur

```
lib/
  main.dart
  core/            # storage, app_store (state), theme
  features/
    onboarding/
    home/
    quran/         # api client, tajwid highlighter, daftar, reader, terakhir dibaca
    hijaiyah/
    iqro/
    kisah/
    kiblat/
    reminder/
    challenge/
    settings/
assets/data/       # iqro.json, kisah_nabi.json, challenge.json
```

Lihat `DESIGN.md` untuk arah desain.
