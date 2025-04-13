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
    id INT PRIMARY KEY NOT NULL,
    courseCode NVARCHAR(20) NOT NULL,
    courseName NVARCHAR(100) NOT NULL,
    subjectArea NVARCHAR(60) NOT NULL
);
GO

USE lab13_2;
GO
CREATE TABLE Courses (
    id INT PRIMARY KEY NOT NULL,
    employeeNumber INT NOT NULL,
    description NVARCHAR(500) NULL,
    difficulty SMALLINT NOT NULL DEFAULT 1 CHECK (difficulty BETWEEN 1 AND 5),
    price MONEY NOT NULL CHECK (price > 0)
);
GO

DROP VIEW IF EXISTS CoursesUnion;
GO

CREATE VIEW CoursesUnion AS
SELECT 
    C1.id,
    C1.courseCode,
    C1.courseName,
    C1.subjectArea,
    C2.employeeNumber,
    C2.description,
    C2.difficulty,
    C2.price
FROM lab13_1.dbo.Courses C1
JOIN lab13_2.dbo.Courses C2 ON C1.id = C2.id;
GO

-- Триггер для вставки 
CREATE TRIGGER InsertCoursesUnion ON CoursesUnion
INSTEAD OF INSERT
AS
BEGIN
    INSERT INTO lab13_1.dbo.Courses (id, courseCode, courseName, subjectArea)
    SELECT id, courseCode, courseName, subjectArea FROM INSERTED;

    INSERT INTO lab13_2.dbo.Courses (id, employeeNumber, description, difficulty, price)
    SELECT id, employeeNumber, description, difficulty, price FROM INSERTED;
END;
GO

-- Триггера для обновления 
CREATE TRIGGER UpdateCoursesUnion ON CoursesUnion
INSTEAD OF UPDATE
AS
BEGIN
    -- запрет изменения id
    IF UPDATE(id)
    BEGIN
        RAISERROR('Изменять id запрещено.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- обновление данных в таб 1
    UPDATE lab13_1.dbo.Courses
    SET 
        courseCode = I.courseCode,
        courseName = I.courseName,
        subjectArea = I.subjectArea
    FROM INSERTED I
    WHERE lab13_1.dbo.Courses.id = I.id;

    -- обновление данных в таб 2
    UPDATE lab13_2.dbo.Courses
    SET 
        employeeNumber = I.employeeNumber,
        description = I.description,
        difficulty = I.difficulty,
        price = I.price
    FROM INSERTED I
    WHERE lab13_2.dbo.Courses.id = I.id;
END;
GO

-- Триггер для удаления 
CREATE TRIGGER DeleteCoursesUnion ON CoursesUnion
INSTEAD OF DELETE
AS
BEGIN
    DELETE FROM lab13_1.dbo.Courses
    WHERE id IN (SELECT id FROM DELETED);

    DELETE FROM lab13_2.dbo.Courses
    WHERE id IN (SELECT id FROM DELETED);
END;
GO

INSERT INTO CoursesUnion (id, courseCode, courseName, subjectArea, employeeNumber, description, difficulty, price)
VALUES
(1, 'CS101', 'Intro to CS', 'Computer Science', 101, 'Basics of CS', 1, 49.99),
(2, 'ML201', 'Machine Learning', 'Artificial Intelligence', 102, 'Introduction to ML', 3, 149.99),
(3, 'DB301', 'Advanced SQL', 'Databases', 103, 'Deep dive into SQL', 4, 199.99);
GO

UPDATE CoursesUnion
SET description = 'Обновлено описание у курса 1', difficulty = 2
WHERE id = 1;

-- Триггер на изменение id (запрещено)
-- UPDATE CoursesUnion
-- SET id = 4
-- WHERE id = 1;

DELETE FROM CoursesUnion WHERE id = 2;

SELECT * FROM CoursesUnion;
SELECT * FROM lab13_1.dbo.Courses;
SELECT * FROM lab13_2.dbo.Courses;
GO
