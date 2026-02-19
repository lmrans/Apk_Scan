import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminApi {
  static const baseUrl = "http://76.4.3.3/apkscan/api";

  static Future<List<Map<String, dynamic>>> getBarang() async {
    final res = await http.get(Uri.parse("$baseUrl/barang.php"));
    final json = jsonDecode(res.body);

    if (json['status'] == true) {
      return List<Map<String, dynamic>>.from(json['data']);
    }
    return [];
  }

}
