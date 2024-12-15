import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Global form key to manage validation
  bool _isLoading = false;  // Track loading state

  // Validate email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email address';
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zAZ0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Validate password
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    return null;
  }

  // Sign In logic
  Future<void> _signIn() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Form validation passed
      setState(() {
        _isLoading = true;  // Show loading spinner
      });

      try {
        // Sign in the user with email and password
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        // Navigate to home screen after successful sign in
        Navigator.pushReplacementNamed(context, '/home');
      } on FirebaseAuthException catch (e) {
        // Show error message if sign-in fails
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      } finally {
        setState(() {
          _isLoading = false;  // Reset loading state
        });
      }
    } else {
      // If validation fails, show a message or other indication
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fix the errors')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        backgroundColor: Color(0xFFA8BBA6)),
      body: Column(
        children: [
          // Top light green container
          Container(
            color: Colors.white,
            height: 30,
            width: double.infinity,
            child: const Center(
              child: Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          // Main form content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey, // Wrap your form with a GlobalKey<FormState>
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Email TextField with validation
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                      ),
                      validator: _validateEmail, // Use validator for the email field
                    ),
                    const SizedBox(height: 10),
                    // Password TextField with validation
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                      ),
                      validator: _validatePassword, // Use validator for the password field
                    ),
                    const SizedBox(height: 20),
                    // Loading state check
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFA8BBA6),  // Light Green button color
                              foregroundColor: Colors.black,  // White text color
                            ),
                            child: const Text('Sign In'),
                          ),
                    const SizedBox(height: 20),
                    // Option to switch to sign-up page
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/sign-up');  // Adjust route name if necessary
                      },
                      child: const Text('Don\'t have an account? Sign Up'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom light green container
          Container(
            color: Color(0xFFA8BBA6),
            height: 40,
            width: double.infinity,
            child: const Center(
              child: Text(
                'Powered by Stock Inventory Manager',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
