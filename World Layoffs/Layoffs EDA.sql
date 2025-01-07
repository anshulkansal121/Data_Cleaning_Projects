-- Exploratory Data Analysis

use world_layoffs;

SELECT * FROM layoffs_staging;

 -- Whats the date range of the layoffs data
 SELECT MIN(`date`) AS initial_date, MAX(`date`) AS last_date
 FROM layoffs_staging;
 -- The data is from Mar'20 to  Mar'23

-- Company Wise Total Layoffs
SELECT company, SUM(total_laid_off)
FROM layoffs_staging
GROUP BY company
ORDER BY 2 DESC;

-- Industry wise total Layoffs
SELECT industry, SUM(total_laid_off) AS total_laid_off
 FROM layoffs_staging
 GROUP BY industry
 ORDER BY 2 DESC;
 
 -- Now Let's look at some of the big name that completely laid off their entire staff
 -- Or Basically companies that largest fundings but still shuts down
 SELECT *
 FROM layoffs_staging
 WHERE percentage_laid_off = 1
 ORDER BY funds_raised_millions DESC;
 
 
 -- Now lets examine which countries have the most layoff
 SELECT country, SUM(total_laid_off)
 FROM layoffs_staging
 GROUP BY country
 ORDER BY 2 DESC;
 -- US have the most number of Layoffs with 256559 total employees laid off in the 3 year span
 -- Followed by India with 35993 employees laid off.
 
-- What's the year wise statistics of layoff wrt to country
SELECT country, YEAR(`date`) AS `Year`, SUM(total_laid_off)
FROM layoffs_staging
GROUP BY YEAR(`date`),country
HAVING SUM(total_laid_off) IS NOT NULL
ORDER BY country,YEAR(`date`) DESC;
 
-- Total Layoffs wrt to year
SELECT YEAR(`date`) AS `Year`, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging
GROUP BY  YEAR(`date`)
ORDER BY 1 DESC;
-- In Year 2022 we have maximum no. of layoffs with 160661


-- Progressive Layoffs over year and month
-- Rolling layoff SUM

WITH rolling_layoffs AS
(
	SELECT SUBSTRING(`date`,1,7) AS `Month`, SUM(total_laid_off) AS total_laid_off
    FROM layoffs_staging
    WHERE SUBSTRING(`date`,1,7) IS NOT NULL
    GROUP BY `Month`
    ORDER BY `Month` ASC
)
SELECT `Month`, total_laid_off, SUM(total_laid_off) OVER(ORDER BY `Month`) AS Rolling_laid_off
FROM rolling_layoffs;


-- Previously when we have looked at the company wise layoffs per year 
-- Now lets rank those layoffs

WITH company_year_rank AS (
	SELECT company, YEAR(`date`) AS `Year`, SUM(total_laid_off),
    DENSE_RANK() OVER(PARTITION BY YEAR(`date`) ORDER BY SUM(total_laid_off) DESC) AS Ranking
	FROM layoffs_staging
	GROUP BY YEAR(`date`),company
	HAVING SUM(total_laid_off) IS NOT NULL
)

SELECT * 
FROM company_year_rank
WHERE Ranking <=5 AND `Year` IS NOT NULL;
-- ORDER BY Ranking ASC

-- We can further change this query for industry or Country or anything
