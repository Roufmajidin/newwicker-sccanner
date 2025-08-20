import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:newwicker/helpers/notif.dart';
import 'package:newwicker/provider/buyer_provider.dart';
import 'package:newwicker/provider/cart_provider.dart';
import 'package:newwicker/provider/product_provider.dart';
import 'package:newwicker/views/dashboard_view.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      ); // aman, pakai default icon launcher

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  try {
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final folderPath = response.payload;
        if (folderPath != null) {
          final uri = Uri.file(folderPath);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        }
      },
    );
  } catch (e) {
    // kalau gagal init, app tetap jalan
    debugPrint("Notifikasi gagal init: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProductProvider()..loadProducts(),
        ),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => BuyerProvider()..fetchBuyers()),
      ],
      child: MaterialApp(
        navigatorObservers: [routeObserver],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.amber,
            primary: Colors.black,
            secondary: Colors.amber,
            background: const Color(0xfff9f9f9),
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: DashboardView(),
      ),
    ),
  );
}
