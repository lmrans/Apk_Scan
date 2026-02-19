import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const baseUrl = "http://127.0.0.1/atk_api/api";

  // ================= KATEGORI =================
  static Future<List<dynamic>> getKategori() async {
    final res = await http.get(
      Uri.parse("$baseUrl/kategori.php"),
    );

    if (res.statusCode != 200) {
      throw Exception("Gagal mengambil kategori");
    }

    final json = jsonDecode(res.body);

    if (json['status'] != true) return [];
    return json['data'];
  }

  // ================= BARANG =================
  static Future<List<dynamic>> getBarang(int idKategori) async {
    final res = await http.get(
      Uri.parse("$baseUrl/barang.php?id_kategori=$idKategori"),
    );

    if (res.statusCode != 200) {
      throw Exception("Gagal mengambil barang");
    }

    final json = jsonDecode(res.body);

    if (json['status'] != true) return [];
    return json['data'];
  }

  // ================= TRANSAKSI USER =================
  static Future<bool> simpanTransaksi({
    required int idBarang,
    required int jumlah,
    required String nama,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/transaksi.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_barang": idBarang,
        "jumlah": jumlah,
        "nama_pengambil": nama,
      }),
    );

    if (res.statusCode != 200) return false;

    final json = jsonDecode(res.body);
    return json['status'] == true;
  }

  // ================= LOGIN ADMIN =================
  static Future<bool> loginAdmin({
    required String username,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/login_admin_page.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "password": password,
      }),
    );

    if (res.statusCode != 200) return false;

    final json = jsonDecode(res.body);
    return json['status'] == true;
  }
}
