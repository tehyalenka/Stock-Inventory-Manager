import 'package:flutter/material.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFA8BBA6), // Light sea green color
      ),
      body: Column(
        children: [
          // Top Light Sea Green Container
          Container(
            color: const Color(0xFFA8BBA6), // Light sea green color
            height: 20, // Adjust height as needed
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Welcome to Stock Inventory App!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),

                  // Sign In Button
                  Center(
                    child: SizedBox(
                      width: 250, // Constrain button width
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to the SignInScreen
                          Navigator.pushReplacementNamed(context, '/sign-in');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA8BBA6), // Light sea green color
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(color: Colors.black), // Black text color
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sign Up Button
                  Center(
                    child: SizedBox(
                      width: 250, // Constrain button width
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate to the SignUpScreen
                          Navigator.pushReplacementNamed(context, '/sign-up');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA8BBA6), // Light sea green color
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(color: Colors.black), // Black text color
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom Light Sea Green Container
          Container(
            color: const Color(0xFFA8BBA6), // Light sea green color
            height: 70, // Adjust height as needed
          ),
        ],
      ),
    );
  }
}
