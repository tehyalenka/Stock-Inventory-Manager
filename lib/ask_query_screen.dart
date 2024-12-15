import 'package:flutter/material.dart';
import 'custom_app_bar.dart';  // Import your custom app bar

class AskQueryScreen extends StatefulWidget {
  @override
  _AskQueryScreenState createState() => _AskQueryScreenState();
}

class _AskQueryScreenState extends State<AskQueryScreen> {
  //final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, String>> messages = []; // Store chat messages
  List<String> categories = ['Purchase', 'Sales', 'Inventory']; // Categories
  String selectedCategory = ''; // To track selected category
  List<String> actionButtons = []; // To store action buttons based on category

  @override
  void initState() {
    super.initState();
    // Initial greeting message from the bot
    messages.add({
      'sender': 'bot',
      'message': 'Hi, there! How can I assist you today? Please select a category below.',
    });
  }

  // Function to send message from user and bot
  void sendMessage(String message, String sender) {
    setState(() {
      messages.add({'sender': sender, 'message': message});
    });
  }

  // Function to handle category button click
  void handleCategorySelection(String category) {
    setState(() {
      selectedCategory = category;
      // Reset the action buttons when a new category is selected
      actionButtons.clear();
    });

    sendMessage(category, 'user');

    String response;
    switch (category) {
      case 'Inventory':
        response = 'The Inventory section of this app allows you to efficiently manage your product stock. You can add new inventory items and track current stock levels. It provides easy access to view inventory details and visualize stock trends. With this section, you can maintain an organized and up-to-date inventory.';
        actionButtons.addAll(['Add Inventory', 'View Inventory', 'Visualize Inventory']);
        break;
      case 'Sales':
        response = 'The Sales section of this app helps you manage customer transactions and sales records. You can add new sales, view past sales details, and analyze sales performance. This section ensures seamless management of your sales operations and boosts customer satisfaction.';
        actionButtons.addAll(['Add Sales', 'View Sales', 'Visualize Sales']);
        break;
      case 'Purchase':
        response = 'The Purchase section of this app helps you manage supplier transactions and purchase orders. You can add new purchase entries, track existing orders, and view detailed records. This section ensures efficient management of your procurement process and keeps stock levels optimized.';
        actionButtons.addAll(['Add Purchase', 'View Purchase', 'Visualize Purchase']);
        break;
      default:
        response = 'Please select a valid category.';
    }

    sendMessage(response, 'bot');
  }

  // Function to handle action button click (e.g., Add, View, Visualize)
  void handleActionSelection(String action) {
    sendMessage(action, 'user');

    String response;
    switch (selectedCategory) {
      case 'Inventory':
        response = _getInventoryActionResponse(action);
        break;
      case 'Sales':
        response = _getSalesActionResponse(action);
        break;
      case 'Purchase':
        response = _getPurchaseActionResponse(action);
        break;
      default:
        response = 'Invalid action selected.';
    }

    sendMessage(response, 'bot');
  }

  // Get specific response for Inventory actions
  String _getInventoryActionResponse(String action) {
    switch (action) {
      case 'Add Inventory':
        return 'Add Inventory allows you to add inventory items by entering product details such as name, rate, and quantity. The amount is automatically calculated based on the rate and quantity entered.You can submit the inventory data, which is then saved to Firestore. After submission, a success message appears, and the form is cleared for new entries. It also handles error messages if data submission fails.';
      case 'View Inventory':
        return 'View Inventory displays inventory items in a data table with real-time updates from Firestore. You can filter inventory by product name, quantity, rate, or amount through a popup menu. The filter can be cleared, and you can also delete inventory items with a popup menu in the actions column. The inventory data is dynamically loaded using a stream, and each entry includes details such as product name, quantity, rate, and amount. It offers an easy-to-use interface for viewing and managing inventory records.';
      case 'Visualize Inventory':
        return 'Visualize Inventory displays inventory data using a vertical bar chart. The chart displays the total quantity of each product in the inventory, with product names on the x-axis and quantities on the y-axis. It provides real-time data updates and error handling during data retrieval. The chart includes tooltips showing product names and quantities when you interact with the bars. It also handles loading states and displays appropriate messages if there is no data or if an error occurs.';
      default:
        return 'Unknown action.';
    }
  }

  // Get specific response for Sales actions
  String _getSalesActionResponse(String action) {
    switch (action) {
      case 'Add Sales':
        return 'The Add Sales menu option allows you to easily record sales transactions. You can input details like the sale date, customer name, billing address, product name, rate, quantity, and total amount. You can add a sale either by manually entering the information or by capturing/uploading an image (e.g., a receipt) to automatically extract sale details. The app will also update inventory records and store the sales data in the system. After submitting a sale, you will receive confirmation of successful submission.';
      case 'View Sales':
        return 'View Sales allows you to view sales data in a table format, displaying key information such as date, customer name, billing address, product name, rate, quantity, and amount. It supports filtering by various fields like date, product name, rate, and quantity, with an option to apply or clear filters. You can delete individual sales, which automatically updates inventory quantities. It dynamically updates based on selected filters and displays a loading spinner while fetching data. Error handling and empty state messages provide feedback if no data is found or if an issue occurs.';
      case 'Visualize Sales':
        return 'Visualize Sales displays a bar chart summarizing sales data by product. It aggregates sales based on product name and shows the total quantity sold for each product. The chart is interactive, providing tooltips with product names and quantities on touch. You can view a loading spinner during data fetch and see an error message if data retrieval fails. If no sales data exists, a notification informs the user that there are no available sales records.';
      default:
        return 'Unknown action.';
    }
  }

  // Get specific response for Purchase actions
  String _getPurchaseActionResponse(String action) {
    switch (action) {
      case 'Add Purchase':
        return 'Add Purchase allows you to easily add purchase details by filling in information such as the date, merchant name, billing address, product name, rate, quantity, and amount. You can also capture a photo or upload an image from your gallery for purchase documentation. If you upload an image, the text from the image is extracted and processed automatically. The system also updates your inventory by checking if the product already exists and adjusting the quantity. Whether you want to add a purchase with an image or without, this page gives you the flexibility to do both.';
      case 'View Purchase':
        return 'View Purchase allows you to view and manage all purchase transactions. You can filter purchases based on various fields such as date, merchant name, product name, rate, quantity, and amount. It displays a table with detailed purchase information and provides an option to delete purchases. If a purchase is deleted, the corresponding inventory is updated automatically to reflect the change in quantity. The filter functionality enables you to quickly find specific purchases, making it easy to manage and track purchase data.';
      case 'Visualize Purchase':
        return 'Visualize Purchase displays a summary of purchase data by aggregating the total quantity purchased for each product. This is shown using an interactive bar chart, where the height of each bar represents the total quantity. You can tap on a bar to view detailed information about the product and its quantity. This helps you identify high-demand products and track purchase trends. If data fetching fails or no purchases are available, appropriate error or notification messages are shown.';
      default:
        return 'Unknown action.';
    }
  }

  // Clear chat history
  void clearChat() {
    setState(() {
      messages.clear();
      selectedCategory = '';
      actionButtons.clear();
      messages.add({
        'sender': 'bot',
        'message': 'Hi, there! How can I assist you today? Please select a category below.',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //key: _scaffoldKey,  // Assign the key to the scaffold
      //appBar: CustomAppBar(scaffoldKey: _scaffoldKey),
      appBar: CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Title before the greeting message
            Text(
              'Ask a Query',
              style: TextStyle(
                fontSize: 22, // Adjust this value to your desired size
                fontWeight: FontWeight.bold, // Set the font weight if needed
              ),
            ),
            SizedBox(height: 25), // Add space between the title and the chat

            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  Map<String, String> message = messages[index];
                  return ChatBubble(
                    message: message['message']!,
                    isBot: message['sender'] == 'bot',
                  );
                },
              ),
            ),
            if (messages.last['sender'] == 'bot' && selectedCategory == '') ...[
              // Show category buttons when no category is selected
              Wrap(
                spacing: 10.0,
                children: categories.map((category) {
                  return ElevatedButton(
                    onPressed: () {
                      handleCategorySelection(category);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFA8BBA6), // Consistent color for buttons
                      foregroundColor: Colors.black, // Text color
                    ),
                    child: Text(category),
                  );
                }).toList(),
              ),
            ] else if (messages.last['sender'] == 'bot' && selectedCategory.isNotEmpty) ...[
              // Show action buttons for the selected category
              Wrap(
                spacing: 10.0,
                children: actionButtons.map((action) {
                  return ElevatedButton(
                    onPressed: () {
                      handleActionSelection(action);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFA8BBA6), // Consistent color for buttons
                      foregroundColor: Colors.black, // Text color
                    ),
                    child: Text(action),
                  );
                }).toList(),
              ),
            ],
            SizedBox(height: 20), // Space before the Clear button
            ElevatedButton(
              onPressed: clearChat,
              child: Text('Clear'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFA8BBA6), 
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isBot;

  const ChatBubble({required this.message, required this.isBot});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isBot ? Alignment.topLeft : Alignment.topRight,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        margin: EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          color: isBot ? Colors.grey[300] : Colors.blue[100],
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Text(
          message,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
