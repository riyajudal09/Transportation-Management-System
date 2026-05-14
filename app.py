from flask import Flask, render_template, request, redirect, url_for, session
import mysql.connector
from mysql.connector import Error

app = Flask(__name__)

# Essential for basic session login functionality
app.secret_key = 'TransportSystemSecretKey'

# Database credentials 
DB_CONFIG = {
    'host': '127.0.0.1',
    'user': 'root',
    'password': 'Riya@0809', # <-- Ensure this is your real MySQL password
    'database': 'DBTransport'
}

def get_db_connection():
    return mysql.connector.connect(**DB_CONFIG)


# ==========================================
#         DATA FETCHING FUNCTIONS
# ==========================================

def get_detailed_vehicles():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("SELECT COUNT(*) as count FROM Vehicles")
        total_vehicles = cursor.fetchone()['count']

        cursor.execute("SELECT SUM(total_fare) as revenue FROM Assignments WHERE status = 'Completed'")
        revenue_result = cursor.fetchone()['revenue']
        total_revenue = f"₹ {revenue_result:,.2f}" if revenue_result else "₹ 0.00"

        cursor.execute("SELECT COUNT(*) as active FROM Assignments WHERE status IN ('Planned', 'In Progress')")
        active_assignments = cursor.fetchone()['active']
        cursor.execute("SELECT * FROM Vehicles ORDER BY vehicle_id DESC")
        all_vehicles = cursor.fetchall()

        detailed_list = []
        for vehicle in all_vehicles:
            v_id = vehicle['vehicle_id']
            vehicle['display_capacity'] = 'N/A' 
            
            if vehicle['type'] == 'Bus':
                cursor.execute("SELECT seating_capacity, is_ac FROM Buses WHERE vehicle_id = %s", (v_id,))
                bus = cursor.fetchone()
                if bus:
                    ac_status = "AC" if bus['is_ac'] else "Non-AC"
                    vehicle['display_capacity'] = f"{bus['seating_capacity']} Seats ({ac_status})"
            elif vehicle['type'] == 'Truck':
                cursor.execute("SELECT load_capacity_tons, truck_type FROM Trucks WHERE vehicle_id = %s", (v_id,))
                truck = cursor.fetchone()
                if truck:
                    vehicle['display_capacity'] = f"{truck['load_capacity_tons']} Tons"
            detailed_list.append(vehicle)

        return {
            'detailed_vehicles': detailed_list,
            'total_vehicles': total_vehicles,
            'total_revenue': total_revenue,
            'active_assignments': active_assignments
        }
    except Error as e:
        print(f"Error: {e}")
        return None
    finally:
        if 'cursor' in locals(): cursor.close()
        if 'conn' in locals() and conn.is_connected(): conn.close()

def get_people_data():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM Drivers ORDER BY driver_id ASC")
        drivers = cursor.fetchall()
        cursor.execute("SELECT * FROM Customers ORDER BY customer_id ASC")
        customers = cursor.fetchall()
        return {'drivers': drivers, 'customers': customers}
    except Error as e:
        return None
    finally:
        if 'cursor' in locals(): cursor.close()
        if 'conn' in locals() and conn.is_connected(): conn.close()

def get_assignments_data():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        query = """
            SELECT a.*, v.vehicle_num, d.first_name, d.last_name, c.company_name 
            FROM Assignments a
            LEFT JOIN Vehicles v ON a.vehicle_id = v.vehicle_id
            LEFT JOIN Drivers d ON a.driver_id = d.driver_id
            LEFT JOIN Customers c ON a.customer_id = c.customer_id
            ORDER BY a.assignment_id DESC
        """
        cursor.execute(query)
        return cursor.fetchall()
    except Error as e:
        return None
    finally:
        if 'cursor' in locals(): cursor.close()
        if 'conn' in locals() and conn.is_connected(): conn.close()

def get_revenue_data():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        # Revenue by Vehicle Type
        cursor.execute("""
            SELECT v.type AS Vehicle_Type, COUNT(a.assignment_id) AS Total_Trips, SUM(a.total_fare) AS Total_Revenue
            FROM Vehicles v LEFT JOIN Assignments a ON v.vehicle_id = a.vehicle_id AND a.status = 'Completed'
            GROUP BY v.type ORDER BY Total_Revenue DESC
        """)
        revenue_by_type = cursor.fetchall()

        # Customer Billing
        cursor.execute("""
            SELECT c.company_name, COUNT(a.assignment_id) AS Total_Bookings, SUM(a.total_fare) AS Total_Billed
            FROM Customers c JOIN Assignments a ON c.customer_id = a.customer_id
            GROUP BY c.customer_id ORDER BY Total_Billed DESC
        """)
        customer_billing = cursor.fetchall()
        return {'revenue_by_type': revenue_by_type, 'customer_billing': customer_billing}
    except Error as e:
        return None
    finally:
        if 'cursor' in locals(): cursor.close()
        if 'conn' in locals() and conn.is_connected(): conn.close()


# ==========================================
#         PAGE NAVIGATION ROUTES
# ==========================================

@app.route('/')
def home():
    if session.get('logged_in'):
        return render_template('index.html', logged_in=True, active_page='dashboard', data=get_detailed_vehicles())
    return render_template('index.html', logged_in=False, error=request.args.get('error'))

@app.route('/people')
def people():
    if not session.get('logged_in'): return redirect(url_for('home'))
    return render_template('index.html', logged_in=True, active_page='people', data=get_people_data())

@app.route('/assignments')
def assignments():
    if not session.get('logged_in'): return redirect(url_for('home'))
    return render_template('index.html', logged_in=True, active_page='assignments', data=get_assignments_data())

@app.route('/revenue')
def revenue():
    if not session.get('logged_in'): return redirect(url_for('home'))
    return render_template('index.html', logged_in=True, active_page='revenue', data=get_revenue_data())


# ==========================================
#       FORM SUBMISSION & AUTH ROUTES
# ==========================================

@app.route('/login', methods=['POST'])
def check_login():
    if request.form['username'] == 'admin' and request.form['password'] == '12345':
        session['logged_in'] = True
        return redirect(url_for('home'))
    return redirect(url_for('home', error='Invalid Username or Password'))

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('home'))

@app.route('/add_vehicle', methods=['POST'])
def add_vehicle_web():
    if not session.get('logged_in'): return redirect(url_for('home'))
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        v_id = request.form.get('v_id')
        v_type = request.form.get('v_type')
        v_num = request.form.get('v_num')
        fare_raw = request.form.get('fare')
        fare = float(fare_raw) if fare_raw and fare_raw.strip() else 0.0

        cursor.execute("INSERT INTO Vehicles (vehicle_id, type, vehicle_num, fare_per_km, status) VALUES (%s, %s, %s, %s, 'Active')", (v_id, v_type, v_num, fare))
        
        if v_type == "Bus":
            seats_raw = request.form.get('seats')
            seats = int(seats_raw) if seats_raw and seats_raw.strip() else 40
            cursor.execute("INSERT INTO Buses (vehicle_id, seating_capacity, is_ac, has_wifi) VALUES (%s, %s, True, False)", (v_id, seats))
            
        elif v_type == "Truck":
            load_raw = request.form.get('load')
            load = float(load_raw) if load_raw and load_raw.strip() else 10.0
            cursor.execute("INSERT INTO Trucks (vehicle_id, load_capacity_tons, truck_type, axles) VALUES (%s, %s, 'Standard', 4)", (v_id, load))
        
        conn.commit()
        return redirect(url_for('home'))
    except Error as e:
        return f"<h3>Database Error: Ensure your Vehicle ID is unique. Detail: {e}</h3> <br><br> <a href='/'>Go Back to Dashboard</a>"
    finally:
        if 'cursor' in locals(): cursor.close()
        if 'conn' in locals() and conn.is_connected(): conn.close()

@app.route('/add_driver', methods=['POST'])
def add_driver():
    if not session.get('logged_in'): return redirect(url_for('home'))
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        d_id = request.form.get('d_id')
        fname = request.form.get('fname')
        lname = request.form.get('lname')
        lic = request.form.get('license')
        phone = request.form.get('phone')
        
        cursor.execute("INSERT INTO Drivers (driver_id, first_name, last_name, license_number, phone_number, status) VALUES (%s, %s, %s, %s, %s, 'Available')", 
                       (d_id, fname, lname, lic, phone))
        conn.commit()
        return redirect(url_for('people'))
    except Error as e:
        return f"<h3>Database Error (Driver): {e}</h3><br><a href='/people'>Go Back</a>"
    finally:
        if 'cursor' in locals(): cursor.close()
        if 'conn' in locals() and conn.is_connected(): conn.close()

@app.route('/add_customer', methods=['POST'])
def add_customer():
    if not session.get('logged_in'): return redirect(url_for('home'))
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        c_id = request.form.get('c_id')
        cname = request.form.get('cname')
        contact = request.form.get('contact')
        phone = request.form.get('phone')
        
        cursor.execute("INSERT INTO Customers (customer_id, company_name, contact_person, phone) VALUES (%s, %s, %s, %s)", 
                       (c_id, cname, contact, phone))
        conn.commit()
        return redirect(url_for('people'))
    except Error as e:
        return f"<h3>Database Error (Customer): {e}</h3><br><a href='/people'>Go Back</a>"
    finally:
        if 'cursor' in locals(): cursor.close()
        if 'conn' in locals() and conn.is_connected(): conn.close()

@app.route('/add_assignment', methods=['POST'])
def add_assignment():
    if not session.get('logged_in'): return redirect(url_for('home'))
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        a_id = request.form.get('a_id')
        v_id = request.form.get('v_id')
        d_id = request.form.get('d_id')
        c_id = request.form.get('c_id')
        start_loc = request.form.get('start_loc')
        end_loc = request.form.get('end_loc')
        status = request.form.get('status')
        
        fare_raw = request.form.get('fare')
        fare = float(fare_raw) if fare_raw and fare_raw.strip() else 0.0
        
        cursor.execute("""
            INSERT INTO Assignments (assignment_id, vehicle_id, driver_id, customer_id, start_location, end_location, total_fare, status) 
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (a_id, v_id, d_id, c_id, start_loc, end_loc, fare, status))
        conn.commit()
        return redirect(url_for('assignments'))
    except Error as e:
        return f"<h3>Database Error (Assignment): Ensure Vehicle ID, Driver ID, and Customer ID exist. Detail: {e}</h3><br><a href='/assignments'>Go Back</a>"
    finally:
        if 'cursor' in locals(): cursor.close()
        if 'conn' in locals() and conn.is_connected(): conn.close()


if __name__ == "__main__":
    app.run(debug=True)