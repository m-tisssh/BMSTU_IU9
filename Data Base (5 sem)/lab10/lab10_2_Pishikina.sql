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
