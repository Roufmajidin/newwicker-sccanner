import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';
import 'package:intl/intl.dart';
import 'package:newwicker/helpers/image_from_external.dart';
import 'package:newwicker/helpers/notif.dart';
import 'package:newwicker/helpers/save_excel.dart';
import 'package:newwicker/models/products.dart';
import 'package:newwicker/provider/cart_provider.dart';
import 'package:newwicker/provider/product_provider.dart';
import 'package:newwicker/views/dashboard_view.dart';
import 'package:newwicker/views/databases/stactic_db.dart';
import 'package:newwicker/views/edit.dart';
import 'package:newwicker/views/qr_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart'
    as xlsioo
    show HAlignType, LineStyle, Range, VAlignType, Workbook, Worksheet;

class SalesView extends StatefulWidget {
  const SalesView({super.key});

  @override
  State<SalesView> createState() => _SalesViewState();
}

class _SalesViewState extends State<SalesView> {
  List<Map<String, dynamic>> buyers = [];
  Map<int, List<Map<String, dynamic>>> buyerCarts = {};
  bool isLoading = true;
  bool isLoadingunduh = false;
  Set<int> loadingBuyers = {};
  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    // 🔹 ambil semua buyers dari DB
    buyers = await _getBuyers();

    // 🔹 ambil carts untuk setiap buyer sekali saja
    for (var buyer in buyers) {
      final carts = await _getCartsForBuyer(buyer['id'], context);
      buyerCarts[buyer['id'] as int] = carts;
      await ImageHelper.preloadImages(carts);
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<List<Map<String, dynamic>>> _getBuyers() async {
    final db = await DBHelper.instance.database;
    final buyers = await db.query('buyer', orderBy: 'id ASC');
    return buyers;
  }

  Future<List<Map<String, dynamic>>> _getCartsForBuyer(
    int buyerId,
    BuildContext context,
  ) async {
    final db = await DBHelper.instance.database;

    // ambil data cart dari sqlite
    final carts = await db.query(
      'cart',
      where: 'buyer_id = ? AND status IS NOT NULL',
      whereArgs: [buyerId],
      orderBy: 'id ASC',
    );

    // ambil data produk (dari provider)
    final prod = Provider.of<ProductProvider>(context, listen: false);

    // gabungkan data cart + produk
    final merged =
        carts.map((cart) {
          final product = prod.allProducts.firstWhere(
            (p) => p.articleCode == cart['article_code'],
            orElse: () => Product.empty(),
          );

          return {
            ...cart,
            ...product.toMap(), // ✅ sekarang bisa digabung
          };
        }).toList();
    return merged;
  }

  Future<void> downloadExcel(int buyerId, List<String> data, carts) async {
    setState(() {
      isLoadingunduh = true; // mulai loading
      loadingBuyers.add(buyerId); // tandai buyer ini loading
    });

    try {
      await createExcelHeaderFromRow12(data, carts);
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        isLoadingunduh = false; // selesai loading
        loadingBuyers.remove(buyerId); // selesai, hapus dari loading
      });
    }
  }

  Future<Uint8List?> convertWebpToJpg(String webpPath) async {
    final bytes = await File(webpPath).readAsBytes();
    final result = await FlutterImageCompress.compressWithList(
      bytes,
      format: CompressFormat.jpeg,
      quality: 100,
    );
    return result;
  }

  Future<void> createExcelHeaderFromRow12(
    List<String> data,
    List<Map<String, dynamic>> carts,
  ) async {
    // 1. Minta permission storage (Android)
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) return;
      }
    }

    // 2. Buat workbook & worksheet
    final workbook = xlsioo.Workbook();
    final sheet = workbook.worksheets[0];
    final headerLabels = [
      "Order No",
      "Company Name",
      "Country",
      "Shipment Date",
      "Packing",
      "Contact Person",
    ];

    for (int i = 0; i < headerLabels.length; i++) {
      int row = 5 + i; // mulai baris 5

      // Merge kolom A–B untuk label
      sheet.getRangeByIndex(row, 1, row, 2).merge();
      sheet.getRangeByIndex(row, 1).setText(headerLabels[i]);

      // Merge kolom C–D untuk value
      sheet.getRangeByIndex(row, 3, row, 4).merge();
      sheet.getRangeByIndex(row, 3).setText(data.length > i ? data[i] : '');

      // Styling label
      final labelRange = sheet.getRangeByIndex(row, 1, row, 2);
      labelRange.cellStyle.bold = true;
      labelRange.cellStyle.hAlign = xlsioo.HAlignType.left;

      // Styling value
      final valueRange = sheet.getRangeByIndex(row, 3, row, 4);
      valueRange.cellStyle.hAlign = xlsioo.HAlignType.left;
    }
    sheet.getRangeByIndex(7, 16).setText('');

    // Styling (opsional)
    final xlsioo.Range finishingRange = sheet.getRangeByIndex(7, 15, 7, 16);
    finishingRange.cellStyle.bold = true;
    finishingRange.cellStyle.hAlign = xlsioo.HAlignType.left;
    finishingRange.cellStyle.vAlign = xlsioo.VAlignType.center;
    finishingRange.cellStyle.fontName = 'Arial';
    // 3. Set row height untuk header
    sheet.getRangeByIndex(12, 1, 12, 22).rowHeight = 20; // baris 12

    // 4. Header utama (baris 12)
    sheet.getRangeByIndex(12, 1).setText('No');
    sheet.getRangeByIndex(12, 2).setText('Photo');
    sheet.getRangeByIndex(12, 3).setText('Description');
    sheet.getRangeByIndex(12, 4).setText('Article Nr.');
    sheet.getRangeByIndex(12, 5).setText('Remark');
    sheet.getRangeByIndex(12, 6).setText('Cushion');
    sheet.getRangeByIndex(12, 7).setText('Glass');
    sheet.getRangeByIndex(12, 8).setText('Item Dimention');
    sheet.getRangeByIndex(12, 11).setText('Packing Dimention');
    sheet.getRangeByIndex(12, 14).setText('Composition');
    sheet.getRangeByIndex(12, 15).setText('Finishing');
    sheet.getRangeByIndex(12, 16).setText('QTY');
    sheet.getRangeByIndex(12, 17).setText('CBM');
    sheet.getRangeByIndex(12, 18).setText('Item Price');
    sheet.getRangeByIndex(12, 19).setText('Cushion Price');
    sheet.getRangeByIndex(12, 20).setText('FOB JAKARTA IN USD');
    sheet.getRangeByIndex(12, 21).setText('Total CBM');
    sheet.getRangeByIndex(12, 22).setText('Value in USD');

    // 5. Merge header dan sub-header (baris 12-13)
    sheet.getRangeByIndex(12, 1, 13, 1).merge();
    sheet.getRangeByIndex(12, 2, 13, 2).merge();
    sheet.getRangeByIndex(12, 3, 13, 3).merge();
    sheet.getRangeByIndex(12, 4, 13, 4).merge();
    sheet.getRangeByIndex(12, 5, 13, 5).merge();
    sheet.getRangeByIndex(12, 6, 13, 6).merge();
    sheet.getRangeByIndex(12, 7, 13, 7).merge();
    sheet.getRangeByIndex(12, 8, 12, 10).merge(); // Item Dimention
    sheet.getRangeByIndex(12, 11, 12, 13).merge(); // Packing Dimention
    sheet.getRangeByIndex(12, 14, 13, 14).merge();
    sheet.getRangeByIndex(12, 15, 13, 15).merge();
    sheet.getRangeByIndex(12, 16, 13, 16).merge();
    sheet.getRangeByIndex(12, 17, 13, 17).merge();
    sheet.getRangeByIndex(12, 18, 13, 18).merge();
    sheet.getRangeByIndex(12, 19, 13, 19).merge();
    sheet.getRangeByIndex(12, 20, 13, 20).merge();
    sheet.getRangeByIndex(12, 21, 13, 21).merge();
    sheet.getRangeByIndex(12, 22, 13, 22).merge();

    // 6. Sub-header W/D/H (baris 13)
    sheet.getRangeByIndex(13, 8).setText('W');
    sheet.getRangeByIndex(13, 9).setText('D');
    sheet.getRangeByIndex(13, 10).setText('H');
    sheet.getRangeByIndex(13, 11).setText('W');
    sheet.getRangeByIndex(13, 12).setText('D');
    sheet.getRangeByIndex(13, 13).setText('H');

    // 7. Styling header
    final xlsioo.Range headerRange = sheet.getRangeByIndex(12, 1, 13, 22);
    headerRange.cellStyle.bold = false;
    headerRange.cellStyle.hAlign = xlsioo.HAlignType.center;
    headerRange.cellStyle.vAlign = xlsioo.VAlignType.center;
    sheet.getRangeByIndex(12, 20).cellStyle.backColor = '#FFFF00';
    headerRange.cellStyle.fontName = 'Arial'; // <-- atur font ke Arial
    headerRange.cellStyle.wrapText = true; // <-- ini untuk wrap text

    headerRange.cellStyle.borders.all.lineStyle = xlsioo.LineStyle.thin;

    // 8. Set column width sesuai permintaan
    // Mengatur lebar kolom
    sheet.getRangeByIndex(1, 1).columnWidth = 5; // No
    sheet.getRangeByIndex(1, 2).columnWidth = 34.43; // Photo
    sheet.getRangeByIndex(1, 3).columnWidth = 16.71; // Description
    sheet.getRangeByIndex(1, 4).columnWidth = 16; // Article Nr
    sheet.getRangeByIndex(1, 5).columnWidth = 14.43; // Remark
    sheet.getRangeByIndex(1, 6).columnWidth = 8.71; // Cushion
    sheet.getRangeByIndex(1, 7).columnWidth = 8.71; // Glass
    sheet.getRangeByIndex(1, 8).columnWidth = 6.86; // Item Dimension W
    sheet.getRangeByIndex(1, 9).columnWidth = 6.86; // Item Dimension D
    sheet.getRangeByIndex(1, 10).columnWidth = 6.86; // Item Dimension H
    sheet.getRangeByIndex(1, 11).columnWidth = 6.86; // Packing Dimension W
    sheet.getRangeByIndex(1, 12).columnWidth = 6.86; // Packing Dimension D
    sheet.getRangeByIndex(1, 13).columnWidth = 6.86; // Packing Dimension H
    sheet.getRangeByIndex(1, 14).columnWidth = 18; // Composition
    sheet.getRangeByIndex(1, 15).columnWidth = 18; // Finishing
    sheet.getRangeByIndex(1, 16).columnWidth = 4.57; // QTY
    sheet.getRangeByIndex(1, 17).columnWidth = 7.71; // CBM
    sheet.getRangeByIndex(1, 18).columnWidth = 7.71; // Item Price
    sheet.getRangeByIndex(1, 19).columnWidth = 7.71; // Cushion Price
    sheet.getRangeByIndex(1, 20).columnWidth = 13.71; // FOB JAKARTA IN USD
    sheet.getRangeByIndex(1, 21).columnWidth = 6.86; // Total CBM
    sheet.getRangeByIndex(1, 22).columnWidth = 12.71; // Value in USD

    // 9. Isi data di baris 14

    // Baris data (misal mulai baris 14)
    for (int i = 0; i < carts.length; i++) {
      sheet.getRangeByIndex(14 + i, 1, 14 + i, 22).rowHeight = 129;

      final cart = carts[i];
      final row = 14 + i;

      String? photoPath;
      if (File(
        '/storage/emulated/0/DCIM/Pictures/Newwicker/${cart['photo']}.jpg',
      ).existsSync()) {
        photoPath =
            '/storage/emulated/0/DCIM/Pictures/Newwicker/${cart['photo']}.jpg';
      } else if (File(
        '/storage/emulated/0/DCIM/Pictures/Newwicker/${cart['photo']}.webp',
      ).existsSync()) {
        photoPath =
            '/storage/emulated/0/DCIM/Pictures/Newwicker/${cart['photo']}.webp';
      }

      final jpgBytes = await convertWebpToJpg(
        '/storage/emulated/0/DCIM/Pictures/Newwicker/${cart['photo']}.webp',
      );
      if (jpgBytes != null) {
        sheet.pictures.addStream(row, 2, jpgBytes)
          ..width = 140
          ..height = 140;
      }

      // sheet.getRangeByIndex(14 + i, 1).setText(cart['nr'].toString());
      // sheet.getRangeByIndex(14 + i, 2).setText(cart['photo'] ?? '');
      // contoh pemakaian

      setCellText(sheet, 14 + i, 3, cart['name']); // kolom C

      setCellText(sheet, 14 + i, 4, cart['article_code']);
      setCellText(sheet, 14 + i, 5, cart['remark']);
      setCellText(sheet, 14 + i, 6, '');
      setCellText(sheet, 14 + i, 7, '');

      // Item Dimension W/D/H
      setCellText(sheet, 14 + i, 8, cart['item_dimension']?.w?.toString());
      setCellText(sheet, 14 + i, 9, cart['item_dimension']?.d?.toString());
      setCellText(sheet, 14 + i, 10, cart['item_dimension']?.h?.toString());

      // Packing Dimension W/D/H
      setCellText(sheet, 14 + i, 11, cart['packing_dimension']?.w?.toString());
      setCellText(sheet, 14 + i, 12, cart['packing_dimension']?.d?.toString());
      setCellText(sheet, 14 + i, 13, cart['packing_dimension']?.h?.toString());

      setCellText(sheet, 14 + i, 14, cart['composition']);
      setCellText(sheet, 14 + i, 15, cart['finishing']);
      setCellText(sheet, 14 + i, 16, cart['qty']?.toString());
      setCellText(sheet, 14 + i, 17, cart['cbm']?.toStringAsFixed(3));
      setCellText(sheet, 14 + i, 18, cart['fob_jakarta_in_usd']?.toString());
      setCellText(sheet, 14 + i, 19, cart['cushion_price']?.toString());
      setCellText(sheet, 14 + i, 20, cart['fob_jakarta_in_usd']?.toString());
      setCellText(sheet, 14 + i, 21, cart['total_cbm']?.toStringAsFixed(3));
      setCellText(sheet, 14 + i, 22, cart['value_in_usd']?.toString());
    }

    // 10. Simpan file di folder Download
    final bytes = workbook.saveAsStream();
    workbook.dispose();
    final now = DateTime.now();
    final formatted = DateFormat('HHmmss_ddMMyyyy').format(now);
    final fileName = 'PFI - $formatted.xlsx';
    final filePath = '/storage/emulated/0/Download/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    // Tampilkan notifikasi dengan nama file yang baru
    await showDownloadNotification(fileName);
  }

  void setCellText(
    xlsioo.Worksheet sheet,
    int row,
    int col,
    String? text, {
    int? mergeToCol,
  }) {
    final range = sheet.getRangeByIndex(
      row,
      col,
      row, // baris akhir = baris yang sama
      mergeToCol ?? col,
    );
    range.setText(text ?? '');
    range.cellStyle.wrapText = true;
    range.cellStyle.hAlign = xlsioo.HAlignType.center;
    range.cellStyle.vAlign = xlsioo.VAlignType.center;
  }

  void addImageToWorksheet(
    xlsioo.Worksheet sheet,
    String imagePath,
    int row,
    int col,
  ) {
    final File imageFile = File(imagePath);
    if (imageFile.existsSync()) {
      final List<int> imageBytes = imageFile.readAsBytesSync();
      sheet.pictures.addStream(row, col, imageBytes);
    }
  }

Future<void> showDownloadProgress(String fileName) async {
  for (int i = 0; i <= 100; i += 20) {
    await Future.delayed(const Duration(milliseconds: 500));

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'download_channel',
          'Downloads',
          channelDescription: 'Sedang mengunduh...',
          importance: Importance.max,
          priority: Priority.high,
          showProgress: true,
          maxProgress: 100,
          progress: i,
          
        );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Mengunduh...',
      '$fileName ($i%)',
      platformDetails,
    );
  }

  // Setelah selesai
  const AndroidNotificationDetails doneDetails =
      AndroidNotificationDetails(
        'download_channel',
        'Downloads',
        channelDescription: 'Download selesai',
        importance: Importance.max,
        priority: Priority.high,
      );

  const NotificationDetails donePlatformDetails = NotificationDetails(
    android: doneDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    0,
    'Download selesai',
    'File $fileName berhasil diunduh',
    donePlatformDetails,
  );
}
  // Print JSON ke console
  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final leftWidth = 100.0; // left column width
    final rightWidth = screenWidth - leftWidth; // sisa untuk kolom kanan

    return Scaffold(
      appBar: AppBar(
        title: const Text("Draft Sales"),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => DashboardView()),
                  (route) => false,
                );
              },

              child: Icon(Icons.home_filled),
            ),
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: buyers.length,
                itemBuilder: (context, index) {
                  final buyer = buyers[index];
                  final carts = buyerCarts[buyer['id']] ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // ==== Buyer Info ====
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Label
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text("Company"),
                                Text("Country"),
                                Text("Packing"),
                                Text("Contact person"),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Nilai buyer
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ": ${buyer['company_name'] ?? '-'}",
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  ": ${buyer['country'] ?? '-'}",
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  ": ${buyer['packing'] ?? '-'}",
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  ": ${buyer['contact_person'] ?? '-'}",
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Tombol aksi
                          Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    await cartProvider.deletebuyerwt(
                                      buyer['id'],
                                    );
                                    await _loadAllData(); // refresh data
                                  },
                                  icon: Icon(Icons.delete),
                                ),
                                const SizedBox(height: 8),
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) =>
                                                EditCart(buyerId: buyer['id']),
                                      ),
                                    ).then(
                                      (_) => _loadAllData(),
                                    ); // refresh setelah edit
                                  },
                                  icon: Icon(Icons.edit_document),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    FocusScope.of(context).unfocus();
                                    final cp = buyer['order_no'].toString();
                                    final nm = buyer['company_name'];
                                    final ctn = buyer['country'];
                                    final ct = buyer['contact_person'];
                                    final pack = buyer['packing'];

                                    List<String> data = [
                                      "#${cp.toString()}",
                                      nm,
                                      ctn,
                                      pack,
                                      ct,
                                    ];

                                    // Panggil fungsi generate Excel
                                    await downloadExcel(
                                      buyer['id'],
                                      data,
                                      carts,
                                    );
                                    print(carts);
                                  },
                                  icon:
                                      loadingBuyers.contains(buyer['id'])
                                          ? Text("Mengunduh..")
                                          : Icon(Icons.download),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // ==== Horizontal Table ====
                      SizedBox(
                        height:
                            carts.isEmpty
                                ? 50
                                : (carts.length * 80.0).clamp(120.0, 400.0),
                        child:
                            carts.isEmpty
                                ? const Center(child: Text("No orders"))
                                : Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: HorizontalDataTable(
                                    leftHandSideColumnWidth: leftWidth,
                                    rightHandSideColumnWidth: 900,
                                    isFixedHeader: true,
                                    headerWidgets: _buildHeader(),
                                    leftSideItemBuilder:
                                        (context, idx) => InkWell(
                                          onTap: () {
                                            FocusScope.of(context).unfocus();

                                            showDialog(
                                              context: context,
                                              builder:
                                                  (context) => Dialog(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            16.0,
                                                          ),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            'Pilih aksi untuk  ID: ${carts[idx]['id']}',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),

                                                          const SizedBox(
                                                            height: 20,
                                                          ),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .end,
                                                            children: [
                                                              TextButton(
                                                                onPressed: () {
                                                                  FocusScope.of(
                                                                    context,
                                                                  ).unfocus();

                                                                  Navigator.pop(
                                                                    context,
                                                                  ); // tutup dialog
                                                                  // aksi Ubah
                                                                  Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder:
                                                                          (
                                                                            _,
                                                                          ) => QRViewExample(
                                                                            cartId:
                                                                                carts[idx]['id'],
                                                                          ),
                                                                    ),
                                                                  );
                                                                },
                                                                child:
                                                                    const Text(
                                                                      'Replace',
                                                                    ),
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              TextButton(
                                                                onPressed: () async {
                                                                  FocusScope.of(
                                                                    context,
                                                                  ).unfocus();

                                                                  await cartProvider
                                                                      .removeFromCartBuyer(
                                                                        carts[idx]['id'],
                                                                        buyer['id'],
                                                                      );
                                                                  Navigator.pop(
                                                                    context,
                                                                  ); // tutup dialog
                                                                  // aksi Hapus
                                                                  print(
                                                                    'Hapus item ID: ${carts[idx]['id']}',
                                                                  );
                                                                },
                                                                child: const Text(
                                                                  'Hapus',
                                                                  style: TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .red,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                            );
                                          },
                                          child: _buildLeftColumn(carts[idx]),
                                        ),
                                    rightSideItemBuilder:
                                        (context, idx) =>
                                            _buildRightColumn(carts[idx]),
                                    itemCount: carts.length,
                                    rowSeparatorWidget: const Divider(
                                      color: Colors.black38,
                                      height: 0.7,
                                    ),
                                  ),
                                ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
    );
  }

  // ===== Horizontal Table =====
  List<Widget> _buildHeader() {
    return [
      _headerCell("Image", 100),
      _headerCell("Article Nr", 100),
      _headerCell("Desc", 100),
      _headerCell("item D", 150),
      _headerCell("packing D", 150),
      _headerCell("cbm", 120),
      _headerCell("value in usd", 120),
      _headerCell("Remark", 100),
    ];
  }

  // ===== Right Column per cart =====
  Widget _buildRightColumn(Map<String, dynamic> cart) {
    final itemDim = cart['item_dimension'];
    final packingDim = cart['packing_dimension'];

    return Row(
      children: [
        _cell(cart['article_code'] ?? '-', 100),
        _cell(cart['name'] ?? '-', 100),
        _cell(itemDim is Dimension ? itemDim.formatted() : '-', 150),
        _cell(packingDim is Dimension ? packingDim.formatted() : '-', 150),
        _cell(
          cart['cbm'] != null
              ? (cart['cbm'] as double).toStringAsFixed(2)
              : '-',
          120,
        ),
        _cell(cart['value_in_usd'].toString() ?? '-', 120),
        _cell(cart['remark'] ?? '-', 100),
      ],
    );
  }

  Widget _headerCell(String label, double width) {
    return Container(
      width: width,
      height: 40,
      color: Colors.blueAccent,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLeftColumn(Map<String, dynamic> cart) {
    final articleCode = cart['article_code']?.toString() ?? '';
    final cachedImage =
        ImageHelper.cachedImages[articleCode]; // ambil dari cache

    return _cellWidget(
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 80,
          height: 80,
          child:
              cachedImage != null
                  ? Image.memory(
                    cachedImage,
                    fit: BoxFit.cover,
                    cacheWidth: 120, // ini akan decode image ke ukuran kecil
                    cacheHeight: 120,
                  )
                  : Container(
                    color: Colors.grey.shade200, // fallback placeholder
                    child: const Icon(Icons.image_not_supported, size: 50),
                  ),
        ),
      ),
      120,
    );
  }

  // Ubah _cell supaya bisa menerima widget
  Widget _cellWidget(Widget child, double width) {
    return Container(
      width: width,
      height: 80,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: child,
    );
  }

  Widget _cell(String text, double width) {
    return Container(
      width: width,
      height: 80,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(text),
    );
  }
}
