# Riset API Al-Quran untuk "Quranku" — equran.ninja API v2

Tanggal riset: 2026-10-17. Metode: struktur diverifikasi lewat triangulasi
(dokumentasi resmi equran.id/apidev/v2 + 6+ repo konsumen open-source: gurun-islamic-mobile,
kait-alquaran, bungrahman/equran, guidelightid/mushaf, MyQuran Flutter).
Fetch langsung ke `equran.ninja/api/v2` dari VM riset GAGAL (empty reply dari server),
jadi payload live belum sempat dibaca 1:1 — semua field di bawah sudah dikonfirmasi
namanya dari banyak konsumen independen, dan disarankan koordinator memverifikasi ulang
satu kali via `curl https://equran.ninja/api/v2/surat/112` sebelum integrasi.

## 1. Endpoint & struktur respons

Base URL: `https://equran.ninja/api/v2` (tanpa API key, tanpa auth).
Fallback ekuivalen: `https://equran.id/api/v2` (domain lama, payload sama persis).

Semua respons memakai wrapper: `{ "code": 200, "message": "...", "data": ... }`.
**Jangan lupa baca dari `.data`, bukan root.**

### GET /surat — daftar 114 surah
`data`: array objek:
```json
{
  "nomor": 112,
  "nama": "الاخلاص",
  "namaLatin": "Al-Ikhlas",
  "jumlahAyat": 4,
  "tempatTurun": "Mekah",
  "arti": "Ikhlas",
  "deskripsi": "<p>Surah ini ...</p>",
  "audioFull": {
    "01": "https://cdn.equran.id/audio-full/Abdullah-Al-Juhany/112.mp3",
    "02": "https://cdn.equran.id/audio-full/Abdul-Muhsin-Al-Qasim/112.mp3",
    "03": "https://cdn.equran.id/audio-full/Abdurrahman-as-Sudais/112.mp3",
    "04": "https://cdn.equran.id/audio-full/Ibrahim-Al-Dossari/112.mp3",
    "05": "https://cdn.equran.id/audio-full/Misyari-Rasyid-Al-Afasi/112.mp3",
    "06": "https://cdn.equran.id/audio-full/Yasser-Al-Dosari/112.mp3"
  }
}
```
Catatan: `deskripsi` berisi HTML (tag `<p>` dll) — render dengan parser HTML, bukan teks mentah.

### GET /surat/{nomor} — detail surah + semua ayat
`data`: objek surah seperti di atas + array `ayat`:
```json
{
  "nomorAyat": 1,
  "teksArab": "قُلْ هُوَ اللّٰهُ اَحَدٌۚ",
  "teksLatin": "qul huwallāhu aḥad",
  "teksIndonesia": "Katakanlah (Muhammad), \"Dialah Allah, Yang Maha Esa.\"",
  "audio": {
    "01": "https://cdn.equran.id/audio-partial/Abdullah-Al-Juhany/112001.mp3",
    "02": "...",
    "03": "...",
    "04": "...",
    "05": "...",
    "06": "..."
  }
}
```
- **Ya: teksArab, teksLatin, teksIndonesia ada per ayat.** Terjemahan = Kemenag (resmi).
- **Audio PER AYAT ada** (6 qari). **Audio PER SURAH ada** via `audioFull` (6 qari).
- **Info qari:** key `"01"`–`"06"` = Abdullah Al-Juhany, Abdul Muhsin Al-Qasim,
  Abdurrahman as-Sudais, Ibrahim Al-Dossari, Misyari Rasyid Al-Afasi, Yasser Al-Dosari.
  (Pemetaan diverifikasi dari kode konsumen, bukan dari respons API — API hanya
  mengirim angka "01".."06".)
- Tidak ada field `primer`/`sekunder` di v2 (itu pola v1). Di v2 kuncinya kode qari.
- Contoh lengkap Surah 112 (Al-Ikhlas) ada di bagian bawah dokumen ini.

### GET /tafsir/{nomor} — tafsir per surah
Ada. `data`: `{ "nomor", "nama", "namaLatin", "jumlahAyat", "tafsir": [ { "ayat": 1, "teks": "..." }, ... ] }`.
Tafsir Wajiz Kemenag, teks panjang per ayat. (Opsional untuk Quranku — tidak wajib di MVP.)

### Endpoint lain yang tercatat (opsional)
- `/doa` dan `/doa/{id}` — doa & dzikir harian (arab, latin, terjemahan).
  Berguna kalau Quranku mau tambah menu doa nanti.
- **Tidak ada endpoint 1 ayat spesifik** (`/surat/{n}/ayat/{m}` tidak ada di v2) —
  untuk 1 ayat, fetch `/surat/{nomor}` lalu filter `nomorAyat` di klien.

## 2. Pola URL audio (hasil verifikasi)

- Host CDN: `cdn.equran.id` (bukan equran.ninja).
- Full surah (terverifikasi dari kode konsumen):
  `https://cdn.equran.id/audio-full/<slug-qari>/<NNN>.mp3`
  contoh: `https://cdn.equran.id/audio-full/Misyari-Rasyid-Al-Afasi/112.mp3`
- Per ayat: URL **sudah disediakan di payload** (`ayat[i].audio["05"]`), jadi
  **tidak perlu merakit URL manual** — pakai langsung dari API.
- **Tanpa auth.** HTTPS publik, bisa langsung diputar via just_audio maupun
  audioplayers. just_audio direkomendasikan (buffering, seek, playback speed,
  support web).
- Catatan web: pemutaran via elemen audio HTML tidak butuh header CORS;
  CORS baru dibutuhkan jika memproses audio via Web Audio API (mis. visualizer).

## 3. Rate limit & CORS (yang perlu dihindari)

- Tidak ada dokumentasi rate limit publik. Ini API komunitas gratis di hosting
  kecil — **jangan di-burst**. Strategi aman:
  1. Fetch `/surat` 1x saat pertama buka, simpan ke shared_preferences (atau file lokal).
  2. Fetch `/surat/{n}` hanya saat surah dibuka, lalu **cache permanen** (data Quran
     tidak pernah berubah). Gunakan staleTime tak terbatas + versi cache.
  3. Jangan fetch paralel 114 surah sekaligus.
- Retry sederhana (1x, backoff) untuk kegagalan jaringan; tampilkan state offline.
- Fetch dari Flutter web berjalan (banyak PWA/web app mengonsumsinya langsung dari
  browser) — tapi jika suatu saat CORS bermasalah, fallback: proxy lewat
  `api.allorigins.win` atau pindah fetch ke sisi yang sama-origin (tidak berlaku di
  sini karena tanpa backend → andalkan cache lokal).

## 4. Rekomendasi strategi audio: Belajar Hijaiyah & Belajar Iqro

### Belajar Hijaiyah → rekaman MP3 kecil sebagai Flutter assets (bukan flutter_tts)
- flutter_tts memang praktis (tanpa file, offline di Android/iOS jika voice Arab
  terinstal, gratis), TAPI kualitas makhraj huruf hijaiyah dari TTS mesin tidak
  akurat (intonasi salah, variasi antar-perangkat, voice Arab sering belum
  terinstal di HP murah, di web tergantung browser). Untuk anak belajar huruf,
  makhraj yang benar itu inti fiturnya.
- Rekomendasi praktis: **bundle ±30 file MP3 pendek (huruf + harakat) sebagai
  assets aplikasi** — ukuran total hanya ratusan KB, 100% offline, konsisten di
  semua perangkat, tanpa backend. flutter_tts cukup jadi **fallback** bila asset
  belum tersedia. (Catatan: file-nya perlu direkam/disourcing sekali di awal —
  bisa dari rekaman ustadz atau generate TTS berkualitas lalu di-freeze sebagai file.)

### Belajar Iqro → streaming audio per ayat dari equran CDN via just_audio
- Kata-kata Iqro jilid 1–3 sebagian besar adalah potongan ayat Juz 'Amma;
  jilid 4+ sudah ayat utuh → **audio per ayat equran (`audio["05"]` qari
  Misyari Rasyid) langsung cocok**, tanpa hosting sendiri.
- Strategi: putar streaming saat online; cache file MP3 yang sudah diputar ke
  direktori dokumen aplikasi (via `just_audio` + cache manual sederhana, atau
  unduh sekali per surah Juz 30 saat pertama dipakai) agar bisa offline.
- **Jangan pakai flutter_tts untuk Iqro** — TTS mesin merusak tajwid (mad,
  ghunnah, qalqalah hilang), berlawanan dengan tujuan belajar.

## 5. Tambahan untuk koordinator

- **Font Arab:** teksArab memakai script Utsmani — bundle font `NotoNaskhArabic`
  atau `Amiri` (atau paket `google_fonts`), set `TextDirection.rtl`.
- **Tanda warna tajwid:** equran v2 TIDAK menyediakan markup tajwid. Untuk fitur
  "tanda warna tajwid", ambil teks bertanda dari AlQuran Cloud:
  `https://api.alquran.cloud/v1/surah/{nomor}/quran-tajweed` lalu petakan marker
  (`[h]`, `[s]`, dsb.) ke warna di klien. Ini pekerjaan terpisah dari integrasi equran.
- **Qibla:** tidak ada di API ini; pakai sensor kompas + rumus haversine ke Ka'bah
  (21.4225, 39.8262) murni di klien.
- **Verifikasi ulang wajib:** `curl https://equran.ninja/api/v2/surat/112` dari
  jaringan normal sebelum integrasi final (VM riset gagal menjangkau host ini).

## 6. Contoh respons lengkap — GET /surat/112 (struktur terverifikasi, isi representatif)

```json
{
  "code": 200,
  "message": "Sukses",
  "data": {
    "nomor": 112,
    "nama": "الاخلاص",
    "namaLatin": "Al-Ikhlas",
    "jumlahAyat": 4,
    "tempatTurun": "Mekah",
    "arti": "Ikhlas",
    "deskripsi": "<p>Surah Al-Ikhlas adalah surah ke-112 ...</p>",
    "audioFull": {
      "01": "https://cdn.equran.id/audio-full/Abdullah-Al-Juhany/112.mp3",
      "05": "https://cdn.equran.id/audio-full/Misyari-Rasyid-Al-Afasi/112.mp3"
    },
    "ayat": [
      {
        "nomorAyat": 1,
        "teksArab": "قُلْ هُوَ اللّٰهُ اَحَدٌۚ",
        "teksLatin": "qul huwallāhu aḥad",
        "teksIndonesia": "Katakanlah (Muhammad), \"Dialah Allah, Yang Maha Esa.\"",
        "audio": { "01": ".../112001.mp3", "05": ".../112001.mp3" }
      },
      {
        "nomorAyat": 2,
        "teksArab": "اَللّٰهُ الصَّمَدُۚ",
        "teksLatin": "allāhuṣ-ṣamad",
        "teksIndonesia": "Allah tempat meminta segala sesuatu.",
        "audio": { "01": ".../112002.mp3", "05": ".../112002.mp3" }
      },
      {
        "nomorAyat": 3,
        "teksArab": "لَمْ يَلِدْ وَلَمْ يُوْلَدْۙ",
        "teksLatin": "lam yalid wa lam yụlad",
        "teksIndonesia": "(Allah) tidak beranak dan tidak pula diperanakkan.",
        "audio": { "01": ".../112003.mp3", "05": ".../112003.mp3" }
      },
      {
        "nomorAyat": 4,
        "teksArab": "وَلَمْ يَكُنْ لَّهٗ كُفُوًا اَحَدٌ",
        "teksLatin": "wa lam yakul lahụ kufuwan aḥad",
        "teksIndonesia": "Dan tidak ada sesuatu yang setara dengan Dia.",
        "audio": { "01": ".../112004.mp3", "05": ".../112004.mp3" }
      }
    ]
  }
}
```
(Nilai `teks*` di atas adalah isi Al-Ikhlas yang standar; koordinator tetap
verifikasi 1x lewat curl karena fetch langsung dari VM riset tidak berhasil.)
