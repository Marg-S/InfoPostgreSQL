-- Task 1
CREATE OR REPLACE PROCEDURE add_p2p(checkedPeer text, checkingPeer text, 
    task text, status state, checktime time)
LANGUAGE plpgsql AS $$
    DECLARE
        check_id integer;
    BEGIN
        IF checkedPeer = checkingPeer
        THEN 
            RAISE INFO 'REJECTED: checkedPeer = checkingPeer';
            RETURN;
        END IF;
        IF status = 'Start'
        THEN INSERT INTO checks("Peer", "Task", "Date")
            VALUES(checkedPeer, task, current_date)
            RETURNING "ID" INTO check_id;
            INSERT INTO p2p ("Check", "CheckingPeer", "State", "Time")
            VALUES(
               check_id,
               checkingPeer,
               status,
               checktime);
        ELSE
            check_id := 
                (SELECT
                    p."Check"
                FROM p2p p
                JOIN checks ch
                ON p."Check" = ch."ID"
                LEFT JOIN p2p 
                ON p."Check" = p2p."Check" AND p."State" <> p2p."State"
                WHERE checkingPeer = p."CheckingPeer"
                AND p2p."State" IS NULL
                AND ch."Peer" = checkedPeer
                AND ch."Task" = task);
            IF check_id IS NULL
            THEN
                RAISE INFO 'REJECTED: check of % for % with unfinished P2P step not found', $3, $1;
            ELSE 
                INSERT INTO p2p ("Check", "CheckingPeer", "State", "Time")
                VALUES(
                check_id,
                checkingPeer,
                status,
                checktime);
            END IF;
        END IF;
    END;
$$;

-- Task 2
CREATE OR REPLACE PROCEDURE add_verter(
    CheckedPeer text, 
    Task text, 
    State state, 
    Time_verter TIME)
LANGUAGE plpgsql
AS $$  
    DECLARE p2p_success integer := 
        (WITH cte_p2p_success AS 
            (SELECT * FROM P2P p 
            JOIN Checks c 
            ON c."ID" = p."Check" 
            WHERE "Peer" = $1 
            AND "Task" = $2 
            AND "State" = 'Success') 
        SELECT "Check" FROM cte_p2p_success 
        WHERE "Date" = (SELECT MAX("Date") FROM cte_p2p_success) 
        AND "Time" = (SELECT MAX("Time") FROM cte_p2p_success));                 
    BEGIN
        IF p2p_success IS NULL 
        THEN RAISE INFO 'REJECTED: P2P check of task % for peer % is not success', $2, $1; 
        ELSE
            INSERT INTO verter 
            VALUES(
                default, 
                p2p_success,
                $3,
                $4);
        END IF;
    END;                         
$$;

-- Task 3
CREATE OR REPLACE FUNCTION fnc_trg_update_transferred_points()
RETURNS TRIGGER AS $$
    DECLARE
        checkedPeer text;
        existing_id bigint;
    BEGIN
        IF NEW."State" = 'Start' THEN
            checkedPeer = (
            SELECT
                "Peer"
            FROM checks
            WHERE NEW."Check" = checks."ID");
            existing_id = (SELECT
                "ID"
            FROM transferredpoints tp
            WHERE NEW."CheckingPeer" = tp."CheckingPeer"
            AND checkedPeer = tp."CheckedPeer");
            IF existing_id IS NOT NULL THEN
                UPDATE transferredpoints tp
                SET "PointsAmount" = "PointsAmount" + 1
                WHERE tp."ID" = existing_id;
            ELSE
                INSERT INTO transferredpoints("CheckingPeer", "CheckedPeer", "PointsAmount")
                VALUES(NEW."CheckingPeer", checkedPeer, 1);
            end if;
        end if;
        RETURN NEW;
    end
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_update_transferred_points
AFTER INSERT ON p2p
FOR EACH ROW EXECUTE FUNCTION fnc_trg_update_transferred_points();

-- Task 4
CREATE OR REPLACE FUNCTION fnc_trg_xp_insert() 
    RETURNS TRIGGER 
    LANGUAGE plpgsql AS 
$trg_xp_insert$ 
    BEGIN 
        IF NEW."XPAmount" >
            (SELECT DISTINCT "MaxXP" 
            FROM checks c
            JOIN tasks t ON c."Task" = t."Title" 
            WHERE c."ID" = NEW."Check")
        THEN RAISE INFO 'REJECTED: XPAmount cannot have value %, this is more than MaxXP', NEW."XPAmount";
            RETURN NULL;
        ELSIF 'Success' NOT IN 
            (WITH cte_p2p AS 
            (SELECT * FROM checks c 
            JOIN p2p p ON c."ID" = p."Check" 
            WHERE c."ID" = NEW."Check") 
            SELECT "State" 
            FROM cte_p2p 
            WHERE "Time" = (SELECT MAX("Time") FROM cte_p2p))
            OR 'Success' <> 
            (WITH cte_verter AS 
            (SELECT * FROM checks c 
            JOIN verter v ON c."ID" = v."Check" 
            WHERE c."ID" = NEW."Check") 
            SELECT "State" 
            FROM cte_verter 
            WHERE "Time" = (SELECT MAX("Time") FROM cte_verter))
        THEN RAISE INFO 'REJECTED: Check with ID = % is not success', NEW."Check";
            RETURN NULL;
        END IF;
        RETURN NEW; 
    END;
$trg_xp_insert$;

CREATE OR REPLACE TRIGGER trg_xp_insert 
    BEFORE INSERT ON xp 
    FOR EACH ROW 
    EXECUTE FUNCTION fnc_trg_xp_insert();
