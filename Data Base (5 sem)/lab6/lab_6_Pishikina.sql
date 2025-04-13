USE master;
GO

DROP DATABASE IF EXISTS courses_db;
GO

CREATE DATABASE courses_db
ON PRIMARY 
    (
    NAME = courses_db_data,
    FILENAME = '/Users/marypishykina/Desktop/DB/lab6/data_log/courses_db_data.mdf',
    SIZE = 5MB,
    MAXSIZE = 50MB,
    FILEGROWTH = 5MB
    )
, FILEGROUP courses_online_filegroup
    (
        NAME = courses_online_filegroup_data,
        FILENAME = '/Users/marypishykina/Desktop/DB/lab6/data_log/courses_db_filegroup_data.ndf',
        SIZE = 5MB,
        MAXSIZE = 50MB,
        FILEGROWTH = 5MB
    )
LOG ON 
    (
    NAME = courses_db_log,
    FILENAME = '/Users/marypishykina/Desktop/DB/lab6/data_log/courses_db_log.ldf',
    SIZE = 5MB,
    MAXSIZE = 50MB,
    FILEGROWTH = 5MB
    );
GO

USE courses_db;
GO

DROP TABLE IF EXISTS Users;
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Courses;
DROP TABLE IF EXISTS Teachers;
DROP TABLE IF EXISTS Lessons;
DROP TABLE IF EXISTS OrderCourses;
GO

-- 1 Создать таблицу с автоинкрементным первичным ключом + IDENTITY
CREATE TABLE Users (
    id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,  -- автоинкрементное поле
    name NVARCHAR(50) NOT NULL,
    surname NVARCHAR(50) NULL,
    email NVARCHAR(320) UNIQUE NOT NULL,
    phone VARCHAR(15) NULL DEFAULT '',
    dateBirth DATE NOT NULL CHECK (dateBirth < GETDATE()),  
    registrationDate DATETIME NOT NULL DEFAULT GETDATE(),   
    lastSignIn DATETIME NOT NULL DEFAULT GETDATE()          
);
GO

INSERT INTO Users (name, surname, email, phone, dateBirth, registrationDate, lastSignIn)
VALUES
('Alice', 'Egorova', 'alice.zaiceva@example.com', '+1234567890', '1990-01-15', GETDATE(), GETDATE()),
('Sergey', 'Zakharin', 'iamstarosta_thebest@example.com', NULL, '1992-11-05', GETDATE(), GETDATE());
GO

-- 2 Использование CHECK, DEFAULT, и встроенные функции для вычисления значения
CREATE TABLE Orders (
    id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,  -- автоинкрементное поле
    orderStatus SMALLINT NOT NULL CHECK (orderStatus IN (0, 1, 2)),  -- 0 = создан, 1 = оплачен, 2 = отменён
    purchaseDate DATETIME NOT NULL DEFAULT GETDATE(),               
    paymentMethod SMALLINT NOT NULL CHECK (paymentMethod IN (1, 2, 3)), 
    totalPrice MONEY NOT NULL CHECK (totalPrice > 0)                 
);
GO

INSERT INTO Orders (orderStatus, paymentMethod, totalPrice)
VALUES 
(1, 1, 249.98),  
(0, 2, 49.99);  
GO

SELECT * FROM Users;
SELECT * FROM Orders;

-- 1 IDENTITY и компания

-- SCOPE_IDENTITY()
DECLARE @NewUserID INT;
INSERT INTO Users (name, surname, email, phone, dateBirth, registrationDate, lastSignIn)
VALUES ('Mary', 'Pishikina', 'pisssssh@gmail.com', '+1234567890', '1995-01-01', GETDATE(), GETDATE());

SET @NewUserID = SCOPE_IDENTITY();
SELECT SCOPE_IDENTITY() AS lastUserID1;
GO

-- @@IDENTITY
INSERT INTO Users (name, surname, email, phone, dateBirth, registrationDate, lastSignIn)
VALUES ('Bob', 'Ross', 'bob.ross@gmail.com', '+1234567890', '1960-01-18', GETDATE(), GETDATE());

SELECT @@IDENTITY AS lastUserID2;
GO

-- IDENT_CURRENT
SELECT IDENT_CURRENT('Orders') AS lastOrderID;
GO


-- 4 Создать таблицу с первичным ключом на основе последовательности.
CREATE SEQUENCE teacher_sequence
    AS INT
    START WITH 101
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

-- 3 Создать таблицу с первичным ключом на основе глобального уникального идентификатора.
CREATE TABLE Courses (
    id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(), 
    courseCode NVARCHAR(20) NOT NULL,
    courseName NVARCHAR(100) NOT NULL,
    subjectArea NVARCHAR(60) NOT NULL,
    employeeNumber INT NOT NULL, 
    description NVARCHAR(500) NULL,
    difficulty SMALLINT NOT NULL DEFAULT 1 CHECK (difficulty BETWEEN 1 AND 5), -- Сложность от 1 до 5
    price MONEY NOT NULL CHECK (price > 0) 
);
GO

INSERT INTO Courses (courseCode, courseName, subjectArea, employeeNumber, description, difficulty, price)
VALUES
('DB101', 'Introduction to SQL', 'Databases', 101, 'Basic SQL course covering fundamental database operations.', 1, 49.99),
('PR102', 'Advanced Python Programming', 'Programming', 102, 'Deep dive into advanced Python features including OOP and modules.', 3, 199.99);
GO

SELECT * FROM Courses;
GO

CREATE TABLE Lessons (
    id INT PRIMARY KEY IDENTITY(1,1) NOT NULL, 
    lessonTopic NVARCHAR(100) NOT NULL,
    duration TIME NOT NULL,
    description NVARCHAR(500) NULL,
    publishedDate DATE NOT NULL,
    courseId UNIQUEIDENTIFIER NULL DEFAULT NULL
);
GO

INSERT INTO Lessons (lessonTopic, duration, description, publishedDate, courseId)
VALUES
('SQL Basics', '01:30:00', 'Introduction to SQL basics', '2023-10-01', (SELECT id FROM Courses WHERE courseCode = 'DB101')),
('Python OOP', '02:00:00', 'Object-Oriented Programming in Python', '2022-05-04', (SELECT id FROM Courses WHERE courseCode = 'PR102'));
GO

-- 5 Протестировать ограничений ссылочной целостности (NO ACTION | CASCADE | SET | SET DEFAULT).

ALTER TABLE Lessons
ADD CONSTRAINT FK_Lessons_Courses FOREIGN KEY (courseId) REFERENCES Courses(id)
-- ON DELETE CASCADE;
-- ON DELETE NO ACTION;
ON DELETE SET DEFAULT;
-- ON DELETE SET NULL;
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
