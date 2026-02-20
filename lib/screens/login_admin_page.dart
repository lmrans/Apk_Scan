import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'admin_dashboard_page.dart'; // Pastikan path ini benar

class LoginAdminPage extends StatefulWidget {
  const LoginAdminPage({super.key});

  @override
  State<LoginAdminPage> createState() => _LoginAdminPageState();
}

class _LoginAdminPageState extends State<LoginAdminPage> {
  bool _isObscured = true;
  bool _isLoading = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // LOGIKA BACKEND DARI KODE SEBELUMNYA
  Future<void> _loginAdmin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar("Username dan password wajib diisi");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Gunakan 10.0.2.2 untuk emulator atau IP lokal komputer Anda
      final response = await http.post(
        Uri.parse("http://76.4.3.3/apkscan/api/login_admin.php"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (data['status'] == true) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDashboardPage(adminName: username),
          ),
        );
      } else {
        _showSnackBar(data['message'] ?? 'Login gagal');
      }
    } catch (e) {
      _showSnackBar("Gagal terhubung ke server: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Image.asset(
            'assets/backroung.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            color: const Color.fromARGB(255, 0, 31, 170).withOpacity(0.6),
            colorBlendMode: BlendMode.darken,
            errorBuilder: (context, e, s) => Container(color: Colors.black87),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/logo_bps.png',
                      width: 70,
                      errorBuilder: (context, e, s) => const Icon(
                        Icons.analytics,
                        size: 70,
                        color: Color(0xFF001FBF),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Selamat Datang",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const Text(
                      "ADMINISTRATOR DASHBOARD",
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Username Field
                    _buildField("Username", Icons.person_outline, false, _usernameController),
                    const SizedBox(height: 15),
                    
                    // Password Field
                    _buildField("Password", Icons.lock_outline, true, _passwordController),
                    
                    const SizedBox(height: 30),
                    
                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _loginAdmin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D4ED8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          disabledBackgroundColor: Colors.grey,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "MASUK SEKARANG",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, IconData icon, bool isPass, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 13, 
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPass ? _isObscured : false,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            suffixIcon: isPass
                ? IconButton(
                    icon: Icon(
                      _isObscured ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: () => setState(() => _isObscured = !_isObscured),
                  )
                : null,
            hintText: label == "Username" ? "Masukkan ID Admin" : "••••••••",
            filled: true,
            fillColor: Colors.grey[50],
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 2.0),
            ),
          ),
        ),
      ],
    );
  }
}