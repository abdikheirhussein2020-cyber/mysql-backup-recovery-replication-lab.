# MySQL Backup, Recovery, PITR and Replication Lab

## Objective

This laboratory demonstrates database backup, recovery, point-in-time recovery (PITR), binary logging, and replication using MySQL 8.0.

The original laboratory instructions were written for PostgreSQL. Since this environment uses MySQL, equivalent MySQL technologies were used.

The laboratory demonstrates:

* Creating and verifying a logical backup
* Creating and restoring a base backup
* Enabling and verifying binary logging
* Simulating a database disaster
* Performing point-in-time recovery using `mysqlbinlog`
* Configuring a replication user
* Building a MySQL replica
* Monitoring replication health
* Testing data replication from the primary server to the replica

---

# PostgreSQL to MySQL Mapping

| PostgreSQL Technology | MySQL Equivalent        |
| --------------------- | ----------------------- |
| `pg_dump`             | `mysqldump`             |
| WAL                   | Binary log              |
| WAL archiving         | Binary logging          |
| `pg_restore`          | `mysql` restore         |
| `pg_basebackup`       | Full MySQL backup       |
| PITR using WAL        | PITR using binary logs  |
| Streaming replication | MySQL replication       |
| `pg_stat_replication` | `SHOW REPLICA STATUS\G` |

---

# Environment

The laboratory used MySQL 8.0.

## Primary Server

* Port: `3306`
* Server ID: `1`
* Binary logging: Enabled
* Binary log format: `ROW`

## Replica Server

* Port: `3307`
* Server ID: `2`

## Database Used

The available database used for the laboratory was:

```text
school
```

The `students` table contained student records used for backup and recovery testing.

---

# Step 1: Logical Backup

The first stage was to create a logical backup of the `school` database.

The backup was created using:

```text
mysqldump -u root -p school > school_backup.sql
```

The resulting backup file was verified from Windows Command Prompt.

The backup was then restored into a separate database named `bootcamp_check`.

```text
mysql -u root -p bootcamp_check < school_backup.sql
```

The restored database was checked using:

```sql
USE bootcamp_check;

SHOW TABLES;

SELECT * FROM students;
```

The restored student data confirmed that the logical backup was valid.

---

# Step 2: Binary Logging

PostgreSQL uses Write-Ahead Logging (WAL), while MySQL uses binary logging.

Binary logging was checked with:

```sql
SHOW VARIABLES LIKE 'log_bin';
```

The server returned:

```text
ON
```

The binary log files were displayed using:

```sql
SHOW BINARY LOGS;
```

The current binary-log file and position were obtained using:

```sql
SHOW MASTER STATUS;
```

Binary logging is important because it records database changes and provides the transaction history required for replication and point-in-time recovery.

---

# Step 3: Base Backup

A full logical backup was used as the base backup for the recovery demonstration.

The base backup command was:

```text
mysqldump -u root -p --single-transaction --routines --triggers --events school > school_base_backup.sql
```

The backup file was verified from Windows Command Prompt.

---

# Step 4: Disaster Simulation

A separate PITR test database was used to demonstrate point-in-time recovery.

The database was created with:

```sql
CREATE DATABASE IF NOT EXISTS pitr_lab;
```

A test table was created:

```sql
USE pitr_lab;

CREATE TABLE IF NOT EXISTS students (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(150)
);
```

Initial records were inserted:

```sql
INSERT INTO students (id, name, email)
VALUES
(1, 'John Doe', 'john@example.com'),
(2, 'Jane Smith', 'jane@example.com');
```

A base backup was then created.

A transaction was performed after the base backup:

```sql
INSERT INTO students (id, name, email)
VALUES
(3, 'Peter Brown', 'peter@example.com');
```

The current server time was recorded:

```sql
SELECT NOW();
```

A simulated disaster was then performed:

```sql
SET SQL_SAFE_UPDATES = 0;

DELETE FROM students;

SET SQL_SAFE_UPDATES = 1;
```

The table was checked to confirm that the data had been deleted.

---

# Step 5: Point-in-Time Recovery

MySQL point-in-time recovery uses the base backup together with binary logs.

The recovery process is:

1. Create a base backup.
2. Record the binary-log information.
3. Perform additional transactions.
4. Record the disaster time.
5. Simulate the disaster.
6. Restore the base backup.
7. Inspect the binary logs using `mysqlbinlog`.
8. Use `--stop-datetime` to limit the transactions being replayed.
9. Restore the required transactions.
10. Verify the recovered data.

The binary logs can be inspected using:

```text
mysqlbinlog --verbose "C:\ProgramData\MySQL\MySQL Server 8.0\Data\YOUR_BINLOG_FILE"
```

A time range can be inspected using:

```text
mysqlbinlog --stop-datetime="YYYY-MM-DD HH:MM:SS" --verbose "C:\ProgramData\MySQL\MySQL Server 8.0\Data\YOUR_BINLOG_FILE"
```

The selected binary-log events can then be replayed:

```text
mysqlbinlog --stop-datetime="YYYY-MM-DD HH:MM:SS" "C:\ProgramData\MySQL\MySQL Server 8.0\Data\YOUR_BINLOG_FILE" | mysql -u root -p
```

The exact binary-log filename and recovery time must come from the actual MySQL server.

After recovery, the database is checked with:

```sql
USE pitr_lab;

SELECT * FROM students;
```

The goal is to recover transactions that occurred before the destructive DELETE while avoiding replaying the destructive transaction itself.

---

# Step 6: Replication User

A dedicated replication user was created on the primary server.

```sql
CREATE USER IF NOT EXISTS
'replicator'@'localhost'
IDENTIFIED WITH mysql_native_password
BY 'reppass';
```

Replication privileges were granted:

```sql
GRANT REPLICATION SLAVE, REPLICATION CLIENT
ON *.*
TO 'replicator'@'localhost';
```

Privileges were refreshed:

```sql
FLUSH PRIVILEGES;
```

The privileges were verified using:

```sql
SHOW GRANTS FOR 'replicator'@'localhost';
```

Using a dedicated replication account is preferable to using the root account for replication.

---

# Step 7: Replica Configuration

The replica was configured as a separate MySQL server instance.

The replica used:

```text
Port: 3307
Server ID: 2
```

The replica data directory was:

```text
C:\ProgramData\MySQL\MySQL Server 8.0\ReplicaData
```

The replica log directory was:

```text
C:\ProgramData\MySQL\MySQL Server 8.0\ReplicaLogs
```

The replica configuration included:

```text
[mysqld]
port=3307
server-id=2
datadir=C:/ProgramData/MySQL/MySQL Server 8.0/ReplicaData
log-bin=C:/ProgramData/MySQL/MySQL Server 8.0/ReplicaLogs/replica-bin
relay-log=C:/ProgramData/MySQL/MySQL Server 8.0/ReplicaLogs/replica-relay-bin
```

---

# Step 8: Configure Replication

The replica was connected to the primary using:

```sql
CHANGE REPLICATION SOURCE TO
SOURCE_HOST='127.0.0.1',
SOURCE_PORT=3306,
SOURCE_USER='replicator',
SOURCE_PASSWORD='reppass',
SOURCE_LOG_FILE='YOUR_BINLOG_FILE',
SOURCE_LOG_POS=YOUR_BINLOG_POSITION;
```

The actual binary-log file and position must be taken from:

```sql
SHOW MASTER STATUS;
```

Replication was started using:

```sql
START REPLICA;
```

---

# Step 9: Monitor Replication

Replication status was monitored using:

```sql
SHOW REPLICA STATUS\G
```

The most important health indicators are:

```text
Replica_IO_Running
Replica_SQL_Running
Seconds_Behind_Source
Last_IO_Error
Last_SQL_Error
```

A healthy replica should normally report:

```text
Replica_IO_Running: Yes
Replica_SQL_Running: Yes
```

---

# Step 10: Replication Test

A test table was created on the primary:

```sql
USE school;

CREATE TABLE IF NOT EXISTS replication_test (
    id INT PRIMARY KEY,
    message VARCHAR(100)
);
```

Two records were inserted:

```sql
INSERT INTO replication_test
(id, message)
VALUES
(1, 'Replication is working');

INSERT INTO replication_test
(id, message)
VALUES
(2, 'Second replication test');
```

The primary was checked:

```sql
SELECT * FROM replication_test;
```

The replica was then checked:

```sql
USE school;

SELECT * FROM replication_test;
```

The records appeared on the replica:

```text
1 | Replication is working
2 | Second replication test
```

This confirmed that changes made on the primary were replicated to the standby.

---

# Results

The laboratory demonstrated the following:

* A logical MySQL backup was successfully created.
* The logical backup was restored into a separate database.
* Binary logging was enabled and verified.
* A full base backup was created.
* A database disaster was simulated.
* MySQL binary logs were used as the recovery transaction source.
* Point-in-time recovery was demonstrated using `mysqlbinlog`.
* A dedicated replication account was configured.
* A separate MySQL replica was configured on port 3307.
* Replication health was monitored.
* Test records created on the primary appeared on the replica.

---

# Security Considerations

The replication process used a dedicated account rather than the root account.

The account was granted replication-specific privileges:

```sql
GRANT REPLICATION SLAVE, REPLICATION CLIENT
ON *.*
TO 'replicator'@'localhost';
```

This follows the principle of using a dedicated account for database replication.

In a production environment, the replication password should not be stored publicly in source-control repositories.

---

# Repository Files

This repository contains:

```text
README.md
backup_recovery_commands.sql
pitr_commands.sql
replication_commands.sql
windows_commands.txt
```

## backup_recovery_commands.sql

Contains SQL commands for checking the database, binary logging, backup verification, and recovery verification.

## pitr_commands.sql

Contains SQL commands used for the point-in-time recovery demonstration.

## replication_commands.sql

Contains SQL commands used to configure, start, monitor, and test replication.

## windows_commands.txt

Contains Windows Command Prompt commands used for `mysqldump`, database restoration, replica initialization, and `mysqlbinlog`.

---

# Conclusion

This laboratory demonstrated how MySQL can provide backup protection, disaster recovery, point-in-time recovery, and replication.

Logical backups provide a recoverable copy of database contents. Binary logging provides the transaction history needed for point-in-time recovery and replication. A replica provides an additional copy of the database and can help improve availability.

Together, these technologies provide both prevention and recovery capabilities for database failures.
