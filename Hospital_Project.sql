
-- 1. Create Database
CREATE DATABASE IF NOT EXISTS HospitalDB;
USE HospitalDB;

-- 2. Create Tables
CREATE TABLE IF NOT EXISTS Patients (
    patient_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    DOB DATE NOT NULL,
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    contact VARCHAR(15),
    blood_group VARCHAR(5),
    address TEXT
);

CREATE TABLE IF NOT EXISTS Doctors (
    doctor_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    specialization VARCHAR(100),
    department_id INT,
    contact VARCHAR(15)
);

CREATE TABLE IF NOT EXISTS Departments (
    department_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    floor INT,
    head_doctor_id INT
);

CREATE TABLE IF NOT EXISTS Appointments (
    appointment_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT,
    doctor_id INT,
    appointment_date DATE NOT NULL,
    status ENUM('Scheduled', 'Completed', 'Cancelled') DEFAULT 'Scheduled',
    notes TEXT,
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES Doctors(doctor_id)
);

CREATE TABLE IF NOT EXISTS Medical_Records (
    record_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT,
    diagnosis TEXT,
    prescription TEXT,
    visit_date DATE NOT NULL,
    doctor_id INT,
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES Doctors(doctor_id)
);

CREATE TABLE IF NOT EXISTS Billing (
    bill_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT,
    amount DECIMAL(10,2),
    bill_date DATE NOT NULL,
    payment_status ENUM('Pending', 'Paid') DEFAULT 'Pending',
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id)
);

CREATE TABLE IF NOT EXISTS Appointment_Log (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    appointment_id INT,
    old_status VARCHAR(50),
    new_status VARCHAR(50),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Indexes for Optimization
CREATE INDEX idx_appointment_date ON Appointments(appointment_date);
CREATE INDEX idx_doctor_specialization ON Doctors(specialization);
CREATE INDEX idx_patient_name ON Patients(name);

-- 4. Insert Sample Data
INSERT INTO Patients (name, DOB, gender, contact, blood_group, address) VALUES
('John Doe', '1985-05-10', 'Male', '9876543210', 'O+', '123 Main St'),
('Jane Smith', '1990-08-15', 'Female', '8765432109', 'A+', '456 Elm St'),
('Amit Kumar', '1978-02-20', 'Male', '7654321098', 'B-', '789 Pine St');

INSERT INTO Departments (name, floor) VALUES
('Cardiology', 2),
('Neurology', 3),
('Orthopedics', 4);

INSERT INTO Doctors (name, specialization, department_id, contact) VALUES
('Dr. Rahul Sharma', 'Cardiologist', 1, '9876500000'),
('Dr. Priya Mehta', 'Neurologist', 2, '9876500001'),
('Dr. Kiran Rao', 'Orthopedic Surgeon', 3, '9876500002');

INSERT INTO Appointments (patient_id, doctor_id, appointment_date, status, notes) VALUES
(1, 1, '2025-08-12', 'Scheduled', 'Regular check-up'),
(2, 2, '2025-08-13', 'Scheduled', 'Headache issue'),
(3, 3, '2025-08-14', 'Scheduled', 'Knee pain');

INSERT INTO Billing (patient_id, amount, bill_date, payment_status) VALUES
(1, 2000.00, '2025-08-12', 'Pending'),
(2, 3500.00, '2025-08-13', 'Pending'),
(3, 1500.00, '2025-08-14', 'Pending');

-- 5. Stored Procedures
DELIMITER //
CREATE PROCEDURE GenerateBill(IN p_patient_id INT, IN p_amount DECIMAL(10,2))
BEGIN
    INSERT INTO Billing (patient_id, amount, bill_date, payment_status)
    VALUES (p_patient_id, p_amount, CURDATE(), 'Pending');
END //

CREATE PROCEDURE ScheduleAppointment(IN p_patient_id INT, IN p_doctor_id INT, IN p_date DATE, IN p_notes TEXT)
BEGIN
    INSERT INTO Appointments (patient_id, doctor_id, appointment_date, notes)
    VALUES (p_patient_id, p_doctor_id, p_date, p_notes);
END //

CREATE PROCEDURE UpdateMedicalRecord(IN p_patient_id INT, IN p_diagnosis TEXT, IN p_prescription TEXT, IN p_doctor_id INT)
BEGIN
    INSERT INTO Medical_Records (patient_id, diagnosis, prescription, visit_date, doctor_id)
    VALUES (p_patient_id, p_diagnosis, p_prescription, CURDATE(), p_doctor_id);
END //
DELIMITER ;

-- 6. Triggers
DELIMITER //
CREATE TRIGGER update_payment_status
BEFORE UPDATE ON Billing
FOR EACH ROW
BEGIN
    IF NEW.amount = 0 THEN
        SET NEW.payment_status = 'Paid';
    END IF;
END //

CREATE TRIGGER log_appointment_changes
BEFORE UPDATE ON Appointments
FOR EACH ROW
BEGIN
    IF OLD.status <> NEW.status THEN
        INSERT INTO Appointment_Log (appointment_id, old_status, new_status)
        VALUES (OLD.appointment_id, OLD.status, NEW.status);
    END IF;
END //
DELIMITER ;

-- 7. Analytics Views
CREATE OR REPLACE VIEW DailySummary AS
SELECT 
    CURDATE() AS report_date,
    COUNT(*) AS total_appointments,
    SUM(amount) AS total_revenue
FROM Appointments a
JOIN Billing b ON a.patient_id = b.patient_id
WHERE appointment_date = CURDATE();

CREATE OR REPLACE VIEW TopDoctors AS
SELECT d.name, COUNT(a.appointment_id) AS total_appointments
FROM Doctors d
JOIN Appointments a ON d.doctor_id = a.doctor_id
GROUP BY d.name
ORDER BY total_appointments DESC
LIMIT 5;

CREATE OR REPLACE VIEW RevenueByDepartment AS
SELECT dep.name AS department, SUM(b.amount) AS total_revenue
FROM Departments dep
JOIN Doctors doc ON dep.department_id = doc.department_id
JOIN Appointments a ON doc.doctor_id = a.doctor_id
JOIN Billing b ON a.patient_id = b.patient_id
GROUP BY dep.name;

-- 8. Example Advanced Queries
-- Monthly revenue trend
-- SELECT DATE_FORMAT(bill_date, '%Y-%m') AS month, SUM(amount) AS total_revenue
-- FROM Billing
-- GROUP BY month
-- ORDER BY month DESC;

-- Average treatment cost per department
-- SELECT dep.name, AVG(b.amount) AS avg_cost
-- FROM Departments dep
-- JOIN Doctors doc ON dep.department_id = doc.department_id
-- JOIN Appointments a ON doc.doctor_id = a.doctor_id
-- JOIN Billing b ON a.patient_id = b.patient_id
-- GROUP BY dep.name;
