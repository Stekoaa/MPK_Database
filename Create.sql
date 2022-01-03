IF OBJECT_ID('Departments', 'U') IS NOT NULL DROP TABLE Departments
IF OBJECT_ID('Buildings', 'U') IS NOT NULL DROP TABLE Buildings
IF OBJECT_ID('DepartmentBuildings', 'U') IS NOT NULL DROP TABLE Buildings
IF OBJECT_ID('Employees', 'U') IS NOT NULL DROP TABLE Employees
IF OBJECT_ID('SalaryHistory', 'U') IS NOT NULL DROP TABLE SalaryHistory
IF OBJECT_ID('EmployeeHolidays', 'U') IS NOT NULL DROP TABLE EmployeeHolidays
IF OBJECT_ID('EmployeeFamilyMembers', 'U') IS NOT NULL DROP TABLE EmployeeFamilyMembers
IF OBJECT_ID('BusDrivers', 'U') IS NOT NULL DROP TABLE BusDrivers
IF OBJECT_ID('TramDrivers', 'U') IS NOT NULL DROP TABLE TramDrivers
IF OBJECT_ID('ServiceTechnicians', 'U') IS NOT NULL DROP TABLE ServiceTechnicians
IF OBJECT_ID('TicketInspectors', 'U') IS NOT NULL DROP TABLE TicketInspectors
IF OBJECT_ID('OfficeWorkers', 'U') IS NOT NULL DROP TABLE OfficeWorkers


CREATE TABLE Departments (
	DepartmentID INT PRIMARY KEY,
	Name VARCHAR(50) NOT NULL
)

CREATE TABLE Buildings (
	BuildingID INT PRIMARY KEY,
	BuildingName VARCHAR(50) NOT NULL,
	Address VARCHAR(50) NOT NULL,
	DepartmentID INT NOT NULL,

	FOREIGN KEY (DepartmentID) REFERENCES Departments (DepartmentID)
)

CREATE TABLE DepartementBuildings (
	DepartmentID INT,
	BuildingID INT,

	PRIMARY KEY (DepartmentID, BuildingID),
	FOREIGN KEY (DepartmentID) REFERENCES Departments (DepartmentID),
	FOREIGN KEY (BuildingID) REFERENCES Buildings (BuildingID)
	ON UPDATE CASCADE
	ON DELETE CASCADE
)



CREATE TABLE Employees (
	EmployeeID INT PRIMARY KEY IDENTITY(1,1),
	PESEL CHAR(11) UNIQUE NOT NULL, 
	FirstName VARCHAR(50) NOT NULL,
	LastName VARCHAR(50) NOT NULL,
	Gender NVARCHAR (1) NOT NULL,
	BirthDate DATE,
	HireDate DATE NOT NULL,
	PhoneNumber CHAR(9),
	Address VARCHAR(50) NOT NULL,
	City VARCHAR(50) NOT NULL,
	DepartmentID INT NOT NULL,

	FOREIGN KEY (DepartmentID) REFERENCES Departments (DepartmentID),
	CONSTRAINT Employees_AltPK UNIQUE (EmployeeID, DepartmentID)
)

CREATE TABLE SalaryHistory (
	EmployeeID INT,
	DateFrom DATE,
	DateTo DATE,
	Salary MONEY NOT NULL,
	
	PRIMARY KEY (EmployeeID, DateFrom),
	FOREIGN KEY (EmployeeID) REFERENCES Employees (EmployeeID)
	ON DELETE CASCADE
	ON UPDATE CASCADE
)

CREATE TABLE EmpolyeeHolidays (
	EmployeeID INT,
	DateFrom DATE,
	DateTo DATE NOT NULL,

	PRIMARY KEY (EmployeeID, DateFrom),
	FOREIGN KEY (EmployeeID) REFERENCES Employees (EmployeeID) --on cascade ??
	ON DELETE CASCADE
	ON UPDATE CASCADE
)

CREATE TABLE EmpolyeeFamilyMembers (
	EmployeeID INT,
	MemberID INT,
	FirstName VARCHAR(50) NOT NULL,
	LastName VARCHAR(50) NOT NULL,
	Gender NVARCHAR (1) NOT NULL,
	BirthDate DATE,
	Relationship VARCHAR(30) NOT NULL,

	PRIMARY KEY (EmployeeID, MemberID),
	FOREIGN KEY (EmployeeID) REFERENCES Employees (EmployeeID)
	ON DELETE CASCADE
	ON UPDATE CASCADE
)

CREATE TABLE BusDrivers (
	EmployeeID INT PRIMARY KEY,
	DepartmentID AS 1 PERSISTED,
	DriverLicenceID CHAR(13) UNIQUE NOT NULL,
	SightDefect BIT NOT NULL,
	MedicalExpiryDate DATE NOT NULL,

	FOREIGN KEY (EmployeeID, DepartmentID) REFERENCES Employees (EmployeeID, DepartmentID)
)

CREATE TABLE TramDrivers (
	EmployeeID INT PRIMARY KEY,
	DepartmentID AS 2 PERSISTED,
	LicenceID CHAR(10) NOT NULL,
	SightDefect BIT NOT NULL,
	MedicalExpiryDate DATE NOT NULL,
	
	FOREIGN KEY (EmployeeID, DepartmentID) REFERENCES Employees (EmployeeID, DepartmentID)
)

CREATE TABLE ServiceTechnicians (
	EmployeeID INT PRIMARY KEY,
	DepartmentID AS 3 PERSISTED,
	BusPermission BIT NOT NULL,
	TramPermission BIT NOT NULL,

	FOREIGN KEY (EmployeeID, DepartmentID) REFERENCES Employees (EmployeeID, DepartmentID)
)

CREATE TABLE TicketInspectors (
	EmployeeID INT PRIMARY KEY,
	DepartmentID AS 3 PERSISTED,
	LicenceID CHAR(10) NOT NULL,

	FOREIGN KEY (EmployeeID, DepartmentID) REFERENCES Employees (EmployeeID, DepartmentID)
)

CREATE TABLE OfficeWorkers (
	EmployeeID INT PRIMARY KEY,
	DepartmentID AS 4 PERSISTED,
	BuildingID INT NOT NULL,

	FOREIGN KEY (BuildingID) REFERENCES Buildings(BuildingID),
	FOREIGN KEY (EmployeeID, DepartmentID) REFERENCES Employees (EmployeeID, DepartmentID)
)


ALTER TABLE Employees
ADD CONSTRAINT is_phone_valid CHECK(ISNUMERIC(PhoneNumber) = 1 AND LEN(PhoneNumber) = 9)

ALTER TABLE Employees
ADD CONSTRAINT is_employee_pesel_valid CHECK(ISNUMERIC(PESEL) = 1 AND LEN(PESEL) = 11)

ALTER TABLE EmpolyeeHolidays 
ADD CONSTRAINT are_holiday_dates_valid CHECK(DateTo >= DateFrom)

ALTER TABLE SalaryHistory
ADD CONSTRAINT are_salary_dates_valid CHECK(DateTo >= DateFrom)

ALTER TABLE BusDrivers
ADD CONSTRAINT is_driver_licence_valid CHECK(LEN(DriverLicenceID) = 13)

ALTER TABLE TramDrivers
ADD CONSTRAINT is_tram_licence_valid CHECK(LEN(LicenceID) = 10)

ALTER TABLE TicketInspectors
ADD CONSTRAINT is_ispector_licence_valid CHECK(LEN(LicenceID) = 10)