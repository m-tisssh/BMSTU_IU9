USE master;
GO

USE lab8;
GO

--- Пункт 1: Хранимая процедура с курсором для выборки из таблицы
IF OBJECT_ID('dbo.GetCoursesCursor', 'P') IS NOT NULL
    DROP PROCEDURE dbo.GetCoursesCursor;
GO

CREATE PROCEDURE dbo.GetCoursesCursor
    @course_cursor CURSOR VARYING OUTPUT
AS
    SET @course_cursor = CURSOR FORWARD_ONLY STATIC FOR
    SELECT 
        id, 
        courseCode, 
        courseName, 
        subjectArea, 
        employeeNumber, 
        description, 
        difficulty, 
        price
    FROM Courses;
    OPEN @course_cursor;
GO

DECLARE @course_cursor CURSOR;
EXEC dbo.GetCoursesCursor @course_cursor = @course_cursor OUTPUT;
DECLARE 
    @CourseID INT,
    @CourseCode NVARCHAR(20),
    @CourseName NVARCHAR(100),
    @SubjectArea NVARCHAR(60),
    @EmployeeID INT,
    @Description NVARCHAR(500),
    @DifficultyLevel SMALLINT,
    @Price MONEY;

-- Получение первой записи из курсора
FETCH NEXT FROM @course_cursor INTO 
    @CourseID, @CourseCode, @CourseName, @SubjectArea, @EmployeeID, @Description, @DifficultyLevel, @Price;
-- Обход всех записей, возвращенных курсором
WHILE (@@FETCH_STATUS = 0)
BEGIN
    PRINT CONCAT(
        'CourseID: ', CAST(@CourseID AS VARCHAR(10)), 
        ' | Code: ', @CourseCode, 
        ' | Name: ', @CourseName, 
        ' | Subject Area: ', @SubjectArea, 
        ' | EmployeeID: ', CAST(@EmployeeID AS VARCHAR(10)), 
        ' | Difficulty: ', CAST(@DifficultyLevel AS VARCHAR(10)), 
        ' | Price: $', CAST(@Price AS VARCHAR(20))
    );
    -- Переход к следующей записи
    FETCH NEXT FROM @course_cursor INTO 
        @CourseID, @CourseCode, @CourseName, @SubjectArea, @EmployeeID, @Description, @DifficultyLevel, @Price;
END;

-- Закрытие и удаление курсора
CLOSE @course_cursor;
DEALLOCATE @course_cursor;
GO


--- Пункт 2: Пользовательская функция для объединения данных о курсе
IF OBJECT_ID('dbo.ConcatCourseNameSubject', 'FN') IS NOT NULL
    DROP FUNCTION dbo.ConcatCourseNameSubject;
GO

CREATE FUNCTION dbo.ConcatCourseNameSubject (
    @CourseName NVARCHAR(100),
    @SubjectArea NVARCHAR(60)
)
RETURNS NVARCHAR(160)
AS
BEGIN
    RETURN CONCAT(@CourseName, ' >-< ', @SubjectArea);
END;
GO

IF OBJECT_ID('dbo.GetCoursesWithConcat', 'P') IS NOT NULL
    DROP PROCEDURE dbo.GetCoursesWithConcat;
GO

CREATE PROCEDURE dbo.GetCoursesWithConcat
@cursor CURSOR VARYING OUTPUT
AS
BEGIN
    SET @cursor = CURSOR FORWARD_ONLY STATIC FOR
        SELECT
            id AS CourseID,
            dbo.ConcatCourseNameSubject(courseName, subjectArea) AS TopicOfCourse,
            courseCode AS CourseCode,
            employeeNumber AS EmployeeID,
            description AS Description,
            difficulty AS DifficultyLevel,
            price AS Price
        FROM Courses;
    OPEN @cursor;
END;
GO

DECLARE @course_cursor CURSOR;
EXEC dbo.GetCoursesWithConcat @cursor = @course_cursor OUTPUT;

-- Объявление переменных для данных из курсора
DECLARE
    @CourseID INT,
    @TopicOfCourse NVARCHAR(160),
    @CourseCode NVARCHAR(20),
    @EmployeeID INT,
    @Description NVARCHAR(500),
    @DifficultyLevel SMALLINT,
    @Price MONEY;

FETCH NEXT FROM @course_cursor INTO 
    @CourseID, @TopicOfCourse, @CourseCode, @EmployeeID, @Description, @DifficultyLevel, @Price;

WHILE (@@FETCH_STATUS = 0)
BEGIN
    PRINT CONCAT(
        'CourseID: ', CAST(@CourseID AS VARCHAR(10)),
        ' | Topic: ', @TopicOfCourse,
        ' | Code: ', @CourseCode,
        ' | Difficulty: ', CAST(@DifficultyLevel AS VARCHAR(10)),
        ' | Price: $', CAST(@Price AS VARCHAR(20))
    );

    FETCH NEXT FROM @course_cursor INTO 
        @CourseID, @TopicOfCourse, @CourseCode, @EmployeeID, @Description, @DifficultyLevel, @Price;
END;

CLOSE @course_cursor;
DEALLOCATE @course_cursor;
GO


--- Пункт 3: Пользовательская функция для проверки уровня сложности курса
IF OBJECT_ID('dbo.CalculateCourseRating', 'FN') IS NOT NULL
    DROP FUNCTION dbo.CalculateCourseRating;
GO

CREATE FUNCTION dbo.CalculateCourseRating (
    @difficulty SMALLINT, 
    @price MONEY
)
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @rating NVARCHAR(50);

    IF @difficulty <= 2 AND @price < 1000
        SET @rating = 'Beginner';
    ELSE IF @difficulty BETWEEN 3 AND 4
        SET @rating = 'Intermediate';
    ELSE
        SET @rating = 'Advanced';

    RETURN @rating;
END;
GO

--- Обновленная процедура для обработки данных с использованием CalculateCourseRating
IF OBJECT_ID('dbo.ProcessCourses', 'P') IS NOT NULL
    DROP PROCEDURE dbo.ProcessCourses;
GO

CREATE PROCEDURE dbo.ProcessCourses
AS
BEGIN
    DECLARE @CourseID INT;
    DECLARE @CourseCode NVARCHAR(20);
    DECLARE @CourseName NVARCHAR(100);
    DECLARE @SubjectArea NVARCHAR(60);
    DECLARE @EmployeeID INT;
    DECLARE @Description NVARCHAR(500);
    DECLARE @DifficultyLevel SMALLINT;
    DECLARE @Price MONEY;
    DECLARE @CourseDetails NVARCHAR(160);
    DECLARE @CourseRating NVARCHAR(50);

    DECLARE @CourseCursor CURSOR;
    EXEC dbo.GetCoursesCursor @course_cursor = @CourseCursor OUTPUT;

    FETCH NEXT FROM @CourseCursor INTO 
        @CourseID, @CourseCode, @CourseName, @SubjectArea, @EmployeeID, @Description, @DifficultyLevel, @Price;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @CourseDetails = dbo.ConcatCourseNameSubject(@CourseName, @SubjectArea);
        SET @CourseRating = dbo.CalculateCourseRating(@DifficultyLevel, @Price);

        PRINT CONCAT('Course: ', @CourseDetails, ' - Rating: ', @CourseRating, ' - Price: ', @Price);

        FETCH NEXT FROM @CourseCursor INTO 
            @CourseID, @CourseCode, @CourseName, @SubjectArea, @EmployeeID, @Description, @DifficultyLevel, @Price;
    END;

    CLOSE @CourseCursor;
    DEALLOCATE @CourseCursor;
END;
GO

EXEC dbo.ProcessCourses;
GO



---- Пункт 4: Табличная функция для выборки курсов
IF OBJECT_ID('dbo.GetCoursesTable', 'IF') IS NOT NULL
    DROP FUNCTION dbo.GetCoursesTable;
GO

DROP FUNCTION IF EXISTS dbo.GetCoursesTableV2;
GO

CREATE FUNCTION dbo.GetCoursesTableV1()
RETURNS TABLE
AS
RETURN
(
    SELECT 
        id AS CourseID, 
        courseCode AS CourseCode, 
        dbo.ConcatCourseNameSubject(courseName, subjectArea) AS TopicOfCourse,
        employeeNumber AS EmployeeID, 
        description AS Description, 
        difficulty AS DifficultyLevel, 
        price AS Price
    FROM Courses
    WHERE difficulty > 3
);
GO

SELECT *
FROM dbo.GetCoursesTableV1()
WHERE DifficultyLevel > 3;
GO


DROP FUNCTION IF EXISTS dbo.GetCoursesTableV2;
GO

CREATE FUNCTION dbo.GetCoursesTableV2()
RETURNS @CourseData TABLE 
(
    CourseID INT,
    TopicOfCourse NVARCHAR(160),
    CourseCode NVARCHAR(20),
    EmployeeID INT,
    Description NVARCHAR(500),
    DifficultyLevel SMALLINT,
    Price MONEY,
    CourseRating NVARCHAR(50)
)
AS
BEGIN
    INSERT INTO @CourseData (CourseID, TopicOfCourse, CourseCode, EmployeeID, Description, DifficultyLevel, Price, CourseRating)
    SELECT 
        id AS CourseID,
        dbo.ConcatCourseNameSubject(courseName, subjectArea) AS TopicOfCourse,
        courseCode AS CourseCode,
        employeeNumber AS EmployeeID,
        description AS Description,
        difficulty AS DifficultyLevel,
        price AS Price,
        dbo.CalculateCourseRating(difficulty, price) AS CourseRating
    FROM Courses;

    RETURN;
END;
GO

SELECT *
FROM dbo.GetCoursesTableV2()
WHERE CourseRating = 'Intermediate';
GO