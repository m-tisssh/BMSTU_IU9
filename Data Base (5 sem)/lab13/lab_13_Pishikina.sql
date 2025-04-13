USE master;
GO

ALTER DATABASE lab13_1 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

DROP DATABASE IF EXISTS lab13_1;
GO

CREATE DATABASE lab13_1;
GO

ALTER DATABASE lab13_2 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

DROP DATABASE IF EXISTS lab13_2;
GO

CREATE DATABASE lab13_2;
GO


USE lab13_1;
GO

CREATE TABLE Courses (
    id INT PRIMARY KEY NOT NULL CHECK (id < 4),
    courseCode NVARCHAR(20) NOT NULL,
    courseName NVARCHAR(100) NOT NULL,
    subjectArea NVARCHAR(60) NOT NULL,
    employeeNumber INT NOT NULL,
    description NVARCHAR(500) NULL,
    difficulty SMALLINT NOT NULL DEFAULT 1 CHECK (difficulty BETWEEN 1 AND 5),
    price MONEY NOT NULL CHECK (price > 0)
);
GO


USE lab13_2;
GO

CREATE TABLE Courses (
    id INT PRIMARY KEY NOT NULL CHECK (id >= 4), 
    courseCode NVARCHAR(20) NOT NULL,
    courseName NVARCHAR(100) NOT NULL,
    subjectArea NVARCHAR(60) NOT NULL,
    employeeNumber INT NOT NULL,
    description NVARCHAR(500) NULL,
    difficulty SMALLINT NOT NULL DEFAULT 1 CHECK (difficulty BETWEEN 1 AND 5),
    price MONEY NOT NULL CHECK (price > 0)
);
GO

INSERT INTO lab13_1.dbo.Courses (id, courseCode, courseName, subjectArea, employeeNumber, description, difficulty, price)
VALUES
(1, 'CS101', 'Intro to CS', 'Computer Science', 101, 'Learn the basics of CS.', 1, 49.99),
(2, 'DB102', 'SQL Basics', 'Databases', 102, 'Learn SQL fundamentals.', 2, 59.99),
(3, 'PY201', 'Python Programming', 'Programming', 103, 'Intermediate Python.', 3, 79.99);

SELECT * FROM lab13_1.dbo.Courses;

INSERT INTO lab13_2.dbo.Courses (id, courseCode, courseName, subjectArea, employeeNumber, description, difficulty, price)
VALUES
(4, 'ML301', 'Machine Learning', 'AI', 201, 'Learn ML concepts.', 4, 99.99),
(5, 'UX101', 'Intro to UX Design', 'Design', 202, 'Basics of user experience.', 2, 39.99);

SELECT * FROM lab13_2.dbo.Courses;
GO

-- представление CoursesUnion для объединения данных из двух таблиц
CREATE VIEW CoursesUnion AS
SELECT * FROM lab13_1.dbo.Courses
UNION ALL
SELECT * FROM lab13_2.dbo.Courses;
GO

INSERT INTO CoursesUnion (id, courseCode, courseName, subjectArea, employeeNumber, description, difficulty, price)
VALUES
(0, 'TEST', 'Test Course', 'Testing', 999, 'This is a test course.', 1, 1.00),
(6, 'AI401', 'AI Fundamentals', 'AI', 203, 'Advanced AI topics.', 4, 129.99),
(7, 'DS101', 'Data Science', 'Data Science', 204, 'Data Science basics.', 3, 89.99),
(8, 'WD101', 'Web Development', 'Programming', 205, 'HTML, CSS, JS basics.', 2, 69.99);
GO

UPDATE CoursesUnion SET price = 999.99 WHERE id = 1;
UPDATE CoursesUnion SET id = 999 WHERE id = 2;

DELETE FROM CoursesUnion WHERE id = 2;

SELECT * FROM CoursesUnion;
SELECT * FROM lab13_1.dbo.Courses;
SELECT * FROM lab13_2.dbo.Courses;
GO
