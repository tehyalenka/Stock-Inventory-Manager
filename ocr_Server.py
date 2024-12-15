from flask import Flask, request, jsonify
from flask_cors import CORS  # Import CORS
from PIL import Image
import pytesseract
import io
import re

app = Flask(__name__)

# Enable CORS for all origins
CORS(app)

# Route to receive image and return extracted text
@app.route('/upload', methods=['POST'])
def upload_image():
    if 'image' not in request.files:
        return jsonify({'error': 'No image file provided'}), 400

    image_file = request.files['image']
    image = Image.open(image_file.stream)

    # Use pytesseract to extract text
    text = pytesseract.image_to_string(image)
    print(text)
    print("OCR Text: ", text)

    # Extract the data using regular expressions
    merchant_name_match = re.search(r'Merchant Name:\s*(.*)', text)
    merchant_name = merchant_name_match.group(1) if merchant_name_match else 'N/A'

    date_match = re.search(r'Date:\s*(\d{2}/\d{2}/\d{4})', text)
    date = date_match.group(1) if date_match else 'N/A'

    billing_address_match = re.search(r'Billing Address:\s*(.*)', text)
    billing_address = billing_address_match.group(1) if billing_address_match else 'N/A'

    customer_name_match = re.search(r'Customer Name:\s*(.*)', text)
    customer_name = customer_name_match.group(1) if customer_name_match else 'N/A'

    # Extracting products information with proper formatting
    products_info = re.findall(r'(\w+)\s+Rs\.\s*(\d+)\s+(\d+)\s+Rs\.\s*(\d+)', text)

    # Prepare the data to return
    response_data = {
        'date': date,
        'merchant_name': merchant_name,
        'customer_name': customer_name,
        'billing_address': billing_address,
        'products': [{'product_name': p[0], 'rate': p[1], 'quantity': p[2], 'amount': p[3]} for p in products_info]
    }

    return jsonify(response_data)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')  # Ensure Flask is available on all network interfaces
