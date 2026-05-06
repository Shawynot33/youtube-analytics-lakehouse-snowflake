-- Part 2: Data Cleaning --

-- Connect to assignment_1 database
USE DATABASE assignment_1;

-- Question 1 --
-- Goal: Identify duplicate category title in table_youtube_category ignoring category id
--       In other words, find category titles that refers to multiple category ids

SELECT category_title
FROM table_youtube_category
GROUP BY category_title
HAVING COUNT(DISTINCT categoryid) > 1;  -- Filter category_title with more than 1 category id

-- Question 2 -- 
-- Goal: Find category titles that exist in only one country

SELECT category_title
FROM table_youtube_category
GROUP BY category_title
HAVING COUNT(DISTINCT country) = 1;    -- Filter category_title that only appear once in a country.

-- Question 3 --
-- Goal: Identify category IDs where the category title is missing

SELECT DISTINCT categoryid
FROM table_youtube_final
WHERE category_title IS NULL    -- Only when title is missing
  AND categoryid IS NOT NULL;   -- Check whether a valid cateogry ID exists


-- Question 4 --
-- Goal: Correct the missing cateogry titles for a known category ID

-- Determine which category title refers to categoryid 29
SELECT categoryid
    , category_title
FROM table_youtube_category
WHERE categoryid = 29;

-- Update table_youtube_finla with the correct category title for categoryid 29.
UPDATE table_youtube_final
SET category_title = 'Nonprofits & Activism'    -- Update the correct category title
WHERE category_title IS NULL                    -- Only update rows where title is missing
AND categoryid = 29;                            -- Ensure only update rows with categoryid 29 
-- Updated 1563 rows

-- Question 5 --
-- Goal: Find videos with missing channel titles

SELECT title
FROM table_youtube_final
WHERE channeltitle IS NULL;         -- Filter where channeltitle is missing

-- Question 6 --
-- Goal: Remove rows with invalid video IDs in table_youtube_final

DELETE FROM table_youtube_final     -- Delete from  table_youtube_final
WHERE video_id = '#NAME?';          -- Filter videos with invalid video_ids
-- 32081 rows deleted

-- Question 7 --
-- Goal: Identify duplicate videos based on video_id, country and trending date

-- Look at which videos have duplicates in video_id, country and trending date
SELECT video_id
    , country
    , trending_date
    , COUNT(*) AS duplicate_count       -- Count duplicates for each combination
FROM table_youtube_final
GROUP BY video_id
    , country
    , trending_date
HAVING COUNT(*) > 1                     -- Keep only duplicates
ORDER BY duplicate_count DESC;

-- Create table_youtube_dupicates containing duplicates ranked by view count in descending order
-- Videos with rank_number > 1 are considered 'bad duplicates' which will be removed
CREATE OR REPLACE TABLE table_youtube_duplicates AS 
WITH ranked_videos AS (
    SELECT *
        , ROW_NUMBER() OVER(
            PARTITION BY video_id
                , country
                , trending_date 
            ORDER BY view_count DESC    -- Ensure the video with highest view count will be ranked as 1
        ) AS rank_number
    FROM table_youtube_final
)
SELECT *
FROM ranked_videos
WHERE rank_number > 1;                  -- Select and store only the 'bad' duplicates that are not ranked 1st.

-- Question 8 --
-- Goal: Delete duplicates from final table using the duplictes table (table_youtube_duplicates)

DELETE FROM table_youtube_final f   -- Delete from the final table
USING table_youtube_duplicates d
WHERE f.id = d.id;                  -- Delete rows with matching duplicate IDs
-- Deleted 37466

-- Question 9 --
-- Goal: Count the number of rows in the cleaned table

SELECT COUNT(*)
FROM table_youtube_final;
-- 2597494 rows which is the expected number of rows.

