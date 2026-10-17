# DESIGN.md — Quranku

## Ringkasan
Aplikasi Al-Quran untuk tiga generasi: Lansia, Normal, dan Anak. Satu aplikasi, tiga suasana.
Identitas visual: **"teman ngaji yang hangat dan tenang"**, bukan "aplikasi teknologi".

## Dial
ENERGY 2 / RHYTHM 2 / MOTION 1
- Alasan ENERGY 2: ini aplikasi ibadah, harus menyapa dengan hangat tapi tidak berisik.
- Alasan RHYTHM 2: setiap fitur (baca, belajar, kisah, kiblat) punya pola tata letak sendiri yang mengikuti isi, bukan satu template kartu berulang.
- Alasan MOTION 1: ketenangan. Hanya hover/press feedback dan transisi halaman halus. Tidak ada animasi loop.

## Palet
- Warna inti: zamrud tua `#0E5E4A` (ketenangan, identitas Islam, dipakai di header/aksen utama). Alasan: hijau zamrud adalah warna yang lekat dengan identitas mushaf, dan kontrasnya kuat di atas krem.
- Netral hangat: krem kertas `#FAF6EE` (latar), tinta `#1F2937` (teks). Alasan: kertas hangat terasa seperti mushaf cetak, lebih nyaman dibaca lama daripada putih dingin.
- Aksen: emas lembut `#C9A227` (dipakai hemat: penanda tajwid tertentu, badge streak, tombol utama sesekali). Alasan: emas memberi kesan "mulia" tanpa berisik; dipakai di momen penting saja.
- Mode Lansia: latar putih bersih `#FFFFFF`, tinta hitam pekat `#111111`, zamrud digelapkan `#0B4A3A`. Alasan: kontras maksimum untuk mata yang sudah lelah.
- Mode Anak: palet sama tapi lebih cerah (zamrud `#16A34A`-ish diganti ke toska ceria `#0FA3A3`, aksen kuning madu `#F5B301`), kartu sudut membulat besar. Alasan: anak butuh kesan ceria; identitas tetap terjaga lewat struktur dan tipografi, bukan warna acak.

Aturan keras: tidak ada gradien biru-ungu generik (R-01). Satu gradien hanya dipakai sebagai aksen latar header halaman utama dengan alasan hierarki.

## Tipografi
- Arab: **Amiri Quran** (google_fonts). Alasan: rasm Utsmani yang rapi, dirancang khusus untuk teks Quran, terbaca di ukuran besar maupun kecil.
- Latin/UI: **system font stack** Flutter default. Alasan: tidak menambah unduhan font, konsisten dengan platform, dan cukup untuk teks Indonesia.
- Mode Lansia menaikkan skala teks 1,35x secara global.

## Motif identitas
Garis lengkung "mihrab" sederhana di bagian atas halaman utama (satu lengkungan, bukan pola berulang). Alasan: satu gestur yang mengingatkan pada arsitektur masjid, mudah dikenali, tidak mengganggu isi.

## Elemen baru (iterasi 2026-10-17)
- **Pola bintang delapan** (`lib/core/dekorasi.dart`, CustomPainter, tanpa aset gambar): kisi geometri Islami yang digambar samar sebagai latar kepala halaman dan onboarding. Alasan: motif identitas yang khas "masjid/mushaf", dipakai hanya sebagai aksen latar (bukan dekorasi acak).
- **KepalaBeranda**: kepala beranda berpola dengan emblem mihrab + sapaan + tanggal. Alasan: satu titik fokus hangat per layar (Part 3), menggantikan AppBar polos + teks sapaan yang terpisah.
- **Kartu hero "Terakhir dibaca"** berwarna primer penuh dengan tombol putih. Alasan: hierarki, menandai aksi utama "lanjutkan ngaji" sebagai satu-satunya elemen berwarna kuat di beranda.
- **MedaliNomor segi delapan** di daftar surah. Alasan: bentuk geometris khas ornamen Islam sebagai penanda identitas, tanpa menambah warna baru.
- **PembatasOrnamen** (garis, belah ketupat emas, garis): pengganti Divider polos di kepala surah, halaman Iqro, dan mushaf. Alasan: nuansa mushaf cetak di area sakral.
- **BingkaiMushaf** (bingkai ganda zamrud + emas tipis) untuk mode Mushaf. Alasan: memberi "ruang hormat" di sekeliling teks suci dan memisahkan hierarki bacaan dari kontrol UI.
- **Mode Mushaf**: toggle "Per Ayat / Mushaf" (SegmentedButton) di AppBar halaman baca; teks Arab mengalir utuh dengan penanda nomor ayat Arab dalam lingkaran; tanpa latin/terjemahan; tajwid, font, dan audio full surah tetap jalan; pilihan diingat di `qb_read_mode` (ikut sync cloud via `tampilan.modeBaca`).
- **Dial kompas kiblat** bergaya instrumen (tick tiap 15 derajat, huruf U/T/S/B, U merah mengikuti konvensi). Alasan: membantu membaca sudut kiblat dengan presisi.
- **Cincin skor** di hasil challenge, **bilah progres** di hijaiyah/iqro/kisah (data nyata dari penyimpanan lokal). Alasan: umpan balik kemajuan yang jujur, bukan angka hiasan.
- **Drop cap** paragraf pembuka kisah nabi. Alasan: sentuhan sastra agar halaman kisah terasa seperti buku cerita.
- **Kartu mode onboarding** memakai warna identitas tiap mode (lansia: zamrud tua, normal: zamrud, anak: toska ceria). Alasan: pratinjau karakter tiap mode sebelum dipilih.

## Larangan copy (R-02, R-15, R-16)
Tidak ada em dash. CTA spesifik: "Mulai Ngaji", "Lanjut ke Ayat", "Dengarkan", bukan "Get Started".
Tidak ada klaim palsu (R-36): tidak ada angka statistik pengguna, tidak ada testimoni.
