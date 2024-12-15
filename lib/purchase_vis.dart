import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Import the fl_chart package
import 'custom_app_bar.dart'; // Import your custom app bar

class PurchaseVisualizationScreen extends StatefulWidget {
  @override
  _PurchaseVisualizationScreenState createState() =>
      _PurchaseVisualizationScreenState();
}

class _PurchaseVisualizationScreenState extends State<PurchaseVisualizationScreen> {
  //final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Purchase> _purchases = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPurchases();
  }

  // Fetch purchase data from Firestore
  Future<void> _fetchPurchases() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('purchase').get();

      List<Purchase> purchases = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Purchase.fromMap(data);
      }).toList();

      setState(() {
        _purchases = purchases;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching purchase data: $e';
      });
    }
  }

  // Aggregate the purchase data by product
  Map<String, int> _aggregatePurchases() {
    Map<String, int> aggregatedData = {};

    for (var purchase in _purchases) {
      if (aggregatedData.containsKey(purchase.productName)) {
        aggregatedData[purchase.productName] = aggregatedData[purchase.productName]! + purchase.quantity;
      } else {
        aggregatedData[purchase.productName] = purchase.quantity;
      }
    }

    return aggregatedData;
  }

  @override
  Widget build(BuildContext context) {
    Map<String, int> aggregatedData = _aggregatePurchases();
    List<String> productNames = aggregatedData.keys.toList();

    return Scaffold(
      //key: _scaffoldKey,  // Assign the key to the scaffold
      //appBar: CustomAppBar(scaffoldKey: _scaffoldKey), 
      appBar: CustomAppBar(),
      body: SingleChildScrollView( // Wrap the entire body in a scrollable view
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show loading spinner or error message
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_errorMessage != null)
                Center(child: Text(_errorMessage!))
              else if (_purchases.isEmpty)
                const Center(child: Text('No purchases available.'))
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title for the visualization with a gap
                    Text(
                      'Purchase Summary by Product',
                      style: TextStyle(
                        fontSize: 22, // Adjust this value to your desired size
                        fontWeight: FontWeight.bold, // You can also set the font weight if needed
                      ),
                    ),
                    const SizedBox(height: 150), // Added some gap between title and chart
                    // Container with vertical bar chart
                    Container(
                      height: 500, // Set a fixed height for the chart
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey), // Add border to the chart
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceEvenly,
                          borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey)),
                          gridData: FlGridData(show: true), // Show gridlines
                          titlesData: FlTitlesData(
                            leftTitles: SideTitles(showTitles: false), // Hide left titles
                            rightTitles: SideTitles(showTitles: false),
                            topTitles: SideTitles(showTitles: false),
                            bottomTitles: SideTitles(
                              showTitles: true,
                              getTitles: (value) {
                                return productNames[value.toInt()];
                              },
                            ),
                          ),
                          barGroups: aggregatedData.entries
                              .map(
                                (entry) {
                                  final productName = entry.key;
                                  final quantity = entry.value;
                                  return BarChartGroupData(
                                    x: productNames.indexOf(productName),
                                    barRods: [
                                      BarChartRodData(
                                        y: quantity.toDouble(),
                                        colors: [Color(0xFFA8BBA6)], // Muted sage green color
                                        width: 20,
                                        borderRadius: BorderRadius.circular(4),
                                        backDrawRodData: BackgroundBarChartRodData(
                                          show: true,
                                          y: quantity.toDouble(),
                                          colors: [Color(0xFFA8BBA6).withOpacity(0.1)],
                                        ),
                                      ),
                                    ],
                                    showingTooltipIndicators: [0],
                                  );
                                },
                              )
                              .toList(),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              tooltipBgColor: Color(0xFFA8BBA6),
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final productName = productNames[group.x.toInt()];
                                return BarTooltipItem(
                                  '$productName\n',
                                  TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: rod.y.toString(),
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// A simple class to represent the purchase data
class Purchase {
  final String productName;
  final int quantity;

  Purchase({
    required this.productName,
    required this.quantity,
  });

  // Convert Firestore document data to Purchase object
  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      productName: map['Product Name'] ?? 'Unknown',
      quantity: (map['Quantity'] ?? 0).toInt(),
    );
  }
}
