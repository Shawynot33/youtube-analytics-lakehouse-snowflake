-- Part 3: Data Analysis --

-- Connect to assignment_1 database
USE DATABASE assignment_1;

-- Question 1 --
-- Goal: Obtain the top 3 gaming videos per country on 2024-04-01 of trending date

-- Create a CTE if gaming videos that are ranked per country
WITH ranked_videos_gaming AS (
    SELECT country
        , title
        , channeltitle
        , view_count
        , RANK() OVER (
            PARTITION BY country            -- Rank videos within each country
            ORDER BY view_count DESC        -- Order from highest to lowest view_count
        ) AS rk
    FROM table_youtube_final
    WHERE trending_date = '2024-04-01'      -- Filter the date
        AND category_title = 'Gaming'       -- Filter only the Gaming category
    ORDER BY country, rk
)
SELECT * 
FROM ranked_videos_gaming
WHERE rk <= 3                               -- Select the top 3 videos per country
ORDER BY country, rk;


-- Question 2 --
-- Goal: Count the number of distinct BTS videos per country

SELECT country
    , COUNT(DISTINCT video_id) AS ct        -- Count unique video IDs containing 'BTS' in the title
FROM table_youtube_final
WHERE title ILIKE '%BTS%'                   -- Case insensitive search for 'BTS' in video title
GROUP BY country
ORDER BY ct DESC;                           -- Order by highest count


-- Question 3 --
-- Goal: Obtain the top viewed video per country per month in 2024 with likes ratio

-- Create CTE to rank videos by view_count within each country and month 
WITH video_rank_2024 AS (
    SELECT country
        , DATE_TRUNC('month', trending_date) AS year_month          -- Aggregate by month
        , title
        , channeltitle
        , category_title
        , view_count
        , ROUND(likes/NULLIF(view_count,0)*100,2) AS likes_ratio    -- Round to 2 decimal place and avoid division by 0
        , RANK() OVER(
        PARTITION BY country, year_month                            -- Rank videos by views within country and month
        ORDER BY view_count DESC                                    -- Rank by highest to lowest view_count
        ) AS rk
    FROM table_youtube_final
    WHERE YEAR(year_month) = 2024                                   -- Filter for only the year 2024
)
SELECT country
    , year_month
    , title
    , channeltitle
    , category_title
    , view_count
    , likes_ratio
FROM video_rank_2024
WHERE rk = 1                                                        -- Select only the top-ranked video per country and month
ORDER BY year_month, country;


-- Question 4 --
-- Goal: Identify the top category in terms of unique videos for each country since 2022 
--       and calculate its percentage contribution to total country videos

-- Create CTE containig total videos per category, per country and rank them
WITH distinct_category AS (
    SELECT country
        , category_title
        , COUNT(DISTINCT video_id) AS total_category_video      -- Number of unique videos in this category per country
        , ROW_NUMBER() OVER (
        PARTITION BY country                                    -- Rank categories within each country
        ORDER BY total_category_video DESC                      -- Highest number of videos gets rank 1
        ) AS rk
    FROM table_youtube_final
    WHERE YEAR(trending_date) >= 2022                           -- Filter from 2022 onwards
    GROUP BY country, category_title
    ORDER BY country, total_category_video DESC
), 
-- Create CTE with total unique videos per country
distinct_video AS (
    SELECT country
        , COUNT(DISTINCT video_id) AS total_country_video       -- Total unique videos per country
    FROM table_youtube_final
    WHERE YEAR(trending_date) >= 2022                           -- Filter from 2022 onwards
    GROUP BY country
    ORDER BY country
)
-- Join two CTEs to calculate the percentage contribution
SELECT dc.country
    , dc.category_title
    , dc.total_category_video                                   -- Top category video count
    , dv.total_country_video                                    -- Total videos in the country
    , ROUND((dc.total_category_video/dv.total_country_video)*100, 2) AS percentage  -- Percentage contribution of top category 2 decimal places
FROM distinct_category dc JOIN distinct_video dv ON dc.country = dv.country
WHERE dc.rk = 1                                                 -- Keep only the top category per country
ORDER BY category_title, country;

-- Question 5 --
-- Goal: Count the number of distinct videos per channel

SELECT channeltitle
    , COUNT(DISTINCT video_id) AS distinct_video_count       -- Number of unique videos per channel
FROM table_youtube_final
GROUP BY channeltitle
ORDER BY distinct_video_count DESC                           -- Order by channels with most unique videos (highest to lowest)
LIMIT 1;                                                     -- Obtain the top channel

-- Output: Vijay Television, 2049



