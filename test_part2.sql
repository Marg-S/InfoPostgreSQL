-- Task 1
SELECT repeat('-',50) AS "Task 1";
SELECT * FROM checks;
SELECT * FROM p2p;

CALL add_p2p('Anna', 'maximilian', 'C2_SimpleBashUtils', 'Success', '23:40:00');
CALL add_p2p('buttery', 'maximilian', 'C2_SimpleBashUtils', 'Start', '23:40:00');
CALL add_p2p('buttery', 'maximilian', 'C2_SimpleBashUtils', 'Success', '23:45:00');
CALL add_p2p('audradan', 'buttery', 'C7_SmartCalc_v1.0', 'Success', '21:40:00');
CALL add_p2p('rodolphu', 'buttery', 'C7_SmartCalc_v1.0', 'Start', '22:40:00');
CALL add_p2p('rodolphu', 'buttery', 'C7_SmartCalc_v1.0', 'Success', '23:40:00');

SELECT * FROM p2p;
SELECT * FROM checks;

CALL add_p2p('rodolphu', 'buttery', 'C7_SmartCalc_v1.0', 'Success', '23:40:00');

-- Task 2
SELECT repeat('-',50) AS "Task 2";
SELECT * FROM verter;

CALL add_verter('buttery', 'C2_SimpleBashUtils', 'Start', '23:45:40');
CALL add_verter('buttery', 'C2_SimpleBashUtils', 'Success', '23:46:00');
CALL add_verter('Anna', 'C2_SimpleBashUtils', 'Start', '23:45:00');
CALL add_verter('Anna', 'C2_SimpleBashUtils', 'Success', '23:46:00');

SELECT * FROM verter;

-- Task 3
SELECT repeat('-',50) AS "Task 3";
CREATE MATERIALIZED VIEW mv_p2p AS (SELECT * FROM p2p);
CREATE MATERIALIZED VIEW mv_checks AS (SELECT * FROM checks);
CREATE MATERIALIZED VIEW mv_transferredpoints 
AS (SELECT * FROM transferredpoints);

CALL add_p2p('rodolphu', 'buttery', 'C7_SmartCalc_v1.0', 'Start', '12:10:00');

SELECT * FROM p2p EXCEPT SELECT * FROM mv_p2p;
SELECT * FROM checks EXCEPT SELECT * FROM mv_checks;
SELECT * FROM mv_transferredpoints EXCEPT SELECT * FROM transferredpoints;
SELECT * FROM transferredpoints EXCEPT SELECT * FROM mv_transferredpoints;

-- Task 4
SELECT repeat('-',50) AS "Task 4";
SELECT * FROM xp;

INSERT INTO xp VALUES (default, 9, 350);
INSERT INTO xp VALUES (default, 20, 450);

SELECT * FROM xp;

INSERT INTO xp VALUES (default, 1, 350);
INSERT INTO xp VALUES (default, 21, 5000);
