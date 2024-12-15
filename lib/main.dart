import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart'; // Firebase options file
import 'auth_screen.dart'; // Authentication screen
import 'home_screen.dart'; // Home screen
import 'sign_in_screen.dart'; // Sign-In screen
import 'sign_up_screen.dart'; // Sign-Up screen
import 'purchase_screen.dart'; // Purchase screen
import 'sales_screen.dart'; // Sales screen
import 'inventory_screen.dart'; // Inventory screen
import 'view_purchases_screen.dart'; // View Purchases screen
import 'view_sales_screen.dart'; // View Sales screen
import 'view_inventory_screen.dart'; // View Inventory screen
import 'ask_query_screen.dart'; // Ask a query screen
import 'purchase_vis.dart';
import 'sales_vis.dart';
import 'inventory_vis.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print("Firebase Initialized Successfully");
  } catch (e) {
    print("Error initializing Firebase: $e");
  }

  // Run the app and decide initial route based on user state
  final user = FirebaseAuth.instance.currentUser;

  runApp(MyApp(initialRoute: user != null ? '/home' : '/'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({required this.initialRoute, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Inventory App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
        ),
      ),
      initialRoute: initialRoute, // Set the initial route based on user state
      routes: {
        '/': (context) => AuthScreen(),
        '/home': (context) => HomeScreen(),
        '/sign-in': (context) => SignInScreen(),
        '/sign-up': (context) => SignUpScreen(),
        '/purchase': (context) => PurchaseScreen(),
        '/sales': (context) => SalesScreen(),
        '/inventory': (context) => InventoryScreen(),
        '/view-purchases': (context) => ViewPurchasesScreen(),
        '/view-sales': (context) => ViewSalesScreen(),
        '/view-inventory': (context) => ViewInventoryScreen(),
        '/visualize-purchase': (context) => PurchaseVisualizationScreen(),
        '/visualize-sales': (context) => SalesVisualizationScreen(),
        '/visualize-inventory': (context) => InventoryVisualizationScreen(),
        '/ask-query': (context) => AskQueryScreen(),
      },
    );
  }
}
