-- Task 1
CREATE OR REPLACE FUNCTION get_transferred_points_table()
RETURNS TABLE (Peer1 text, Peer2 text, PointsAmount integer) AS $$
    SELECT
        t1."CheckingPeer" AS Peer1,
        t1."CheckedPeer" AS Peer2,
        CASE WHEN t2."PointsAmount" IS NOT NULL
            THEN t1."PointsAmount" - t2."PointsAmount"
        ELSE t1."PointsAmount"
        END AS PointsAmount
    FROM transferredpoints t1
    LEFT JOIN transferredpoints t2
    ON t1."CheckedPeer" = t2."CheckingPeer"
    AND t1."CheckingPeer" = t2."CheckedPeer"
    WHERE t1."ID" < t2."ID" OR t2."ID" IS NULL
    ORDER BY Peer1;
$$ LANGUAGE sql;

-- Task 2
CREATE OR REPLACE FUNCTION fnc2_success_tasks() 
    RETURNS TABLE ("Peer" text, "Task" text, "XP" integer)
    LANGUAGE sql AS 
$$ 
    SELECT "Peer", "Task", "XPAmount" 
    FROM checks c 
    JOIN xp x 
    ON c."ID" = x."Check"
    ORDER BY "Peer";
$$;

-- Task 3
CREATE OR REPLACE FUNCTION get_peers_not_left_campus(day date DEFAULT current_date)
RETURNS TABLE (Peer text) AS $$
    SELECT
        "Peer"
    FROM timetracking
    WHERE "Date" = day
    GROUP BY "Peer", "Date"
    HAVING count("State") < 3;
$$ LANGUAGE sql;

-- Task 4
CREATE OR REPLACE FUNCTION fnc4_points_change()
    RETURNS TABLE ("Peer" text, "PointsChange" integer)
    LANGUAGE sql AS 
$$
    SELECT "Peer", SUM(sum) 
    FROM 
        (SELECT "CheckingPeer" AS "Peer", SUM("PointsAmount") as sum
        FROM transferredpoints 
        GROUP BY "CheckingPeer" 
        UNION 
        SELECT "CheckedPeer", -SUM("PointsAmount") 
        FROM transferredpoints 
        GROUP BY "CheckedPeer") a 
    GROUP BY "Peer" ORDER BY sum DESC;
$$;

-- Task 5
CREATE OR REPLACE FUNCTION get_points_change()
RETURNS TABLE (Peer text, PointsChange integer) AS $$
    SELECT
        t.Peer AS Peer,
        sum(sum) AS PointsChange
    FROM (SELECT
        peer1 AS peer,
        sum(t1.PointsAmount) AS sum
    FROM get_transferred_points_table() t1
    GROUP BY t1.Peer1
    UNION
    SELECT
        peer2 AS peer,
        sum(-1 * t2.PointsAmount) AS sum
    FROM get_transferred_points_table() t2
    GROUP BY t2.Peer2) t
    GROUP BY peer
    ORDER BY PointsChange DESC;
$$ LANGUAGE sql;

-- Task 6
CREATE OR REPLACE FUNCTION fnc6_often_checks()
    RETURNS TABLE ("Day" text, "Task" text)
    LANGUAGE sql AS 
$$
    WITH cte_count_checks AS 
        (SELECT "Date", "Task", COUNT("Task") as count
        FROM checks GROUP BY "Date", "Task") 
    SELECT to_char(a."Date", 'dd.mm.yyyy'), b."Task" 
    FROM 
        (SELECT "Date", MAX(count) 
        FROM cte_count_checks GROUP BY "Date") a 
    JOIN cte_count_checks b 
    ON a."Date" = b."Date" AND a.max = b.count;
$$;

-- Task 7
CREATE OR REPLACE FUNCTION get_peers_finish_tasks()
RETURNS TABLE (Peer text, Day date, Task text) AS $$
    BEGIN
        RETURN QUERY
        SELECT DISTINCT
            ch."Peer" AS Peer,
            ch."Date" AS Day,
            ch."Task"
        FROM checks ch
        JOIN p2p p
        ON p."Check"=ch."ID"
        LEFT JOIN verter v
        ON v."Check" = ch."ID"
        WHERE p."State" = 'Success'
        AND (v."State" = 'Success'
        OR v."State" IS NULL);
    end;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_peers_finish_block(block_name text DEFAULT 'C')
RETURNS TABLE (Peer text, Day text) AS $$
    DECLARE
        tasks_count integer;
    BEGIN
        SELECT count(*) INTO tasks_count FROM tasks WHERE "Title" LIKE $1 || '_' || E'\\_' || '%';
    RETURN QUERY
    SELECT
        t2.Peer,
        to_char(max(t2.Day), 'dd.mm.yyyy') AS Day
    FROM
    (SELECT
       t1.Peer, t1.Day, t1.Task
    FROM get_peers_finish_tasks() t1
    WHERE Task IN (SELECT
        "Title"
    FROM tasks t2
    WHERE t2."Title" LIKE 'C' || '_' || E'\\_' || '%')) t2
    GROUP BY t2.Peer
    HAVING count(DISTINCT t2.Task) = tasks_count;
    end
$$ LANGUAGE plpgsql;

-- Task 8
CREATE OR REPLACE FUNCTION fnc8_recommended()
    RETURNS TABLE ("Peer" text, "RecommendedPeer" text)
    LANGUAGE sql AS 
$$
    WITH cte_count_recommend AS 
        (SELECT "Peer1", "RecommendedPeer", COUNT("RecommendedPeer") as count
        FROM (SELECT * FROM 
            (SELECT "Peer1", "Peer2" FROM friends
            UNION ALL
            SELECT "Peer2", "Peer1" FROM friends) f 
        JOIN recommendations r ON f."Peer2" = r."Peer" 
        WHERE "Peer1" <> "RecommendedPeer" 
        AND "RecommendedPeer" <> 'null') a 
        GROUP BY "Peer1", "RecommendedPeer") 
    SELECT a."Peer1", b."RecommendedPeer" 
    FROM 
        (SELECT "Peer1", MAX(count) 
        FROM cte_count_recommend 
        GROUP BY "Peer1") a 
    JOIN cte_count_recommend b 
    ON a."Peer1" = b."Peer1" AND a.max = b.count;
$$;

-- Task 9
CREATE OR REPLACE FUNCTION get_peers_count_start_block(block text)
RETURNS numeric AS $$
    DECLARE
        peer_count numeric := 0;
    BEGIN
        SELECT
            count(*) INTO peer_count
        FROM peers p2
        WHERE p2."Nickname" IN (
            SELECT
                ch."Peer"
            FROM checks ch
            WHERE ch."Task" LIKE $1 || '_' || E'\\_' || '%');
        RETURN peer_count;
    end;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_peers_count_didnt_start_any_block()
RETURNS numeric AS $$
    DECLARE
        peer_count numeric := 0;
    BEGIN
        SELECT
            count(*) INTO peer_count
        FROM peers p
        WHERE p."Nickname" NOT IN (
            SELECT
                "Peer"
            FROM checks)
        AND p."Nickname" <> 'null';
        RETURN peer_count;
    end;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_blocks_start_statistics(block1 text, block2 text)
RETURNS TABLE (StartedBlock1 numeric, StartedBlock2 numeric, StartedBothBlocks numeric, DidntStartAnyBlock numeric) AS $$
    SELECT
        round(get_peers_count_start_block($1) / count(*) * 100),
        round(get_peers_count_start_block($2) / count(*) * 100),
        round((get_peers_count_start_block($1) + get_peers_count_start_block($2)) / count(*) * 100),
        round(get_peers_count_didnt_start_any_block() / count(*) * 100)
    FROM peers p
    WHERE p."Nickname" <> 'null';
$$ LANGUAGE sql;

-- Task 10
CREATE OR REPLACE FUNCTION fnc10_checks_birthday()
    RETURNS TABLE ("SuccessfulChecks" numeric, "UnsuccessfulChecks" numeric)
    LANGUAGE sql AS 
$$
    WITH cte_checks_birthday AS (
        SELECT * 
        FROM checks c 
        JOIN p2p p ON c."ID" = p."Check"
        JOIN peers pr ON c."Peer" = pr."Nickname"  
        WHERE date_part('day',"Date") = date_part('day',"Birthday") 
        AND date_part('month',"Date") = date_part('month',"Birthday"))
    SELECT 
        (SELECT ROUND(COUNT(*)::REAL / (SELECT COUNT(*) FROM peers) * 100) 
        FROM 
            (SELECT DISTINCT "Peer" 
            FROM cte_checks_birthday 
            WHERE "State" = 'Success') a),  
        (SELECT ROUND(COUNT(*)::REAL / (SELECT COUNT(*) FROM peers) * 100) 
        FROM 
            (SELECT DISTINCT "Peer" 
            FROM cte_checks_birthday 
            WHERE "State" = 'Failure') a);
$$;

-- Task 11
CREATE OR REPLACE FUNCTION get_peers_finish_task(task text)
RETURNS TABLE (Peer text) AS $$
    SELECT
        Peer
    FROM get_peers_finish_tasks() t
    WHERE t.Task = $1;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION get_peer_finish_tasks_statistics(task1 text, task2 text, task3 text)
RETURNS TABLE (Peer text) AS $$
    SELECT
        p."Nickname"
    FROM peers p
    WHERE p."Nickname" IN (SELECT Peer FROM get_peers_finish_task(task1))
    AND p."Nickname" IN (SELECT Peer FROM get_peers_finish_task(task2))
    AND p."Nickname" NOT IN (SELECT Peer FROM get_peers_finish_task(task3));
$$ LANGUAGE sql;

-- Task 12
CREATE OR REPLACE FUNCTION fnc12_task_parents()
    RETURNS TABLE ("Task" text, "PrevCount" integer)
    LANGUAGE sql AS 
$$
    WITH RECURSIVE parents AS (
        SELECT "Title", "ParentTask"
        FROM tasks WHERE "Title" <> 'null'

        UNION ALL

        SELECT p."Title", t."ParentTask" FROM parents p
        JOIN tasks t ON p."ParentTask" = t."Title"
        WHERE p."ParentTask" <> 'null') 
    SELECT "Title", COUNT(*) - 1
    FROM parents 
    GROUP BY "Title";
$$;

-- Task 13
CREATE OR REPLACE FUNCTION fnc13_successful_days(N integer)
RETURNS SETOF date 
LANGUAGE plpgsql AS $$
DECLARE
    curr_date date := 'infinity';
    print_date date := 'infinity';
    consecutive_success integer := 0;
    r RECORD;
BEGIN
    FOR r IN 
        (SELECT p.*, c."Date", p2p."State" AS "Res"
        FROM p2p p 
        JOIN checks c ON p."Check" = c."ID" 
        JOIN p2p ON p."Check" = p2p."Check" AND p."State" <> p2p."State" 
        JOIN tasks t ON t."Title" = c."Task" 
        LEFT JOIN xp ON xp."Check" = p."Check" 
        WHERE p."State" = 'Start' 
        AND xp."XPAmount"::REAL / t."MaxXP" * 100 >= 80
        ORDER BY "Date", "Time")
    LOOP
        IF r."Date" = print_date 
        THEN CONTINUE; 
        END IF;
        IF curr_date = 'infinity'
        THEN curr_date := r."Date";
        END IF;
        IF curr_date = r."Date" AND r."Res" = 'Success'
        THEN consecutive_success := consecutive_success + 1;
            IF consecutive_success >= N
            THEN print_date = r."Date";
                RETURN NEXT print_date;
                curr_date := 'infinity';
                consecutive_success := 0;
            END IF;
        ELSE consecutive_success := 0;
        END IF;
    END LOOP;
END;
$$;

-- Task 14
CREATE OR REPLACE PROCEDURE prc14_max_xp(
    out "Peer" text, 
    out "XP" integer)
    LANGUAGE plpgsql AS 
$$
BEGIN
    WITH xp_count AS (
        SELECT c."Peer", SUM("XPAmount") as sum
        FROM xp x 
        JOIN checks c ON x."Check" = c."ID" 
        GROUP BY c."Peer") 
    SELECT * INTO "Peer", "XP"
    FROM xp_count 
    WHERE sum = (
        SELECT MAX(sum) 
        FROM xp_count);
END;
$$;

-- Task 15
CREATE OR REPLACE FUNCTION get_peers_come_early(time_of_coming TIME, num_of_times numeric)
RETURNS TABLE (Peer text) AS $$
    SELECT
        tt."Peer"
    FROM timetracking tt
    WHERE tt."State" = 1
    AND tt."Time" < $1
    GROUP BY tt."Peer"
    HAVING count(*) >= $2;
$$ LANGUAGE sql;

-- Task 16
CREATE OR REPLACE FUNCTION fnc16_peers_out(day_cnt integer, cnt integer)
    RETURNS TABLE ("Peer" text)
    LANGUAGE sql AS 
$$
    WITH peers_out AS (
        SELECT "Peer", COUNT(*) as count
        FROM timetracking 
        WHERE "State" = 2 AND CURRENT_DATE - "Date" <= $1 
        GROUP BY "Peer") 
    SELECT "Peer" 
    FROM peers_out 
    WHERE count > $2;
$$;

-- Task 16 procedure plpgsql
CREATE OR REPLACE PROCEDURE prc16_peers_out(day_cnt integer, cnt integer, REFCURSOR)
LANGUAGE plpgsql AS 
$$ 
BEGIN
    OPEN $3 FOR
        (WITH peers_out AS (
            SELECT "Peer", COUNT(*) as count
            FROM timetracking 
            WHERE "State" = 2 AND CURRENT_DATE - "Date" <= day_cnt 
            GROUP BY "Peer") 
        SELECT "Peer" 
        FROM peers_out 
        WHERE count > cnt);
END;
$$;

-- Task 17
CREATE OR REPLACE FUNCTION get_early_entries()
RETURNS TABLE (Month text, EarlyEntries numeric) AS $$
    SELECT
        TO_CHAR("Birthday", 'Month') AS Month,
        round((COUNT(*) FILTER (WHERE EXTRACT(HOUR FROM "Time") < 12)::DECIMAL / COUNT(*) * 100)) AS EarlyEntries
    FROM peers p
    LEFT JOIN timetracking tt
    ON tt."Peer" = p."Nickname"
    WHERE tt."State" <> 2
    GROUP BY TO_CHAR("Birthday", 'Month')
    ORDER BY TO_DATE(TO_CHAR("Birthday", 'Month'), 'Month');
$$ LANGUAGE sql;
