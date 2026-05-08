-- ============================================================
-- FILE: 08_stored_procedures.sql
-- PURPOSE: Reusable stored procedures — real analyst workflows
-- ============================================================

USE HospitalDB;
GO

-- ?????????????????????????????????????????????
-- SP 1: Admit a new patient
-- Handles insertion + basic validation
-- ?????????????????????????????????????????????
CREATE OR ALTER PROCEDURE usp_AdmitPatient
    @PatientID    INT,
    @DoctorID     INT,
    @DeptID       INT,
    @AdmType      VARCHAR(20),
    @Diagnosis    VARCHAR(255),
    @RoomNo       VARCHAR(10),
    @BedType      VARCHAR(20),
    @AdmissionID  INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate patient exists
    IF NOT EXISTS (SELECT 1 FROM Patients WHERE PatientID = @PatientID)
    BEGIN
        RAISERROR('Patient ID %d does not exist.', 16, 1, @PatientID);
        RETURN;
    END

    -- Validate doctor is active
    IF NOT EXISTS (SELECT 1 FROM Doctors WHERE DoctorID = @DoctorID AND IsActive = 1)
    BEGIN
        RAISERROR('Doctor ID %d is not active.', 16, 1, @DoctorID);
        RETURN;
    END

    INSERT INTO Admissions (PatientID, DoctorID, DepartmentID, AdmissionDate,
                            AdmissionType, Diagnosis, RoomNumber, BedType, Status)
    VALUES (@PatientID, @DoctorID, @DeptID, GETDATE(),
            @AdmType, @Diagnosis, @RoomNo, @BedType, 'Active');

    SET @AdmissionID = SCOPE_IDENTITY();

    PRINT 'Patient admitted. AdmissionID: ' + CAST(@AdmissionID AS VARCHAR);
END;
GO

-- ?????????????????????????????????????????????
-- SP 2: Discharge a patient and create bill
-- ?????????????????????????????????????????????
CREATE OR ALTER PROCEDURE usp_DischargePatient
    @AdmissionID      INT,
    @RoomCharges      DECIMAL(10,2),
    @MedCharges       DECIMAL(10,2),
    @DoctorFee        DECIMAL(10,2),
    @LabCharges       DECIMAL(10,2),
    @InsuranceCovered DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PatientID INT;
    DECLARE @Status    VARCHAR(20);

    SELECT @PatientID = PatientID, @Status = Status
    FROM Admissions WHERE AdmissionID = @AdmissionID;

    IF @PatientID IS NULL
    BEGIN
        RAISERROR('Admission ID %d not found.', 16, 1, @AdmissionID);
        RETURN;
    END

    IF @Status <> 'Active'
    BEGIN
        RAISERROR('Patient is not currently active. Status: %s', 16, 1, @Status);
        RETURN;
    END

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Update discharge
        UPDATE Admissions
        SET DischargeDate = GETDATE(), Status = 'Discharged'
        WHERE AdmissionID = @AdmissionID;

        -- Create bill
        INSERT INTO Billing (AdmissionID, PatientID, RoomCharges, MedicineCharges, 
                             DoctorFee, LabCharges, InsuranceCovered, PaymentStatus)
        VALUES (@AdmissionID, @PatientID, @RoomCharges, @MedCharges, 
                @DoctorFee, @LabCharges, @InsuranceCovered, 'Pending');

        COMMIT TRANSACTION;
        PRINT 'Patient discharged and bill created.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Discharge failed: %s', 16, 1, @Err);
    END CATCH;
END;
GO

-- ?????????????????????????????????????????????
-- SP 3: Department performance report
-- (Parameterized — pass in any dept or NULL for all)
-- ?????????????????????????????????????????????
CREATE OR ALTER PROCEDURE usp_DeptPerformanceReport
    @DeptID      INT = NULL,
    @StartDate   DATE = NULL,
    @EndDate     DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SET @StartDate = ISNULL(@StartDate, '2000-01-01');
    SET @EndDate   = ISNULL(@EndDate,   GETDATE());

    SELECT
        dep.DeptName,
        COUNT(DISTINCT a.AdmissionID)           AS TotalAdmissions,
        COUNT(DISTINCT a.PatientID)             AS UniquePatients,
        AVG(DATEDIFF(DAY, a.AdmissionDate, 
            ISNULL(a.DischargeDate, GETDATE()))) AS AvgLOS,
        ISNULL(SUM(b.TotalAmount), 0)           AS TotalRevenue,
        COUNT(DISTINCT d.DoctorID)              AS DoctorsInvolved,
        SUM(CASE WHEN a.BedType = 'ICU' THEN 1 ELSE 0 END) AS ICUAdmissions
    FROM Departments dep
    LEFT JOIN Admissions  a   ON dep.DepartmentID  = a.DepartmentID
                              AND a.AdmissionDate BETWEEN @StartDate AND @EndDate
    LEFT JOIN Billing     b   ON a.AdmissionID     = b.AdmissionID
    LEFT JOIN Doctors     d   ON a.DoctorID        = d.DoctorID
    WHERE (@DeptID IS NULL OR dep.DepartmentID = @DeptID)
    GROUP BY dep.DeptName
    ORDER BY TotalRevenue DESC;
END;
GO

-- Test the procedures:
-- EXEC usp_DeptPerformanceReport;                         -- all depts
-- EXEC usp_DeptPerformanceReport @DeptID = 1;             -- cardiology only
-- EXEC usp_DeptPerformanceReport @StartDate = '2024-02-01', @EndDate = '2024-02-28';
GO