USE master;
GO

DROP DATABASE IF EXISTS lab9_2;
GO

CREATE DATABASE lab9_2
ON PRIMARY
    (
        NAME = lab9_data,
        FILENAME = '/Users/marypishykina/Desktop/DB/lab9/data_log/lab9_data.mdf',
        SIZE = 5MB,
        MAXSIZE = 50MB,
        FILEGROWTH = 5MB
    )
LOG ON
    (
        NAME = lab9_log,
        FILENAME = '/Users/marypishykina/Desktop/DB/lab9/data_log/lab9_log.ldf',
        SIZE = 5MB,
        MAXSIZE = 50MB,
        FILEGROWTH = 5MB
    );
GO

USE lab9_2;
GO

CREATE TABLE Teachers (
    id INT PRIMARY KEY NOT NULL,
    name NVARCHAR(50) NOT NULL,
    surname NVARCHAR(50) NOT NULL,
    email NVARCHAR(320) UNIQUE NOT NULL,
    dateBirth DATE NOT NULL,
    educationLevel SMALLINT NULL CHECK (educationLevel BETWEEN 1 AND 5), -- Уровень образования от 1 до 5
    about NVARCHAR(500) NULL
);
GO

INSERT INTO Teachers (id, name, surname, email, dateBirth, educationLevel, about)
VALUES
(52, 'Sasha', 'Medvedeva', 'memdved_privet@gmail.com', '1996-07-26', 5, NULL),
(89, 'Abraham', 'Lincoln', 'us.lincoln.com', '1985-03-30', 4, 'Specialist in mathematics and statistics.'),
(102, 'Jane', 'Smith', 'jane.smith@example.com', '1982-03-22', 4, 'Python programming expert');


CREATE TABLE Courses (
    id INT PRIMARY KEY NOT NULL,
    courseCode NVARCHAR(20) UNIQUE NOT NULL,
    courseName NVARCHAR(100) NOT NULL,
    subjectArea NVARCHAR(60) NOT NULL,
    employeeNumber INT FOREIGN KEY REFERENCES Teachers(id),
    description NVARCHAR(500) NULL,
    difficulty SMALLINT NOT NULL DEFAULT 1 CHECK (difficulty BETWEEN 1 AND 5), -- Сложность от 1 до 5
    price MONEY NOT NULL CHECK (price > 0) 
);
GO

INSERT INTO Courses (id, courseCode, courseName, subjectArea, employeeNumber, description, difficulty, price)
VALUES
(2372, 'DB101', 'Introduction to SQL', 'Databases', 89, 'Basic SQL course covering fundamental database operations.', 1, 49.99),
(5225, 'AI888', 'What is AI', 'Artificial Intelligence', 52, '>>>>>>', 1, 5.99),
(4721, 'PR102', 'Advanced Python Programming', 'Programming', 102, 'Deep dive into advanced Python features including OOP and modules.', 3, 199.99);
GO


------------- ЗАДАНИЕ 1 -----------

-- 1. Триггер на вставку
IF OBJECT_ID('trg_InsertCourse', 'TR') IS NOT NULL
    DROP TRIGGER trg_InsertCourse;
GO

CREATE TRIGGER trg_InsertCourse
ON Courses
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM Inserted i
        JOIN Teachers t ON i.employeeNumber = t.id
        WHERE i.difficulty > t.educationLevel
    )
    BEGIN
        RAISERROR('Сложность курса не может превышать уровень образования преподавателя.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- тестирование 
INSERT INTO Courses (id, courseCode, courseName, subjectArea, employeeNumber, description, difficulty, price)
VALUES (9001, 'DB202', 'Advanced SQL', 'Databases', 937, 'Deep SQL knowledge', 5, 299.99);
GO
-- Ожидается ошибка: The course difficulty exceeds the education level of the teacher.

-- 2. Триггер на обновление
IF OBJECT_ID('trg_UpdateCourse', 'TR') IS NOT NULL
    DROP TRIGGER trg_UpdateCourse;
GO

CREATE TRIGGER trg_UpdateCourse
ON Courses
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(difficulty)
    BEGIN
        UPDATE c
        SET c.description = CONCAT(c.description, ' (Обновленная сложность: ', i.difficulty, ')')
        FROM Courses c
        JOIN Inserted i ON c.id = i.id;
    END
END;
GO

-- Обновим сложность курса id=2372
UPDATE Courses
SET difficulty = 2
WHERE id=2372
GO

--3. Триггер на удаление
-- Удаляем старую таблицу
DROP TABLE IF EXISTS DeletedCourses;

-- Создаём таблицу без ограничения на первичный ключ
CREATE TABLE DeletedCourses (
    id INT NOT NULL,
    courseCode NVARCHAR(20),
    courseName NVARCHAR(100),
    deletedAt DATETIME DEFAULT GETDATE()
);
GO

IF OBJECT_ID('trg_DeleteCourse', 'TR') IS NOT NULL
    DROP TRIGGER trg_DeleteCourse;
GO

CREATE TRIGGER trg_DeleteCourse
ON Courses
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO DeletedCourses (id, courseCode, courseName)
    SELECT id, courseCode, courseName
    FROM Deleted;
END;
GO

/*INSERT INTO Courses (id, courseCode, courseName, subjectArea, employeeNumber, description, difficulty, price)
VALUES (9003, 'ML937', 'Introduction to Machine Learning', 'Artificial Intelligence', 937, 'Basics of machine learning', 2, 149.99);
GO
*/
SELECT * FROM Courses;
GO

DELETE FROM Courses WHERE id = 9003;
GO

SELECT * FROM DeletedCourses;
GO


------------- ЗАДАНИЕ 2 -----------

DROP VIEW IF EXISTS CoursesAndTeachersInfo;
GO

CREATE VIEW CoursesAndTeachersInfo AS
SELECT 
    t.id AS teacherId,
    t.name,
    t.surname,
    t.email,
    t.dateBirth,
    t.educationLevel,
    c.id AS courseId,
    c.courseName,
    c.courseCode,
    c.subjectArea,
    c.difficulty,
    c.price
FROM dbo.Courses c
LEFT JOIN dbo.Teachers t
ON c.employeeNumber = t.id;
GO

-- INSERT
IF OBJECT_ID('InsertCoursesAndTeachersInfo', 'TR') IS NOT NULL
    DROP TRIGGER InsertCoursesAndTeachersInfo;
GO

CREATE TRIGGER InsertCoursesAndTeachersInfo ON CoursesAndTeachersInfo
INSTEAD OF INSERT
AS
BEGIN
    -- Запрет вставки преподавателя без курса
    IF EXISTS (
        SELECT 1
        FROM INSERTED I
        WHERE I.courseId IS NULL OR I.courseName IS NULL
    )
    BEGIN
        RAISERROR ('Преподаватель должен иметь как минимум один курс.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- Вставка новых преподавателей, если их нет в таблице Teachers
    INSERT INTO Teachers (id, name, surname, email, dateBirth, educationLevel)
    SELECT DISTINCT I.teacherId, I.name, I.surname, I.email, I.dateBirth, I.educationLevel
    FROM INSERTED I
    -- WHERE NOT EXISTS (
    --     SELECT 1
    --     FROM Teachers T
    --     WHERE I.teacherId = T.id
    -- );

    -- Вставка курсов
    INSERT INTO Courses (id, courseName, courseCode, subjectArea, difficulty, price, employeeNumber)
    SELECT
        I.courseId, I.courseName, I.courseCode, I.subjectArea, I.difficulty, I.price, T.id AS employeeNumber
    FROM INSERTED I
    --INNER JOIN Teachers T ON T.id = I.teacherId
END;
GO


-- Проверка 1 - удачно
INSERT INTO CoursesAndTeachersInfo (
    teacherId, name, surname, email, dateBirth, educationLevel,
    courseId, courseName, courseCode, subjectArea, difficulty, price
)
VALUES
    (1, 'Martin', 'Luther', 'mmmartin@example.com', '1980-05-10', 4,
     191, 'Math in short', 'MATH191', 'Mathematics', 1, 10.00);
GO

-- Проверка 2 - неудачно 
INSERT INTO CoursesAndTeachersInfo (
    teacherId, name, surname, email, dateBirth, educationLevel,
    courseId, courseName, courseCode, subjectArea, difficulty, price
)
VALUES
    (2, 'Alice', 'Egorova', 'zaiceva@example.com', '1990-02-15', 4,   -- Проверка 2 - неудача
     NULL, NULL, NULL, NULL, NULL, NULL); -- Курс отсутствует
GO

SELECT * FROM Teachers;
SELECT * FROM Courses;
GO


---- UPDATE ----
IF OBJECT_ID('UpdateCoursesAndTeachersInfo', 'TR') IS NOT NULL
    DROP TRIGGER UpdateCoursesAndTeachersInfo;
GO

CREATE TRIGGER UpdateCoursesAndTeachersInfo ON CoursesAndTeachersInfo
INSTEAD OF UPDATE
AS
BEGIN
    -- Запрещается измененять ключевые поля teacherId, courseId,
    IF (UPDATE(teacherId) OR UPDATE(courseId))
    BEGIN
        RAISERROR('Изменять teacherId, courseId запрещено.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    UPDATE Teachers
    SET
        name = I.name,
        surname = I.surname,
        email = I.email,
        dateBirth = I.dateBirth,
        educationLevel = I.educationLevel
    FROM Teachers T
    INNER JOIN INSERTED I ON T.id = I.teacherId;

    UPDATE Courses
    SET
        subjectArea = I.subjectArea,
        difficulty = I.difficulty,
        price = I.price,
        courseCode = I.courseCode
    FROM Courses C
    INNER JOIN INSERTED I ON C.id = I.courseId;
END;
GO

UPDATE CoursesAndTeachersInfo
SET teacherId = 999
WHERE courseId = 101;
GO

UPDATE CoursesAndTeachersInfo
SET
    email = 'new.emailllll@example.com',
    subjectArea = 'Advanced Mathematics :)',
    price = 250.99
WHERE teacherId = 102;
GO

SELECT * FROM Teachers;
SELECT * FROM Courses;
GO

---- DELETE ----
CREATE TRIGGER DeleteCoursesAndTeachersInfo ON CoursesAndTeachersInfo
INSTEAD OF DELETE
AS
BEGIN
    DELETE FROM Courses
    WHERE id IN (SELECT courseId FROM DELETED);

    -- Удаление преподавателей, оставшихся без курсов
    DELETE FROM Teachers
    WHERE id IN (
        SELECT teacherId
        FROM DELETED
        WHERE NOT EXISTS (
            SELECT 1 FROM Courses WHERE employeeNumber = teacherId
        )
    );
END;
GO

DELETE FROM CoursesAndTeachersInfo
WHERE courseId = 191;

-- Проверка результата
SELECT * FROM CoursesAndTeachersInfo;
SELECT * FROM Courses;
SELECT * FROM Teachers;
GO
