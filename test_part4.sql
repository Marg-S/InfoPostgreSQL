SELECT repeat('-',50) AS "Task 1";

SELECT table_name AS "Tables in the current database"
FROM information_schema.tables 
WHERE table_schema = 'public';

CALL prc_part4_task1();
SELECT 'Destroy tables whose names begin with the phrase "TableName"' 
AS "prc_part4_task1();";

SELECT table_name AS "Tables in the current database"
FROM information_schema.tables 
WHERE table_schema = 'public';

-------------------------------------------------
SELECT repeat('-',50) AS "Task 2";

CALL prc_part4_task2(0);

-------------------------------------------------
SELECT repeat('-',50) AS "Task 3";

SELECT trigger_name AS "Triggers in the current database" 
FROM information_schema.triggers;

SELECT 'Destroy all triggers in the current database' 
AS "prc_part4_task3(0);";
CALL prc_part4_task3(0);

SELECT trigger_name AS "Triggers in the current database" 
FROM information_schema.triggers;

-------------------------------------------------
SELECT repeat('-',50) AS "Task 4";

CALL prc_part4_task4('trig');
