import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../custom_app_bar.dart'; // Import your custom app bar widget

class ViewPurchasesScreen extends StatefulWidget {
  const ViewPurchasesScreen({super.key});

  @override
  _ViewPurchasesScreenState createState() => _ViewPurchasesScreenState();
}

class _ViewPurchasesScreenState extends State<ViewPurchasesScreen> {
  //final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedFilterField; // The field to filter by
  String? _selectedFilterValue; // The value to filter with

  // Fetch the purchase data from Firestore
  Future<List<Map<String, dynamic>>> _fetchPurchases() async {
    Query query = _firestore.collection('purchase');

    if (_selectedFilterField != null && _selectedFilterValue != null) {
      // If the filter is for numeric fields like Rate, Quantity, or Amount
      if (_selectedFilterField == 'Rate' ||
          _selectedFilterField == 'Quantity' ||
          _selectedFilterField == 'Amount') {
        try {
          final int numericValue = int.parse(_selectedFilterValue!);
          query = query.where(_selectedFilterField!, isEqualTo: numericValue);
        } catch (e) {
          // If parsing fails, you can show an error or return no results
          return [];
        }
      } else {
        // For string fields (like Date, Merchant Name, etc.)
        query = query.where(_selectedFilterField!, isEqualTo: _selectedFilterValue);
      }
    }

    QuerySnapshot snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Add document ID for deletion
      return data;
    }).toList();
  }

  // Function to delete a purchase by its document ID
  Future<void> _deletePurchase(String purchaseId) async {
    try {
      // Fetch the purchase document from Firestore
      final purchaseSnapshot = await _firestore.collection('purchase').doc(purchaseId).get();
      if (!purchaseSnapshot.exists) throw "Purchase not found.";

      final purchaseData = purchaseSnapshot.data()!;
      final String productName = purchaseData['Product Name'] ?? '';
      final int rate = purchaseData['Rate'] ?? 0; // Rate should be an integer
      final int quantity = purchaseData['Quantity'] ?? 0;

      // Query the inventory by Product Name and Rate
      final inventorySnapshot = await _firestore
          .collection('inventory')
          .where('Product Name', isEqualTo: productName)
          .where('Rate', isEqualTo: rate)
          .limit(1)
          .get();

      if (inventorySnapshot.docs.isNotEmpty) {
        // If product with the same rate exists, get the inventory document
        final inventoryDoc = inventorySnapshot.docs.first;
        final inventoryData = inventoryDoc.data();
        final int inventoryQuantity = inventoryData['Quantity'] ?? 0;
        final int updatedQuantity = inventoryQuantity - quantity;

        if (updatedQuantity >= 0) {
          // Update inventory if there is remaining stock
          await _firestore.collection('inventory').doc(inventoryDoc.id).update({'Quantity': updatedQuantity});
        } else {
          // If no stock remains in the inventory, delete the product from inventory
          await _firestore.collection('inventory').doc(inventoryDoc.id).delete();

          // Handle sales collection adjustment when inventory is negative
          await _adjustSalesForDeletedPurchase(productName, rate, updatedQuantity);
        }
      } else {
        // If no matching product with the same rate is found in inventory
        print("Product with the specified rate doesn't exist in the inventory.");
      }

      // Now delete the purchase from the 'purchase' collection
      await _firestore.collection('purchase').doc(purchaseId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Purchase deleted and inventory updated")),
      );
      setState(() {}); // Refresh UI
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting purchase: $e")),
      );
    }
  }

  // Function to adjust sales when the inventory quantity goes negative
    Future<void> _adjustSalesForDeletedPurchase(String productName, int rate, int updatedInventoryQuantity) async {
      try {
        // Query the sales collection to find sales related to the product and rate
        final salesSnapshot = await _firestore
            .collection('sales')
            .where('Product Name', isEqualTo: productName)
            .where('Rate', isEqualTo: rate)
            .get();

        if (salesSnapshot.docs.isNotEmpty) {
          for (var saleDoc in salesSnapshot.docs) {
            final saleData = saleDoc.data();
            int soldQuantity = saleData['Quantity'] ?? 0;

            // Check if the quantity sold is more than the remaining inventory
            if (soldQuantity > updatedInventoryQuantity) {
              // If quantity sold is more than remaining, reduce it and delete sale if quantity is 0
              await _firestore.collection('sales').doc(saleDoc.id).update({
                'Quantity': soldQuantity + updatedInventoryQuantity
              });
            } 

            final updatedSaleSnapshot = await _firestore.collection('sales').doc(saleDoc.id).get();
            if (updatedSaleSnapshot.exists) {
              final updatedSaleData = updatedSaleSnapshot.data() as Map<String, dynamic>;
              int updatedSaleQuantity = updatedSaleData['Quantity'] ?? 0;
              if (updatedSaleQuantity <= 0) {
                // If the updated quantity is 0 or negative, delete the sale
                await _firestore.collection('sales').doc(saleDoc.id).delete();
              }
            }
            // Once we adjust the sales, break the loop since we are done
            break;
          }
        } else {
          print("No sales records found for this product.");
        }
      } catch (e) {
        print("Error adjusting sales: $e");
      }
    }


  void _clearFilter() {
    setState(() {
      _selectedFilterField = null;
      _selectedFilterValue = null;
    });
  }

  void _applyFilter(String field, String value) {
    setState(() {
      _selectedFilterField = field;
      _selectedFilterValue = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //key: _scaffoldKey,  // Assign the key to the scaffold
      //appBar: CustomAppBar(scaffoldKey: _scaffoldKey),
      appBar: CustomAppBar(),
      body: SingleChildScrollView( // Makes the whole content scrollable
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'View Purchases',
                    style: TextStyle(
                      fontSize: 22, // Adjust this value to your desired size
                      fontWeight: FontWeight.bold, // You can also set the font weight if needed
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'clear') {
                        _clearFilter();
                      } else {
                        final selectedValue = await showDialog<String>(
                          context: context,
                          builder: (_) => _FilterValueDialog(selectedField: value),
                        );
                        if (selectedValue != null) {
                          _applyFilter(value, selectedValue);
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'Date', child: Text('Filter by Date')),
                      const PopupMenuItem(value: 'Merchant Name', child: Text('Filter by Merchant Name')),
                      const PopupMenuItem(value: 'Billing Address', child: Text('Filter by Billing Address')),
                      const PopupMenuItem(value: 'Product Name', child: Text('Filter by Product Name')),
                      const PopupMenuItem(value: 'Rate', child: Text('Filter by Rate')),
                      const PopupMenuItem(value: 'Quantity', child: Text('Filter by Quantity')),
                      const PopupMenuItem(value: 'Amount', child: Text('Filter by Amount')),
                      const PopupMenuDivider(),
                      const PopupMenuItem(value: 'clear', child: Text('Clear Filter')),
                    ],
                    icon: const Icon(Icons.filter_list),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchPurchases(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final purchases = snapshot.data;
                  if (purchases == null || purchases.isEmpty) {
                    return const Center(child: Text('No purchases found.'));
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Merchant Name')),
                        DataColumn(label: Text('Billing Address')),
                        DataColumn(label: Text('Product Name')),
                        DataColumn(label: Text('Rate')),
                        DataColumn(label: Text('Quantity')),
                        DataColumn(label: Text('Amount')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: purchases.map((purchase) {
                        return DataRow(cells: [
                          DataCell(Text(purchase['Date'] ?? 'N/A')),
                          DataCell(Text(purchase['Merchant Name'] ?? 'N/A')),
                          DataCell(Text(purchase['Billing Address'] ?? 'N/A')),
                          DataCell(Text(purchase['Product Name'] ?? 'N/A')),
                          DataCell(Text(purchase['Rate']?.toString() ?? 'N/A')),
                          DataCell(Text(purchase['Quantity']?.toString() ?? 'N/A')),
                          DataCell(Text(purchase['Amount']?.toString() ?? 'N/A')),
                          DataCell(
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'delete') {
                                  _deletePurchase(purchase['id']);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                              child: const Icon(Icons.more_vert),
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterValueDialog extends StatelessWidget {
  final String selectedField;

  const _FilterValueDialog({required this.selectedField});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return AlertDialog(
      title: Text(
        'Enter value for $selectedField',
          style: TextStyle(
            fontSize: 16, // Adjust the font size as needed
          ),
        ),
      content: TextField(
        controller: controller,
        keyboardType: selectedField == 'Rate' || selectedField == 'Quantity' || selectedField == 'Amount'
            ? TextInputType.number
            : TextInputType.text, // Use number keyboard for numeric fields
        decoration: const InputDecoration(hintText: 'Enter value'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
