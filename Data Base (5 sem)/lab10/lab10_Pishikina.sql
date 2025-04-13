    USE master;
GO

/*DROP DATABASE IF EXISTS lab_10;
GO

CREATE DATABASE lab_10
ON PRIMARY 
    (
    NAME = lab_10_data,
    FILENAME = '/Users/marypishykina/Desktop/DB/lab10/data_log/lab9_data.mdf',
    SIZE = 5MB,
    MAXSIZE = 50MB,
    FILEGROWTH = 5MB
    )
, FILEGROUP courses_online_filegroup
    (
        NAME = courses_online_filegroup_data,
        FILENAME = '/Users/marypishykina/Desktop/DB/lab10/data_log/lab9_filegroup_data.ndf',
        SIZE = 5MB,
        MAXSIZE = 50MB,
        FILEGROWTH = 5MB
    )
LOG ON 
    (
    NAME = lab_10_log,
    FILENAME = '/Users/marypishykina/Desktop/DB/lab10/data_log/lab9_log.ldf',
    SIZE = 5MB,
    MAXSIZE = 50MB,
    FILEGROWTH = 5MB
    );
GO

USE lab_10;
GO

CREATE TABLE Courses (
    id INT PRIMARY KEY NOT NULL,
    courseCode NVARCHAR(20) NOT NULL,
    courseName NVARCHAR(100) NOT NULL,
    subjectArea NVARCHAR(60) NOT NULL,
    employeeNumber INT NOT NULL,
    description NVARCHAR(500) NULL,
    difficulty SMALLINT NOT NULL DEFAULT 1 CHECK (difficulty BETWEEN 1 AND 5), -- Сложность от 1 до 5
    price MONEY NOT NULL CHECK (price > 0) 
);
GO

INSERT INTO Courses (id, courseCode, courseName, subjectArea, employeeNumber, description, difficulty, price)
VALUES
(2372, 'DB101', 'Introduction to SQL', 'Databases', 101, 'Basic SQL course covering fundamental database operations.', 1, 49.99),
(4721, 'PR102', 'Advanced Python Programming', 'Programming', 102, 'Deep dive into advanced Python features including OOP and modules.', 3, 199.99);
GO
*/

USE lab_10;
GO

--- ПЕРВЫЙ ФАЙЛ -----

------ a) READ UNCOMMITTED
-- В Окне 1 обновленное значение price (грязное чтение), даже если транзакция в Окне 2 еще не была завершена.
-- уровень READ UNCOMMITTED позволяет читать изменения, которые могут быть откатаны.


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO

BEGIN TRANSACTION;
    UPDATE Courses SET price = price / 2 WHERE id = 2372;
    WAITFOR DELAY '00:00:10'; 
ROLLBACK TRANSACTION;
GO

SELECT * FROM Courses WHERE id = 2372;
GO


------ b) READ COMMITTED
-- В Окне 2 обновление будет заблокировано до завершения транзакции в Окне 1.
-- Уровень READ COMMITTED предотвращает чтение незавершенных изменений.


-- SET TRANSACTION ISOLATION LEVEL READ COMMITTED
-- GO

-- BEGIN TRANSACTION;
--     UPDATE Courses SET employeeNumber = 1000 WHERE id = 2372;
--     WAITFOR DELAY '00:00:15'; 
-- ROLLBACK TRANSACTION;
-- GO

-- BEGIN TRANSACTION;
--     SELECT * FROM Courses WHERE id = 2372;
--     WAITFOR DELAY '00:00:10';
--     SELECT description FROM Courses WHERE id = 2372;
-- COMMIT TRANSACTION;
-- GO


------- c) REPEATABLE READ
-- В Окне 2 обновление будет заблокировано до завершения транзакции в Окне 1.
-- Уровень READ COMMITTED предотвращает чтение незавершенных изменений.


-- SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
-- GO

-- BEGIN TRANSACTION;
--     SELECT * FROM Courses WHERE id = 2372;
--     WAITFOR DELAY '00:00:05';
--     SELECT * FROM Courses WHERE id = 2372;
-- COMMIT TRANSACTION;
-- GO

-- BEGIN TRANSACTION;
--     SELECT * FROM Courses;
--     WAITFOR DELAY '00:00:07';
--     SELECT * FROM Courses;
-- COMMIT TRANSACTION;
-- GO


----- 4. SERIALIZABLE (Сериализуемость)
-- Вставка в Окне 2 будет заблокирована, пока транзакция в Окне 1 не завершится.

-- SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
-- GO

-- BEGIN TRANSACTION;
--     SELECT * FROM Courses WHERE id BETWEEN 2000 AND 3000;
--     WAITFOR DELAY '00:00:06';
--     SELECT * FROM Courses;
-- COMMIT TRANSACTION;
-- GO


-- 5. SNAPSHOT (Снимок данных)
-- В Окне 1 данные останутся неизменными, даже если в Окне 2 данные обновлены.

-- ALTER DATABASE [lab_10] SET ALLOW_SNAPSHOT_ISOLATION ON;
-- SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
-- BEGIN TRANSACTION;
--     SELECT * FROM Courses;
--     WAITFOR DELAY '00:00:10';
-- COMMIT;
-- GO



---- ВТОРОЙ ФАЙЛ ----

USE master;
GO

USE lab_10;
GO

-- 1) UNCOMMITTED

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
GO

BEGIN TRANSACTION;
    SELECT * FROM Courses WHERE id = 2372;
COMMIT TRANSACTION;
GO

-- 2) COMMITTED

-- SET TRANSACTION ISOLATION LEVEL READ COMMITTED
-- GO

-- BEGIN TRANSACTION;
--     SELECT * FROM Courses WHERE id = 2372;
-- COMMIT TRANSACTION;
-- GO

-- BEGIN TRANSACTION;
--     UPDATE Courses SET employeeNumber = 1000 WHERE id = 2372;
-- COMMIT TRANSACTION;
-- GO


-- 3) REPEATABLE READ

-- SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
-- GO

-- BEGIN TRANSACTION;
--     UPDATE Courses SET price = price * 2 WHERE id = 2372;
-- COMMIT TRANSACTION;
-- GO

-- BEGIN TRANSACTION;
--     INSERT INTO Courses (id, courseCode, courseName, subjectArea, employeeNumber, description, difficulty, price)
--     VALUES (8125, 'ML821', 'Advanced ML for profi', 'Machine Learning', 821, 'How to learn ML', 5, 199.99);
-- COMMIT TRANSACTION;
-- GO

-- 4) SERIALIZABLE


-- SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
-- GO
-- BEGIN TRANSACTION;
--     INSERT INTO Courses (id, courseCode, courseName, subjectArea, employeeNumber, description, difficulty, price)
--     VALUES (6, 'DB6', 'SQL ___', 'Databases', 273, 'SQL course.', 1, 8.99);
-- -- Это вызовет блокировку до завершения транзакции в Окне 1
-- COMMIT TRANSACTION;
-- GO


------

-- SET TRANSACTION ISOLATION LEVEL SNAPSHOT
-- GO

-- BEGIN TRANSACTION;
--     UPDATE Courses SET price = price * 2 WHERE id = 2372;
-- COMMIT;



SELECT DTL.resource_type,  
   CASE   
       WHEN DTL.resource_type IN ('DATABASE', 'FILE', 'METADATA') THEN DTL.resource_type  
       WHEN DTL.resource_type = 'OBJECT' THEN OBJECT_NAME(DTL.resource_associated_entity_id, SP.[dbid])  
       WHEN DTL.resource_type IN ('KEY', 'PAGE', 'RID') THEN   
           (  
           SELECT OBJECT_NAME([object_id])  
           FROM sys.partitions  
           WHERE sys.partitions.hobt_id =   
             DTL.resource_associated_entity_id  
           )  
       ELSE 'Unidentified'  
   END AS requested_object_name, DTL.request_mode, DTL.request_status,  
   DEST.TEXT
FROM sys.dm_tran_locks DTL  
   INNER JOIN sys.sysprocesses SP  
       ON DTL.request_session_id = SP.spid   
   -- INNER JOIN sys.[dm_exec_requests] AS SDER ON SP.[spid] = [SDER].[session_id] 
   CROSS APPLY sys.dm_exec_sql_text(SP.sql_handle) AS DEST  
WHERE SP.dbid = DB_ID()  
   AND DTL.[resource_type] <> 'DATABASE' 
ORDER BY DTL.[request_session_id];
