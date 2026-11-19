---- LESSON 3: JOINING LOCAL DATA WITH SHARED DATA ----

--1) Create new intl_db database

USE ROLE sysadmin;
CREATE DATABASE intl_db;
USE SCHEMA intl_db.public;

--2) create warehouse for loading intl_db

USE ROLE sysadmin;
CREATE WAREHOUSE intl_wh WITH WAREHOUSE_SIZE = 'XSMALL' WAREHOUSE_TYPE = 'STANDARD' AUTO_SUSPEND = 600--600 seconds/10mins
AUTO_RESUME = TRUE;
USE WAREHOUSE intl_wh;

--3) Create and load new table

CREATE
OR REPLACE TABLE intl_db.public.INT_STDS_ORG_3166 (
    iso_country_name VARCHAR(100),
    country_name_official VARCHAR(200),
    sovreignty VARCHAR(40),
    alpha_code_2digit VARCHAR(2),
    alpha_code_3digit VARCHAR(3),
    numeric_country_code INTEGER,
    iso_subdivision VARCHAR(15),
    internet_domain_code VARCHAR(10)
);

--file format to load table

CREATE
OR REPLACE FILE FORMAT util_db.public.PIPE_DBLQUOTE_HEADER_CR TYPE = 'CSV' --use csv for any flat file
COMPRESSION = 'AUTO' FIELD_DELIMITER = '|' RECORD_DELIMITER = '\r' --carriage return
SKIP_HEADER = 1 --1 header row
FIELD_OPTIONALLY_ENCLOSED_BY = '\042' --double quotes
TRIM_SPACE = FALSE;

-- check files in newly created stage for formatting

list @util_db.public.internal_stage_aws_s3_bucket;

--4) load ISO table using file format

COPY INTO intl_db.public.INT_STDS_ORG_3166
FROM
    @util_db.public.internal_stage_aws_s3_bucket 
FILES = ('ISO_Countries_UTF8_pipe.csv') 
file_format = (format_name = 'util_db.public.PIPE_DBLQUOTE_HEADER_CR');
    
-- 5) Check work: check table created and loaded correctly

select
    count(*) as found,
    '249' as expected
FROM
    INTL_DB.PUBLIC.INT_STDS_ORG_3166;
    
--6) code checks using metadata

    --asking if table exists
SELECT
    COUNT(*) AS objects_found
FROM
    INTL_DB.INFORMATION_SCHEMA.TABLES
WHERE
    TABLE_SCHEMA = 'PUBLIC'
    AND TABLE_NAME = 'INT_STDS_ORG_3166';
    
--asking if table has expected number of rows
SELECT
    row_count
FROM
    INTL_DB.INFORMATION_SCHEMA.TABLES
WHERE
    table_schema = 'PUBLIC'
    AND table_name = 'INT_STDS_ORG_3166';
    
--7) join local data with shared data

SELECT *
FROM snowflake_sample_data.tpch_sf1.nation;
    
SELECT
    *
FROM snowflake_sample_data.tpch_sf1.region;
    
Select
    *
FROM intl_db.public.int_stds_org_3166;
    
SELECT
    iso_country_name,
    country_name_official,
    alpha_code_2digit,
    r_name AS region
FROMmintl_db.public.int_stds_org_3166 i
    LEFT JOIN snowflake_sample_data.tpch_sf1.nation n ON UPPER(i.iso_country_name) = n.n_name
    LEFT JOIN snowflake_sample_data.tpch_sf1.region r ON n_regionkey = r_regionkey;
    
-- convert to a view
    CREATE VIEW intl_db.public.NATIONS_SAMPLE_PLUS_ISO (
        iso_country_name,
        country_name_official,
        alpha_code_2didigt,
        region
    ) AS
SELECT
    iso_country_name,
    country_name_official,
    alpha_code_2digit,
    r_name AS region
FROM
    intl_db.public.int_stds_org_3166 i
    LEFT JOIN snowflake_sample_data.tpch_sf1.nation n ON UPPER(i.iso_country_name) = n.n_name
    LEFT JOIN snowflake_sample_data.tpch_sf1.region r ON n_regionkey = r_regionkey;

SELECT
    *
FROM
    intl_db.public.NATIONS_SAMPLE_PLUS_ISO;
    
--8) Create and load currencies and country_code_to_currency_code tables

    CREATE TABLE intl_db.public.CURRENCIES (
        currency_ID INTEGER,
        currency_char_code VARCHAR(3),
        currency_symbol VARCHAR(4),
        currency_digital_code VARCHAR(3),
        currency_digital_name VARCHAR(30)
    ) COMMENT = 'Information about currencies including character codes, symbols, digital codes, etc.';

CREATE TABLE intl_db.public.COUNTRY_CODE_TO_CURRENCY_CODE (
        country_char_code VARCHAR(3),
        country_numeric_code INTEGER,
        country_name VARCHAR(100),
        currency_name VARCHAR(100),
        currency_char_code VARCHAR(3),
        currency_numeric_code INTEGER
    ) COMMENT = 'Mapping table currencies to countries';


--file format
CREATE FILE FORMAT util_db.public.CSV_COMMA_LF_HEADER
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n' -- \n represents line feed character
    SKIP_HEADER = 1
;

--load tables with data

COPY INTO intl_db.public.CURRENCIES
FROM @util_db.public.internal_stage_aws_s3_bucket 
FILES = ('currencies.csv') 
file_format = (format_name = 'util_db.public.CSV_COMMA_LF_HEADER');

COPY INTO intl_db.public.COUNTRY_CODE_TO_CURRENCY_CODE
FROM @util_db.public.internal_stage_aws_s3_bucket 
FILES = ('country_code_to_currency_code.csv') 
file_format = (format_name = 'util_db.public.CSV_COMMA_LF_HEADER');

SELECT *
FROM intl_db.public.CURRENCIES;

SELECT *
FROM intl_db.public.COUNTRY_CODE_TO_CURRENCY_CODE;

--9) create views for simple_currency with country_code_to_currency_code as basis

CREATE VIEW simple_currency (
    cty_code,
    cur_code
    ) AS
    SELECT 
    country_char_code as cty_code,
    currency_char_code as cur_code
    FROM COUNTRY_CODE_TO_CURRENCY_CODE
;

SELECT * 
FROM simple_currency

