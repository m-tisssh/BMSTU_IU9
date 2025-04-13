USE master;
GO

DROP DATABASE IF EXISTS lab11_1;
GO

DROP TABLE IF EXISTS Users
DROP TABLE IF EXISTS Orders
DROP TABLE IF EXISTS Teachers
DROP TABLE IF EXISTS Lessons
DROP TABLE IF EXISTS Courses
GO


CREATE DATABASE lab11_1
ON PRIMARY
    (
        NAME = lab9_data,
        FILENAME = '/Users/marypishykina/Desktop/DB/lab11/data_log_1/lab9_data.mdf',
        SIZE = 5MB,
        MAXSIZE = 50MB,
        FILEGROWTH = 5MB
    )
LOG ON
    (
        NAME = lab9_log,
        FILENAME = '/Users/marypishykina/Desktop/DB/lab11/data_log_1/lab9_log.ldf',
        SIZE = 5MB,
        MAXSIZE = 50MB,
        FILEGROWTH = 5MB
    );
GO

USE lab11_1;
GO

CREATE TABLE Users (
    userID INT PRIMARY KEY IDENTITY(1,1) NOT NULL,  -- автоинкрементное поле
    name NVARCHAR(50) NOT NULL,
    surname NVARCHAR(50) NULL,
    email NVARCHAR(320) UNIQUE NOT NULL,
    phone VARCHAR(15) UNIQUE NULL DEFAULT '',
    dateBirth DATE NOT NULL CHECK (dateBirth < GETDATE()),  
    registrationDate DATETIME NOT NULL DEFAULT GETDATE(),   
    lastSignIn DATETIME NOT NULL DEFAULT GETDATE()          
);


CREATE TABLE Orders (
    transactionNumber INT IDENTITY(1,1) NOT NULL,  -- автоинкрементное поле
    userID INT NOT NULL,
    PRIMARY KEY(transactionNumber, userID),
    orderStatus SMALLINT NOT NULL CHECK (orderStatus IN (0, 1, 2)),  -- 0 = создан, 1 = оплачен, 2 = отменён
    purchaseDate DATETIME NOT NULL DEFAULT GETDATE(),               
    paymentMethod SMALLINT NOT NULL CHECK (paymentMethod IN (1, 2, 3)), 
    totalPrice MONEY NOT NULL CHECK (totalPrice > 0) 
    -- userID - FK 
    CONSTRAINT FK_ORDERS_User FOREIGN KEY (userID) REFERENCES Users(userID),             
);


CREATE TABLE Teachers (
    employeeNumber INT PRIMARY KEY IDENTITY(1,1) NOT NULL, 
    name NVARCHAR(50) NOT NULL,
    surname NVARCHAR(50) NULL,
    email NVARCHAR(320) UNIQUE NOT NULL,
    dateBirth DATE NOT NULL,
    educationLevel SMALLINT NULL CHECK (educationLevel BETWEEN 1 AND 5), -- Уровень образования от 1 до 5
    about NVARCHAR(500) NULL
);


CREATE TABLE Courses (
    courseID INT PRIMARY KEY IDENTITY(1,1) NOT NULL, 
    courseCode NVARCHAR(20) UNIQUE NOT NULL,
    courseName NVARCHAR(100) NOT NULL,
    subjectArea NVARCHAR(60) NOT NULL,
    employeeNumber INT NOT NULL,
    description NVARCHAR(500) NULL,
    difficulty SMALLINT NOT NULL,
    price MONEY NOT NULL
    --- employeeNumber - FK
    CONSTRAINT FK_LESSONS_Teachers FOREIGN KEY (employeeNumber) REFERENCES Teachers(employeeNumber),           
);


CREATE TABLE Lessons (
    lessonID INT PRIMARY KEY NOT NULL, 
    lessonTopic NVARCHAR(100) NOT NULL,
    courseID INT NOT NULL,
    duration TIME NOT NULL,
    description NVARCHAR(500) NULL,
    publishedDate DATE NOT NULL,
    taskList SMALLINT NULL,
    --- courseID - FK
    CONSTRAINT FK_LESSONS_Courses FOREIGN KEY (courseID) REFERENCES Courses(courseID),           
);


INSERT INTO Users (name, surname, email, phone, dateBirth)
VALUES
('Mark', 'Tishkin', 'tiiiissssh@example.com', '1234567890', '1985-05-15'),
('Serg', 'Zakharin', 'starosta@example.com', '', '1990-08-22'),
('Alice', 'Egorova', 'rabbit@example.com', '9876543210', '1992-12-01');


INSERT INTO Orders (userID, orderStatus, paymentMethod, totalPrice)
VALUES
(1, 0, 1, 100.00),
(3, 1, 2, 250.50),
(2, 2, 3, 75.25),
(2, 1, 2, 20.50),
(2, 0, 2, 75.25),
(2, 1, 3, 725.25),
(1, 2, 3, 150.00);


INSERT INTO Teachers (name, surname, email, dateBirth, educationLevel, about)
VALUES
('Martin', 'Luther', 'luth.mart@example.com', '1970-03-18', 5, 'Experienced teacher in computer science.'),
('Abraham', 'Lincoln', 'us.lincoln.com', '1985-03-30', 4, 'Specialist in mathematics and statistics.'),
('Mark', 'Shagal', 'marrrrk@mail.com', '1990-11-18', 3, 'Art of 18th century.');


INSERT INTO Courses (courseCode, courseName, subjectArea, employeeNumber, description, difficulty, price)
VALUES
('CS101', 'Computer Science Basics', 'Computer Science', 1, 'An introduction to the field of computer science.', 2, 200.00),
('MATH201', 'Advanced Mathematics', 'Mathematics', 2, 'A comprehensive course on advanced math topics.', 3, 300.00),
('LIT303', 'World Literature', 'Literature', 3, 'Exploration of global literary traditions.', 4, 150.00);


INSERT INTO Lessons (lessonID, lessonTopic, courseID, duration, description, publishedDate, taskList)
VALUES
(1, 'Introduction to Programming', 1, '01:30:00', 'Basic concepts of programming.', '2023-01-15', 10),
(2, 'Advanced Mathematics', 2, '02:00:00', 'Deep dive into calculus and algebra.', '2023-02-20', 15),
(3, 'Art of 18th century', 3, '01:45:00', 'Overview of key works from the 18th century.', '2023-03-05', NULL),
(4, 'Expending Programming', 1, '04:30:00', 'Concepts of programming.', '2024-01-10', 123);
GO

-- SELECT * FROM Users;
-- SELECT * FROM Orders;
-- SELECT * FROM Teachers;
-- SELECT * FROM Courses;
-- SELECT * FROM Lessons;
-- GO

-- Функции
-- Функция для подсчёта количества заказов пользователя:
CREATE FUNCTION GetUserOrderCount(@userID INT)
RETURNS INT
AS
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM Orders
        WHERE userID = @userID
    );
END;
GO

-- Функция для вычисления средней стоимости заказов пользователя:
CREATE FUNCTION GetUserAverageOrderPrice(@userID INT)
RETURNS MONEY
AS
BEGIN
    RETURN (
        SELECT AVG(totalPrice)
        FROM Orders
        WHERE userID = @userID
    );
END;
GO

SELECT dbo.GetUserOrderCount(2) AS OrderCount;
SELECT dbo.GetUserAverageOrderPrice(2) AS AverageOrderPrice;
GO

-- Процедуры
-- Процедура для обновления статуса заказа:

CREATE PROCEDURE UpdateOrderStatus
    @transactionNumber INT,
    @userID INT,
    @orderStatus SMALLINT
AS
BEGIN
    UPDATE Orders
    SET orderStatus = @orderStatus
    WHERE transactionNumber = @transactionNumber AND userID = @userID;
END;
GO

EXEC UpdateOrderStatus @transactionNumber = 1, @userID = 1, @orderStatus = 0;
GO

SELECT * FROM Courses;
GO

-- Индексы
-- Индекс для ускорения поиска по email
CREATE UNIQUE INDEX IX_Users_Email ON Users(email);

SELECT * 
FROM Users 
WHERE email = 'rabbit@example.com';
GO

-- Индекс для фильтрации и сортировки заказов по дате
CREATE INDEX IX_Orders_PurchaseDate ON Orders(purchaseDate);

SELECT COUNT(*) AS CountOfPurchases
FROM Orders
WHERE purchaseDate BETWEEN '2024-01-01' AND '2024-12-31';
GO


-- Представления
CREATE VIEW CourseLessons AS
SELECT 
    c.courseName,
    c.subjectArea,
    l.lessonTopic,
    l.duration,
    l.publishedDate
FROM Courses c
INNER JOIN Lessons l ON c.courseID = l.courseID;
GO

--- Удаление записей (команда DELETE)

CREATE TRIGGER trg_PreventUserDelete
ON Users
INSTEAD OF DELETE
AS
BEGIN
    RAISERROR('Запрещено удалять пользователя.',16, 1)
END;
GO

CREATE TRIGGER trg_PreventTeacherDelete
ON Teachers
INSTEAD OF DELETE
AS
BEGIN
    RAISERROR('Запрещено удалять преподавателя.',16, 1)
END;
GO

CREATE TRIGGER trg_PreventCoursesDelete
ON Courses
INSTEAD OF DELETE
AS
BEGIN
    RAISERROR('Запрещено удалять курсы.',16, 1)
END;
GO


--- Модификации записи (команда UPDATE)

CREATE TRIGGER trg_PreventOrderKeyChange
ON Orders
AFTER UPDATE
AS
BEGIN
    IF UPDATE(userID) OR UPDATE(transactionNumber) OR UPDATE(totalPrice)
    BEGIN
        RAISERROR('Изменять userID, transactionNumber, totalPrice в Orders запрещено.', 16, 1)
        ROLLBACK TRANSACTION;
    END;
END;
GO

CREATE TRIGGER trg_PreventLessonKeyChange
ON Lessons
AFTER UPDATE
AS
BEGIN
    IF UPDATE(courseID)
    BEGIN
        RAISERROR('Изменять courseID в Lessons запрещено.', 16, 1)
        ROLLBACK TRANSACTION;
    END;
END;
GO

CREATE TRIGGER trg_PreventCourseKeyChange
ON Courses
AFTER UPDATE
AS
BEGIN
    IF UPDATE(employeeNumber)
    BEGIN
        RAISERROR('Изменять employeeNumber в Courses запрещено.', 16, 1)
        ROLLBACK TRANSACTION;
    END;
END;
GO

CREATE TRIGGER trg_PreventUserKeyChange
ON Users
AFTER UPDATE
AS
BEGIN
    IF UPDATE(userID) OR UPDATE(email)
    BEGIN
        RAISERROR('Изменять userID или email в Users запрещено.', 16, 1)
        ROLLBACK TRANSACTION;
    END;
END;
GO

--- удаление повторяющихся записей (DISTINCT)
SELECT DISTINCT *
INTO Lessons_temp
FROM Lessons;

DELETE FROM Lessons;

INSERT INTO Lessons
SELECT *
FROM Lessons_temp;

DROP TABLE Lessons_temp;
SELECT * FROM Lessons;
GO

--- Соединение таблиц (INNER, LEFT, RIGHT, FULL OUTER JOIN)
SELECT l.lessonID AS Lesson_Number,
       l.publishedDate AS Lesson_Published_Date,
       c.courseName AS Course_Name,
       u.name + ' ' + u.surname AS User_Name
FROM Lessons l
INNER JOIN Courses c ON l.courseID = c.courseID
INNER JOIN Orders o ON c.courseID = o.transactionNumber  
INNER JOIN Users u ON o.userID = u.userID
ORDER BY l.publishedDate DESC;


SELECT u.name, u.surname, l.lessonID
FROM Users u
INNER JOIN Orders o ON u.userID = o.userID
INNER JOIN Lessons l ON o.transactionNumber = l.lessonID; 


SELECT u.name, u.surname, l.lessonID
FROM Users u
LEFT JOIN Orders o ON u.userID = o.userID
LEFT JOIN Lessons l ON o.transactionNumber = l.lessonID;


SELECT l.lessonID, u.name, u.surname
FROM Lessons l
RIGHT JOIN Orders o ON l.lessonID = o.transactionNumber
RIGHT JOIN Users u ON o.userID = u.userID;


SELECT l.lessonID, u.name, u.surname
FROM Lessons l
FULL OUTER JOIN Orders o ON l.lessonID = o.transactionNumber
FULL OUTER JOIN Users u ON o.userID = u.userID;


--- Условия выбора записей (NULL, LIKE, BETWEEN, IN, EXISTS)
SELECT * 
FROM Users
WHERE dateBirth < '2012-01-01';

SELECT * 
FROM Users
WHERE email LIKE '%@mail.com';

SELECT * 
FROM Orders
WHERE totalPrice BETWEEN 90 AND 250;

SELECT * 
FROM Courses
WHERE courseCode IN ('CS101', 'LIT303');

SELECT l.lessonID
FROM Lessons l
WHERE EXISTS (
    SELECT 1
    FROM Orders o
    INNER JOIN Courses c ON o.userID = c.employeeNumber
    WHERE o.transactionNumber = c.courseID
);


--- Cортировка записей  (ASC/DESC)

SELECT * FROM Teachers
ORDER BY dateBirth DESC;

--- Группировка записей (GROUP BY + HAVING) и функции агрегирования (COUNT/AVG/SUM/MIN/MAX)
SELECT 
    CAST(registrationDate AS DATE) AS RegistrationDate,
    COUNT(*) AS TotalUsers
FROM Users
GROUP BY CAST(registrationDate AS DATE)
ORDER BY RegistrationDate;

SELECT 
    paymentMethod,
    AVG(totalPrice) AS AveragePrice
FROM Orders
GROUP BY paymentMethod
HAVING AVG(totalPrice) > 100; 

SELECT 
    orderStatus,
    COUNT(*) AS TotalOrders,
    SUM(totalPrice) AS TotalRevenue
FROM Orders
GROUP BY orderStatus
HAVING SUM(totalPrice) > 100; -- Условие: только статусы с суммарным доходом > 5000

SELECT 
    subjectArea,
    MIN(difficulty) AS MinDifficulty,
    MAX(difficulty) AS MaxDifficulty,
    AVG(difficulty) AS AvgDifficulty
FROM Courses
GROUP BY subjectArea;

SELECT 
    courseID,
    COUNT(*) AS TotalLessons,
    SUM(DATEDIFF(MINUTE, '00:00:00', duration)) AS TotalDurationMinutes
FROM Lessons
GROUP BY courseID
HAVING COUNT(*) >= 1; -- Условие: только курсы с 1 и более уроками


SELECT 
    employeeNumber,
    MAX(price) AS MaxCoursePrice
FROM Courses
GROUP BY employeeNumber;


--- Объединение результатов (UNION...)

SELECT name
FROM Users
UNION
SELECT name
FROM Teachers;

SELECT name, surname
FROM Users
UNION ALL
SELECT name, surname
FROM Teachers;

-- Исключение уроков, у которых описание совпадает с описанием курсов 
SELECT lessonID AS ID, description 
FROM Lessons
EXCEPT
SELECT courseID AS ID, description 
FROM Courses;

SELECT name 
FROM Users
INTERSECT
SELECT name 
FROM Teachers;

--- Вложенный запрос
SELECT name, surname, email
FROM Users
WHERE userID IN (
    SELECT userID
    FROM Orders
    WHERE totalPrice > (SELECT AVG(totalPrice) FROM Orders)
);
