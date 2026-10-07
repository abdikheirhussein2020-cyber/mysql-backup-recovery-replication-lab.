-- ============================================================
-- MYSQL POINT-IN-TIME RECOVERY (PITR)
-- ============================================================

-- MySQL uses binary logs for point-in-time recovery.
-- PostgreSQL uses WAL for the same general purpose.
----------------------------------------------------

-- Windows commands such as mysqldump and mysqlbinlog are
-- documented in windows_commands.txt.

-- ============================================================
-- 1. CREATE PITR TEST DATABASE
-- ============================================================

CREATE DATABASE IF NOT EXISTS pitr_lab;

-- ============================================================
-- 2. SELECT PITR DATABASE
-- ============================================================

USE pitr_lab;

-- ============================================================
-- 3. CREATE TEST TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS students (
id INT PRIMARY KEY,
name VARCHAR(100),
email VARCHAR(150)
);

-- ============================================================
-- 4. INSERT INITIAL DATA
-- ============================================================

INSERT INTO students
(id, name, email)
VALUES
(1, 'John Doe', '[john@example.com](mailto:john@example.com)'),
(2, 'Jane Smith', '[jane@example.com](mailto:jane@example.com)');

-- ============================================================
-- 5. VERIFY INITIAL DATA
-- ============================================================

SELECT * FROM students;

-- ============================================================
-- 6. CHECK BINARY LOGGING
-- ============================================================

SHOW VARIABLES LIKE 'log_bin';

-- ============================================================
-- 7. CHECK BINARY LOG FORMAT
-- ============================================================

SHOW VARIABLES LIKE 'binlog_format';

-- ============================================================
-- 8. RECORD CURRENT BINARY LOG POSITION
-- ============================================================

SHOW MASTER STATUS;

-- ============================================================
-- 9. ADD DATA AFTER THE BASE BACKUP
-- ============================================================

INSERT INTO students
(id, name, email)
VALUES
(3, 'Peter Brown', '[peter@example.com](mailto:peter@example.com)');

-- ============================================================
-- 10. VERIFY DATA BEFORE DISASTER
-- ============================================================

SELECT * FROM students;

-- ============================================================
-- 11. RECORD CURRENT SERVER TIME
-- ============================================================

SELECT NOW();

-- ============================================================
-- IMPORTANT:
-------------

-- Record the exact time returned above.
-- This time is used to identify the recovery point.
-- ============================================================

-- ============================================================
-- 12. SIMULATE DATABASE DISASTER
-- ============================================================

SET SQL_SAFE_UPDATES = 0;

DELETE FROM students;

SET SQL_SAFE_UPDATES = 1;

-- ============================================================
-- 13. VERIFY DISASTER
-- ============================================================

SELECT * FROM students;

-- ============================================================
-- 14. CHECK CURRENT BINARY LOG POSITION
-- ============================================================

SHOW MASTER STATUS;

-- ============================================================
-- 15. AFTER RESTORING THE BASE BACKUP,
--     SELECT THE PITR DATABASE
-- ============================================================

USE pitr_lab;

-- ============================================================
-- 16. VERIFY DATA AFTER BASE RESTORATION
-- ============================================================

SELECT * FROM students;

-- ============================================================
-- 17. VERIFY FINAL RECOVERED DATA
-- ============================================================

SELECT
id,
name,
email
FROM students
ORDER BY id;

-- ============================================================
-- PITR RECOVERY EXPLANATION
-- ============================================================
---------------------------------------------------------------

## -- The Windows Command Prompt is used to replay binary logs.

## -- Example:

-- mysqlbinlog --stop-datetime="YYYY-MM-DD HH:MM:SS"
-- "C:\ProgramData\MySQL\MySQL Server 8.0\Data\YOUR_BINLOG_FILE"
-- | mysql -u root -p
---------------------

## -- Replace:

## -- YYYY-MM-DD HH:MM:SS

## -- with the actual recovery time.

## -- Replace:

## -- YOUR_BINLOG_FILE

## -- with the actual binary-log filename.

-- ============================================================

-- ============================================================
-- 18. VERIFY RECOVERED RECORD COUNT
-- ============================================================

SELECT COUNT(*) AS recovered_students
FROM students;

-- ============================================================
-- END OF PITR SQL
-- ============================================================
