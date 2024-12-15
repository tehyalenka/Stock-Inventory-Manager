import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../custom_app_bar.dart'; // Import your custom app bar widget

class ViewSalesScreen extends StatefulWidget {
  const ViewSalesScreen({super.key});

  @override
  _ViewSalesScreenState createState() => _ViewSalesScreenState();
}

class _ViewSalesScreenState extends State<ViewSalesScreen> {
  //final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedFilterField; // The field to filter by
  String? _selectedFilterValue; // The value to filter with

  // Fetch the sales data from Firestore
  Future<List<Map<String, dynamic>>> _fetchSales() async {
    Query query = _firestore.collection('sales');

    // Apply filter if a filter is selected
    if (_selectedFilterField != null && _selectedFilterValue != null) {
      // Check if the filter field is one of the numeric fields (Rate, Quantity, Amount)
      if (_selectedFilterField == 'Rate' || _selectedFilterField == 'Quantity' || _selectedFilterField == 'Amount') {
        try {
          final double numericValue = double.parse(_selectedFilterValue!);
          query = query.where(_selectedFilterField!, isEqualTo: numericValue);
        } catch (e) {
          // If parsing fails, return an empty list or show an error
          return [];
        }
      } else {
        // For string fields, apply the filter as a string
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

  // Function to delete a sale by its document ID
  Future<void> _deleteSale(String saleId) async {
    try {
      // Fetch the sale document from Firestore
      final saleSnapshot = await _firestore.collection('sales').doc(saleId).get();

      if (saleSnapshot.exists) {
        final saleData = saleSnapshot.data() as Map<String, dynamic>;

        // Retrieve the product name, rate, and quantity from the sale data
        String productName = saleData['Product Name'];
        double rate = saleData['Rate'] ?? 0.0; // Ensure rate is double or use your desired type
        int quantity = saleData['Quantity'] ?? 0;

        // Query the inventory by both Product Name and Rate
        final inventorySnapshot = await _firestore
            .collection('inventory')
            .where('Product Name', isEqualTo: productName)
            .where('Rate', isEqualTo: rate)
            .limit(1)
            .get();

        if (inventorySnapshot.docs.isNotEmpty) {
          // If the matching product and rate exist in the inventory, update the quantity
          final inventoryDoc = inventorySnapshot.docs.first;
          final inventoryData = inventoryDoc.data() as Map<String, dynamic>;

          int inventoryQuantity = inventoryData['Quantity'] ?? 0;
          int updatedQuantity = inventoryQuantity + quantity;

          if (updatedQuantity > 0) {
            // Update the inventory quantity
            await _firestore
                .collection('inventory')
                .doc(inventoryDoc.id)
                .update({'Quantity': updatedQuantity});
          } else {
            // If the quantity becomes zero or negative, delete the product from inventory
            await _firestore.collection('inventory').doc(inventoryDoc.id).delete();
          }
        } else {
          // If no matching product with the same rate is found, handle as needed
          print("Product with the specified rate doesn't exist in the inventory.");
        }

        // Now delete the sale from the 'sales' collection
        await _firestore.collection('sales').doc(saleId).delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sale deleted and inventory updated")),
        );

        setState(() {}); // Rebuild the UI to reflect changes
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sale not found")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting sale: $e")),
      );
    }
  }


  // Function to reset filters
  void _clearFilter() {
    setState(() {
      _selectedFilterField = null;
      _selectedFilterValue = null;
    });
  }

  // Function to apply a filter
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
      body: SingleChildScrollView( // Wrap the body with SingleChildScrollView for scrollability
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'View Sales',
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
                        String? selectedValue = await showDialog<String>(
                          context: context,
                          builder: (context) => _FilterValueDialog(selectedField: value),
                        );

                        if (selectedValue != null) {
                          _applyFilter(value, selectedValue);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(value: 'Date', child: Text('Filter by Date')),
                      const PopupMenuItem<String>(value: 'Customer Name', child: Text('Filter by Customer Name')),
                      const PopupMenuItem<String>(value: 'Billing Address', child: Text('Filter by Billing Address')),
                      const PopupMenuItem<String>(value: 'Product Name', child: Text('Filter by Product Name')),
                      const PopupMenuItem<String>(value: 'Rate', child: Text('Filter by Rate')),
                      const PopupMenuItem<String>(value: 'Quantity', child: Text('Filter by Quantity')),
                      const PopupMenuItem<String>(value: 'Amount', child: Text('Filter by Amount')),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(value: 'clear', child: Text('Clear Filter')),
                    ],
                    icon: const Icon(Icons.filter_list),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchSales(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No sales found.'));
                  }

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Customer Name')),
                          DataColumn(label: Text('Billing Address')),
                          DataColumn(label: Text('Product Name')),
                          DataColumn(label: Text('Rate')),
                          DataColumn(label: Text('Quantity')),
                          DataColumn(label: Text('Amount')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: snapshot.data!.map((sale) {
                          return DataRow(cells: [
                            DataCell(Text(sale['Date'] ?? 'N/A')),
                            DataCell(Text(sale['Customer Name'] ?? 'N/A')),
                            DataCell(Text(sale['Billing Address'] ?? 'N/A')),
                            DataCell(Text(sale['Product Name'] ?? 'N/A')),
                            DataCell(Text(sale['Rate']?.toString() ?? 'N/A')),
                            DataCell(Text(sale['Quantity']?.toString() ?? 'N/A')),
                            DataCell(Text(sale['Amount']?.toString() ?? 'N/A')),
                            DataCell(
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _deleteSale(sale['id']);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                                child: const Icon(Icons.more_vert),
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
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

  const _FilterValueDialog({Key? key, required this.selectedField}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController _controller = TextEditingController();

    return AlertDialog(
      title: Text(
        'Enter value for $selectedField',
          style: TextStyle(
            fontSize: 16, // Adjust the font size as needed
          ),
        ),
      content: TextField(
        controller: _controller,
        keyboardType: selectedField == 'Rate' || selectedField == 'Quantity' || selectedField == 'Amount'
            ? TextInputType.number
            : TextInputType.text,
        decoration: const InputDecoration(hintText: 'Enter value'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
