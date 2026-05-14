DROP DATABASE IF EXISTS DBTransport;
CREATE DATABASE DBTransport;
USE DBTransport;

-- ==========================================
-- 1. CORE ENTITIES (Drivers & Customers)
-- ==========================================
CREATE TABLE Drivers (
    driver_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    license_number VARCHAR(30) UNIQUE,
    phone_number VARCHAR(20),
    hire_date DATE,
    status VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    company_name VARCHAR(100),
    contact_person VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20)
);

-- ==========================================
-- 2. BASE VEHICLE TABLE
-- ==========================================
CREATE TABLE Vehicles (
    vehicle_id INT PRIMARY KEY,
    type VARCHAR(30),
    vehicle_num VARCHAR(20) UNIQUE,
    make_model VARCHAR(50),
    manufacture_year INT,
    fare_per_km DOUBLE,
    status VARCHAR(20) DEFAULT 'Active' -- Active, Maintenance, Out of Service
);

-- ==========================================
-- 3. SPECIFIC VEHICLE TABLES (Sub-types)
-- ==========================================
CREATE TABLE Buses (
    vehicle_id INT PRIMARY KEY,
    seating_capacity INT,
    is_ac BOOLEAN,
    has_wifi BOOLEAN,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id) ON DELETE CASCADE
);
CREATE TABLE Trucks (
    vehicle_id INT PRIMARY KEY,
    load_capacity_tons DOUBLE,
    truck_type VARCHAR(30), -- Flatbed, Refrigerated, Tanker, Box
    axles INT,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id) ON DELETE CASCADE
);

CREATE TABLE Taxis (
    vehicle_id INT PRIMARY KEY,
    car_class VARCHAR(30), -- Economy, Premium, SUV
    fuel_type VARCHAR(20), -- EV, Hybrid, Petrol, Diesel
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id) ON DELETE CASCADE
);

CREATE TABLE CargoVans (
    vehicle_id INT PRIMARY KEY,
    cargo_volume_m3 DOUBLE,
    max_payload_kg DOUBLE,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id) ON DELETE CASCADE
);

-- ==========================================
-- 4. OPERATIONS TABLES
-- ==========================================
CREATE TABLE Maintenance_Logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    vehicle_id INT,
    service_date DATE,
    description VARCHAR(255),
    cost DOUBLE,
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id) ON DELETE CASCADE
);

CREATE TABLE Assignments (
    assignment_id INT AUTO_INCREMENT PRIMARY KEY,
    vehicle_id INT,
    driver_id INT,
    customer_id INT,
    start_location VARCHAR(100),
    end_location VARCHAR(100),
    distance_km DOUBLE,
    total_fare DOUBLE,
    start_date DATE,
    end_date DATE,
    status VARCHAR(30) DEFAULT 'Completed', -- Planned, In Progress, Completed, Cancelled
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id) ON DELETE SET NULL,
    FOREIGN KEY (driver_id) REFERENCES Drivers(driver_id) ON DELETE SET NULL,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id) ON DELETE SET NULL
);

-- ==========================================
-- 5. INSERTING MASTER DATA
-- ==========================================

-- Insert Drivers
INSERT INTO Drivers (driver_id, first_name, last_name, license_number, phone_number, hire_date) VALUES
(101, 'Rahul', 'Sharma', 'DL-MH-1001', '9876543210', '2021-03-15'),
(102, 'Amit', 'Khan', 'DL-GJ-2002', '9876543211', '2020-08-10'),
(103, 'Priya', 'Singh', 'DL-DL-3003', '9876543212', '2022-01-20'),
(104, 'John', 'Doe', 'DL-KA-4004', '9876543213', '2019-11-05'),
(105, 'Suresh', 'Raina', 'DL-UP-5005', '9876543214', '2023-05-12');

-- Insert Customers
INSERT INTO Customers (customer_id, company_name, contact_person, email, phone) VALUES
(201, 'TechCorp Logistics', 'Alice Smith', 'alice@techcorp.com', '111-222-3333'),
(202, 'FreshFoods Inc.', 'Bob Jones', 'bob@freshfoods.com', '444-555-6666'),
(203, 'City Tours Agency', 'Charlie Brown', 'charlie@citytours.com', '777-888-9999');

-- Insert General Vehicle Info
INSERT INTO Vehicles (vehicle_id, type, vehicle_num, make_model, manufacture_year, fare_per_km, status) VALUES
(1, 'Bus', 'BUS-101', 'Volvo 9700', 2020, 15.5, 'Active'), 
(2, 'Bus', 'BUS-102', 'Tata Marcopolo', 2018, 12.0, 'Maintenance'),
(3, 'Bus', 'BUS-103', 'Scania Touring', 2022, 18.0, 'Active'),
(11, 'Truck', 'TRK-201', 'Tata Prima', 2019, 25.0, 'Active'), 
(12, 'Truck', 'TRK-202', 'Ashok Leyland Pro', 2021, 30.5, 'Active'),
(13, 'Truck', 'TRK-203', 'Mahindra Blazo', 2017, 28.0, 'Active'),
(21, 'Taxi', 'TAX-301', 'Toyota Prius', 2022, 10.0, 'Active'), 
(22, 'Taxi', 'TAX-302', 'Tesla Model 3', 2023, 12.5, 'Active'),
(23, 'Taxi', 'TAX-303', 'Honda City', 2019, 9.5, 'Maintenance'),
(31, 'CargoVan', 'VAN-401', 'Ford Transit', 2021, 14.0, 'Active'),
(32, 'CargoVan', 'VAN-402', 'Mercedes Sprinter', 2022, 15.0, 'Active');

-- Insert Bus Details
INSERT INTO Buses (vehicle_id, seating_capacity, is_ac, has_wifi) VALUES
(1, 40, TRUE, TRUE), 
(2, 50, FALSE, FALSE), 
(3, 60, TRUE, TRUE);

-- Insert Truck Details
INSERT INTO Trucks (vehicle_id, load_capacity_tons, truck_type, axles) VALUES
(11, 15.0, 'Flatbed', 4), 
(12, 25.5, 'Refrigerated', 6), 
(13, 20.0, 'Box Truck', 4);

-- Insert Taxi Details
INSERT INTO Taxis (vehicle_id, car_class, fuel_type) VALUES
(21, 'Economy', 'Hybrid'), 
(22, 'Premium', 'EV'), 
(23, 'SUV', 'Petrol');

-- Insert Cargo Van Details
INSERT INTO CargoVans (vehicle_id, cargo_volume_m3, max_payload_kg) VALUES
(31, 10.5, 1500.0), 
(32, 14.0, 2000.0);

-- Insert Maintenance Logs
INSERT INTO Maintenance_Logs (vehicle_id, service_date, description, cost) VALUES
(2, '2023-09-15', 'Engine overhaul and oil change', 2500.00),
(13, '2023-09-20', 'Brake pad replacement', 850.00),
(23, '2023-10-01', 'AC Compressor repair', 400.00),
(1, '2023-08-10', 'Routine tire alignment', 150.00);

-- Insert Assignments
INSERT INTO Assignments (vehicle_id, driver_id, customer_id, start_location, end_location, distance_km, total_fare, start_date, end_date, status) VALUES
(1, 101, 203, 'Mumbai', 'Pune', 150.0, 2325.0, '2023-10-01', '2023-10-01', 'Completed'),
(12, 102, 202, 'Delhi', 'Jaipur', 280.0, 8540.0, '2023-10-02', '2023-10-03', 'Completed'),
(22, 103, 201, 'Airport', 'City Center', 25.0, 312.5, '2023-10-03', '2023-10-03', 'Completed'),
(31, 104, 201, 'Warehouse A', 'Store B', 45.0, 630.0, '2023-10-04', '2023-10-04', 'Completed'),
(11, 105, 202, 'Factory C', 'Port D', 120.0, 3000.0, '2023-10-05', '2023-10-05', 'In Progress'),
(3, 101, 203, 'Bangalore', 'Mysore', 145.0, 2610.0, '2023-10-06', '2023-10-06', 'Planned');

-- ==========================================
-- 6. ADVANCED ANALYTICS & REPORTING QUERIES
-- ==========================================

-- Query 1: Total Revenue Generated by Vehicle Type
SELECT 
    v.type AS Vehicle_Type,
    COUNT(a.assignment_id) AS Total_Trips,
    SUM(a.distance_km) AS Total_Distance_Driven,
    SUM(a.total_fare) AS Total_Revenue
FROM Vehicles v
LEFT JOIN Assignments a ON v.vehicle_id = a.vehicle_id AND a.status = 'Completed'
GROUP BY v.type
ORDER BY Total_Revenue DESC;

-- Query 2: Driver Performance Report
SELECT 
    d.first_name, 
    d.last_name, 
    COUNT(a.assignment_id) AS Assignments_Handled,
    SUM(a.distance_km) AS Total_KMs_Driven,
    SUM(a.total_fare) AS Revenue_Generated
FROM Drivers d
JOIN Assignments a ON d.driver_id = a.driver_id
WHERE a.status = 'Completed'
GROUP BY d.driver_id
ORDER BY Revenue_Generated DESC;

-- Query 3: Customer Billing Summary (Who is our most valuable client?)
SELECT 
    c.company_name, 
    c.contact_person,
    COUNT(a.assignment_id) AS Total_Bookings,
    SUM(a.total_fare) AS Total_Billed
FROM Customers c
JOIN Assignments a ON c.customer_id = a.customer_id
GROUP BY c.customer_id
ORDER BY Total_Billed DESC;

-- Query 4: Vehicle Profitability (Revenue minus Maintenance Costs)
SELECT 
    v.vehicle_num, 
    v.type,
    IFNULL(SUM(a.total_fare), 0) AS Gross_Revenue,
    IFNULL(m.Total_Maintenance, 0) AS Maintenance_Costs,
    (IFNULL(SUM(a.total_fare), 0) - IFNULL(m.Total_Maintenance, 0)) AS Net_Profit
FROM Vehicles v
LEFT JOIN Assignments a ON v.vehicle_id = a.vehicle_id AND a.status = 'Completed'
LEFT JOIN (
    SELECT vehicle_id, SUM(cost) AS Total_Maintenance 
    FROM Maintenance_Logs 
    GROUP BY vehicle_id
) m ON v.vehicle_id = m.vehicle_id
GROUP BY v.vehicle_id, v.vehicle_num, v.type, m.Total_Maintenance
ORDER BY Net_Profit DESC;

-- Query 5: Find Available Vehicles (Not currently In Progress or in Maintenance)
SELECT 
    v.vehicle_id, 
    v.type, 
    v.vehicle_num, 
    v.make_model
FROM Vehicles v
WHERE v.status = 'Active' 
  AND v.vehicle_id NOT IN (
      SELECT vehicle_id 
      FROM Assignments 
      WHERE status = 'In Progress'
  );
  
select * from buses; 
select * from Trucks;
select*from Drivers;
select*from Assignments;