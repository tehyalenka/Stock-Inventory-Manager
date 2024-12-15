import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'custom_app_bar.dart'; // Import your custom app bar

// Create a GlobalKey to manage Scaffold state
//final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //key: _scaffoldKey, // Pass the GlobalKey here
      //appBar: CustomAppBar(scaffoldKey: _scaffoldKey), // Pass the key to your custom app bar
      appBar: CustomAppBar(),
      drawer: const NavigationDrawer(), // Custom navigation drawer
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Your home screen content goes here
            const SizedBox(height: 20),
            const Text(
              'Welcome to the Stock Inventory Manager!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Stay in control of your inventory with ease!',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            // Quick access action buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          context,
          Icons.shopping_cart,
          'Add Purchase',
          '/purchase',
        ),
        _buildActionButton(
          context,
          Icons.attach_money,
          'Add Sale',
          '/sales',
        ),
        _buildActionButton(
          context,
          Icons.inventory,
          'Add Inventory',
          '/inventory',
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, String route) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, size: 40, color: Colors.black),
          onPressed: () {
            Navigator.pushNamed(context, route);
          },
        ),
        Text(
          label,
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ],
    );
  }
}

// Navigation Drawer with menu options
class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({super.key});

  // Sign out logic
  Future<void> _signOut(BuildContext context) async {
    try {
      // Sign out the user from Firebase
      await FirebaseAuth.instance.signOut();

      // Navigate to the sign-in screen and remove all previous screens
      Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false);
    } catch (e) {
      // Handle any errors that may occur during sign-out
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFFA8BBA6), // Light sea green color for the drawer
        child: Column(
          children: [
            // Add padding at the top of the drawer to push content below the app bar
            Padding(
              padding: const EdgeInsets.only(top: 60.0), // Adjust the top padding as needed
              child: Column(
                children: [
                  // List items of the Drawer (starts below the app bar)
                  ListTile(
                    leading: const Icon(Icons.home, color: Colors.black),
                    title: const Text('Home', style: TextStyle(color: Colors.black)),
                    onTap: () {
                      Navigator.pushNamed(context, '/home');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.shopping_cart, color: Colors.black),
                    title: const Text('Add Purchase', style: TextStyle(color: Colors.black)),
                    onTap: () {
                      Navigator.pushNamed(context, '/purchase');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.attach_money, color: Colors.black),
                    title: const Text('Add Sale', style: TextStyle(color: Colors.black)),
                    onTap: () {
                      Navigator.pushNamed(context, '/sales');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.inventory, color: Colors.black),
                    title: const Text('Add Inventory', style: TextStyle(color: Colors.black)),
                    onTap: () {
                      Navigator.pushNamed(context, '/inventory');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.list, color: Colors.black),
                    title: const Text('View Purchase', style: TextStyle(color: Colors.black)),
                    onTap: () {
                      Navigator.pushNamed(context, '/view-purchases');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.list_alt, color: Colors.black),
                    title: const Text('View Sales', style: TextStyle(color: Colors.black)),
                    onTap: () {
                      Navigator.pushNamed(context, '/view-sales');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.view_list, color: Colors.black),
                    title: const Text('View Inventory', style: TextStyle(color: Colors.black)),
                    onTap: () {
                      Navigator.pushNamed(context, '/view-inventory');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bar_chart, color: Colors.black),
                    title: const Text('Visualize Purchase ', style: TextStyle(color: Colors.black)),
                    onTap: () {
                      Navigator.pushNamed(context, '/visualize-purchase');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.show_chart, color: Colors.black),
                    title: const Text('Visualize Sales ', style: TextStyle(color: Colors.black)),
                    onTap: () {
                      Navigator.pushNamed(context, '/visualize-sales');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.insights, color: Colors.black),
                    title: const Text('Visualize Inventory ', style: TextStyle(color: Colors.black)),
                    onTap: () {
                      Navigator.pushNamed(context, '/visualize-inventory');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.help, color: Colors.black),
                    title: const Text('Ask a Query', style: TextStyle(color: Colors.black)),
                    onTap: () {
                      Navigator.pushNamed(context, '/ask-query');
                    },
                  ),
                  // Sign Out item at the bottom of the drawer
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.black),
                    title: const Text('Sign Out', style: TextStyle(color: Colors.black)),
                    onTap: () {
                      _signOut(context); // Call sign-out function
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}