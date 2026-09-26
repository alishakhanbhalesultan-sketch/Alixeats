from flask import Flask, render_template, request, jsonify, session
from dotenv import load_dotenv
from werkzeug.security import generate_password_hash, check_password_hash
import mysql.connector
import os

# Load .env
load_dotenv()

app = Flask(__name__)

# Flask secret key
app.secret_key = os.getenv("SECRET_KEY")


# ==============================
# DATABASE CONNECTION
# ==============================

def get_db_connection():
    try:
        connection = mysql.connector.connect(
            host=os.getenv("DB_HOST"),
            port=int(os.getenv("DB_PORT", 3306)),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
            database=os.getenv("DB_NAME")
        )

        return connection

    except mysql.connector.Error as error:
        print("Database connection error:", error)
        return None


# ==============================
# HOME PAGE
# ==============================

@app.route("/")
def home():
    return render_template("index.html")


# ==============================
# DATABASE TEST
# ==============================

@app.route("/api/db-test")
def db_test():

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    connection.close()

    return jsonify({
        "success": True,
        "message": "AlixEats database connected successfully!"
    })


# ==============================
# REGISTER
# ==============================

@app.route("/api/register", methods=["POST"])
def register():

    data = request.get_json()

    name = data.get("name")
    email = data.get("email")
    phone = data.get("phone")
    password = data.get("password")

    if not name or not email or not phone or not password:
        return jsonify({
            "success": False,
            "message": "All fields are required"
        }), 400

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = connection.cursor(dictionary=True)

    try:

        cursor.execute(
            "SELECT id FROM users WHERE email = %s",
            (email,)
        )

        existing_user = cursor.fetchone()

        if existing_user:
            return jsonify({
                "success": False,
                "message": "Email already registered"
            }), 409

        password_hash = generate_password_hash(password)

        cursor.execute(
            """
            INSERT INTO users
            (name, email, phone, password_hash)
            VALUES (%s, %s, %s, %s)
            """,
            (name, email, phone, password_hash)
        )

        connection.commit()

        return jsonify({
            "success": True,
            "message": "Registration successful"
        }), 201

    except mysql.connector.Error as error:

        connection.rollback()

        return jsonify({
            "success": False,
            "message": "Registration failed",
            "error": str(error)
        }), 500

    finally:

        cursor.close()
        connection.close()


# ==============================
# LOGIN
# ==============================

@app.route("/api/login", methods=["POST"])
def login():

    data = request.get_json()

    email = data.get("email")
    password = data.get("password")

    if not email or not password:
        return jsonify({
            "success": False,
            "message": "Email and password are required"
        }), 400

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = connection.cursor(dictionary=True)

    try:

        cursor.execute(
            """
            SELECT
                id,
                name,
                email,
                phone,
                password_hash
            FROM users
            WHERE email = %s
            """,
            (email,)
        )

        user = cursor.fetchone()

        if not user:
            return jsonify({
                "success": False,
                "message": "Invalid email or password"
            }), 401

        if not check_password_hash(
            user["password_hash"],
            password
        ):
            return jsonify({
                "success": False,
                "message": "Invalid email or password"
            }), 401

        session["user_id"] = user["id"]
        session["user_name"] = user["name"]
        session["user_email"] = user["email"]

        return jsonify({
            "success": True,
            "message": "Login successful",
            "user": {
                "id": user["id"],
                "name": user["name"],
                "email": user["email"],
                "phone": user["phone"]
            }
        })

    finally:

        cursor.close()
        connection.close()


# ==============================
# CURRENT USER
# ==============================

@app.route("/api/me")
def current_user():

    if "user_id" not in session:
        return jsonify({
            "logged_in": False
        })

    return jsonify({
        "logged_in": True,
        "user": {
            "id": session["user_id"],
            "name": session["user_name"],
            "email": session["user_email"]
        }
    })


# ==============================
# LOGOUT
# ==============================

@app.route("/api/logout", methods=["POST"])
def logout():

    session.clear()

    return jsonify({
        "success": True,
        "message": "Logout successful"
    })


# ==============================
# GET RESTAURANTS
# ==============================

@app.route("/api/restaurants")
def restaurants():

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = connection.cursor(dictionary=True)

    try:

        cursor.execute(
            """
            SELECT
                id,
                name,
                category,
                about,
                rating,
                eta_minutes,
                image_url AS image
            FROM restaurants
            ORDER BY rating DESC
            """
        )

        restaurants = cursor.fetchall()

        return jsonify({
            "success": True,
            "restaurants": restaurants
        })

    finally:

        cursor.close()
        connection.close()


# ==============================
# GET FOOD ITEMS
# ==============================

@app.route("/api/food")
def food():

    connection = get_db_connection()

    if connection is None:
        return jsonify({
            "success": False,
            "message": "Database connection failed"
        }), 500

    cursor = connection.cursor(dictionary=True)

    try:

        cursor.execute(
            """
            SELECT
                id,
                restaurant_id,
                name,
                description,
                price,
                category,
                image_url AS image,
                is_available AS available,
                is_popular AS popular
            FROM food_items
            WHERE is_available = 1
            ORDER BY is_popular DESC, name ASC
            """
        )

        food_items = cursor.fetchall()

        return jsonify({
            "success": True,
            "food": food_items
        })

    finally:

        cursor.close()
        connection.close()


# ==============================
# RUN APPLICATION
# ==============================

if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=5000,
        debug=True
    )