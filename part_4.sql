-- Part 4: Business Question -- 
-- Goal: Analyse which YouTube content categories (excluding Music & Entertainment) perform best
--          if starting a new channel right now and whether it would work for all countries

-- Connect to assignment_1 database
USE DATABASE assignment_1;


-- 1. Investigate overall metrics for each category across all years --
-- Calculate avg view_count, peak views, total_views, likes and comment ratio per category
SELECT category_title
    , COUNT(DISTINCT video_id) AS total_videos                                      -- Total unique videos in category
    , ROUND(AVG(view_count), 2) AS avg_views                                        -- Average views per video
    , MAX(view_count) AS peak_views                                                 -- Highest viewed video in this category
    , SUM(view_count) AS total_views                                                -- Total view_count added up
    , ROUND(AVG(likes / NULLIF(view_count, 0)), 3) AS avg_like_ratio                -- Average likes to views ratio 
    , ROUND(AVG(comment_count / NULLIF(view_count, 0)), 4) AS avg_comment_ratio     -- Average comment to views ratio
FROM table_youtube_final
WHERE category_title NOT IN ('Music','Entertainment')                               -- Filter out Music and Entertainment
GROUP BY category_title
ORDER BY avg_views DESC;                                                            -- Order by top avg_views  



-- 2. Top category per year with the highest average views --
-- Create CTE that computes yearly statistics for each category and is ranked
WITH category_year_stats AS (
    SELECT category_title
            , EXTRACT(YEAR FROM trending_date) AS year                                      -- Extract the year
            , COUNT(DISTINCT video_id) AS total_videos                                      -- Total unique videos in this category
            , ROUND(AVG(view_count), 2) AS avg_views                                        -- Average views per video
            , MAX(view_count) AS peak_views                                                 -- Highest viewed video in this category
            , SUM(view_count) AS total_views                                                -- Total view_count added up
            , ROUND(AVG(likes / NULLIF(view_count, 0)), 3) AS avg_like_ratio                -- Average likes to views ratio 
            , ROUND(AVG(comment_count / NULLIF(view_count, 0)), 4) AS avg_comment_ratio     -- Average comment to views ratio
            , RANK() OVER(
        PARTITION BY year                                                                   -- Rank within years
        ORDER BY avg_views DESC                                                             -- Rank based on highest to lowest avg_views
        ) AS rk
        FROM table_youtube_final
        WHERE category_title NOT IN ('Music','Entertainment')                               -- Filter out Music and Entertainment
        GROUP BY category_title, year
        ORDER BY category_title, year
)
SELECT *
FROM category_year_stats
WHERE rk = 1                                                                                -- Filter top category per year
ORDER BY year;                                                                              -- Sort chronologically 



-- 3. Category trend analysis using lag function --
-- Calculate avg view_count, peak views, total_views, likes and comment ratio per category per year
-- Detect increase/decrease/no change in avg_views per category over each year

WITH category_year_stats AS (
    SELECT category_title
            , EXTRACT(YEAR FROM trending_date) AS year                                      -- Extract the year
            , COUNT(DISTINCT video_id) AS total_videos                                      -- Total unique videos in this category
            , ROUND(AVG(view_count), 2) AS avg_views                                        -- Average views per video
            , MAX(view_count) AS peak_views                                                 -- Highest viewed video in this category
            , SUM(view_count) AS total_views                                                -- Total view_count added up
            , ROUND(AVG(likes / NULLIF(view_count, 0)), 3) AS avg_like_ratio                -- Average likes to views ratio 
            , ROUND(AVG(comment_count / NULLIF(view_count, 0)), 4) AS avg_comment_ratio     -- Average comment to views ratio
        FROM table_youtube_final
        WHERE category_title NOT IN ('Music','Entertainment')                               -- Filter out Music and Entertainment
        GROUP BY category_title, year
        ORDER BY category_title, year
)
SELECT 
    *
    , CASE 
        WHEN avg_views > LAG(avg_views) OVER (PARTITION BY category_title ORDER BY year)
        THEN 'Increase'                                                                     -- avg_views increased from previous year
        WHEN avg_views < LAG(avg_views) OVER (PARTITION BY category_title ORDER BY year)
        THEN 'Decrease'                                                                     -- avg_views decreased from previous year
        ELSE 'No Change'                                                                    -- avg_views same as previous or first year
    END AS trend
FROM category_year_stats
ORDER BY category_title, year;                                                              -- Sort results chronologically by category and year 

-- SAME CODE AS ABOVE EXCEPT: Selecting Only Film & Animation, Gaming and Science & Technology 
WITH category_year_stats AS (
    SELECT category_title
            , EXTRACT(YEAR FROM trending_date) AS year                                      -- Extract the year
            , COUNT(DISTINCT video_id) AS total_videos                                      -- Total unique videos in this category
            , ROUND(AVG(view_count), 2) AS avg_views                                        -- Average views per video
            , MAX(view_count) AS peak_views                                                 -- Highest viewed video in this category
            , SUM(view_count) AS total_views                                                -- Total view_count added up
            , ROUND(AVG(likes / NULLIF(view_count, 0)), 3) AS avg_like_ratio                -- Average likes to views ratio 
            , ROUND(AVG(comment_count / NULLIF(view_count, 0)), 4) AS avg_comment_ratio     -- Average comment to views ratio
        FROM table_youtube_final
        WHERE category_title NOT IN ('Music','Entertainment')                               -- Filter out Music and Entertainment
        GROUP BY category_title, year
        ORDER BY category_title, year
)
SELECT 
    *
    , CASE 
        WHEN avg_views > LAG(avg_views) OVER (PARTITION BY category_title ORDER BY year)
        THEN 'Increase'                                                                     -- avg_views increased from previous year
        WHEN avg_views < LAG(avg_views) OVER (PARTITION BY category_title ORDER BY year)
        THEN 'Decrease'                                                                     -- avg_views decreased from previous year
        ELSE 'No Change'                                                                    -- avg_views same as previous or first year
    END AS trend
FROM category_year_stats
WHERE category_title IN ('Film & Animation', 'Gaming', 'Science & Technology')
ORDER BY category_title, year;          


-- 4. Top category for each country across all years
-- Obtain the top category per country based on average views per video across all years
WITH category_avg_views_country AS (
    SELECT country
        , category_title                                  
        , COUNT(DISTINCT video_id) AS total_videos                                      -- Total unique videos in this category
        , ROUND(AVG(view_count), 2) AS avg_views                                        -- Average views per video
        , MAX(view_count) AS peak_views                                                 -- Highest viewed video in this category
        , SUM(view_count) AS total_views                                                -- Total view_count added up
        , ROUND(AVG(likes / NULLIF(view_count, 0)), 3) AS avg_like_ratio                -- Average likes to views ratio 
        , ROUND(AVG(comment_count / NULLIF(view_count, 0)), 4) AS avg_comment_ratio     -- Average comment to views ratio
        , RANK() OVER (
        PARTITION BY country                                                            -- Rank separately within each country
        ORDER BY avg_views DESC                                                         -- Order by highest to lowest avg views
        ) AS rk
    FROM table_youtube_final
    WHERE category_title NOT IN ('Music','Entertainment')                               -- Filter out Music and Entertainment
    GROUP BY country, category_title
)
SELECT * FROM category_avg_views_country
WHERE rk = 1                                                                            -- Keep the top category
ORDER BY country;



-- 5. Top category title for each country per year
-- Get the top category per country, per year based on average views
WITH category_avg_views_years AS (
    SELECT country
        , category_title
        , EXTRACT(YEAR FROM trending_date) AS year
        , COUNT(DISTINCT video_id) AS total_videos                                      -- Total unique videos in this category
        , ROUND(AVG(view_count), 2) AS avg_views                                        -- Average views per video
        , MAX(view_count) AS peak_views                                                 -- Highest viewed video in this cateogry
        , SUM(view_count) AS total_views                                                -- Total view_count added up
        , ROUND(AVG(likes / NULLIF(view_count, 0)), 3) AS avg_like_ratio                -- Average likes to views ratio 
        , ROUND(AVG(comment_count / NULLIF(view_count, 0)), 4) AS avg_comment_ratio     -- Average comment to views ratio
        , RANK() OVER (
        PARTITION BY country, year                                                      -- Rank categories over country and year
        ORDER BY avg_views DESC                                                         -- Order by highest to lowest avg views
        ) AS rk
    FROM table_youtube_final
    WHERE category_title NOT IN ('Music','Entertainment')                               -- Filter out Music and Entertainment
    GROUP BY country, category_title, year
)
SELECT *
FROM category_avg_views_years
WHERE rk = 1                                                                            -- Keep the top category
ORDER BY country, year;


-- SAME CODE AS ABOVE EXCEPT: Selecting only year 2024
WITH category_avg_views_years AS (
    SELECT country
        , category_title
        , EXTRACT(YEAR FROM trending_date) AS year
        , COUNT(DISTINCT video_id) AS total_videos                                      -- Total unique videos in this category
        , ROUND(AVG(view_count), 2) AS avg_views                                        -- Average views per video
        , MAX(view_count) AS peak_views                                                 -- Highest viewed video in this cateogry
        , SUM(view_count) AS total_views                                                -- Total view_count added up
        , ROUND(AVG(likes / NULLIF(view_count, 0)), 3) AS avg_like_ratio                -- Average likes to views ratio 
        , ROUND(AVG(comment_count / NULLIF(view_count, 0)), 4) AS avg_comment_ratio     -- Average comment to views ratio
        , RANK() OVER (
        PARTITION BY country, year                                                      -- Rank categories over country and year
        ORDER BY avg_views DESC                                                         -- Order by highest to lowest avg views
        ) AS rk
    FROM table_youtube_final
    WHERE category_title NOT IN ('Music','Entertainment')                               -- Filter out Music and Entertainment
    GROUP BY country, category_title, year
)
SELECT *
FROM category_avg_views_years
WHERE rk = 1 AND year = 2024                                                            -- Keep the top category and only year 2024
ORDER BY country, year;


