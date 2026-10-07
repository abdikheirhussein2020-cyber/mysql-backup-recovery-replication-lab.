-- ============================================================
-- MYSQL REPLICATION COMMANDS
-- ============================================================
---------------------------------------------------------------

-- PRIMARY SERVER:
-- Port: 3306
-- Server ID: 1
---------------

-- REPLICA SERVER:
-- Port: 3307
-- Server ID: 2
---------------

-- ============================================================

-- ============================================================
-- PRIMARY SERVER
-- ============================================================

---

-- 1. CHECK PRIMARY SERVER ID

---

SHOW VARIABLES LIKE 'server_id';

---

-- 2. CHECK PRIMARY SERVER PORT

---

SHOW VARIABLES LIKE 'port';

---

-- 3. CHECK BINARY LOGGING

---

SHOW VARIABLES LIKE 'log_bin';

---

-- 4. CHECK BINARY LOG FORMAT

---

SHOW VARIABLES LIKE 'binlog_format';

---

-- 5. DISPLAY BINARY LOGS

---

SHOW BINARY LOGS;

---

-- 6. DISPLAY CURRENT BINARY LOG POSITION

---

SHOW MASTER STATUS;

-- ============================================================
-- CREATE REPLICATION USER
-- ============================================================

---

-- 7. CREATE REPLICATION USER

---

CREATE USER IF NOT EXISTS
'replicator'@'localhost'
IDENTIFIED WITH mysql_native_password
BY 'reppass';

---

-- 8. GRANT REPLICATION PRIVILEGES

---

GRANT REPLICATION SLAVE,
REPLICATION CLIENT
ON *.*
TO 'replicator'@'localhost';

---

-- 9. REFRESH PRIVILEGES

---

FLUSH PRIVILEGES;

---

-- 10. VERIFY REPLICATION USER

---

SHOW GRANTS FOR 'replicator'@'localhost';

-- ============================================================
-- REPLICA SERVER
-- ============================================================

---

-- 11. CHECK REPLICA SERVER ID

---

SHOW VARIABLES LIKE 'server_id';

---

-- 12. CHECK REPLICA SERVER PORT

---

SHOW VARIABLES LIKE 'port';

-- ============================================================
-- CONFIGURE REPLICATION
-- ============================================================

## -- IMPORTANT:

-- Replace YOUR_BINLOG_FILE with the actual File value
-- returned by SHOW MASTER STATUS on the primary.
-------------------------------------------------

-- Replace YOUR_BINLOG_POSITION with the actual Position
-- returned by SHOW MASTER STATUS on the primary.
-------------------------------------------------

## -- Example:

-- SOURCE_LOG_FILE='DESKTOP-CG3C7FT-bin.000077',
-- SOURCE_LOG_POS=13274
-----------------------

-- ============================================================

---

-- 13. CONFIGURE REPLICATION SOURCE

---

CHANGE REPLICATION SOURCE TO
SOURCE_HOST='127.0.0.1',
SOURCE_PORT=3306,
SOURCE_USER='replicator',
SOURCE_PASSWORD='reppass',
SOURCE_LOG_FILE='YOUR_BINLOG_FILE',
SOURCE_LOG_POS=YOUR_BINLOG_POSITION;

---

-- 14. START REPLICATION

---

START REPLICA;

---

-- 15. CHECK REPLICATION STATUS

---

SHOW REPLICA STATUS\G;

-- ============================================================
-- REPLICATION TEST
-- ============================================================

---

-- 16. SELECT SCHOOL DATABASE

---

USE school;

---

-- 17. CREATE REPLICATION TEST TABLE

---

CREATE TABLE IF NOT EXISTS replication_test (
id INT PRIMARY KEY,
message VARCHAR(100)
);

---

-- 18. INSERT FIRST TEST RECORD

---

INSERT INTO replication_test
(id, message)
VALUES
(1, 'Replication is working');

---

-- 19. INSERT SECOND TEST RECORD

---

INSERT INTO replication_test
(id, message)
VALUES
(2, 'Second replication test');

---

-- 20. VERIFY PRIMARY

---

SELECT * FROM replication_test;

-- ============================================================
-- RUN THE FOLLOWING COMMANDS ON THE REPLICA
-- ============================================================

-- USE school;

-- SELECT * FROM replication_test;

## -- Expected:

-- 1 | Replication is working
-- 2 | Second replication test
------------------------------

---

-- 21. CHECK REPLICA STATUS AGAIN

---

SHOW REPLICA STATUS\G;

-- ============================================================
-- HEALTHY REPLICATION SHOULD SHOW:
-----------------------------------

-- Replica_IO_Running: Yes
-- Replica_SQL_Running: Yes
---------------------------

-- ============================================================

-- ============================================================
-- END OF REPLICATION SQL
-- ============================================================
