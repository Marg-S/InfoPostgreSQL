CREATE TABLE IF NOT EXISTS Peers(
  "Nickname" text PRIMARY KEY,
  "Birthday" date);

CREATE TABLE IF NOT EXISTS Tasks(
  "Title" text PRIMARY KEY,
  "ParentTask" text REFERENCES Tasks,
  "MaxXP" integer NOT NULL
);

CREATE TYPE state AS ENUM ('Start', 'Success', 'Failure');

CREATE TABLE IF NOT EXISTS Checks(
  "ID" SERIAL PRIMARY KEY,
  "Peer" text NOT NULL REFERENCES Peers,
  "Task" text NOT NULL REFERENCES Tasks,
  "Date" date NOT NULL
);

CREATE TABLE IF NOT EXISTS P2P(
  "ID" SERIAL PRIMARY KEY,
  "Check" integer NOT NULL REFERENCES Checks,
  "CheckingPeer" text NOT NULL REFERENCES Peers,
  "State" state,
  "Time" time NOT NULL,
  UNIQUE ("Check", "State")
);

CREATE TABLE IF NOT EXISTS Verter(
  "ID" SERIAL PRIMARY KEY,
  "Check" integer NOT NULL REFERENCES Checks,
  "State" state NOT NULL,
  "Time" time NOT NULL,
  UNIQUE ("Check", "State")
);

CREATE TABLE IF NOT EXISTS TransferredPoints(
  "ID" SERIAL PRIMARY KEY,
  "CheckingPeer" text NOT NULL REFERENCES Peers,
  "CheckedPeer" text NOT NULL REFERENCES Peers,
  "PointsAmount" integer NOT NULL
);

CREATE TABLE IF NOT EXISTS Friends(
  "ID" BIGSERIAL PRIMARY KEY,
  "Peer1" text NOT NULL REFERENCES Peers,
  "Peer2" text NOT NULL REFERENCES Peers
);

CREATE TABLE IF NOT EXISTS Recommendations(
  "ID" BIGSERIAL PRIMARY KEY,
  "Peer" text NOT NULL REFERENCES Peers,
  "RecommendedPeer" text REFERENCES Peers
);

CREATE TABLE IF NOT EXISTS XP(
  "ID" BIGSERIAL PRIMARY KEY,
  "Check" integer NOT NULL REFERENCES Checks,
  "XPAmount" integer NOT NULL
);

CREATE TABLE IF NOT EXISTS TimeTracking(
  "ID" BIGSERIAL PRIMARY KEY,
  "Peer" text NOT NULL REFERENCES Peers,
  "Date" date NOT NULL,
  "Time" time NOT NULL,
  "State" smallint CHECK ("State" IN (1, 2))
);


CREATE OR REPLACE PROCEDURE export_table_csv(
    table_name text DEFAULT 'peers', 
    delimiter char(1) DEFAULT ',',
    dir text DEFAULT '/Users/rodolphu/SQL2_Info21_v1.0-1/src/csv')
LANGUAGE plpgsql AS 
$$ 
    BEGIN 
        $3 := $3 || '/' || $1 || '.csv';
        EXECUTE format('COPY %I TO %L CSV HEADER DELIMITER %L NULL ''null''', $1, $3, $2);
    END;
$$;

CREATE OR REPLACE PROCEDURE import_table_csv(
    table_name text DEFAULT 'peers', 
    delimiter char(1) DEFAULT ',',
    dir text DEFAULT '/Users/rodolphu/SQL2_Info21_v1.0-1/src/csv')
LANGUAGE plpgsql AS 
$$ 
    BEGIN 
        $3 := $3 || '/' || $1 || '.csv';
        IF $1 = 'checks'
        THEN $1 := $1 || '("Peer", "Task", "Date")'; 
        ELSIF $1 = 'p2p'
        THEN $1 := $1 || '("Check", "CheckingPeer", "State", "Time")'; 
        ELSIF $1 = 'verter'
        THEN $1 := $1 || '("Check", "State", "Time")';
        ELSIF $1 = 'transferredpoints'
        THEN $1 := $1 || '("CheckingPeer", "CheckedPeer", "PointsAmount")';
        ELSIF $1 = 'friends'
        THEN $1 := $1 || '("Peer1", "Peer2")';
        ELSIF $1 = 'recommendations'
        THEN $1 := $1 || '("Peer", "RecommendedPeer")';
        ELSIF $1 = 'xp'
        THEN $1 := $1 || '("Check", "XPAmount")';
        ELSIF $1 = 'timetracking'
        THEN $1 := $1 || '("Peer", "Date", "Time", "State")';
        END IF;
        EXECUTE format('COPY %s FROM %L CSV HEADER DELIMITER %L NULL ''null''', $1, $3, $2);
    END;
$$;


CALL import_table_csv('peers', ',');
CALL import_table_csv('tasks', ',');
CALL import_table_csv('checks', ',');
CALL import_table_csv('p2p', ',');
CALL import_table_csv('verter', ',');
CALL import_table_csv('transferredpoints', ',');
CALL import_table_csv('friends', ',');
CALL import_table_csv('recommendations', ',');
CALL import_table_csv('xp', ',');
CALL import_table_csv('timetracking', ',');
