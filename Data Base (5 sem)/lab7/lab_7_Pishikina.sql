USE online_courses;
GO

-- Удаление зависимых объектов
DROP VIEW IF EXISTS v_courses;
GO
DROP VIEW IF EXISTS v_teachers;
GO
DROP INDEX Teachers.index_teachers
GO

-- Создание представления для преподавателей
CREATE VIEW v_teachers AS
SELECT id, name, surname FROM Teachers;
GO

-- Проверка данных представления
SELECT * FROM v_teachers;
GO

-- Создание представления на основе полей обеих связанных таблиц 
-- SCHEMABINDING гарантирует связь представления и таблицы
CREATE VIEW v_courses WITH SCHEMABINDING AS
SELECT 
    t.id AS teacherId,
    t.name AS teacherName,
    t.surname AS teacherSurname,
    c.courseName,
    c.courseCode,
    c.price
FROM dbo.Courses c
JOIN dbo.Teachers t
ON c.employeeNumber = t.id;
GO

SELECT * FROM v_courses;
GO

-- Создание индекса для одной из таблиц, включив в него дополнительные неключевые поля.
CREATE INDEX index_teachers
ON Teachers (email)
INCLUDE (educationLevel)
GO

SELECT email, educationLevel 
FROM Teachers
WHERE email = 'jane.smith@example.com'

-- Создание кластерного индекса на представлении
CREATE UNIQUE CLUSTERED INDEX idx_v_courses_courseCode
ON v_courses (courseCode);
GO

SELECT courseCode, courseName, teacherName, price 
FROM v_courses
WHERE courseCode = 'DB104';
GO

use master
GO