-- ============================================================
-- FILE: 09_triggers.sql
-- PURPOSE: Audit trail + business rule enforcement via triggers
-- ============================================================

USE HospitalDB;
GO

-- ?????????????????????????????????????????????
-- TRIGGER 1: Log every new admission
-- ?????????????????????????????????????????????
CREATE OR ALTER TRIGGER trg_Admissions_AfterInsert
ON Admissions
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO AuditLog (TableName, ActionType, RecordID, NewValues)
    SELECT 
        'Admissions',
        'INSERT',
        i.AdmissionID,
        CONCAT(
            'PatientID=', i.PatientID,
            ' | DoctorID=', i.DoctorID,
            ' | Diagnosis=', i.Diagnosis,
            ' | AdmDate=', CAST(i.AdmissionDate AS VARCHAR)
        )
    FROM inserted i;
END;
GO

-- ?????????????????????????????????????????????
-- TRIGGER 2: Log admission updates (status changes, discharge)
-- ?????????????????????????????????????????????
CREATE OR ALTER TRIGGER trg_Admissions_AfterUpdate
ON Admissions
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO AuditLog (TableName, ActionType, RecordID, OldValues, NewValues)
    SELECT
        'Admissions',
        'UPDATE',
        i.AdmissionID,
        CONCAT(
            'Status=', d.Status,
            ' | DischargeDate=', ISNULL(CAST(d.DischargeDate AS VARCHAR), 'NULL')
        ),
        CONCAT(
            'Status=', i.Status,
            ' | DischargeDate=', ISNULL(CAST(i.DischargeDate AS VARCHAR), 'NULL')
        )
    FROM inserted i
    JOIN deleted d ON i.AdmissionID = d.AdmissionID
    WHERE i.Status <> d.Status 
       OR ISNULL(CAST(i.DischargeDate AS VARCHAR),'') <> ISNULL(CAST(d.DischargeDate AS VARCHAR),'');
END;
GO

-- ?????????????????????????????????????????????
-- TRIGGER 3: Business rule — prevent billing
-- if patient is still active (not discharged)
-- ?????????????????????????????????????????????
CREATE OR ALTER TRIGGER trg_Billing_PreventActiveBill
ON Billing
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check for any active admissions in the inserted set
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN Admissions a ON i.AdmissionID = a.AdmissionID
        WHERE a.Status = 'Active'
    )
    BEGIN
        RAISERROR('Cannot create final bill for an Active admission. Discharge the patient first.', 16, 1);
        RETURN;
    END

    -- If validation passes, proceed with insert
    INSERT INTO Billing (AdmissionID, PatientID, RoomCharges, MedicineCharges,
                         DoctorFee, LabCharges, InsuranceCovered, PaymentStatus, BillDate)
    SELECT AdmissionID, PatientID, RoomCharges, MedicineCharges,
           DoctorFee, LabCharges, InsuranceCovered, PaymentStatus, GETDATE()
    FROM inserted;

    -- Log it
    INSERT INTO AuditLog (TableName, ActionType, RecordID, NewValues)
    SELECT 'Billing', 'INSERT', b.BillID, 
           CONCAT('Total=', b.TotalAmount, ' | Status=', b.PaymentStatus)
    FROM Billing b
    WHERE b.BillDate >= CAST(GETDATE() AS DATE);
END;
GO

-- ?????????????????????????????????????????????
-- TRIGGER 4: Salary change audit on Doctors table
-- ?????????????????????????????????????????????
CREATE OR ALTER TRIGGER trg_Doctors_SalaryAudit
ON Doctors
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(Salary)
    BEGIN
        INSERT INTO AuditLog (TableName, ActionType, RecordID, OldValues, NewValues)
        SELECT
            'Doctors',
            'UPDATE',
            i.DoctorID,
            'Salary=' + CAST(d.Salary AS VARCHAR),
            'Salary=' + CAST(i.Salary AS VARCHAR)
        FROM inserted i
        JOIN deleted d ON i.DoctorID = d.DoctorID
        WHERE i.Salary <> d.Salary;
    END
END;
GO

-- Test it — update a salary and check audit log
UPDATE Doctors SET Salary = 200000 WHERE DoctorID = 1;
SELECT * FROM AuditLog ORDER BY ChangedAt DESC;
GO