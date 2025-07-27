import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:newwicker/provider/product_provider.dart';
import 'package:newwicker/views/details.dart';
import 'package:provider/provider.dart';

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  String? _scanMessage;
  bool _cameraActive = true; // manual flag

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = MobileScannerController(
      autoStart: true, // Kunci penting!
      formats: [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      detectionTimeoutMs: 500,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_cameraActive) {
        _controller.start();
        _cameraActive = true;
      }
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (_cameraActive) {
        _controller.stop();
        _cameraActive = false;
      }
    }
  }

  void _onBarcodeDetect(BarcodeCapture capture) {
  final String? code = capture.barcodes.first.rawValue;
  if (code != null) {
    final provider = context.read<ProductProvider>();
    provider.findProductByNr(code);
    _controller.stop();
    _cameraActive = false;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailView(product: provider.foundProduct!),
      ),
    );
  }
}


  bool _isInitializing = false;
  Key _scannerKey = UniqueKey();

Future<void> _resetScanner() async {
  context.read<ProductProvider>().clearScan();

  setState(() {
    _scanMessage = null;
    _scannerKey = UniqueKey(); // reset kamera widget
  });

  await Future.delayed(const Duration(milliseconds: 300)); // beri waktu rebuild
  await _startCamera(); // pastikan kamera aktif lagi
}
Future<void> _startCamera() async {
  if (_cameraActive || _isInitializing) return;
  _isInitializing = true;

  try {
    await _controller.start();
    _cameraActive = true;
  } catch (e) {
    debugPrint('Start camera error: $e');
  } finally {
    _isInitializing = false;
  }
}

  @override
  Widget build(BuildContext context) {
    final product = context.watch<ProductProvider>().foundProduct;

    return Scaffold(
      appBar: AppBar(title: const Text('Offline QR Scanner')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child:
                product == null
                    ? MobileScanner(
                      key: _scannerKey, // ini penting untuk reset widget
                      controller: _controller,
                      onDetect: _onBarcodeDetect,
                      errorBuilder: (context, error) {
                        return Center(
                          child: Text(
                            'Error kamera: ${error.errorCode.name}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      },
                    )
                    : const Center(child: Text('Scan berhasil.')),
          ),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child:
                  product == null
                      ? const Text(
                        'Silakan scan QR code untuk melihat data produk.',
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _scanMessage ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text('Nama Produk: ${product.name}'),
                          Text('Kategori: ${product.categories}'),
                          Text(
                            'Ukuran: ${product.itemDimension.w} x ${product.itemDimension.d} x ${product.itemDimension.h} cm',
                          ),
                          Text('Finishing: ${product.finishing}'),
                          Text('CBM: ${product.cbm}'),
                          const Divider(),
                          Text(
                            'Harga Rangka: Rp ${product.remarks.rangka.harga}',
                          ),
                          Text(
                            'Harga Anyam: Rp ${product.remarks.anyam.harga}',
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.qr_code_scanner),
                              label: const Text("Scan Ulang"),
                              onPressed: _resetScanner,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
