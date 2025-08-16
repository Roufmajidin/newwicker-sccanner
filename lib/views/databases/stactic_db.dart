// stactic_db.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  // Singleton
  DBHelper._privateConstructor();
  static final DBHelper instance = DBHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'my_o.db');

    return await openDatabase(path, version: 2, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE buyer (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        buyer_id INTEGER,
        order_no INTEGER,
        company_name TEXT NOT NULL,
        country TEXT,
        shipment_date TEXT,
        packing TEXT,
        contact_person TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        article_code TEXT NOT NULL,
        created_at TEXT NOT NULL,
        buyer_id INTEGER,
        status TEXT NULL,
        remark TEXT NULL
      )
    ''');
  }

  Future<int> insertCart(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('cart', data);
  }

  Future<List<Map<String, dynamic>>> getCart() async {
    final db = await database;
    return await db.query('cart', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getDarftCart() async {
    final db = await database;
    return await db.query(
      'cart',
      where: 'buyer_id = ?',
      whereArgs: [1],
      orderBy: 'id ASC',
    );
  }

  // EDIT
  Future<void> assignOrUpdateCartBuyer(
    List<String> articleCodes, {
    required int orderNo,
    required String companyName,
    String? country,
    String? shipmentDate,
    String? packing,
    String? contactPerson,
    String? createdAt,
    Map<String, String>? remarks,
    int? buyerId, // jika null atau 1 → buat buyer baru
  }) async {
    final db = await database;

    int targetBuyerId;

    if (buyerId != null && buyerId > 1) {
      // UPDATE existing buyer
      targetBuyerId = buyerId;
      await db.update(
        'buyer',
        {
          'order_no': orderNo,
          'company_name': companyName,
          'country': country,
          'shipment_date': shipmentDate,
          'packing': packing,
          'contact_person': contactPerson,
        },
        where: 'id = ?',
        whereArgs: [buyerId],
      );
    } else {
      // CREATE new buyer
      targetBuyerId = await db.insert('buyer', {
        'order_no': orderNo,
        'company_name': companyName,
        'country': country,
        'shipment_date': shipmentDate,
        'packing': packing,
        'contact_person': contactPerson,
      });
    }

    // Ambil cart yang dicentang
    final carts = await db.query(
      'cart',
      where:
          'article_code IN (${List.filled(articleCodes.length, '?').join(',')}) AND buyer_id = ?',
      whereArgs: [...articleCodes, buyerId],
    );

    final batch = db.batch();
    for (var cart in carts) {
      final code = cart['article_code'] as String;
      final newRemark = remarks?[code] ?? cart['remark'] ?? '';

      batch.update(
        'cart',
        {
          'buyer_id': targetBuyerId,
          'created_at': createdAt ?? DateTime.now().toIso8601String(),
          'status': 'true',
          'remark': newRemark,
        },
        where: 'id = ?',
        whereArgs: [cart['id']],
      );
    }

    await batch.commit(noResult: true);
  }

  // Hapus cart berdasarkan ID
  Future<int> deleteCart(int id) async {
    final db = await database;
    return await db.delete('cart', where: 'id = ?', whereArgs: [id]);
  }

  // hapus buyer
  Future<void> deleteBuyerWithCart(int buyerId) async {
    final db = await database;
    final batch = db.batch();

    batch.delete('cart', where: 'buyer_id = ?', whereArgs: [buyerId]);

    batch.delete('buyer', where: 'id = ?', whereArgs: [buyerId]);

    await batch.commit(noResult: true);
  }

  Future<int> insertBuyer({
    required int orderNo,
    required String companyName,
    String? country,
    String? shipmentDate,
    String? packing,
    String? contactPerson,
    String? buyerId,
  }) async {
    final db = await database;

    return await db.insert('buyer', {
      'order_no': orderNo,
      'buyer_id': buyerId,
      'company_name': companyName,
      'country': country,
      'shipment_date': shipmentDate,
      'packing': packing,
      'contact_person': contactPerson,
    });
  }

  Future<void> assignCartToBuyer(
    List<String> articleCodes, {
    required int orderNo,
    required String companyName,
    String? country,
    String? shipmentDate,
    String? packing,
    String? contactPerson,
    String? createdAt,
    Map<String, String>? remarks,
    int? buyerId,
  }) async {
    if (articleCodes.isEmpty) return; // mencegah IN () error

    final db = await database;
    final targetBuyerId = buyerId ?? DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      // Insert atau update buyer
      await txn.insert('buyer', {
        'id': targetBuyerId,
        'order_no': orderNo,
        'company_name': companyName,
        'country': country,
        'shipment_date': shipmentDate,
        'packing': packing,
        'contact_person': contactPerson,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // Ambil cart draft yang dicentang
      final carts = await txn.query(
        'cart',
        where:
            'article_code IN (${List.filled(articleCodes.length, '?').join(',')}) AND (buyer_id = 1 OR buyer_id IS NULL)',
        whereArgs: articleCodes,
      );

      if (carts.isEmpty) return;

      // Update cart secara batch
      final batch = txn.batch();
      for (var cart in carts) {
        final code = cart['article_code']?.toString().trim() ?? '';
        batch.update(
          'cart',
          {
            'buyer_id': targetBuyerId,
            'created_at': createdAt ?? DateTime.now().toIso8601String(),
            'status': 'true',
            'remark': remarks?[code] ?? cart['remark'] ?? '',
          },
          where: 'id = ?',
          whereArgs: [cart['id']],
        );
      }

      await batch.commit(noResult: true);
    });
  }
}
