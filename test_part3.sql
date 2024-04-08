-- Task 1
SELECT repeat('-',50) AS "Task 1";
SELECT * FROM get_transferred_points_table();

-- Task 2
SELECT repeat('-',50) AS "Task 2";
SELECT * FROM fnc2_success_tasks();

-- Task 3
SELECT repeat('-',50) AS "Task 3";
SELECT * FROM get_peers_not_left_campus('2023-12-01');

-- Task 4
SELECT repeat('-',50) AS "Task 4";
SELECT * FROM fnc4_points_change();

-- Task 5
SELECT repeat('-',50) AS "Task 5";
SELECT * FROM get_points_change();

-- Task 6
SELECT repeat('-',50) AS "Task 6";
SELECT * FROM fnc6_often_checks();

-- Task 7
SELECT repeat('-',50) AS "Task 7";
SELECT * FROM get_peers_finish_block('C');

-- Task 8
SELECT repeat('-',50) AS "Task 8";
SELECT * FROM fnc8_recommended();

-- Task 9
SELECT repeat('-',50) AS "Task 9";
SELECT * FROM get_blocks_start_statistics('C', 'SQL');

-- Task 10
SELECT repeat('-',50) AS "Task 10";
SELECT * FROM fnc10_checks_birthday();

-- Task 11
SELECT repeat('-',50) AS "Task 11";
SELECT * FROM get_peer_finish_tasks_statistics(
    'C2_SimpleBashUtils', 'C7_SmartCalc_v1.0', 'CPP3_SmartCalc_v2.0');

-- Task 12
SELECT repeat('-',50) AS "Task 12";
SELECT * FROM fnc12_task_parents();

-- Task 13
SELECT repeat('-',50) AS "Task 13";
SELECT * FROM fnc13_successful_days(2);

-- Task 14
SELECT repeat('-',50) AS "Task 14";
CALL prc14_max_xp(NULL, NULL);

-- Task 15
SELECT repeat('-',50) AS "Task 15";
SELECT * FROM get_peers_come_early('16:40:00', 3);

-- Task 16
SELECT repeat('-',50) AS "Task 16 (function)";
SELECT * FROM fnc16_peers_out(40,1);

-- Task 16 procedure plpgsql
SELECT repeat('-',50) AS "Task 16 (procedure / plpgsql)";

BEGIN;
CALL prc16_peers_out(40,1,'cur');
FETCH ALL FROM cur;
COMMIT;

-- Task 17
SELECT repeat('-',50) AS "Task 17";
SELECT * FROM get_early_entries();
