USE world_layoffs;
SELECT * FROM layoffs;

-- Firstly we will create a new table so that our original data remain intact
-- We can call this table anything i am calling it layoffs_staging;

CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT INTO layoffs_staging
SELECT * 
FROM layoffs;

SELECT * FROM layoffs_staging;

-- now when we are cleaning the data we usually follow a few steps
-- 1. check for duplicates and remove any
-- 2. standardize data and fix errors
-- 3. Look at null values and see what 
-- 4. remove any columns and rows that are not necessary - few ways

-- 1. Check for Duplicates and remove any if found.
WITH duplicateCTE AS (
	SELECT *,
		ROW_NUMBER() OVER(
			PARTITION BY company,location,industry,total_laid_off, percentage_laid_off, `date`,stage,country,funds_raised_millions
		) AS row_num
	FROM layoffs_staging
)

SELECT * FROM duplicateCTE 
WHERE row_num >1;

-- Above DELETE will not work as in MySQL CTEs are not updatable
-- One of the solution is to update the layoffs_staging table and add a column for row_num and then populate that column
-- Let's try that approach

ALTER TABLE layoffs_staging
ADD row_num INT;

-- now update the table and populate the row_num column
DELETE FROM layoffs_staging;

INSERT INTO layoffs_staging
SELECT *,
		ROW_NUMBER() OVER(
			PARTITION BY company,location,industry,total_laid_off, percentage_laid_off, `date`,stage,country,funds_raised_millions
		) AS row_num
	FROM layoffs;

SELECT * FROM layoffs_staging 
WHERE row_num >1;

-- DELETE THE DUPLICATE RECORDS
DELETE FROM layoffs_staging
WHERE row_num >1;


-- ------------------------------------------------------------------------------------------------------------------------------------------- 

-- 2. Standardize data and fix errors
-- Standardizing Data include looking at each column and try to fix common errors

-- Let's take a look at company column
SELECT DISTINCT company
FROM layoffs_staging
ORDER BY 1; 

 -- Some comapanies have space that needs to be trimmed 
UPDATE layoffs_staging
SET company = TRIM(company);

-- Let's take a look at country
SELECT DISTINCT country
FROM layoffs_staging
ORDER BY 1;

-- Some countries have a period at the end that need to be fixed
UPDATE layoffs_staging
SET country = TRIM(TRAILING '.' FROM country);

-- Let's look at industry
SELECT DISTINCT industry
FROM layoffs_staging
ORDER BY 1;

-- There are certail blank & NULL values we will treat them later
-- But first there is crypto and cryptoCurrency two industries which migh be same
SELECT company,industry
FROM layoffs_staging
WHERE industry LIKE 'Crypto%'
ORDER BY 1;

UPDATE layoffs_staging
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Lets Update the Date column to DATE datatype
SELECT `date`, STR_TO_DATE(`date`,'%m/%d/%Y')
FROM layoffs_staging;

UPDATE layoffs_staging
SET `date` = STR_TO_DATE(`date`,'%m/%d/%Y');

ALTER TABLE layoffs_staging
MODIFY COLUMN `date` DATE;

-- ------------------------------------------------------------------------------------------------------------------------------------------- 

-- 3. Treat NULL and Blank Values
-- Treating NULL values in industry

SELECT t1.industry, t2.industry
FROM layoffs_staging t1
JOIN layoffs_staging t2
ON t1.company = t2.company
WHERE t1.industry = '' OR t1.industry IS NULL
AND t2.industry IS NOT NULL
ORDER BY t1.company;

UPDATE layoffs_staging
SET industry = NULL
WHERE industry = '';

UPDATE layoffs_staging t1
JOIN layoffs_staging t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry = '' OR t1.industry IS NULL
AND t2.industry IS NOT NULL;

ALTER TABLE layoffs_staging
DROP COLUMN row_num;


-- Here we are done with Data Cleaning 

-- But as of now we have NULL Values in total_laid_off and percentage_laid_off
-- that is a part of EDA Process.
