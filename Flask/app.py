import random  # For generating random sensor values
import time
from flask import Flask, jsonify, request, render_template, send_from_directory  # Tambahkan render_template
from flask_cors import CORS
from pymongo import MongoClient
from datetime import datetime
import traceback
import os

app = Flask(__name__)
CORS(app)

# Connect to MongoDB
client = MongoClient('mongodb+srv://rafebyours:SurajaKids@cluster0.5e2ml.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0')
db = client['sensor_db']  # Use your database
collection = db['sensor_data']  # Use your collection

@app.route('/frontend/static/<path:filename>')
def serve_frontend_static(filename):
    return send_from_directory(os.path.join(app.root_path, 'frontend/static'), filename)

@app.route('/')
def index():
    return render_template('index.html')

# Endpoint to get data
@app.route('/data', methods=['GET'])
def get_data():
    data = list(collection.find())
    for item in data:
        item['_id'] = str(item['_id'])  # Convert ObjectId to string
        if 'timestamp' in item and isinstance(item['timestamp'], datetime):
            # Convert datetime to ISO 8601 format
            item['timestamp'] = item['timestamp'].isoformat() + "Z"
    return jsonify(data)

# Endpoint untuk menerima data dari ESP32
@app.route('/data', methods=['POST'])
def add_data():
    try:
        data = request.get_json()
        print("Data yang diterima:", data)  # Menampilkan data yang diterima

        required_keys = ['sensor_value_gas', 'sensor_value_humidity', 'sensor_value_temp']
        if not data or not all(key in data for key in required_keys):
            return jsonify({"error": f"Data tidak lengkap, harus mengandung {required_keys}"}), 400

        data['timestamp'] = datetime.utcnow().isoformat() + "Z"

        # Simpan ke MongoDB
        result = collection.insert_one(data)
        print(f"Data berhasil disimpan dengan ID: {result.inserted_id}")

        return jsonify({"message": "Data berhasil disimpan", "id": str(result.inserted_id)}), 201
    except Exception as e:
        print(f"Error: {traceback.format_exc()}")  # Untuk melihat error yang lebih mendetail
        return jsonify({"error": "Terjadi kesalahan pada server"}), 500

# Function to automatically add data every 5 seconds
def auto_add_data():
    while True:
        # Generate random sensor values
        new_data = {
            "sensor_value_gas": random.randint(100, 200),  # Random gas value
            "sensor_value_humidity": random.randint(50, 70),  # Random humidity value
            "sensor_value_temp": round(20 + (random.random() * 10), 2),  # Random temperature value
            "timestamp": datetime.utcnow().isoformat() + "Z"  # Timestamp in ISO 8601 format
        }
        # Insert the new data into MongoDB
        collection.insert_one(new_data)
        print(f"Data inserted: {new_data}")
        time.sleep(5)  # Wait 5 seconds before adding the next data point

if __name__ == '__main__':
    # Run the auto_add_data function in the background
    from threading import Thread
    Thread(target=auto_add_data, daemon=True).start()
        # Use the PORT environment variable set by Vercel
    port = int(os.environ.get('PORT', 5000))  # Default to 5000 if PORT is not set
    app.run(host='0.0.0.0', port=port, debug=True)