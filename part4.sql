-- Prepare
CREATE DATABASE part4;
\connect part4

CREATE TABLE IF NOT EXISTS "TableName_1" ("1" integer);
CREATE TABLE IF NOT EXISTS "TableName_2" ("1" integer);
CREATE TABLE IF NOT EXISTS "TableName_3" ("1" integer);
CREATE TABLE IF NOT EXISTS "tableName_4" ("1" integer);
CREATE TABLE IF NOT EXISTS "Name_5" ("1" integer);

CREATE OR REPLACE FUNCTION fnc_test_1(IN x integer) 
    RETURNS TABLE ("1" integer)
    LANGUAGE sql AS 
$$ 
    SELECT * FROM "tableName_4";
$$;

CREATE OR REPLACE FUNCTION fnc_test_2(IN x integer, OUT y integer) 
    LANGUAGE sql AS 
$$ 
    SELECT * FROM "Name_5";
$$;

CREATE OR REPLACE FUNCTION fnc_test_3(IN x integer, IN y text) 
RETURNS integer
    LANGUAGE sql AS 
$$ 
    SELECT * FROM "Name_5";
$$;

CREATE OR REPLACE PROCEDURE prc_test_1()
LANGUAGE plpgsql AS 
$$ 
BEGIN
    SELECT * FROM "tableName_4";
END;
$$;

CREATE OR REPLACE PROCEDURE prc_test_2()
LANGUAGE plpgsql AS 
$$ 
BEGIN
    SELECT * FROM "Name_5";
END;
$$;

CREATE OR REPLACE FUNCTION fnc_trg_test_1() 
    RETURNS TRIGGER 
    LANGUAGE plpgsql AS 
$trg_test_1$ 
    BEGIN 
        RETURN NEW; 
    END;
$trg_test_1$;

CREATE OR REPLACE FUNCTION fnc_trg_test_2() 
    RETURNS TRIGGER 
    LANGUAGE plpgsql AS 
$trg_test_2$ 
    BEGIN 
        RETURN NEW; 
    END;
$trg_test_2$;

CREATE OR REPLACE TRIGGER trg_test_1 
    BEFORE INSERT ON "tableName_4" 
    FOR EACH ROW 
    EXECUTE FUNCTION fnc_trg_test_1();

CREATE OR REPLACE TRIGGER trg_test_2 
    BEFORE INSERT ON "Name_5" 
    FOR EACH ROW 
    EXECUTE FUNCTION fnc_trg_test_2();

-- Task 1
CREATE OR REPLACE PROCEDURE prc_part4_task1()
LANGUAGE plpgsql AS 
$$
DECLARE 
    r RECORD; 
BEGIN
    FOR r IN (SELECT table_name
        FROM information_schema.tables 
        WHERE table_schema = 'public'
        AND table_name LIKE 'TableName%')
    LOOP
        EXECUTE 'DROP TABLE "' || r.table_name || '" CASCADE';
    END LOOP;
END;
$$;

-- Task 2
CREATE OR REPLACE PROCEDURE prc_part4_task2(
    OUT count integer)
LANGUAGE plpgsql AS 
$$
DECLARE 
    fnc text;
    r RECORD; 
BEGIN
    count := 0;
    fnc := chr(10) || repeat('-', 50) || chr(10) || 
        ' Functions with parameters' || chr(10) || ' ';
    FOR r IN 
        (SELECT 
            proname, 
            pg_get_function_arguments(oid) AS arg 
        FROM pg_proc 
        WHERE pronamespace = 
            (SELECT oid 
            FROM pg_namespace 
            WHERE nspname = 'public') 
        AND prokind = 'f' AND proargtypes <> '')
    LOOP
        count := count + 1;
        fnc := format('%s%s(%s) ', fnc, r.proname, r.arg);
    END LOOP;
    fnc := fnc || chr(10) || repeat('-', 50);
    RAISE INFO '%', fnc;
END;
$$;

-- Task 3
CREATE OR REPLACE PROCEDURE prc_part4_task3(
    OUT count integer)
LANGUAGE plpgsql AS 
$$
DECLARE 
    r RECORD; 
BEGIN
    count := 0;
    FOR r IN 
        (SELECT trigger_name, event_object_table
        FROM information_schema.triggers)
    LOOP
        count := count + 1;
        EXECUTE format('DROP TRIGGER %s ON %I', 
            r.trigger_name, r.event_object_table);
    END LOOP;
END;
$$;

-- Task 4
CREATE OR REPLACE PROCEDURE prc_part4_task4(
    IN txt text)
LANGUAGE plpgsql AS 
$$
DECLARE 
    functions text;
    type text;
    r RECORD; 
BEGIN
    functions := chr(10) || ' Subprogramms that have a string "' 
        || txt || '":' || chr(10) || chr(9);
    FOR r IN (SELECT p.proname, p.prokind 
        FROM pg_proc p
        WHERE pronamespace = 
            (SELECT oid 
            FROM pg_namespace
            WHERE nspname = 'public')
        AND pg_get_functiondef(p.oid) LIKE '%' || $1 ||'%')
    LOOP
        IF r.prokind = 'f' 
        THEN type := 'function'; 
        ELSE type := 'procedure'; 
        END IF;
        functions := format('%s%s (%s)%s%s', 
            functions, r.proname, type, chr(10), chr(9));
    END LOOP;
    RAISE INFO '%', chr(10) || repeat('-', 50) || functions || chr(10) || repeat('-', 50);
END;
$$;
