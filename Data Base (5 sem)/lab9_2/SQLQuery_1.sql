

-- ВЕРСИЯ 2 (исправленная)

CREATE TRIGGER trg_Insert_v_courses
ON v_courses
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Проверяем, существует ли преподаватель с указанным teacherId
    IF EXISTS (
        SELECT 1
        FROM Inserted i
        LEFT JOIN Teachers t ON i.teacherId = t.id
        WHERE t.id IS NULL
    )
    BEGIN
        INSERT INTO Teachers (id, name, surname, email, dateBirth, educationLevel, about)
        SELECT DISTINCT
            i.teacherId,
            i.teacherName, 
            i.teacherSurname,
            i.teacherEmail,  
            NULL,  
            NULL,  
            NULL   
        WHERE NOT EXISTS (
            SELECT 1
            FROM Teachers t
            WHERE t.id = i.teacherId
        );
    END;

    IF EXISTS (
        SELECT 1
        FROM Inserted
        WHERE courseId IS NULL
    )
    BEGIN
        RAISERROR('Course ID не может быть NULL. Укажите корректный ID.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    INSERT INTO Courses (id, courseCode, courseName, price, subjectArea, employeeNumber)
    SELECT 
        i.courseId, 
        i.courseCode, 
        i.courseName, 
        i.price, 
        i.subjectArea, 
        i.teacherId
    FROM Inserted i;
END;
GO

---- изначальная
CREATE TRIGGER trg_Update_v_courses
ON v_courses
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Обновляем данные курса
    UPDATE Courses
    SET courseName = i.courseName,
        courseCode = i.courseCode,
        price = i.price
    FROM Courses c
    JOIN Inserted i ON c.courseCode = i.courseCode;
END;
GO

-- Версия 2 (исправленная)

CREATE TRIGGER trg_Update_v_courses
ON v_courses
INSTEAD OF UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE c
    SET 
        c.courseName = i.courseName,
        c.subjectArea = i.subjectArea,
        c.difficulty = i.difficulty,
        c.price = i.price
    FROM Courses c
    JOIN Inserted i ON c.id = i.courseId;
    
END;
GO

INSERT INTO v_courses (courseId, courseCode, teacherId, courseName, subjectArea, difficulty, price)
VALUES (1, 'CS101', 101, 'Introduction to Computer Science', 'Computer Science', 3, 100);

-- ошибка
UPDATE v_courses
SET courseCode = 'CS102', teacherId = 102
WHERE courseId = 1;

-- Попытка обновить только разрешенные поля
UPDATE v_courses
SET courseName = 'Advanced Computer Science', subjectArea = 'Computer Science', difficulty = 4, price = 200
WHERE courseId = 1;