USE master
GO

DROP DATABASE IF EXISTS online_courses;
GO

-- 1 Создвть БД + настройка файлов
CREATE DATABASE online_courses
ON PRIMARY 
    (
        NAME = online_courses_data,
        FILENAME = '/Users/marypishykina/Desktop/DB/lab5/data_log/online_courses_data.mdf',
        SIZE = 5MB,
        MAXSIZE = 50MB,
        FILEGROWTH = 5MB
    )
, FILEGROUP LargeFileGroup
    (
        NAME = online_courses_large_data,
        FILENAME = '/Users/marypishykina/Desktop/DB/lab5/data_log/courses_large_data.ndf',
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
-- 2 Создать произвольную группу 
USE online_courses;
GO

DROP TABLE IF EXISTS Users;
GO

CREATE TABLE Users (
    id INT PRIMARY KEY NOT NULL,
    email VARCHAR(320) UNIQUE NOT NULL,
    firstName VARCHAR(50) NOT NULL,
    lastName VARCHAR(50) NULL,
    passportNumber VARCHAR(15) NOT NULL,
    phoneNumber VARCHAR(15) NULL,
    dateBirth DATE NOT NULL
);
GO

-- 3 Добавить файловую группу и файл данных 
ALTER DATABASE online_courses
ADD FILEGROUP online_courses_filegroup;
GO

ALTER DATABASE online_courses
ADD FILE 
    (
        NAME = online_courses_filegroup_data,
        FILENAME = '/Users/marypishykina/Desktop/DB/lab5/data_log/online_courses_filegroup_data.ndf',
        SIZE = 5MB,
        MAXSIZE = 50MB,
        FILEGROWTH = 5MB
    ) 
TO FILEGROUP online_courses_filegroup;
GO

-- 4 Сделать созданную файловую группу файловой группой по умолчанию
ALTER DATABASE online_courses
MODIFY FILEGROUP online_courses_filegroup DEFAULT;
GO

-- 5 Создать еще одну произвольную таблицу

CREATE TABLE Courses (
    id INT PRIMARY KEY NOT NULL,
    courseName NVARCHAR(100) NOT NULL,
    subjectArea NVARCHAR(60) NOT NULL,
    employeeNumber INT NOT NULL,
    description NVARCHAR(500) NULL,
    difficulty SMALLINT NOT NULL,
    price MONEY NOT NULL
);
GO

INSERT INTO Courses (id, courseName, subjectArea, employeeNumber, description, difficulty, price)
VALUES
(1, 'Introduction to SQL', 'Databases', 101, 'Basic SQL course covering fundamental database operations.', 1, 49.99),
(2, 'Advanced Python Programming', 'Programming', 102, 'Deep dive into advanced Python features including OOP and modules.', 3, 199.99);

-- 
DROP TABLE IF EXISTS CoursesBackups;
GO

SELECT * INTO CoursesBackups FROM Courses;

DROP TABLE Courses;
SELECT * FROM CoursesBackups;

-- 6 Удалить созданную вручную файловую группу

ALTER DATABASE online_courses
REMOVE FILE online_courses_large_data;
GO

ALTER DATABASE online_courses
REMOVE FILEGROUP LargeFileGroup;
GO

-- 7 Создать схему, переместить в нее одну из таблиц, удалить схему
CREATE SCHEMA customers_schema;
GO

ALTER SCHEMA customers_schema
TRANSFER dbo.Users;
GO

-- Удаляем схему, перед этим вернув таблицу в dbo
ALTER SCHEMA dbo
TRANSFER customers_schema.Users;
GO

DROP SCHEMA customers_schema;
GO