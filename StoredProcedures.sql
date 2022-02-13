IF OBJECT_ID('Passenger_Ticket_Info', 'P') IS NOT NULL
DROP PROCEDURE Passenger_Ticket_Info

IF OBJECT_ID('Passengers_With_Valid_Periodic_Tickets', 'P') IS NOT NULL
DROP PROCEDURE Passengers_With_Valid_Periodic_Tickets

IF OBJECT_ID('Ticket_Prices', 'P') IS NOT NULL
DROP PROCEDURE Ticket_Prices

IF OBJECT_ID('Add_Employee', 'P') IS NOT NULL
DROP PROCEDURE Add_Employee

IF OBJECT_ID('Add_Bus_Driver', 'P') IS NOT NULL
DROP PROCEDURE Add_Bus_Driver

IF OBJECT_ID('Add_Tram_Driver', 'P') IS NOT NULL
DROP PROCEDURE Add_Tram_Driver

IF OBJECT_ID('Add_Technician', 'P') IS NOT NULL
DROP PROCEDURE Add_Technician

IF OBJECT_ID('Add_Inspector', 'P') IS NOT NULL
DROP PROCEDURE Add_Inspector

IF OBJECT_ID('Add_Office_Worker', 'P') IS NOT NULL
DROP PROCEDURE Add_Office_Worker

GO

CREATE PROCEDURE Passenger_Ticket_Info (@id INT) AS
BEGIN
	IF NOT EXISTS(SELECT * FROM Passengers P WHERE P.PassengerID = @id)
		BEGIN
			;THROW 51000, 'Passenger does not exist.', 1
		END

	DECLARE @pesel CHAR(11)
	DECLARE @passengerID INT
	DECLARE @birthDate DATE
	DECLARE @firstName VARCHAR(50)
	DECLARE @lastName VARCHAR(50)
	DECLARE @placeOfResidence VARCHAR(50)
	DECLARE @city VARCHAR(50)
	DECLARE @student BIT
	DECLARE @pupil BIT
	DECLARE @honoraryBloodDonor BIT
	DECLARE @pensioner BIT

	DECLARE cur CURSOR FOR (SELECT * FROM Passengers P WHERE P.PassengerID = @id)
	OPEN cur
	FETCH NEXT FROM cur INTO @passengerID, @pesel, @birthDate, @firstName, @lastName, @placeOfResidence, @city, @student, @pupil,
	@honoraryBloodDonor, @pensioner
	SELECT FORMATMESSAGE('Passenger info: PESEL: %s; ID: %d; Date of birth: %s; first name: %s; last name: %s; address: %s; city: %s; student: %d; pupil: %d; honorary blood donor: %d; pensioner: %d',  @pesel, @passengerID, CONVERT(varchar(50), @birthDate), @firstName,
	@lastName, @placeOfResidence, @city, CONVERT(INT, @student), CONVERT(INT, @pupil), CONVERT(INT, @honoraryBloodDonor), CONVERT(INT, @pensioner))
	CLOSE cur
	DEALLOCATE cur

	IF (@student = 1 OR @pupil = 1 OR @honoraryBloodDonor = 1 OR @pensioner = 1)
		SELECT FORMATMESSAGE('%s %s with passenger id %d can buy tickets with reduced prices.', @firstName, @lastName, @id)
	ELSE
		SELECT FORMATMESSAGE('%s %s with passenger id %d cannot buy tickets with reduced prices.', @firstName, @lastName, @id)
END

GO

GO
CREATE PROCEDURE Passengers_With_Valid_Periodic_Tickets (@currentDay DATE) AS
BEGIN
	DECLARE cur CURSOR FOR SELECT PT.TicketID, OwnerID, DateFrom, PassengerID, FirstName, LastName FROM PeriodicTickets PT JOIN TypesOfTickets T ON PT.TicketID = T.TicketID
	JOIN Passengers P ON PT.OwnerID = P.PassengerID

	DECLARE @result Table(ID INT, FirstName VARCHAR(50), LastName VARCHAR(50), DateOfPurchase DATE)

	OPEN cur
	DECLARE @ticketID INT
	DECLARE @ownerID INT
	DECLARE @dateFrom DATE
	DECLARE @days INT
	DECLARE @isValid BIT
	DECLARE @firstName VARCHAR(50)
	DECLARE @lastName VARCHAR(50)
	DECLARE @id INT
	FETCH cur INTO @ticketID, @ownerID, @dateFrom, @id, @firstName, @lastName
	DECLARE @daysDiff INT
	
	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		IF (@dateFrom <= @currentDay)
		BEGIN
			SET @daysDiff = DATEDIFF(day, @dateFrom, @currentDay)
			IF ((@ticketID BETWEEN 18 AND 21 AND @daysDiff <= 30) OR (@ticketID BETWEEN 22 AND 23 AND @daysDiff <= 180))
			INSERT INTO @result VALUES(@ownerID, @firstName, @lastName, @dateFrom)
		END
		FETCH cur INTO @ticketID, @ownerID, @dateFrom, @id, @firstName, @lastName
	END

	CLOSE cur
	DEALLOCATE cur

	SELECT * FROM @result
END
GO

GO
-- view ticket prices on a day passed as an argument
CREATE PROCEDURE Ticket_Prices(@day DATE) AS
BEGIN
	SELECT * INTO #result FROM TypesOfTickets

	IF EXISTS (SELECT * FROM Days_With_Discounts
	WHERE @day = Days_With_Discounts.AirReadingDate)
		UPDATE #result SET Price = 0 WHERE Periodic = 0
	
	SELECT * FROM #result
END
GO



CREATE PROCEDURE Add_Employee(
 @PESEL CHAR(11) = NULL,
 @first_name VARCHAR(50) = NULL,
 @second_name VARCHAR(50) = NULL,
 @gender NVARCHAR(1) = NULL,
 @birth_date DATE = NULL,
 @hire_date DATE = NULL,
 @phone_number CHAR(9),
 @address VARCHAR(50) = NULL,
 @city VARCHAR(50) = NULL,
 @error BIT OUTPUT,
 @department_id INT = NULL
)
AS
DECLARE @error_msg NVARCHAR(500)

	IF @PESEL IS NULL OR @first_name IS NULL OR @second_name IS NULL OR @gender IS NULL 
	   OR @birth_date IS NULL OR @hire_date IS NULL OR @address IS NULL OR @city IS NULL OR @department_id IS NULL
	BEGIN 
		SET @error_msg = 'Invalid personal data. Check your input'
		SET @error = 1
		RAISERROR(@error_msg, 16, 1)
		RETURN
	END

	BEGIN TRY
		INSERT INTO Employees VALUES
			(@PESEL, @first_name, @second_name, @gender, @birth_date, @hire_date, @phone_number, @address, @city, @department_id)
	END TRY
	BEGIN CATCH
		SET @error = 1
		SET @error_msg = 'Error while inserting data'
		RAISERROR(@error_msg, 16, 1)
	END CATCH
	
RETURN

GO
CREATE PROCEDURE Add_Bus_Driver
(
 @PESEL CHAR(11) = NULL,
 @first_name VARCHAR(50) = NULL,
 @second_name VARCHAR(50) = NULL,
 @gender NVARCHAR(1) = NULL,
 @birth_date DATE = NULL,
 @hire_date DATE = NULL,
 @phone_number CHAR(9),
 @address VARCHAR(100) = NULL,
 @city VARCHAR(50) = NULL,
 @driver_licence CHAR(13) = NULL,
 @sight_defect BIT = NULL,
 @medicial DATE = NULL
)
AS	
	DECLARE @error BIT = 0
	EXEC dbo.Add_employee @PESEL, @first_name, @second_name, @gender, @birth_date, @hire_date, @phone_number, @address, 
						  @city, @error OUTPUT, @department_id = 1
	
	DECLARE @id INT = (SELECT COUNT(*) FROM Employees)	
	
	IF @error <> 1
	BEGIN
		INSERT INTO BusDrivers VALUES
			(@id, @driver_licence, @sight_defect, @medicial)
	END
		
RETURN
 
GO
CREATE PROCEDURE Add_Technician
(
 @PESEL CHAR(11) = NULL,
 @first_name VARCHAR(50) = NULL,
 @second_name VARCHAR(50) = NULL,
 @gender CHAR = NULL,
 @birth_date DATE = NULL,
 @hire_date DATE = NULL,
 @phone_number CHAR(9),
 @address VARCHAR(50) = NULL,
 @city VARCHAR(50) = NULL,
 @bus_perm BIT = NULL,
 @tram_perm BIT = NULL
)
AS
	DECLARE @error BIT = 0
	EXEC dbo.Add_employee @PESEL, @first_name, @second_name, @gender, @birth_date, @hire_date, @phone_number, @address, 
						  @city, @error OUTPUT, @department_id = 3
	
	DECLARE @id INT = (SELECT COUNT(*) FROM Employees)	
	
	IF @error <> 1
	BEGIN
		INSERT INTO ServiceTechnicians VALUES
				(@id, @bus_perm, @tram_perm)
	END
	
RETURN

GO
CREATE PROCEDURE Add_Tram_Driver
(
 @PESEL CHAR(11) = NULL,
 @first_name VARCHAR(50) = NULL,
 @second_name VARCHAR(50) = NULL,
 @gender CHAR = NULL,
 @birth_date DATE = NULL,
 @hire_date DATE = NULL,
 @phone_number CHAR(9),
 @address VARCHAR(50) = NULL,
 @city VARCHAR(50) = NULL,
 @driver_licence CHAR(10) = NULL,
 @sight_defect BIT = NULL,
 @medicial DATE = NULL
)
AS	
	DECLARE @error BIT = 0
	EXEC dbo.Add_employee @PESEL, @first_name, @second_name, @gender, @birth_date, @hire_date, @phone_number, @address, 
						  @city, @error OUTPUT, @department_id = 2
	
	DECLARE @id INT = (SELECT COUNT(*) FROM Employees)	
	
	IF @error <> 1
	BEGIN
		INSERT INTO TramDrivers VALUES
			(@id, @driver_licence, @sight_defect, @medicial)
	END

RETURN

GO
CREATE PROCEDURE Add_Inspector
(
 @PESEL CHAR(11) = NULL,
 @first_name VARCHAR(50) = NULL,
 @second_name VARCHAR(50) = NULL,
 @gender CHAR = NULL,
 @birth_date DATE = NULL,
 @hire_date DATE = NULL,
 @phone_number CHAR(9),
 @address VARCHAR(50) = NULL,
 @city VARCHAR(50) = NULL,
 @licence CHAR(10)
)
AS
DECLARE @error BIT = 0
	EXEC dbo.Add_employee @PESEL, @first_name, @second_name, @gender, @birth_date, @hire_date, @phone_number, @address, 
						  @city, @error OUTPUT, @department_id = 5
	
	DECLARE @id INT = (SELECT COUNT(*) FROM Employees)	
	
	IF @error <> 1
	BEGIN
		INSERT INTO TicketInspector VALUES
				(@id, @licence)
	END
RETURN

GO
CREATE PROCEDURE Add_Office_Worker
(
 @PESEL CHAR(11) = NULL,
 @first_name VARCHAR(50) = NULL,
 @second_name VARCHAR(50) = NULL,
 @gender CHAR = NULL,
 @birth_date DATE = NULL,
 @hire_date DATE = NULL,
 @phone_number CHAR(9),
 @address VARCHAR(50) = NULL,
 @city VARCHAR(50) = NULL,
 @building INT = NULL
)
AS
	DECLARE @error BIT = 0
	EXEC dbo.Add_employee @PESEL, @first_name, @second_name, @gender, @birth_date, @hire_date, @phone_number, @address, 
						  @city, @error OUTPUT, @department_id = 4
	
	DECLARE @id INT = (SELECT COUNT(*) FROM Employees)	
	
	IF @error <> 1
	BEGIN
		INSERT INTO OfficeWorkers VALUES
				(@id, @building)
	END
RETURN

GO
EXEC Add_Tram_Driver '76011039337', 'Dor', 'Czarnecki', 'M', '1976-09-10', '2017-05-10', '698007238', 'Anczyca 148', 'Krakow', 'ZZZZZZZZZ9929', 1, '2022-12-11'
SELECT * FROM TramDrivers
SELECT * FROM Employees
