import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:newwicker/main.dart';
import 'package:newwicker/models/products.dart';
import 'package:newwicker/provider/product_provider.dart';
import 'package:newwicker/views/details.dart';
import 'package:provider/provider.dart';

class ScannerView extends StatefulWidget {
  final Product? product; // null artinya mode scan

  const ScannerView({super.key, this.product});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView>
    with WidgetsBindingObserver, RouteAware {
  late final MobileScannerController _controller;
  String? _scanMessage;
  bool _cameraActive = true; // manual flag

  bool _isInitializing = false;
  Key _scannerKey = UniqueKey();
  final TextEditingController _articleNrController = TextEditingController();
  late ProductProvider _productProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = MobileScannerController(
      autoStart: widget.product == null, // autoStart hanya di mode scan
      formats: [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      detectionTimeoutMs: 500,
    );
  }

  @override
  void didPopNext() {
    debugPrint("Kembali ke ScannerView - start kamera lagi");
    _startCamera(); // restart kamera jika user kembali dari halaman detail
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.unsubscribe(this); 
    _productProvider = context.read<ProductProvider>();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    _controller.dispose();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _productProvider.clearScan();
    });

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_cameraActive) {
      _controller.start();
      _cameraActive = true;
    } else if ((state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused) &&
        _cameraActive) {
      _controller.stop();
      _cameraActive = false;
    }
  }

  void _onBarcodeDetect(BarcodeCapture capture) {
    final String? code = capture.barcodes.first.rawValue;
    if (code != null) {
      final provider = context.read<ProductProvider>();
      provider.findProductByNr(code);
      _controller.stop();
      _cameraActive = false;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailView(product: provider.foundProduct),
        ),
      ).then((_) {
        _clearScanner();
      });
      ;
    }
  }

  Future<void> _clearScanner() async {
    context.read<ProductProvider>().clearScan();

    setState(() {
      _scanMessage = null;
      _scannerKey = UniqueKey();
      _cameraActive = false;
    });

    await _startCamera();
  }

  Future<void> _resetScanner() async {
    await _controller.stop(); 
    await Future.delayed(
      const Duration(milliseconds: 200),
    ); 

    // ignore: use_build_context_synchronously
    context.read<ProductProvider>().clearScan();
    setState(() {
      _scanMessage = null;
      _scannerKey = UniqueKey(); 
    });
    await _startCamera();
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
      backgroundColor: const Color(0xfff9f9f9),

      appBar: AppBar(
        leading: const BackButton(),
        title: Text(product != null ? 'Detail Produk' : 'Scan QR'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _resetScanner,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 32),

          physics: const AlwaysScrollableScrollPhysics(),

          children: [
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TypeAheadField<Product>(
                      suggestionsCallback: (pattern) {
                        final provider = Provider.of<ProductProvider>(
                          context,
                          listen: false,
                        );
                        return provider.allProducts
                            .where(
                              (product) =>
                                  product.nr.toLowerCase().contains(
                                    pattern.toLowerCase(),
                                  ) ||
                                  product.name.toLowerCase().contains(
                                    pattern.toLowerCase(),
                                  ),
                            )
                            .take(5)
                            .toList();
                      },
                      builder: (context, controller, focusNode) {
                        return SizedBox(
                          height: 40,
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: 'Article NR',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        );
                      },
                      itemBuilder: (context, Product suggestion) {
                        return ListTile(
                          title: Text(suggestion.nr),
                          subtitle: Text(suggestion.name),
                        );
                      },
                      onSelected: (Product suggestion) async {
                        final provider = Provider.of<ProductProvider>(
                          context,
                          listen: false,
                        );
                        provider.foundProduct = suggestion;
                        _articleNrController.text = suggestion.nr;
                        // _showProductBottomSheet(context, suggestion);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ProductDetailView(product: suggestion),
                          ),
                        );
                      },
                      emptyBuilder:
                          (context) => const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Tidak ada produk ditemukan.'),
                          ),
                      loadingBuilder:
                          (context) => const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Scan QR Code",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Letak QR Code dalam kotak",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        alignment: Alignment.center,

                        children: [
                          SizedBox(
                            width: 280,
                            height: 280,
                            child: Image.asset(
                              fit: BoxFit.cover,
                              'assets/images/qr.png',
                              // width: 220,
                              // height: 220,
                            ),
                          ),
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: MobileScanner(
                              key: _scannerKey,
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
    );
  }
}
