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
CREATE TABLE Teachers (
    id INT PRIMARY KEY NOT NULL,
    name NVARCHAR(50) NOT NULL,
    surname NVARCHAR(50) NULL,
    email NVARCHAR(320) UNIQUE NOT NULL,
    dateBirth DATE NOT NULL,
    educationLevel SMALLINT NULL CHECK (educationLevel BETWEEN 1 AND 5), -- Уровень образования от 1 до 5
    about NVARCHAR(500) NULL
);
GO

-- Создание таблицы Courses в базе lab_courses2
USE lab13_2;
GO
CREATE TABLE Courses (
    id INT PRIMARY KEY NOT NULL,
    courseCode NVARCHAR(20) NOT NULL,
    courseName NVARCHAR(100) NOT NULL,
    subjectArea NVARCHAR(60) NOT NULL,
    employeeNumber INT NOT NULL, -- внешний ключ на Teachers.id
    description NVARCHAR(500) NULL,
    difficulty SMALLINT NOT NULL DEFAULT 1 CHECK (difficulty BETWEEN 1 AND 5),
    price MONEY NOT NULL CHECK (price > 0)
);
GO

USE lab13_1;
GO

-- Триггер на обновление в таб 1
CREATE TRIGGER UpdateTeachers ON Teachers
AFTER UPDATE
AS
BEGIN
    IF UPDATE(id)
    BEGIN 
        RAISERROR('Изменять id запрещено.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

-- Триггер на удаление в таб 1
CREATE TRIGGER DeleteTeachers ON Teachers
AFTER DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM lab13_2.dbo.Courses C
        INNER JOIN DELETED D ON C.employeeNumber = D.id
    )
    BEGIN
        RAISERROR('Удаление невозможно, так как есть связанные записи в таблице Courses.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    DELETE FROM Teachers WHERE id IN (SELECT id FROM DELETED);
END;
GO


USE lab13_2;
GO

-- Триггер на вставку в таб 2
CREATE TRIGGER InsertCourses ON Courses
AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT * FROM INSERTED
        WHERE employeeNumber NOT IN (SELECT id FROM lab13_1.dbo.Teachers)
    )
    BEGIN
        RAISERROR('Вставка невозможна, так как преподаватель с таким employeeNumber не существует в таблице Teachers.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- Триггер на обновление в таб 2
CREATE TRIGGER UpdateCourses ON Courses
AFTER UPDATE
AS
BEGIN
    IF UPDATE(id)
    BEGIN 
        RAISERROR('Изменять id запрещено.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    IF UPDATE(employeeNumber)
    BEGIN
        IF EXISTS (
            SELECT * FROM INSERTED
            WHERE employeeNumber NOT IN (SELECT id FROM lab13_1.dbo.Teachers)
        )
        BEGIN
            RAISERROR('Обновление невозможно, так как преподаватель с таким employeeNumber не существует в таблице Teachers.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
    END;
END;
GO

USE lab13_1;
GO
INSERT INTO Teachers (id, name, surname, email, dateBirth, educationLevel, about)
VALUES
(1, 'Alice', 'Egorova', 'alice.zaiceva@example.com', '2004-05-15', 4, 'Senior instructor of AI'),
(2, 'Sergey', 'Zakharin', 'iamstarosta_thebest@example.com', '2004-11-24', 3, 'Database expert'),
(3, 'Mark', 'Shagal', 'art_france_shag@example.com', '1985-08-20', 5, 'Art expert');
GO

USE lab13_2;
GO
INSERT INTO Courses (id, courseCode, courseName, subjectArea, employeeNumber, description, difficulty, price)
VALUES
(1, 'CS101', 'Intro to Computer Science', 'Computer Science', 1, 'Basics of computer science', 2, 49.99),
(2, 'DB202', 'Databases Fundamentals', 'Databases', 2, 'Learn SQL and relational databases', 3, 99.99),
(3, 'A303', 'Art in 19th century', 'Web', 3, 'How artisrs draw their paintings', 4, 149.99);
GO

-- Тестовые операции
-- Запрещённые операции:
-- UPDATE lab13_1.dbo.Teachers SET id = 999 WHERE id = 1;
-- DELETE FROM lab13_1.dbo.Teachers WHERE id = 1;

-- INSERT INTO lab13_2.dbo.Courses (id, courseCode, courseName, subjectArea, employeeNumber, description, difficulty, price)
-- VALUES (4, 'AI404', 'Artificial Intelligence', 'AI', 999, 'AI basics', 5, 199.99);

-- UPDATE lab13_2.dbo.Courses SET employeeNumber = 999 WHERE id = 1;

-- Удаление и обновление разрешённых записей:
DELETE FROM lab13_2.dbo.Courses WHERE id = 2;
UPDATE lab13_2.dbo.Courses SET price = 79.99 WHERE id = 1;


SELECT * FROM lab13_1.dbo.Teachers;
SELECT * FROM lab13_2.dbo.Courses;
GO
