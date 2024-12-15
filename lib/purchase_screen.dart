import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';  // For Uint8List (used to store image bytes)
import 'dart:convert';

import '../custom_app_bar.dart'; // Import the reusable AppBar

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  _PurchaseScreenState createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _merchantController = TextEditingController();
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
        const SnackBar(content: Text("Error extracting text from image")),
      );
    }
  }

  // Function to add data from extracted image data to Firestore
  void _addDataToFirestoreFromImage(Map<String, dynamic> data) {
    final products = data['products'] as List<dynamic>? ?? [];  // Get list of products (ensure it's a List)

    for (var product in products) {
      final purchaseData = {
        'Date': data['date'] ?? '',
        'Merchant Name': data['merchant_name'] ?? '',
        'Billing Address': data['billing_address'] ?? '',
        'Product Name': product['product_name'] ?? '',
        'Rate': _parseToInt(product['rate']) ?? 0,
        'Quantity': _parseToInt(product['quantity']) ?? 0,
        'Amount': _parseToInt(product['amount']) ?? 0,
        'Image/Document': '',
      };

      _firestore.collection('purchase').add(purchaseData).then((value) {
        _checkAndUpdateInventory(product);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Purchase Submitted Successfully")),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $error")),
        );
      });
    }

    _clearForm();
  }

  void _checkAndUpdateInventory(Map<String, dynamic> product) async {
    final productName = product['product_name'] ?? '';
    final rate = _parseToInt(product['rate']) ?? 0;
    final quantity = _parseToInt(product['quantity']) ?? 0;
    final amount = _parseToInt(product['amount']) ?? 0;

    // Query inventory by product name and rate
    final inventoryQuery = await _firestore
        .collection('inventory')
        .where('Product Name', isEqualTo: productName)
        .where('Rate', isEqualTo: rate)
        .get();

    if (inventoryQuery.docs.isNotEmpty) {
      // If product with the same rate exists, update the quantity and amount
      final existingDoc = inventoryQuery.docs.first;
      final existingQuantity = existingDoc['Quantity'];
      final newQuantity = existingQuantity + quantity;
      final newAmount = rate * newQuantity;

      await existingDoc.reference.update({
        'Quantity': newQuantity,
        'Amount': newAmount,
      });

      print("Inventory updated successfully");
    } else {
      // If no matching product with the same rate exists, add a new entry
      await _firestore.collection('inventory').add({
        'Product Name': productName,
        'Rate': rate,
        'Quantity': quantity,
        'Amount': amount,
      });

      print("New product added to inventory");
    }
  }


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

  void _addDataToFirestore() {
    final rate = _parseToInt(_rateController.text) ?? 0;
    final quantity = _parseToInt(_quantityController.text) ?? 0;
    final amount = _parseToInt(_amountController.text) ?? 0;

    final purchaseData = {
      'Date': _dateController.text,
      'Merchant Name': _merchantController.text,
      'Billing Address': _billingController.text,
      'Product Name': _productController.text,
      'Rate': rate,
      'Quantity': quantity,
      'Amount': amount,
      'Image/Document': '',
    };

    _firestore.collection('purchase').add(purchaseData).then((value) {
      _checkAndUpdateInventory({
        'product_name': _productController.text,
        'quantity': quantity,
        'rate': rate,
        'amount': amount,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Purchase Submitted Successfully")),
      );
      _clearForm();
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $error")),
      );
    });
  }

  void _clearForm() {
    _dateController.clear();
    _merchantController.clear();
    _billingController.clear();
    _productController.clear();
    _rateController.clear();
    _quantityController.clear();
    _amountController.clear();
    setState(() {
      _imageBytes = null;
    });
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  // Function to calculate the amount
  void _calculateAmount() {
    final rate = _parseToInt(_rateController.text) ?? 0;
    final quantity = _parseToInt(_quantityController.text) ?? 0;
    final amount = rate * quantity;

    _amountController.text = amount.toString();
  }

  @override
  void initState() {
    super.initState();

    // Add listeners to rate and quantity fields to automatically calculate amount
    _rateController.addListener(_calculateAmount);
    _quantityController.addListener(_calculateAmount);
  }

  @override
  void dispose() {
    // Clean up controllers when widget is disposed
    _rateController.removeListener(_calculateAmount);
    _quantityController.removeListener(_calculateAmount);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: SingleChildScrollView(  // Wrap the entire body with SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Add Purchase',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(controller: _dateController, decoration: const InputDecoration(labelText: 'Date')),
              TextField(controller: _merchantController, decoration: const InputDecoration(labelText: 'Merchant Name')),
              TextField(controller: _billingController, decoration: const InputDecoration(labelText: 'Billing Address')),
              TextField(controller: _productController, decoration: const InputDecoration(labelText: 'Product Name')),
              TextField(
                controller: _rateController,
                decoration: const InputDecoration(labelText: 'Rate'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                enabled: false,  // Amount is read-only
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 250,
                  child: ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA8BBA6), foregroundColor: Colors.black),
                    child: const Text("Capture Image"),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 250,
                  child: ElevatedButton(
                    onPressed: _pickImageFromGallery,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA8BBA6), foregroundColor: Colors.black),
                    child: const Text("Upload Image from Gallery"),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_imageBytes != null)
                Image.memory(_imageBytes!, height: 150),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 250,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_imageBytes != null) {
                        _extractTextFromImage(_imageBytes!);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please capture or upload an image")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA8BBA6), foregroundColor: Colors.black),
                    child: const Text('Add Purchase with Image'),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 250,
                  child: ElevatedButton(
                    onPressed: _addDataToFirestore,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA8BBA6), foregroundColor: Colors.black),
                    child: const Text('Add Purchase Without Image'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
