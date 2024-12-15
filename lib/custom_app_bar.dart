import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFA8BBA6), // Muted Sage Green color
      actions: [
        IconButton(
          icon: const Icon(Icons.home, color: Colors.black), // White icon color
          onPressed: () {
            Navigator.pushNamed(context, '/home');
          },
        ),
        IconButton(
          icon: const Icon(Icons.list, color: Colors.black),
          onPressed: () {
            Navigator.pushNamed(context, '/view-purchases');
          },
        ),
        IconButton(
          icon: const Icon(Icons.list_alt, color: Colors.black),
          onPressed: () {
            Navigator.pushNamed(context, '/view-sales');
          },
        ),
        IconButton(
          icon: const Icon(Icons.view_list, color: Colors.black),
          onPressed: () {
            Navigator.pushNamed(context, '/view-inventory');
          },
        ),
        IconButton(
          icon: const Icon(Icons.bar_chart, color: Colors.black),
          onPressed: () {
            Navigator.pushNamed(context, '/visualize-purchase');
          },
        ),
        IconButton(
          icon: const Icon(Icons.show_chart, color: Colors.black),
          onPressed: () {
            Navigator.pushNamed(context, '/visualize-sales');
          },
        ),
        IconButton(
          icon: const Icon(Icons.insights, color: Colors.black),
          onPressed: () {
            Navigator.pushNamed(context, '/visualize-inventory');
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}