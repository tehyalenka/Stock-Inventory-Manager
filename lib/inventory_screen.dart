import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../custom_app_bar.dart'; // Import the reusable AppBar

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _productNameController = TextEditingController(); // Controller for product name
  final TextEditingController _rateController = TextEditingController(); // Controller for rate
  final TextEditingController _quantityController = TextEditingController(); // Controller for quantity
  int rate = 0;
  int quantity = 0;
  int amount = 0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to calculate amount based on rate and quantity (as integer)
  void _calculateAmount() {
    setState(() {
      amount = rate * quantity; // Calculate amount as int
    });
  }

  // Function to add or update data in Firestore
  void _addOrUpdateDataInFirestore() async {
    final productName = _productNameController.text.trim();

    // Check if product name is not empty
    if (productName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a product name")),
      );
      return;
    }

    // Query Firestore for existing product
    final querySnapshot = await _firestore
        .collection('inventory')
        .where('Product Name', isEqualTo: productName)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // If product exists, update the quantity and amount
      final existingDoc = querySnapshot.docs.first;
      final existingQuantity = existingDoc['Quantity'];
      final existingAmount = existingDoc['Amount'];
      final existingRate = existingDoc['Rate'];

      if (existingRate == rate) {
        // If the rate is the same, update the quantity and amount
        final updatedQuantity = existingQuantity + quantity;
        final updatedAmount = rate * updatedQuantity;

        // Update the document with new quantity and amount
        existingDoc.reference.update({
          'Quantity': updatedQuantity,
          'Amount': updatedAmount,
        }).then((value) {
          // Show success message and clear the form
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Inventory Updated Successfully")),
          );
          _clearForm();
        }).catchError((error) {
          // Show error message if something goes wrong
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $error")),
          );
        });
      } else {
        // If the rate is different, add a new product entry
        final inventoryData = {
          'Product Name': productName,
          'Rate': rate,
          'Quantity': quantity,
          'Amount': amount,
        };

        _firestore.collection('inventory').add(inventoryData).then((value) {
          // Show success message and clear the form
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Inventory Added Successfully")),
          );
          _clearForm();
        }).catchError((error) {
          // Show error message if something goes wrong
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $error")),
          );
        });
      }
    } else {
      // If product doesn't exist, create a new entry
      final inventoryData = {
        'Product Name': productName,
        'Rate': rate,
        'Quantity': quantity,
        'Amount': amount,
      };

      _firestore.collection('inventory').add(inventoryData).then((value) {
        // Show success message and clear the form
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Inventory Added Successfully")),
        );
        _clearForm();
      }).catchError((error) {
        // Show error message if something goes wrong
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $error")),
        );
      });
    }
  }

  // Clear form after submitting data
  void _clearForm() {
    setState(() {
      _productNameController.clear(); // Clear product name
      _rateController.clear(); // Clear rate field
      _quantityController.clear(); // Clear quantity field
      rate = 0;
      quantity = 0;
      amount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: SingleChildScrollView(  // Wrap the content in SingleChildScrollView to make it scrollable
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Add Inventory',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Product Name TextField (User input field)
            TextField(
              controller: _productNameController,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            // Rate input as integer
            TextField(
              controller: _rateController,
              decoration: const InputDecoration(labelText: 'Rate'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  rate = int.tryParse(value) ?? 0;
                  _calculateAmount();
                });
              },
            ),
            // Quantity input as integer
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  quantity = int.tryParse(value) ?? 0;
                  _calculateAmount();
                });
              },
            ),
            // Display calculated Amount
            TextField(
              controller: TextEditingController(text: amount.toString()), // Display amount
              decoration: const InputDecoration(labelText: 'Amount'),
              enabled: false, // Amount is automatically calculated
            ),
            const SizedBox(height: 20),

            // Submit Button with light sea green color and white text
            Center(
              child: SizedBox(
                width: 250, // Fixed width for the button
                child: ElevatedButton(
                  onPressed: _addOrUpdateDataInFirestore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA8BBA6), // Light sea green color
                    foregroundColor: Colors.black, // Black text inside button
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: const Text('Submit Inventory'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
