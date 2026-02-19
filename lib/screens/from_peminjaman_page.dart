import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FormPeminjamanPage extends StatefulWidget {
  final String kodeBarcode;
  const FormPeminjamanPage({super.key, required this.kodeBarcode});

  @override
  State<FormPeminjamanPage> createState() => _FormPeminjamanPageState();
}

class _FormPeminjamanPageState extends State<FormPeminjamanPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  // Controller Input
  final namaController = TextEditingController();
  final jumlahController = TextEditingController();

  // Controller Readonly
  final kodeController = TextEditingController();
  final stokController = TextEditingController();
  final hargaController = TextEditingController();

  // Animasi & Data
  late AnimationController _rotationController;
  List<dynamic> daftarBarang = [];
  Map<String, dynamic>? barangTerpilih;
  int? selectedIdBarang;
  bool loading = false;
  bool loadingBarang = true;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    ambilBarang();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    namaController.dispose();
    jumlahController.dispose();
    kodeController.dispose();
    stokController.dispose();
    hargaController.dispose();
    super.dispose();
  }

  /// ================= AMBIL DATA BARANG & AUTO-FILL =================
  Future<void> ambilBarang() async {
    try {
      final response = await http.get(
        Uri.parse("http://76.4.3.3/apkscan/api/barang_user.php"),
      );

      print("STATUS: ${response.statusCode}"); 
      print("BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == true) {
          setState(() {
            daftarBarang = data['data'];
            loadingBarang = false;
          });
        } else {
          setState(() => loadingBarang = false);
        }
      } else {
        setState(() => loadingBarang = false);
      }
    } catch (e) {
      print("ERROR AMBIL BARANG: $e");

      // WAJIB agar tidak loading terus
      setState(() => loadingBarang = false);
    }
  }

  /// ================= SIMPAN KE BACKEND =================
  Future<void> simpanTransaksi() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedIdBarang == null) {
      print("ID BARANG NULL");
      return;
    }

    setState(() => loading = true);

    try {
      final response = await http.post(
        Uri.parse("http://76.4.3.3/apkscan/api/transaksi.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "id_barang": selectedIdBarang,
          "nama_pengambil": namaController.text.trim(),
          "jumlah": int.tryParse(jumlahController.text) ?? 0,
        }),
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      final result = jsonDecode(response.body);

      if (result['status'] == true) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result['message'])));
      }
    } catch (e) {
      print("ERROR SIMPAN: $e");
    }

    setState(() => loading = false);
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Berhasil",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("Transaksi berhasil disimpan."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Tutup dialog dulu
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: loadingBarang
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // 1. HEADER BIRU MODERN
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF001FBF),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -50,
                        right: -40,
                        child: RotationTransition(
                          turns: _rotationController,
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Form Pengambilan",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "MANAJEMEN LOGISTIK BPS",
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 10,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. BODY FORM MELAYANG
                Padding(
                  padding: const EdgeInsets.only(top: 130),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel("Pilih Jenis ATK"),

                            DropdownSearch<int>(
                              items: daftarBarang
                                  .map<int>(
                                    (b) => int.parse(b['id_barang'].toString()),
                                  )
                                  .toList(),

                              selectedItem: selectedIdBarang,

                              itemAsString: (id) {
                                final barang = daftarBarang.firstWhere(
                                  (b) =>
                                      int.parse(b['id_barang'].toString()) ==
                                      id,
                                );
                                return "${barang['kode_barang']} - ${barang['nama_barang']}";
                              },

                              popupProps: const PopupProps.menu(
                                showSearchBox: true,
                              ),

                              dropdownDecoratorProps: DropDownDecoratorProps(
                                dropdownSearchDecoration: _inputDecoration(
                                  "Pilih Barang",
                                ),
                              ),

                              onChanged: (value) {
                                if (value == null) return;

                                final selected = daftarBarang.firstWhere(
                                  (b) =>
                                      int.parse(b['id_barang'].toString()) ==
                                      value,
                                );

                                setState(() {
                                  selectedIdBarang = value;
                                  barangTerpilih = selected;

                                  kodeController.text =
                                      selected['kode_barang'] ?? '';
                                  stokController.text = selected['stok']
                                      .toString();
                                  hargaController.text =
                                      "Rp ${selected['harga']}";
                                });
                              },

                              validator: (v) =>
                                  v == null ? "Pilih barang" : null,
                            ),

                            const SizedBox(height: 20),

                            // PANEL DETAIL (READONLY)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F7FF),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFDBEAFE),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildReadonlyField(
                                          "Kode",
                                          kodeController,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _buildReadonlyField(
                                          "Stok",
                                          stokController,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),
                            _buildLabel("Nama Pengambil"),
                            TextFormField(
                              controller: namaController,
                              decoration: _inputDecoration(
                                "Masukkan nama lengkap",
                              ),
                              validator: (v) =>
                                  v!.isEmpty ? "Wajib diisi" : null,
                            ),

                            const SizedBox(height: 16),
                            _buildLabel("Jumlah Pengambilan"),
                            TextFormField(
                              controller: jumlahController,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration("0"),
                              validator: (v) {
                                if (v!.isEmpty) return "Wajib diisi";
                                final j = int.tryParse(v);
                                if (j == null) return "Harus angka";

                                if (barangTerpilih != null &&
                                    j >
                                        int.parse(
                                          barangTerpilih!['stok'].toString(),
                                        )) {
                                  return "Stok tidak cukup";
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: loading ? null : simpanTransaksi,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF001FBF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: loading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text(
                                        "Simpan Transaksi",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // --- WIDGET HELPERS ---
  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13,
        color: Colors.black87,
      ),
    ),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF001FBF), width: 1.5),
    ),
  );

  Widget _buildReadonlyField(String label, TextEditingController controller) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            readOnly: true,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFE3EEFF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      );
}
