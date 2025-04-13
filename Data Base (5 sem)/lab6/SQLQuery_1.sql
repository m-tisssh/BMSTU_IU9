USE master;
GO

DROP DATABASE IF EXISTS online_courses;
GO

CREATE DATABASE online_courses
ON PRIMARY 
(
    NAME = online_courses_data,
    FILENAME = '/Users/marypishykina/Desktop/DB/lab5/data_log/online_courses_data.mdf',
    SIZE = 5MB,
    MAXSIZE = 50MB,
    FILEGROWTH = 5MB
)
LOG ON 
(
    NAME = online_courses_log,
    FILENAME = '/Users/marypishykina/Desktop/DB/lab5/data_log/online_courses_log.ldf',
    SIZE = 5MB,
    MAXSIZE = 50MB,
    FILEGROWTH = 5MB
);
GO

USE online_courses;
GO

DROP TABLE IF EXISTS Users;
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Courses;
DROP TABLE IF EXISTS Teachers;
DROP TABLE IF EXISTS Lessons;
DROP TABLE IF EXISTS OrderCourses;
GO


CREATE TABLE Users (
    id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,  -- автоинкрементное поле
    name NVARCHAR(50) NOT NULL,
    surname NVARCHAR(50) NULL,
    email NVARCHAR(320) UNIQUE NOT NULL,
    phone VARCHAR(15) NULL,
    dateBirth DATE NOT NULL CHECK (dateBirth < GETDATE()),  
    registrationDate DATETIME NOT NULL DEFAULT GETDATE(),   
    lastSignIn DATETIME NOT NULL DEFAULT GETDATE()          
);
GO

INSERT INTO Users (name, surname, email, phone, dateBirth, registrationDate, lastSignIn)
VALUES
('Alice', 'Johnson', 'alice.johnson@example.com', '+1234567890', '1990-01-15', GETDATE(), GETDATE()),
('Charlie', 'Brown', 'charlie.brown@example.com', NULL, '1992-11-05', GETDATE(), GETDATE());
GO


CREATE TABLE Orders (
    id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,  -- автоинкрементное поле
    orderStatus SMALLINT NOT NULL CHECK (orderStatus IN (0, 1, 2)),  -- 0 = создан, 1 = оплачен, 2 = отменён
    purchaseDate DATETIME NOT NULL DEFAULT GETDATE(),               
    paymentMethod SMALLINT NOT NULL CHECK (paymentMethod IN (1, 2, 3)), 
    totalPrice MONEY NOT NULL CHECK (totalPrice > 0),                 
);
GO

INSERT INTO Orders (orderStatus, paymentMethod, totalPrice)
VALUES 
(1, 1, 249.98),  
(0, 2, 49.99);  
GO

SELECT * FROM Users;
SELECT * FROM Orders;

SELECT SCOPE_IDENTITY() AS lastOrderID1;
GO

SELECT @@IDENTITY AS lastOrderID2;
GO

SELECT IDENT_CURRENT('Users') AS lastUserID;
GO

CREATE SEQUENCE teacher_sequence
    AS INT
    START WITH 100
    INCREMENT BY 1;
GO


CREATE TABLE Teachers (
    id INT PRIMARY KEY NOT NULL DEFAULT (NEXT VALUE FOR teacher_sequence), -- ключ на основе последовательности
    name NVARCHAR(50) NOT NULL,
    surname NVARCHAR(50) NULL,
    email NVARCHAR(320) UNIQUE NOT NULL,
    dateBirth DATE NOT NULL,
    educationLevel SMALLINT NULL CHECK (educationLevel BETWEEN 1 AND 5), -- Уровень образования от 1 до 5
    about NVARCHAR(500) NULL
);
GO

INSERT INTO Teachers (name, surname, email, dateBirth, educationLevel, about)
VALUES
('John', 'D', 'john.d@example.com', '1975-05-15', 5, 'Expert in Databases'),
('Jane', 'Smith', 'jane.smith@example.com', '1982-03-22', 4, 'Python programming expert');
GO

SELECT * FROM Teachers;
GO


CREATE TABLE Courses (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), 
    courseCode NVARCHAR(20) NOT NULL,
    courseName NVARCHAR(100) NOT NULL,
    subjectArea NVARCHAR(60) NOT NULL,
    employeeNumber INT NOT NULL, 
    description NVARCHAR(500) NULL,
    difficulty SMALLINT NOT NULL CHECK (difficulty BETWEEN 1 AND 5), -- Сложность от 1 до 5
    price MONEY NOT NULL CHECK (price > 0), 
);
GO

INSERT INTO Courses (courseCode, courseName, subjectArea, employeeNumber, description, difficulty, price)
VALUES
('DB101', 'Introduction to SQL', 'Databases', 100, 'Basic SQL course covering fundamental database operations.', 1, 49.99),
('PR102', 'Advanced Python Programming', 'Programming', 101, 'Deep dive into advanced Python features including OOP and modules.', 3, 199.99);
GO

SELECT * FROM Courses;
GO

CREATE TABLE Lessons (
    id INT PRIMARY KEY IDENTITY(1,1) NOT NULL, 
    lessonTopic NVARCHAR(100) NOT NULL,
    duration TIME NOT NULL,
    description NVARCHAR(500) NULL,
    publishedDate DATE NOT NULL,
    courseId UNIQUEIDENTIFIER NOT NULL, 
);
GO

INSERT INTO Lessons (lessonTopic, duration, description, publishedDate, courseId)
VALUES
('SQL Basics', '01:30:00', 'Introduction to SQL basics', '2023-10-01', (SELECT id FROM Courses WHERE courseCode = 'DB101')),
('Python OOP', '02:00:00', 'Object-Oriented Programming in Python', '2023-09-15', (SELECT id FROM Courses WHERE courseCode = 'PR102'));
GO

ALTER TABLE Lessons
ADD CONSTRAINT FK_Lessons_Courses FOREIGN KEY (courseId) REFERENCES Courses(id)
ON DELETE CASCADE;
-- ON DELETE SET NULL;
-- ON DELETE SET DEFAULT;
-- ON DELETE NO ACTION;
GO

SELECT * FROM Lessons;
GO

DELETE FROM Courses
WHERE courseCode = 'DB101';
GO

SELECT * FROM Courses;
GO

SELECT * FROM Lessons;
GO
