-- ============================================================
-- FILE: 10_tsql_advanced.sql
-- PURPOSE: T-SQL advanced features used in real analyst work
-- Covers: TRY/CATCH, temp tables, table variables,
--         WHILE loops, cursors, dynamic SQL
-- ============================================================

USE HospitalDB;
GO

-- ?????????????????????????????????????????????
-- TEMP TABLE: Monthly admission summary
-- (Temp tables survive the session, not just the query)
-- ?????????????????????????????????????????????
DROP TABLE IF EXISTS #MonthlyAdmissions;

SELECT
    FORMAT(AdmissionDate, 'yyyy-MM') AS AdmMonth,
    DepartmentID,
    COUNT(*)                          AS Admissions,
    SUM(CASE WHEN BedType = 'ICU'     THEN 1 ELSE 0 END) AS ICU_Count,
    SUM(CASE WHEN AdmissionType = 'Emergency' THEN 1 ELSE 0 END) AS Emergency_Count
INTO #MonthlyAdmissions
FROM Admissions
GROUP BY FORMAT(AdmissionDate,'yyyy-MM'), DepartmentID;

SELECT m.*, d.DeptName
FROM #MonthlyAdmissions m
JOIN Departments d ON m.DepartmentID = d.DepartmentID
ORDER BY AdmMonth, DeptName;
GO

-- ?????????????????????????????????????????????
-- TABLE VARIABLE: Quick in-memory lookup
-- ?????????????????????????????????????????????
DECLARE @HighRiskDepts TABLE (
    DeptID   INT,
    DeptName VARCHAR(100),
    Reason   VARCHAR(100)
);

INSERT INTO @HighRiskDepts VALUES
(1, 'Cardiology', 'High ICU utilization'),
(2, 'Neurology',  'Complex diagnoses'),
(4, 'Emergency',  'High volume');

SELECT 
    a.AdmissionID,
    p.FirstName + ' ' + p.LastName AS Patient,
    a.Diagnosis,
    hr.Reason AS DeptRiskReason
FROM Admissions a
JOIN Patients p ON a.PatientID = a.PatientID
JOIN @HighRiskDepts hr ON a.DepartmentID = hr.DeptID;
GO

-- ?????????????????????????????????????????????
-- TRY / CATCH: Safe procedure execution with rollback
-- ?????????????????????????????????????????????
BEGIN TRY
    BEGIN TRANSACTION;

    -- Simulate a business operation
    UPDATE Billing SET PaymentStatus = 'Paid'
    WHERE PaymentStatus = 'Pending'
      AND AmountDue = 0;  -- only zero-balance pending bills

    -- Force a simulated error to test CATCH (comment out for normal run)
    -- DECLARE @x INT = 1/0;

    COMMIT TRANSACTION;
    PRINT 'Transaction committed: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' bills updated.';

END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'ERROR: ' + ERROR_MESSAGE();
    PRINT 'Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR);
    PRINT 'Line: '     + CAST(ERROR_LINE()     AS VARCHAR);

    -- Insert into error log
    INSERT INTO AuditLog (TableName, ActionType, RecordID, NewValues)
    VALUES ('Billing', 'ERROR', 0, 
            CONCAT('Msg=', ERROR_MESSAGE(), 
                   ' | Line=', ERROR_LINE()));
END CATCH;
GO

-- ?????????????????????????????????????????????
-- WHILE LOOP: Generate monthly occupancy stats
-- ?????????????????????????????????????????????
DECLARE @StartMonth DATE = '2024-01-01';
DECLARE @EndMonth   DATE = '2024-03-01';
DECLARE @Current    DATE = @StartMonth;

DROP TABLE IF EXISTS #OccupancyByMonth;
CREATE TABLE #OccupancyByMonth (
    ReportMonth   VARCHAR(7),
    TotalBeds     INT,
    OccupiedBeds  INT,
    OccupancyPct  DECIMAL(5,2)
);

WHILE @Current <= @EndMonth
BEGIN
    DECLARE @Occupied INT, @Total INT;

    SELECT @Occupied = COUNT(*)
    FROM Admissions
    WHERE AdmissionDate <= EOMONTH(@Current)
      AND (DischargeDate IS NULL OR DischargeDate >= @Current);

    SELECT @Total = SUM(MaxBeds) FROM Departments;

    INSERT INTO #OccupancyByMonth
    VALUES (FORMAT(@Current,'yyyy-MM'), @Total, @Occupied,
            CASE WHEN @Total = 0 THEN 0 
                 ELSE ROUND(@Occupied * 100.0 / @Total, 2) END);

    SET @Current = DATEADD(MONTH, 1, @Current);
END

SELECT * FROM #OccupancyByMonth ORDER BY ReportMonth;
GO

-- ?????????????????????????????????????????????
-- CURSOR: Process each doctor and print workload
-- (Used when row-by-row logic is unavoidable)
-- ?????????????????????????????????????????????
DECLARE @DocID    INT;
DECLARE @DocName  VARCHAR(100);
DECLARE @PtCount  INT;

DECLARE doctor_cursor CURSOR FOR
    SELECT DoctorID, FirstName + ' ' + LastName
    FROM Doctors
    WHERE IsActive = 1;

OPEN doctor_cursor;
FETCH NEXT FROM doctor_cursor INTO @DocID, @DocName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @PtCount = COUNT(*)
    FROM Admissions
    WHERE DoctorID = @DocID;

    PRINT @DocName + ' handles ' + CAST(@PtCount AS VARCHAR) + ' admission(s).';

    FETCH NEXT FROM doctor_cursor INTO @DocID, @DocName;
END

CLOSE doctor_cursor;
DEALLOCATE doctor_cursor;
GO

-- ?????????????????????????????????????????????
-- DYNAMIC SQL: Build a pivot report at runtime
-- Pivots departments as columns for any date range
-- ?????????????????????????????????????????????
DECLARE @Cols      NVARCHAR(MAX) = '';
DECLARE @Query     NVARCHAR(MAX) = '';

SELECT @Cols = @Cols + QUOTENAME(DeptName) + ','
FROM Departments
ORDER BY DepartmentID;

SET @Cols = LEFT(@Cols, LEN(@Cols) - 1);  -- remove trailing comma

SET @Query = '
SELECT AdmMonth, ' + @Cols + '
FROM (
    SELECT 
        FORMAT(a.AdmissionDate,''yyyy-MM'') AS AdmMonth,
        dep.DeptName,
        COUNT(a.AdmissionID) AS Admissions
    FROM Admissions a
    JOIN Departments dep ON a.DepartmentID = dep.DepartmentID
    GROUP BY FORMAT(a.AdmissionDate,''yyyy-MM''), dep.DeptName
) AS SourceData
PIVOT (
    SUM(Admissions)
    FOR DeptName IN (' + @Cols + ')
) AS PivotTable
ORDER BY AdmMonth;';

EXEC sp_executesql @Query;
GO