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
