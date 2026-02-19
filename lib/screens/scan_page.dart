import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'from_peminjaman_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with TickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController();

  late AnimationController _laserController;
  late Animation<double> _laserAnimation;
  late AnimationController _rotationController;

  bool sudahScan = false;

  @override
  void initState() {
    super.initState();

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0, end: 240).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _laserController.dispose();
    _rotationController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanSize = 260.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          /// BACKGROUND IMAGE
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset('assets/Subtract.png', fit: BoxFit.cover),
            ),
          ),

          /// HEADER BIRU
          Container(
            height: 220,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF001FBF),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(55),
                bottomRight: Radius.circular(55),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -60,
                  right: -40,
                  child: RotationTransition(
                    turns: _rotationController,
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(45),
                      ),
                    ),
                  ),
                ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text(
                      "SCAN QR TPS",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// SCANNER AREA
          Align(
            alignment: Alignment.center,
            child: Container(
              width: scanSize,
              height: scanSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  /// CAMERA
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: MobileScanner(
                      controller: controller,
                      onDetect: (capture) {
                        if (sudahScan) return;

                        final barcode = capture.barcodes.first.rawValue;

                        if (barcode != null && barcode.isNotEmpty) {
                          sudahScan = true;
                          controller.stop();

                          /// TETAP POP KE TPSCAN
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  FormPeminjamanPage(kodeBarcode: barcode),
                            ),
                          );
                        }
                        ;
                      },
                    ),
                  ),

                  /// BORDER FRAME
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  /// LASER
                  AnimatedBuilder(
                    animation: _laserAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: _laserAnimation.value,
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.8),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          /// BOTTOM SHEET
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(35, 35, 35, 50),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(45),
                  topRight: Radius.circular(45),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 30,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Pindai Kode QR TPS',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Arahkan kamera ke QR Code',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () => controller.toggleTorch(),
                      icon: const Icon(Icons.flash_on, color: Colors.amber),
                      label: const Text(
                        "Nyalakan Flash",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5E7EB),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// BACK BUTTON
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
