-- Part 1: Data Ingestion --

-- 1.Setup Database and Stage --

-- Create database and connect to it
CREATE DATABASE assignment_1;
USE DATABASE assignment_1;

-- Creating a stage called stage_assignment pointing to Azure Storage
-- The stage provides access to raw files uploaded in the specified container
CREATE OR REPLACE STAGE stage_assignment
URL='azure://utsbdeshawya.blob.core.windows.net/at1'
CREDENTIALS=(AZURE_SAS_TOKEN='?sv=2024-11-04&ss=b&srt=co&sp=rwdlaciytfx&se=2025-12-31T06:43:47Z&st=2025-08-09T23:28:47Z&spr=https&sig=DJeSlzRSpXPuynpqulYTtsyPEvhOtBDAb6aC6sbvxZA%3D');

-- Check which files are available in the stage
list @stage_assignment;


-- 2. File Format: Define CSV format for ingestion --

-- Skips headers, handles null values and quoted values
CREATE OR REPLACE FILE FORMAT file_format_csv
TYPE = 'CSV'
FIELD_DELIMITER = ','
SKIP_HEADER = 1
NULL_IF = ('\\N', 'NULL', 'NUL', '')
FIELD_OPTIONALLY_ENCLOSED_BY = '"';

-- 3. External table for trending data (CSV files) --

-- Create external table from raw CSV files
CREATE OR REPLACE EXTERNAL TABLE ex_table_youtube_trending
WITH LOCATION = @stage_assignment
FILE_FORMAT = file_format_csv
PATTERN = '.*\.csv';

-- Creating external table for trending data that is structured
CREATE OR REPLACE EXTERNAL TABLE ex_table_youtube_trending(
    video_id varchar AS (value:c1::varchar)
    , title varchar AS (value:c2::varchar)
    , publishedat date AS (value:c3::date)
    , channelid varchar AS (value:c4::varchar)
    , channeltitle varchar AS (value:c5::varchar)
    , categoryid int AS (value:c6::int)
    , trending_date date AS (value:c7::date)
    , view_count int AS (value:c8::int)
    , likes int AS (value:c9::int)
    , dislikes int AS (value:c10::int)
    , comment_count int AS (value:c11::int)
)
WITH LOCATION = @stage_assignment
FILE_FORMAT = file_format_csv
PATTERN = '.*\.csv';

-- 4. Trending Data Table -- 

-- Create a permanent table called 'table_youtube_trending' from the previously created external table
-- Additionally, added country column from the file name 
CREATE OR REPLACE TABLE table_youtube_trending AS
SELECT value:c1::varchar AS video_id
    , value:c2::varchar AS title
    , value:c3::date AS publishedat
    , value:c4::varchar AS channelid
    , value:c5::varchar AS channeltitle
    , value:c6::int AS categoryid
    , value:c7::date AS trending_date
    , value:c8::int AS view_count
    , value:c9::int AS likes
    , value:c10::int AS dislikes
    , value:c11::int AS comment_count
    , split_part(metadata$filename, '_', 1) AS country -- Extracts the country code from file name
FROM ex_table_youtube_trending;

-- 5. External table for category data (JSON files) --

-- Creating an external table 'ex_table_youtube_category' that reads JSON files 
-- The table extracts the 'items' field from each JSON document as a VARIANT column.
-- 'items' is a nested array of JSON objects, which will be flattened later
CREATE OR REPLACE EXTERNAL TABLE ex_table_youtube_category (
    items VARIANT AS (VALUE:items)
)
WITH LOCATION = @stage_assignment
FILE_FORMAT = (TYPE=JSON)
PATTERN = '.*[.]json';

-- 6. Category Data Table -- 

-- Create a permanent table 'table_youtube_category' from the previously created external table
-- Extracting 'country' from file name, 'categoryid' and 'category_title' from JSON file
CREATE OR REPLACE TABLE table_youtube_category AS
SELECT
    split_part(metadata$filename, '_', 1) AS country, -- Extracts country code from file name
    item.value:id::varchar AS categoryid,
    item.value:snippet.title::varchar AS category_title,
FROM ex_table_youtube_category,
LATERAL FLATTEN(input => items) item;


-- 8. Final Table: Combine trending and category data

-- Create a final table combining table_youtube_trending and table_youtube_category
-- A LEFT JOIN is used to ensure all videos from 'table_youtube_trending' are included
-- Join is performed on 'country' and 'categoryid' to correctly map category titles
CREATE OR REPLACE TABLE table_youtube_final AS
SELECT 
    UUID_STRING() AS id,    -- Generates a unique identifier for each row (primary key)
    t.video_id,
    t.title,
    t.publishedat,
    t.channelid,
    t.channeltitle,
    t.categoryid,
    c.category_title,
    t.trending_date,
    t.view_count,
    t.likes,
    t.dislikes,
    t.comment_count,
    t.country
FROM 
    table_youtube_trending t
LEFT JOIN 
    table_youtube_category c
ON 
    t.country = c.country 
    AND t.categoryid = c.categoryid;

-- Count the number of rows in table_youtube_final
SELECT COUNT(*) 
FROM table_youtube_final;
-- Result: 2667041 rows

