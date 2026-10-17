// GENERATED dari cdn-images/kisah/manifest.json — jangan edit manual.
// Satu konstanta base URL: pindah ke Cloudflare tinggal ganti ini.
const kisahCdnBaseUrl =
    'https://cdn.jsdelivr.net/gh/faruqeclypst/My-Qur-an@main/cdn-images/kisah/';

/// Nama nabi -> daftar nama file ilustrasi (simbolik, tanpa figur nabi).
const Map<String, List<String>> kisahGambar = {
  'Adam': ['nabi_01_adam_a.jpg', 'nabi_01_adam_b.jpg', 'nabi_01_adam_c.jpg'],
  'Idris': ['nabi_02_idris_a.jpg', 'nabi_02_idris_b.jpg'],
  'Nuh': ['nabi_03_nuh_a.jpg', 'nabi_03_nuh_b.jpg', 'nabi_03_nuh_c.jpg'],
  'Hud': ['nabi_04_hud_a.jpg', 'nabi_04_hud_b.jpg'],
  'Shalih': ['nabi_05_shalih_a.jpg', 'nabi_05_shalih_b.jpg'],
  'Ibrahim': ['nabi_06_ibrahim_a.jpg', 'nabi_06_ibrahim_b.jpg', 'nabi_06_ibrahim_c.jpg'],
  'Luth': ['nabi_07_luth_a.jpg', 'nabi_07_luth_b.jpg'],
  'Ismail': ['nabi_08_ismail_a.jpg', 'nabi_08_ismail_b.jpg'],
  'Ishaq': ['nabi_09_ishaq_a.jpg', 'nabi_09_ishaq_b.jpg'],
  'Yaqub': ['nabi_10_yaqub_a.jpg', 'nabi_10_yaqub_b.jpg'],
  'Yusuf': ['nabi_11_yusuf_a.jpg', 'nabi_11_yusuf_b.jpg'],
  'Ayub': ['nabi_12_ayub_a.jpg', 'nabi_12_ayub_b.jpg'],
  'Syuaib': ['nabi_13_syuaib_a.jpg', 'nabi_13_syuaib_b.jpg'],
  'Musa': ['nabi_14_musa_a.jpg', 'nabi_14_musa_b.jpg', 'nabi_14_musa_c.jpg'],
  'Harun': ['nabi_15_harun_a.jpg', 'nabi_15_harun_b.jpg'],
  'Zulkifli': ['nabi_16_zulkifli_a.jpg', 'nabi_16_zulkifli_b.jpg'],
  'Dawud': ['nabi_17_dawud_a.jpg', 'nabi_17_dawud_b.jpg'],
  'Sulaiman': ['nabi_18_sulaiman_a.jpg', 'nabi_18_sulaiman_b.jpg'],
  'Ilyas': ['nabi_19_ilyas_a.jpg', 'nabi_19_ilyas_b.jpg'],
  'Ilyasa': ['nabi_20_ilyasa_a.jpg', 'nabi_20_ilyasa_b.jpg'],
  'Yunus': ['nabi_21_yunus_a.jpg', 'nabi_21_yunus_b.jpg'],
  'Zakaria': ['nabi_22_zakaria_a.jpg', 'nabi_22_zakaria_b.jpg'],
  'Yahya': ['nabi_23_yahya_a.jpg', 'nabi_23_yahya_b.jpg'],
  'Isa': ['nabi_24_isa_a.jpg', 'nabi_24_isa_b.jpg', 'nabi_24_isa_c.jpg'],
  'Muhammad': ['nabi_25_muhammad_a.jpg', 'nabi_25_muhammad_b.jpg', 'nabi_25_muhammad_c.jpg'],
};

/// URL lengkap ilustrasi ke-[index] untuk nabi [namaNabi].
/// Indeks melingkar: episode ke-n memakai gambar ke-(n % jumlah).
String kisahGambarUrl(String namaNabi, int index) {
  final daftar = kisahGambar[namaNabi];
  if (daftar == null || daftar.isEmpty) return '';
  return '$kisahCdnBaseUrl${daftar[index % daftar.length]}';
}
