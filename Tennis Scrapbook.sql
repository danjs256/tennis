--Set the role and warehouse contexts.
USE ROLE TRANSFORMER;
USE WAREHOUSE TRANSFORMING;

--Create and use the top level objects for the dbt project.
--CREATE DATABASE DB_DANIEL;
--CREATE SCHEMA MWS_DEV;
USE DATABASE DB_DANIEL;
USE SCHEMA DB_DANIEL.MWS_DEV;

/**********************
*** SHOW SCHEMA ERD ***
**********************/

--Create file format.
CREATE OR REPLACE FILE FORMAT csv_ff
    TYPE = CSV
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    SKIP_HEADER = 1
    NULL_IF = ('', 'NULL');
SHOW FILE FORMATS;
DESCRIBE FILE FORMAT csv_ff;

--Create internal stage for initial ingestion.
CREATE OR REPLACE STAGE manual_load_csv
    FILE_FORMAT = (FORMAT_NAME = 'csv_ff')
    --FILE_FORMAT = (TYPE = CSV)
    COMMENT = 'Internal stage for manually loading plain CSV data.';
SHOW STAGES;
LIST @DB_DANIEL.MWS_DEV.MANUAL_LOAD_CSV;

--Create tables.
CREATE OR REPLACE TABLE DB_DANIEL.MWS_DEV.MATCHES (
    ID INTEGER,
    SRC_SYS VARCHAR,
    SRC_ID VARCHAR,
    DATE DATE,
    TIME TIME,
    ROUND_ORDER INTEGER,
    ROUND_NAME VARCHAR,
    IS_LADDER VARCHAR,
    VENUE VARCHAR,
    COURTS VARCHAR,
    HOME_TEAM_ID INTEGER,
    HOME_GAMES INTEGER,
    HOME_SETS INTEGER,
    HOME_POINTS FLOAT,
    AWAY_TEAM_ID INTEGER,
    AWAY_GAMES INTEGER,
    AWAY_SETS INTEGER,
    AWAY_POINTS FLOAT,
    FORMAT VARCHAR,
    STATUS VARCHAR,
    STATUS_REASON VARCHAR
);

CREATE OR REPLACE TABLE DB_DANIEL.MWS_DEV.PLAYERS (
    ID INTEGER,
    FULL_NAME VARCHAR,
    FIRST_NAME VARCHAR,
    SURNAME VARCHAR,
    STATUS VARCHAR,
    POSITION VARCHAR,
    PHONE VARCHAR,
    EMAIL VARCHAR,
    DOB DATE,
    TENNIS_ID VARCHAR,
    MC_ID VARCHAR,
    UTR_ID VARCHAR,
    TJ_WIN_SEASON VARCHAR
);

CREATE OR REPLACE TABLE DB_DANIEL.MWS_DEV.PLAYER_RATINGS (
    PLAYER_ID INTEGER,
    DATE DATE,
    SINGLES_UTR FLOAT,
    SINGLES_STATUS VARCHAR,
    DOUBLES_UTR FLOAT,
    DOUBLES_STATUS VARCHAR
);

CREATE OR REPLACE TABLE DB_DANIEL.MWS_DEV.PLAYER_REGISTRATIONS (
    PLAYER_ID INTEGER,
    REGISTRATION_FORM VARCHAR,
    SUBMITTED_AT DATETIME,
    RESPONSE VARIANT --JSON
);

CREATE OR REPLACE TABLE DB_DANIEL.MWS_DEV.SETS (
    ID INTEGER,
    MATCH_ID INTEGER,
    SRC_SYS VARCHAR,
    SRC_ID VARCHAR,
    SEQUENCE INTEGER,
    COURT VARCHAR,
    SURFACE VARCHAR,
    P1_POSITION VARCHAR,
    P2_POSITION VARCHAR,
    HOME_P1 INTEGER,
    HOME_P2 INTEGER,
    HOME_GAMES INTEGER,
    HOME_SETS INTEGER,
    HOME_POINTS FLOAT,
    AWAY_P1 INTEGER,
    AWAY_P2 INTEGER,
    AWAY_GAMES INTEGER,
    AWAY_SETS INTEGER,
    AWAY_POINTS FLOAT,
    FORMAT VARCHAR,
    STATUS VARCHAR,
    STATUS_REASON VARCHAR
);

CREATE OR REPLACE TABLE DB_DANIEL.MWS_DEV.TEAMS (
    ID INTEGER,
    COMPETITION VARCHAR,
    SEASON VARCHAR,
    SEQUENCE INTEGER,
    NAME VARCHAR
);

CREATE OR REPLACE TABLE DB_DANIEL.MWS_DEV.TEAM_PLAYERS (
    TEAM_ID INTEGER,
    PLAYER_ID INTEGER,
    SEQUENCE INTEGER,
    POSITION VARCHAR,
    IS_SHARED VARCHAR,
    DESCRIPTION VARCHAR
);

/*************************
*** ADD FILES TO STAGE ***
*************************/

--Confirm stage exists and files are waiting.
LIST @DB_DANIEL.MWS_DEV.MANUAL_LOAD_CSV;

--Truncate tables if required?
TRUNCATE TABLE DB_DANIEL.MWS_DEV.MATCHES;
TRUNCATE TABLE DB_DANIEL.MWS_DEV.PLAYERS;
TRUNCATE TABLE DB_DANIEL.MWS_DEV.PLAYER_RATINGS;
TRUNCATE TABLE DB_DANIEL.MWS_DEV.PLAYER_REGISTRATIONS;
TRUNCATE TABLE DB_DANIEL.MWS_DEV.SETS;
TRUNCATE TABLE DB_DANIEL.MWS_DEV.TEAMS;
TRUNCATE TABLE DB_DANIEL.MWS_DEV.TEAM_PLAYERS;

--Load data into tables.
--TODO fix this?
COPY INTO DB_DANIEL.MWS_DEV.MATCHES
    FROM @DB_DANIEL.MWS_DEV.MANUAL_LOAD_CSV/matches.csv;
COPY INTO DB_DANIEL.MWS_DEV.PLAYERS
    FROM @DB_DANIEL.MWS_DEV.MANUAL_LOAD_CSV/players.csv;
COPY INTO DB_DANIEL.MWS_DEV.PLAYER_RATINGS
    FROM @DB_DANIEL.MWS_DEV.MANUAL_LOAD_CSV/player_ratings.csv;
COPY INTO DB_DANIEL.MWS_DEV.PLAYER_REGISTRATIONS
    FROM @DB_DANIEL.MWS_DEV.MANUAL_LOAD_CSV/player_registrations.csv;
COPY INTO DB_DANIEL.MWS_DEV.SETS
    FROM @DB_DANIEL.MWS_DEV.MANUAL_LOAD_CSV/sets.csv;
COPY INTO DB_DANIEL.MWS_DEV.TEAMS
    FROM @DB_DANIEL.MWS_DEV.MANUAL_LOAD_CSV/teams.csv;
COPY INTO DB_DANIEL.MWS_DEV.TEAM_PLAYERS
    FROM @DB_DANIEL.MWS_DEV.MANUAL_LOAD_CSV/team_players.csv;

--Confirm successful loads.
SELECT * FROM DB_DANIEL.MWS_DEV.MATCHES;
SELECT * FROM DB_DANIEL.MWS_DEV.PLAYERS;
SELECT * FROM DB_DANIEL.MWS_DEV.PLAYER_RATINGS;
SELECT * FROM DB_DANIEL.MWS_DEV.PLAYER_REGISTRATIONS;
SELECT * FROM DB_DANIEL.MWS_DEV.SETS;
SELECT * FROM DB_DANIEL.MWS_DEV.TEAMS;
SELECT * FROM DB_DANIEL.MWS_DEV.TEAM_PLAYERS;

--Create a Github Account and Repository:
/*  Create an account on Github.com.
    Link account to your organisation (if required).
    Create new repository, ensuring at least one file exists (tick the box to create a README.md file).
        - Snowflake will throw an internal error with little guidance later if the repo is empty
    Note the URL of the repository, we'll need it later.
*/

--Create an API Integration, and grant USAGE to the user's role.
--This is used to integrate your workspace with Github for Version Control.
--It requires ACCOUNTADMIN privileges, and has already been created by Hung.
CREATE OR REPLACE API INTEGRATION github_for_workspaces
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/')
    API_USER_AUTHENTICATION = (TYPE = SNOWFLAKE_GITHUB_APP)
    ENABLED = TRUE
    COMMENT = 'For connecting Snowflake Workspaces to Github. First used in the dbt project in DB_DANIEL.TENNIS on 14/08/2025.'
    ;
GRANT USAGE ON INTEGRATION github_for_workspaces TO ROLE TRANSFORMER;
SHOW INTEGRATIONS;
DESCRIBE INTEGRATION github_for_workspaces;


--In Snowflake Workspaces, create a new Workspace.
/*  Snowflake > Projects > Workspaces
    My Workspace > Create Workspace > From Git Repository
    Paste Repository URL
    Name Workspace
    Select API Integration "GITHUB_FOR_WORKSPACES"
    Use OAuth2
    Click Sign In, login to Github
    Click configure, it will take you back to Github
    Install "snowflakedb" to your Github account (or organisation) where the new repository was created
    Select your new repository and click Install
    Return to Snowflake Workspaces, and click Create
*/

--Create your dbt Project.
/*  Add New > dbt Project
    Name Project
    Set Role and Warehouse context
    Set Database and Schema context
    Click Create
    In profiles.yml, replace the '' next to account and user with N/A. This just prevents a warning from showing during dbt runs.
    Delete the default dbt sample models(?)
    Build all of your dbt code as desired (sources.yml, transformation layers, semantic layers, testing, documentation, etc.)
*/

--Drop the default dbt model tables if you forgot to delete the model files.
SELECT * FROM DB_DANIEL.MWS_DEV.MY_FIRST_DBT_MODEL;
SELECT * FROM DB_DANIEL.MWS_DEV.MY_SECOND_DBT_MODEL;
DROP TABLE DB_DANIEL.MWS_DEV.MY_FIRST_DBT_MODEL;
DROP VIEW DB_DANIEL.MWS_DEV.MY_SECOND_DBT_MODEL;
