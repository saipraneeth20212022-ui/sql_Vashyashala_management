-- ============================================================
-- FILE: 02_raw_data_insert.sql
-- PURPOSE: Insert realistic MESSY raw data (like real imports)
-- Intentional issues: nulls, wrong cases, duplicates, bad formats
-- ============================================================

USE HospitalDB;
GO

-- DEPARTMENTS
INSERT INTO Departments (DeptName, DeptHead, Floor, MaxBeds) VALUES
('Cardiology',         'Dr. Ramesh Iyer',    3, 40),
('Neurology',          'Dr. Sunita Rao',     4, 30),
('Orthopedics',        'DR. VIKRAM NAIR',    2, 35),  -- messy case
('Emergency',          NULL,                 1, 60),  -- missing head
('Pediatrics',         'dr. ananya shetty',  5, 25),  -- lowercase
('oncology',           'Dr. Priya Menon',    6, 20),  -- lowercase dept
('Radiology',          'Dr. Arjun Das',      2,  0),
('General Surgery',    'Dr. Kavitha Reddy',  3, 45);

-- DOCTORS (some have bad phone formats, missing emails)
INSERT INTO Doctors (FirstName, LastName, Specialization, DepartmentID, Phone, Email, HireDate, Salary) VALUES
('Ramesh',   'Iyer',     'Cardiologist',    1, '9849123456',        'ramesh.iyer@hospital.com',   '2015-03-12', 180000),
('Sunita',   'Rao',      'Neurologist',     2, '9849-234-567',      'sunita.rao@hospital.com',    '2017-07-01', 175000),
('Vikram',   'Nair',     'Orthopedic',      3, '(98) 4934-5678',    NULL,                         '2016-01-15', 160000),  -- no email
('Priya',    'Menon',    'Oncologist',      6, '9849456789',        'priya@hospital.com',         '2019-09-20', 195000),
('Ananya',   'Shetty',   'Pediatrician',    5, '9849567890',        'ananya.shetty@hospital.com', '2020-04-10', 140000),
('Arjun',    'Das',      'Radiologist',     7, 'N/A',               'arjun.das@hospital.com',     '2014-06-30', 130000),  -- bad phone
('Kavitha',  'Reddy',    'Surgeon',         8, '9849789012',        'kavitha.r@hospital.com',     '2013-11-25', 210000),
('Mohan',    'Krishnan', 'Cardiologist',    1, '9849890123',        'mohan.k@hospital.com',       '2021-02-28', 170000),
('Deepa',    'Varma',    'Neurologist',     2, NULL,                'deepa.varma@hospital.com',   '2022-05-17', 165000),  -- no phone
('Rahul',    'Sharma',   'Emergency Med',   4, '9849012345',        'rahul.s@hospital.com',       '2018-08-08', 155000);

-- PATIENTS (messy: duplicates, wrong gender codes, mixed case names)
INSERT INTO Patients (FirstName, LastName, DOB, Gender, BloodGroup, Phone, Email, City, InsuranceID) VALUES
('Arun',      'Kumar',    '1985-04-20', 'M', 'O+',  '9000111111', 'arun.k@email.com',     'Hyderabad', 'INS-10021'),
('SUNITA',    'DEVI',     '1990-08-15', 'F', 'A+',  '9000222222', 'sunita.d@email.com',   'HYDERABAD', 'INS-10022'),  -- all caps
('Ravi',      'Teja',     '1978-12-01', 'M', 'B+',  '9000333333', NULL,                   'Warangal',  NULL),
('Meena',     'Reddy',    '2001-03-10', 'F', 'AB-', '9000444444', 'meena.r@email.com',    'Karimnagar','INS-10024'),
('arun',      'kumar',    '1985-04-20', 'M', 'O+',  '9000111111', 'arun.k@email.com',     'hyderabad', 'INS-10021'),  -- DUPLICATE of row 1
('Sai',       'Prasad',   '1995-06-25', 'X', 'A-',  '9000666666', 'sai.p@email.com',      'Nizamabad', 'INS-10026'),  -- bad gender
('Lakshmi',   'Naidu',    '1970-11-30', 'F', 'O-',  NULL,         'lakshmi.n@email.com',  'Hyderabad', 'INS-10027'),
('Kiran',     'Rao',      '1988-07-14', 'M', 'B-',  '9000888888', 'kiran.rao@email.com',  'Secunderabad','INS-10028'),
('Pooja',     'Sharma',   '2000-01-01', 'F', 'A+',  '9000999999', NULL,                   'Hyderabad', NULL),
('Naresh',    'Babu',     '1965-09-09', 'M', 'AB+', '9001000000', 'naresh.b@email.com',   'Hyderabad', 'INS-10030'),
('Deepa',     'Singh',    '1993-05-18', 'F', 'O+',  '9001111111', 'deepa.s@email.com',    'Hyderabad', 'INS-10031'),
('Venkat',    'Rao',      '1975-02-28', 'M', NULL,  '9001222222', 'venkat.r@email.com',   'Hyderabad', 'INS-10032'),  -- no blood group
('Anjali',    'Patel',    '1998-10-10', 'F', 'B+',  '9001333333', 'anjali.p@email.com',   'Mumbai',    'INS-10033'),
('Suresh',    'Goud',     '1982-03-22', 'M', 'A-',  '9001444444', 'suresh.g@email.com',   'Hyderabad', 'INS-10034'),
('Bhavana',   'Reddy',    '2003-07-07', 'F', 'O+',  '9001555555', NULL,                   'Hyderabad', 'INS-10035');

-- ADMISSIONS
INSERT INTO Admissions (PatientID, DoctorID, DepartmentID, AdmissionDate, DischargeDate, AdmissionType, Diagnosis, RoomNumber, BedType, Status) VALUES
(1,  1, 1, '2024-01-05 09:00', '2024-01-10 11:00', 'Emergency',  'Acute MI',               'C101', 'ICU',     'Discharged'),
(2,  2, 2, '2024-01-07 14:00', '2024-01-15 10:00', 'Elective',   'Epilepsy Monitoring',    'N201', 'General', 'Discharged'),
(3,  7, 8, '2024-01-10 11:00', '2024-01-13 09:00', 'Emergency',  'Appendicitis',           'S301', 'General', 'Discharged'),
(4,  5, 5, '2024-01-12 08:00', NULL,               'Elective',   'Tonsillectomy',          'P401', 'Private', 'Active'),
(6,  1, 1, '2024-01-14 16:00', '2024-01-20 12:00', 'Emergency',  'Angina Pectoris',        'C102', 'ICU',     'Discharged'),
(7,  3, 3, '2024-01-18 10:00', '2024-01-25 14:00', 'Elective',   'Hip Replacement',        'O101', 'Private', 'Discharged'),
(8,  8, 1, '2024-01-20 07:00', '2024-01-24 09:00', 'Emergency',  'Heart Failure',          'C103', 'ICU',     'Discharged'),
(1,  1, 1, '2024-02-01 10:00', '2024-02-05 11:00', 'Emergency',  'Post MI Follow-up',      'C104', 'ICU',     'Discharged'),  -- readmission!
(9,  4, 6, '2024-02-03 09:00', '2024-02-18 10:00', 'Elective',   'Chemotherapy Cycle 1',   'ON101','General', 'Discharged'),
(10, 2, 2, '2024-02-10 11:00', NULL,               'Emergency',  'Stroke',                 'N202', 'ICU',     'Active'),
(11, 7, 8, '2024-02-14 13:00', '2024-02-17 10:00', 'Elective',   'Gallbladder Removal',    'S302', 'General', 'Discharged'),
(12, 1, 1, '2024-02-20 08:00', '2024-02-26 10:00', 'Emergency',  'Myocarditis',            'C105', 'ICU',     'Discharged'),
(13, 3, 3, '2024-03-01 09:00', '2024-03-08 11:00', 'Elective',   'Knee Replacement',       'O102', 'Private', 'Discharged'),
(14, 10,4, '2024-03-05 20:00', '2024-03-06 08:00', 'Emergency',  'Fracture',               'E101', 'General', 'Discharged'),
(15, 5, 5, '2024-03-10 08:00', NULL,               'Elective',   'Asthma Management',      'P402', 'General', 'Active');

-- BILLING
INSERT INTO Billing (AdmissionID, PatientID, RoomCharges, MedicineCharges, DoctorFee, LabCharges, InsuranceCovered, PaymentStatus) VALUES
(1,  1,  15000, 8000, 5000, 3000, 20000, 'Paid'),
(2,  2,  12000, 4000, 4500, 2000, 15000, 'Paid'),
(3,  3,  8000,  6000, 3500, 1500, 10000, 'Partial'),
(5,  6,  18000, 9000, 5000, 4000, 25000, 'Paid'),
(6,  7,  25000, 5000, 8000, 2000, 30000, 'Paid'),
(7,  8,  20000, 10000,5000, 5000, 28000, 'Partial'),
(8,  1,  16000, 7000, 5000, 3500, 18000, 'Pending'),  -- readmission billing
(9,  9,  30000, 15000,6000, 8000, 40000, 'Paid'),
(11, 11, 9000,  5000, 3500, 1500,  8000, 'Paid'),
(12, 12, 19000, 8000, 5000, 4000, 22000, 'Paid'),
(13, 13, 22000, 6000, 8000, 3000, 25000, 'Partial'),
(14, 14, 5000,  3000, 2000,  500,  5000, 'Paid'),
(4,  4,  NULL,  2000, 3000, 1000,  5000, 'Pending'); -- NULL room charges (messy)

-- LAB TESTS
INSERT INTO LabTests (AdmissionID, TestName, OrderedBy, Result, IsAbnormal, Cost) VALUES
(1, 'ECG',              1, 'ST elevation noted',    1, 800),
(1, 'Troponin I',       1, '2.4 ng/mL - HIGH',      1, 1200),
(1, 'CBC',              1, 'Normal',                 0, 500),
(2, 'EEG',              2, 'Abnormal spikes',        1, 2000),
(3, 'CT Abdomen',       7, 'Appendix inflamed',      1, 3500),
(5, 'Angiography',      1, 'Blockage 70%',           1, 8000),
(7, 'Echo',             8, 'EF 35% - reduced',       1, 2500),
(8, 'Troponin I',       1, '0.8 ng/mL',              1, 1200),
(9, 'CA-125',           4, 'Elevated',               1, 1500),
(10,'MRI Brain',        2, 'Ischemic stroke R side', 1, 5000),
(12,'Cardiac MRI',      1, 'Inflammation noted',     1, 6000);

PRINT 'Raw data inserted (with intentional data quality issues).';
GO