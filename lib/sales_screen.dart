import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';  // For Uint8List (used to store image bytes)
import 'dart:convert';

import '../custom_app_bar.dart'; // Import the reusable AppBar

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  _SalesScreenState createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _billingController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  Uint8List? _imageBytes;  // Store image as bytes (Uint8List)
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to upload an image to Flask backend and get extracted data
  Future<void> _extractTextFromImage(Uint8List imageBytes) async {
    final uri = Uri.parse('http://192.168.29.35:5000/upload');  // Flask server endpoint
    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: 'image.jpg'));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);

      // Directly send the extracted data to Firestore
      _addDataToFirestoreFromImage(data);  // Send extracted data to Firestore
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error extracting text from image")),
      );
    }
  }

  void _addDataToFirestoreFromImage(Map<String, dynamic> data) {
    final products = data['products'] as List<dynamic>? ?? [];  // Get list of products (ensure it's a List)

    // Loop through each product and upload it to Firestore
    for (var product in products) {
      final salesData = {
        'Date': data['date'] ?? '',
        'Customer Name': data['customer_name'] ?? '',
        'Billing Address': data['billing_address'] ?? '',
        'Product Name': product['product_name'] ?? '',
        'Rate': _parseToDouble(product['rate']) ?? 0.0,  // Ensure rate is a number
        'Quantity': _parseToInt(product['quantity']) ?? 0,  // Ensure quantity is a number
        'Amount': _parseToDouble(product['amount']) ?? 0.0,  // Ensure amount is a number
        'Image/Document': '',  // Image field can remain empty or you can add a URL if you upload the image
      };

      // Add each product to Firestore purchase collection
      _firestore.collection('sales').add(salesData).then((value) {
        // After successfully adding the purchase data, check inventory
        _checkAndUpdateInventory(product);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sale Submitted Successfully")),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $error")),
        );
      });
    }

    // After adding all products, clear the form
    _clearForm();
  }

  void _checkAndUpdateInventory(Map<String, dynamic> product) async {
    final productName = product['product_name'] ?? '';
    final  rate = _parseToDouble(product['rate']) ?? 0;
    final quantitySold = _parseToInt(product['quantity']) ?? 0;
    final amount = _parseToDouble(product['amount']) ?? 0;

    // Query the inventory by both Product Name and Rate
    final inventoryQuery = await _firestore
        .collection('inventory')
        .where('Product Name', isEqualTo: productName)
        .where('Rate', isEqualTo: rate)
        .get();

    try {
      if (inventoryQuery.docs.isNotEmpty) {
        // If the product with the same rate exists in inventory, update it
        final inventoryDoc = inventoryQuery.docs.first;
        final inventoryData = inventoryDoc.data();
        final currentQuantity = inventoryData?['Quantity'] ?? 0;
        final newQuantity = currentQuantity - quantitySold;
        final newAmount = rate * newQuantity;

        if (newQuantity >= 0) {
          // If there is enough stock, update the inventory
          await inventoryDoc.reference.update({
            'Quantity': newQuantity,
            'Amount': newAmount,
          });

          print("Inventory updated successfully");
        } else {
          // If not enough stock is available, show an error
          print("Not enough stock for sale");
        }
      } else {
        // If no matching product with the same rate exists in inventory, log or handle accordingly
        print("Product with the specified rate doesn't exist in the inventory.");
      }
    } catch (error) {
      print("Error updating inventory: $error");
    }
  }


  // Helper functions to ensure proper type conversion
  double? _parseToDouble(dynamic value) {
    if (value is String) {
      return double.tryParse(value);
    }
    return value is double ? value : null;
  }

  int? _parseToInt(dynamic value) {
    if (value is String) {
      return int.tryParse(value);
    }
    return value is int ? value : null;
  }

  // Function to add manually entered data to Firestore
  void _addDataToFirestore() {
    // Ensure Rate, Quantity, and Amount are numbers
    final rate = _parseToDouble(_rateController.text) ?? 0.0;
    final quantity = _parseToInt(_quantityController.text) ?? 0;
    final amount = _parseToDouble(_amountController.text) ?? 0.0;

    final salesData = {
      'Date': _dateController.text,
      'Customer Name': _customerController.text,
      'Billing Address': _billingController.text,
      'Product Name': _productController.text,
      'Rate': rate, // Ensure rate is a number
      'Quantity': quantity, // Ensure quantity is a number
      'Amount': amount, // Ensure amount is a number
      'Image/Document': '', // If no image is uploaded, leave it empty
    };

    // Add purchase data to Firestore
    _firestore.collection('sales').add(salesData).then((value) {
      // After successfully adding the purchase data, check inventory
      _checkAndUpdateInventory({
        'product_name': _productController.text,
        'quantity': quantity,
        'rate': rate,
        'amount': amount,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sale Submitted Successfully")),
      );
      _clearForm();  // Clear the form after submission
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $error")),
      );
    });
  }

  // Function to clear all form fields
  void _clearForm() {
    _dateController.clear();
    _customerController.clear();
    _billingController.clear();
    _productController.clear();
    _rateController.clear();
    _quantityController.clear();
    _amountController.clear();
    setState(() {
      _imageBytes = null;  // Reset the image
    });
  }

  // Function to pick an image from the camera (works for web as well)
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();  // Read image as bytes
      setState(() {
        _imageBytes = bytes;  // Store image as bytes (Uint8List)
      });
    }
  }

  // Function to pick an image from the gallery
  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();  // Read image as bytes
      setState(() {
        _imageBytes = bytes;  // Store image as bytes (Uint8List)
      });
    }
  }

  // Function to calculate the amount
  void _calculateAmount() {
    final rate = _parseToDouble(_rateController.text) ?? 0.0;
    final quantity = _parseToInt(_quantityController.text) ?? 0;
    final amount = rate * quantity;

    _amountController.text = amount.toStringAsFixed(2);  // Update amount with 2 decimal places
  }

  @override
  void initState() {
    super.initState();

    // Add listeners to rate and quantity controllers
    _rateController.addListener(_calculateAmount);
    _quantityController.addListener(_calculateAmount);
  }

  @override
  void dispose() {
    // Remove listeners when the widget is disposed
    _rateController.removeListener(_calculateAmount);
    _quantityController.removeListener(_calculateAmount);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: SingleChildScrollView(  // Wrap the body in SingleChildScrollView to make it scrollable
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "Add Sale",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Date Field
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(labelText: 'Date'),
            ),
            // Customer Name Field
            TextField(
              controller: _customerController,
              decoration: const InputDecoration(labelText: 'Customer Name'),
            ),
            // Billing Address Field
            TextField(
              controller: _billingController,
              decoration: const InputDecoration(labelText: 'Billing Address'),
            ),
            // Product Name Field
            TextField(
              controller: _productController,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            // Rate Field
            TextField(
              controller: _rateController,
              decoration: const InputDecoration(labelText: 'Rate'),
              keyboardType: TextInputType.number,
            ),
            // Quantity Field
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            // Amount Field (automatically calculated)
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              readOnly: true,  // Amount is calculated, so this is read-only
            ),
            const SizedBox(height: 20),
            // Capture Image Button
            Center(
              child: SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA8BBA6), // Light Sea Green color
                    foregroundColor: Colors.black, // Black text color
                  ),
                  child: const Text("Capture Image"),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Upload Image from Gallery Button
            Center(
              child: SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: _pickImageFromGallery,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA8BBA6), // Light Sea Green color
                    foregroundColor: Colors.black, // Black text color
                  ),
                  child: const Text("Upload Image from Gallery"),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Display selected image if any
            if (_imageBytes != null)
              Center(
                child: Image.memory(
                  _imageBytes!, // Display image from Uint8List
                  height: 150, // Adjust size as needed
                ),
              ),
            const SizedBox(height: 20),
            // Add Sale with Image Button
            Center(
              child: SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: () {
                    if (_imageBytes != null) {
                      _extractTextFromImage(_imageBytes!); // Extract data from image
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please capture an image")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA8BBA6), // Light Sea Green color
                    foregroundColor: Colors.black, // Black text color
                  ),
                  child: const Text('Add Sale with Image'),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Add Sale Without Image Button
            Center(
              child: SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: _addDataToFirestore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA8BBA6), // Light Sea Green color
                    foregroundColor: Colors.black, // Black text color
                  ),
                  child: const Text('Add Sale Without Image'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
