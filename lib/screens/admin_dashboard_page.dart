import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminDashboardPage extends StatefulWidget {
  final String adminName;

  const AdminDashboardPage({super.key, this.adminName = "Admin"});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  String? _selectedSatuan;

  final String baseUrl = "http://76.4.3.3/apkscan/api";
  // jika pakai HP asli ganti dengan IP komputer kamu
  Map<String, String> get headers => {
    "Content-Type": "application/json",
    "Role": "admin", // WAJIB ada sesuai script PHP kamu
  };
  List<Map<String, dynamic>> _allInventory = [];
  List<Map<String, dynamic>> _foundInventory = [];

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _kodeController = TextEditingController();
  final TextEditingController _stokController = TextEditingController();
  final TextEditingController _updateStokController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchBarang(); // 🔥 ambil data dari database
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  // FETCH DATA BARANG
  Future<void> fetchBarang() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/barang_admin.php"),
        headers: headers,
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        List<Map<String, dynamic>> barang = List<Map<String, dynamic>>.from(
          data['data'].map(
            (item) => {
              "id_barang": item['id_barang'],
              "kode_barang": item['kode_barang'] ?? "",
              "nama_barang": item['nama_barang'] ?? "",
              "stok": int.tryParse(item['stok'].toString()) ?? 0,
              "satuan": item['satuan'] ?? "",
            },
          ),
        );

        setState(() {
          _allInventory = barang;
          _foundInventory = barang;
        });

        print("Data berhasil dimuat: ${_allInventory.length} barang");
      } else {
        print("Gagal ambil data: ${data['message']}");
      }
    } catch (e) {
      print("Error Koneksi: $e");
    }
  }

  // TAMBAH BARANG KE DATABASE
  Future<void> _addNewItem() async {
    String inputKode = _kodeController.text.trim().toUpperCase();
    String nama = _namaController.text.trim();
    String stok = _stokController.text.trim();
    String? satuan = _selectedSatuan; // dari dropdown

    // ================= VALIDASI =================
    if (inputKode.isEmpty || nama.isEmpty || stok.isEmpty || satuan == null) {
      _showSnackBar("Semua field wajib diisi!");
      return;
    }

    if (!inputKode.startsWith("ATK-")) {
      _showSnackBar("Kode harus diawali ATK-");
      return;
    }

    int? stokInt = int.tryParse(stok);
    if (stokInt == null) {
      _showSnackBar("Stok harus berupa angka!");
      return;
    }

    if (stokInt < 0) {
      _showSnackBar("Stok tidak boleh negatif!");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/barang_admin.php"),
        headers: headers, // pastikan ada Role: admin
        body: jsonEncode({
          "role": "admin", // WAJIB ADA
          "kode_barang": inputKode,
          "nama_barang": nama,
          "stok": stokInt,
          "satuan": satuan,
        }),
      );

      print("Status: ${response.statusCode}");
      print("Response: ${response.body}");

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['status'] == true) {
          await fetchBarang();

          _namaController.clear();
          _kodeController.clear();
          _stokController.clear();
          _selectedSatuan = null;

          if (mounted) Navigator.pop(context);

          _showSnackBar("Barang berhasil ditambahkan!");
        } else {
          _showSnackBar(result['message'] ?? "Gagal menambahkan barang");
        }
      } else {
        _showSnackBar("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
      _showSnackBar("Terjadi kesalahan koneksi!");
    }
  }

  // UPDATE STOK DI DATABASE
  Future<void> _updateExistingStok(String kodeBarang) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/barang_admin.php"),
        headers: headers,
        body: jsonEncode({
          "kode_barang": kodeBarang,
          "stok": int.parse(_updateStokController.text),
        }),
      );

      final result = jsonDecode(response.body);

      if (result['status'] == true) {
        await fetchBarang();
        if (mounted) Navigator.pop(context); // tutup bottomsheet
        _showSnackBar("Stok berhasil diperbarui!");
      }{
        _showSnackBar(result['message']);
      }
    } catch (e) {
      _showSnackBar("Gagal terhubung ke server");
    }
  }

  Future<void> _deleteBarang(int id) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/barang_admin.php"),
        headers: headers,
        body: jsonEncode({"role": "admin", "id_barang": id}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result['status'] == true) {
          await fetchBarang(); // refresh list
          _showSnackBar("Barang berhasil dihapus");
        } else {
          _showSnackBar(result['message'] ?? "Gagal menghapus barang");
        }
      } else {
        _showSnackBar("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error delete: $e");
      _showSnackBar("Terjadi kesalahan koneksi!");
    }
  }

  // SEARCH
  void _runFilter(String enteredKeyword) {
    List<Map<String, dynamic>> results = [];

    if (enteredKeyword.isEmpty) {
      results = _allInventory;
    } else {
      results = _allInventory.where((item) {
        // Kita ambil value dengan key yang sesuai dengan mapping di fetchBarang
        final String nama = (item["nama_barang"] ?? "")
            .toString()
            .toLowerCase();
        final String kode = (item["kode_barang"] ?? "")
            .toString()
            .toLowerCase();
        final String search = enteredKeyword.toLowerCase();

        return nama.contains(search) || kode.contains(search);
      }).toList();
    }

    setState(() {
      _foundInventory = results;
    });

    print("Keyword: $enteredKeyword | Hasil: ${results.length} item");
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showAddProductModal() {
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 25,
            left: 25,
            right: 25,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Tambah Barang Baru",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF001FBF),
                ),
              ),
              const SizedBox(height: 20),

              // ================= KODE =================
              TextField(
                controller: _kodeController,
                onChanged: (val) {
                  setModalState(() {
                    if (!val.toUpperCase().startsWith("ATK-")) {
                      errorText = "Wajib diawali dengan 'ATK-'";
                    } else {
                      errorText = null;
                    }
                  });
                },
                decoration: InputDecoration(
                  labelText: "Kode Aset",
                  errorText: errorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ================= NAMA =================
              TextField(
                controller: _namaController,
                decoration: InputDecoration(
                  labelText: "Nama Barang",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ================= STOK =================
              TextField(
                controller: _stokController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Stok",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 15),
              // ================= SATUAN =================
              Row(
                children: [
                  // INPUT JUMLAH
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _stokController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Jumlah",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // DROPDOWN SATUAN
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: _selectedSatuan,
                      decoration: InputDecoration(
                        labelText: "Satuan",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      items:
                          [
                                "buah",
                                "pcs",
                                "pack",
                                "lusin",
                                "Rim",
                                "Box",
                                "Roll",
                                "Botol",
                                "kaleng",
                              ]
                              .map(
                                (satuan) => DropdownMenuItem(
                                  value: satuan,
                                  child: Text(satuan),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        setModalState(() {
                          _selectedSatuan = value;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // ================= BUTTON =================
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: errorText == null
                      ? () async {
                          await _addNewItem();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF001FBF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    "TAMBAHKAN",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int jumlahStokMenipis = _allInventory
        .where((item) => item['stok'] < 10)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          _buildHeader(), // Header Statis
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
              child: Column(
                children: [
                  _buildSummaryCard(
                    "Total item",
                    "${_allInventory.length} Barang",
                    Icons.inventory_2_outlined,
                    Colors.blue,
                  ),
                  const SizedBox(height: 15),
                  _buildSummaryCard(
                    "Stok Menipis",
                    "$jumlahStokMenipis Item",
                    Icons.warning_amber_rounded,
                    Colors.red,
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: _showAddProductModal,
                    child: _buildSummaryCard(
                      "Tambah Barang Baru",
                      "",
                      Icons.add_box_rounded,
                      Colors.green,
                      isAction: true,
                    ),
                  ),
                  const SizedBox(height: 15),

                  GestureDetector(
                    onTap: () async {
                      final url = Uri.parse(
                        "http://76.4.3.3/apkscan/api/export_transaksi.php",
                      );
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    child: _buildSummaryCard(
                      "Export Transaksi",
                      "export transaksi ke excel",
                      Icons.download_rounded,
                      Colors.teal,
                      isAction: true,
                    ),
                  ),

                  const SizedBox(height: 35),
                  _buildInventoryList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SEMUA UI DI BAWAH INI TIDAK DIUBAH
  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 130,
          decoration: const BoxDecoration(
            color: Color(0xFF001FBF),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(35),
              bottomRight: Radius.circular(35),
            ),
          ),
        ),
        Positioned(
          top: -50,
          right: -40,
          child: RotationTransition(
            turns: _rotationController,
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Container(
            height: 140,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildHeaderIcon(),
                const SizedBox(width: 15),
                _buildHeaderTitle(),
                _buildAdminInfo(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderIcon() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(15),
    ),
    child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 28),
  );

  Widget _buildHeaderTitle() => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text(
          "Dashboard Admin",
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
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _buildAdminInfo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.adminName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "Administrator",
              style: TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(width: 10),
        // --- POPUP MENU UNTUK LOGOUT ---
        PopupMenuButton<String>(
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          onSelected: (value) {
            if (value == 'logout') {
              Navigator.pop(context); // Kembali ke halaman Login
            }
          },
          child: const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white, size: 22),
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.redAccent),
                  SizedBox(width: 10),
                  Text("Log Out"),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInventoryList() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF001FBF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Daftar Stok Barang',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ================= TEXTFIELD PENCARIAN =================
          TextField(
            onChanged: (value) => _runFilter(value), // Memanggil fungsi filter
            decoration: InputDecoration(
              hintText: 'Cari nama atau kode barang...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 20),

          // Header Tabel
          Row(
            children: const [
              Expanded(
                flex: 2,
                child: Text(
                  'KODE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  'NAMA BARANG',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'STOK',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'AKSI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const Divider(thickness: 0.5),
          // ================= LIST DATA (HASIL FILTER) =================
          _foundInventory.isNotEmpty
              ? Column(
                  // Menggunakan data dari _foundInventory bukan _allInventory
                  children: _foundInventory
                      .map((item) => _buildTableRow(item))
                      .toList(),
                )
              : const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "Data tidak ditemukan",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> item) {
    bool isStokRendah = item['stok'] < 5;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              // UBAH DARI item['kode'] MENJADI item['kode_barang']
              item['kode_barang'] ?? "-",
              style: const TextStyle(
                color: Color(0xFF001FBF),
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // PASTIKAN KEY-NYA nama_barang
                  item['nama_barang'] ?? "Tanpa Nama",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                if (isStokRendah)
                  const Text(
                    "⚠️ Stok Menipis",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isStokRendah
                      ? const Color(0xFFFFEBEE)
                      : const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item['stok'].toString(),
                  style: TextStyle(
                    color: isStokRendah ? Colors.red : const Color(0xFF001FBF),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 32,
              child: OutlinedButton(
                onPressed: () => _showUpdateModal(item),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF001FBF), width: 1.2),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Update',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF001FBF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isAction = false,
  }) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isAction ? 17 : 12,
                fontWeight: FontWeight.bold,
                color: isAction ? Colors.black : Colors.grey,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: isAction ? 11 : 18,
                fontWeight: isAction ? FontWeight.normal : FontWeight.bold,
                color: isAction ? Colors.grey : Colors.black,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  @override
  void dispose() {
    _rotationController.dispose();
    _namaController.dispose();
    _kodeController.dispose();
    _stokController.dispose();
    _updateStokController.dispose();
    super.dispose();
  }

  void _showUpdateModal(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 25,
          left: 25,
          right: 25,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "Update Stok: ${item['nama_barang']}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            // INPUT TAMBAH STOK
            TextField(
              controller: _updateStokController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: "Masukkan Jumlah Tambahan",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // TOMBOL SIMPAN
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  await _updateExistingStok(item['kode_barang']);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001FBF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "SIMPAN",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // TOMBOL DELETE
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);

                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      title: const Text("Konfirmasi Hapus"),
                      content: Text(
                        "Yakin ingin menghapus ${item['nama_barang']}?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text("Batal"),
                        ),
                        TextButton(
                          onPressed: () async {
                            await _deleteBarang(item['id_barang']);

                            Navigator.pop(dialogContext); // tutup dialog
                            Navigator.pop(context); // tutup bottomsheet
                          },
                          child: const Text(
                            "Hapus",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "HAPUS BARANG",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
