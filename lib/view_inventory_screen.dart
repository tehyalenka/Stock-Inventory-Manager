import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../custom_app_bar.dart'; // Import the custom app bar

class ViewInventoryScreen extends StatefulWidget {
  const ViewInventoryScreen({super.key});

  @override
  _ViewInventoryScreenState createState() => _ViewInventoryScreenState();
}

class _ViewInventoryScreenState extends State<ViewInventoryScreen> {
  //final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedFilterField; // Field to filter by
  String? _selectedFilterValue; // Value to filter with

  // Stream to fetch inventory data with real-time updates
  Stream<List<Map<String, dynamic>>> _fetchInventory() {
    Query query = _firestore.collection('inventory');

    // Apply filter dynamically if a filter is set
    if (_selectedFilterField != null && _selectedFilterValue != null) {
      if (_selectedFilterField == 'Rate' ||
          _selectedFilterField == 'Quantity' ||
          _selectedFilterField == 'Amount') {
        // Parse the filter value as a number (double or int)
        var numericValue = num.tryParse(_selectedFilterValue!);
        if (numericValue != null) {
          // Apply the filter with the parsed numeric value
          query = query.where(_selectedFilterField!, isEqualTo: numericValue);
        } else {
          // If the value is not a valid number, do not filter by this field
          return query.snapshots().map(
            (snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id; // Include document ID for actions
              return data;
            }).toList(),
          );
        }
      } else {
        // Apply text-based filter (for 'Product Name' or other fields)
        query = query.where(_selectedFilterField!, isEqualTo: _selectedFilterValue);
      }
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Include document ID for actions
        return data;
      }).toList(),
    );
  }

  // Function to delete an inventory item
  Future<void> _deleteInventoryItem(String id) async {
    try {
      await _firestore.collection('inventory').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inventory item deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting inventory item: $e")),
      );
    }
  }

  // Clear any active filters
  void _clearFilter() {
    setState(() {
      _selectedFilterField = null;
      _selectedFilterValue = null;
    });
  }

  // Apply a selected filter
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
      //appBar: CustomAppBar(scaffoldKey: _scaffoldKey),// Custom AppBar
      appBar: CustomAppBar(),
      body: SingleChildScrollView( // Make the body scrollable
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page title and filter button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'View Inventory',
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
                      const PopupMenuItem<String>(value: 'Product Name', child: Text('Filter by Product Name')),
                      const PopupMenuItem<String>(value: 'Quantity', child: Text('Filter by Quantity')),
                      const PopupMenuItem<String>(value: 'Rate', child: Text('Filter by Rate')),
                      const PopupMenuItem<String>(value: 'Amount', child: Text('Filter by Amount')),
                      const PopupMenuDivider(),
                      const PopupMenuItem<String>(value: 'clear', child: Text('Clear Filter')),
                    ],
                    icon: const Icon(Icons.filter_list), // Filter icon
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // StreamBuilder to display inventory data
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _fetchInventory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No inventory found.'));
                  }

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Product Name')),
                          DataColumn(label: Text('Quantity')),
                          DataColumn(label: Text('Rate')),
                          DataColumn(label: Text('Amount')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: snapshot.data!.map((inventoryItem) {
                          return DataRow(cells: [
                            DataCell(Text(inventoryItem['Product Name'] ?? 'N/A')),
                            DataCell(Text(inventoryItem['Quantity']?.toString() ?? '0')),
                            DataCell(Text(inventoryItem['Rate']?.toString() ?? '0.0')),
                            DataCell(Text(inventoryItem['Amount']?.toString() ?? '0.0')),
                            DataCell(
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _deleteInventoryItem(inventoryItem['id']);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                                child: const Icon(Icons.more_vert), // Actions icon
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
