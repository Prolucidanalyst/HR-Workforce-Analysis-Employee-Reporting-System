--Data Quality Investigation
  --Duplicates
SELECT BusinessEntityID, COUNT(*) AS Duplicate_count 
FROM HumanResources.Employee
GROUP BY BusinessEntityID
HAVING COUNT(*) > 1

SELECT BusinessEntityID, COUNT(*) AS Duplicate_count 
FROM HumanResources.EmployeeDepartmentHistory
GROUP BY BusinessEntityID
HAVING COUNT(*) > 1
  --End date and start date
SELECT BusinessEntityId
FROM HumanResources.EmployeeDepartmentHistory
WHERE enddate < startdate
  --Employees Missing Department History
SELECT e.BusinessEntityId,edh.departmentid,Jobtitle,Startdate,EndDate
FROM HumanResources.Employee e
JOIN HumanResources.EmployeeDepartmentHistory edh
ON e.BusinessEntityID = edh.BusinessEntityID
WHERE e.BusinessEntityID IS NULL OR edh.BusinessEntityID IS NULL
--Employee's age
CREATE FUNCTION Age(@BirthDate Date)
RETURNS int
AS
BEGIN
DECLARE @Age int
SET @Age= DATEDIFF(YEAR,@BirthDate,GETDATE())-
    CASE
    WHEN MONTH(@BirthDate) > MONTH(GETDATE()) OR
    (MONTH(@BirthDate) = MONTH(GETDATE()) AND DAY(@Birthdate) > DAY(GETDATE()))
    THEN 1
    ELSE 0
    END
    RETURN @Age
END
--Years of Service
CREATE FUNCTION Years(@HireDate Date)
RETURNS int
AS
BEGIN
DECLARE @Years int
SET @Years= DATEDIFF(YEAR,@HireDate,GETDATE())-
  CASE
  WHEN MONTH(@HireDate) > MONTH(GETDATE()) OR
  (MONTH(@HireDate) = MONTH(GETDATE()) AND DAY(@HireDate) > DAY(GETDATE()))
  THEN 1
  ELSE 0
  END
  RETURN @Years
END
--Hiring Period
CREATE FUNCTION HirePeriod(@HireDate Date)
RETURNS NVARCHAR (10)
AS
BEGIN
DECLARE @HirePeriod NVARCHAR (10)
SET @Hireperiod = 
CASE
 WHEN CAST(DATENAME(YEAR, @HireDate) as int) < 2010
 THEN 'Before 2010'
 WHEN CAST(DATENAME(YEAR, @HireDate) as int) >= 2010 AND CAST(DATENAME(YEAR, @HireDate) as int) < 2015
 THEN '2010-2014'
 WHEN CAST(DATENAME(YEAR, @HireDate) as int) >= 2015 AND CAST(DATENAME(YEAR, @HireDate) as int) < 2020
 THEN '2015-2019'
 Else '2020+'
 END
 RETURN @Hireperiod
END

--Department Assignment
SELECT e.BusinessEntityId,edh.departmentid,Jobtitle,Startdate,EndDate
FROM HumanResources.Employee e
JOIN HumanResources.EmployeeDepartmentHistory edh
ON e.BusinessEntityID = edh.BusinessEntityID

SELECT e.BusinessEntityId, Jobtitle,edh.departmentid,Startdate,EndDate
FROM HumanResources.Employee e
JOIN HumanResources.EmployeeDepartmentHistory edh
ON e.BusinessEntityID = edh.BusinessEntityID
WHERE enddate IS NOT NULL
--Employees Without Departmnt History
SELECT e.BusinessEntityId,edh.departmentid,Jobtitle,Startdate,EndDate
FROM HumanResources.Employee e
JOIN HumanResources.EmployeeDepartmentHistory edh
ON e.BusinessEntityID = edh.BusinessEntityID
WHERE e.BusinessEntityID IS NULL OR edh.BusinessEntityID IS NULL
--Years in current Department
CREATE FUNCTION YearsInCurrentDepartment(@Startdate Date)
RETURNS INT
AS
BEGIN
  DECLARE @YearsInCurrentDepartment INT
  SET @YearsInCurrentDepartment = DATEDIFF(YEAR,@StartDate,GETDATE())-
  CASE
  WHEN MONTH(@StartDate) > MONTH(GETDATE()) OR
  (MONTH(@StartDate) = MONTH(GETDATE()) AND DAY(@StartDate) > DAY(GETDATE()))
  THEN 1
  ELSE 0
  END
  RETURN @YearsInCurrentDepartment
END
SELECT jobtitle, dbo.YearsInCurrentDepartment(Startdate) FROM HumanResources.EmployeeDepartmentHistory
--Department Assignment History
SELECT e.BusinessEntityId, COUNT(edh.DepartmentID) AS NumberOfDepartmentAssignment
FROM HumanResources.Employee e
JOIN HumanResources.EmployeeDepartmentHistory edh
ON e.BusinessEntityID = edh.BusinessEntityID
GROUP BY e.BusinessEntityId
HAVING  COUNT(edh.DepartmentID) > 1
--Leave hours category(inline)
CREATE FUNCTION fn_Leaveclassification(@Gender nchar(1) )
RETURNS TABLE
AS
RETURN(SELECT Businessentityid,vacationhours,Gender,sickleavehours, Vacationhours + sickleavehours AS TotalLeaveHours , 
  CASE
  WHEN Vacationhours + sickleavehours < 100 THEN'Low' 
  WHEN Vacationhours + sickleavehours >= 100 AND Vacationhours + sickleavehours <=150 THEN 'Moderate'
  WHEN Vacationhours + sickleavehours > 150 THEN'High'
  END
  AS leavehoursclassification
  FROM HumanResources.Employee
  WHERE Gender=@Gender)
  DROP FUNCTION fn_Leaveclassification
SELECT * FROM fn_Leaveclassification()
--Employee search
CREATE PROCEDURE spemployee @Businessentityid int
AS
BEGIN
 SELECT BusinessEntityID, Loginid,BirthDate,Gender,HireDate, Vacationhours, Sickleavehours
 FROM HumanResources.Employee
 WHERE BusinessEntityID= @Businessentityid
END 
--Job Search Procedure
CREATE PROC spjobsearch @JobTitle varchar(25)
AS
BEGIN
 SELECT BusinessEntityID, Loginid, Jobtitle, HireDate
 FROM HumanResources.Employee
 WHERE JobTitle = @JobTitle
END
--Department Employee
CREATE PROC spdepartmentemployee @DepartmentID int
AS
BEGIN
 SELECT e.BusinessEntityID, Loginid, Jobtitle, HireDate, edh.DepartmentID
 FROM HumanResources.Employee e
 JOIN HumanResources.EmployeeDepartmentHistory edh
 ON e.BusinessEntityID= edh.BusinessEntityID
 WHERE edh.DepartmentID = @DepartmentID
END
--Employee Leave Report
CREATE PROC spemployeeleavereport
AS
BEGIN
 SELECT  BusinessEntityID, Jobtitle, VacationHours,SickLeaveHours,
 VacationHours/SickLeaveHours As Vaction_to_sickratio,Vacationhours + sickleavehours 
 AS TotalLeaveHours, (VacationHours +SickLeaveHours)/2 
 AS AverageLeaveHours, dbo.Leaveclassification(VacationHours,SickLeaveHours) 
 AS leaveclassification FROM HumanResources.Employee 
END
spemployeeleavereport
--Employee Workforce Analysis
CREATE PROC  Spemployeeworkforceanalysis
AS
BEGIN
 SELECT e.BusinessEntityID, Jobtitle,Gender, HireDate, dbo.Years(Hiredate) 
 AS YearsOfService,BirthDate,dbo.HirePeriod(HireDate) 
 AS HirePeriod, dbo.YearsInCurrentDepartment(StartDate) 
 AS YearsInCurrentDepartment,  dbo.Age(Birthdate) AS Age, edh.DepartmentID, ShiftID, 
 Vacationhours, Sickleavehours, Vacationhours + Sickleavehours As TotalLeaveHours,
 dbo.Leaveclassification(VacationHours,SickLeaveHours) AS LeaveClassification, 
 Case 
  WHEN EndDate IS NULL THEN 'Current'
  ELSE 'Historical'
  END
  AS CurrentDepartmentStatus
FROM HumanResources.Employee e
 JOIN HumanResources.EmployeeDepartmentHistory edh
 ON e.BusinessEntityID= edh.BusinessEntityID
END
--Business Questions
  -- Most common job titles
SELECT Jobtitle, Count(BusinessEntityID) 
AS CountOfJobtitle
FROM HumanResources.Employee
GROUP BY Jobtitle
ORDER BY CountOfJobtitle DESC
  -- Jobtitle Highest total leave hours
SELECT Jobtitle, Sum(VacationHours + SickLeaveHours) 
AS TotalLeaveHours
FROM HumanResources.Employee
GROUP BY Jobtitle
ORDER BY TotalLeaveHours DESC
  -- Total Numbers of Employees In each Department
SELECT edh.departmentid, count(e.businessentityid) 
AS CountofEmployeeinDepartment
FROM HumanResources.Employee e
JOIN HumanResources.EmployeeDepartmentHistory edh
ON e.BusinessEntityID= edh.BusinessEntityID
GROUP BY edh.DepartmentID
ORDER BY count(e.businessentityid) DESC

SELECT Jobtitle, dbo.Years(HireDate) AS Totalyearsjobtitle FROM HumanResources.Employee
ORDER BY dbo.Years(HireDate) DESC
SELECT * FROM HumanResources.Department