/*

Cleaning Data in SQL Queries
-- No. of Rows = 56477
-- No. of Columns = 

*/

SELECT *
FROM DataCleaning..NashvilleHousing
ORDER BY 1

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format

SELECT SaleDate, FORMAT(SaleDate, 'yyyy-MM-dd')
FROM DataCleaning..NashvilleHousing

UPDATE NashvilleHousing
SET SaleDate = FORMAT(SaleDate, 'yyyy-MM-dd')

-- NOT WORKING

SELECT SaleDate
FROM DataCleaning..NashvilleHousing

-- If it doesn't Update properly

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

SELECT SaleDateConverted
FROM DataCleaning..NashvilleHousing

ALTER TABLE NashvilleHousing
DROP Column SaleDate

EXEC sp_RENAME 'NashvilleHousing.SaleDateConverted', 'SaleDate', 'COLUMN'



 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data
-- Certain Property Address are  NULL lets populate them with address having same ParcelID
SELECT a.ParcelID,a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM DataCleaning..NashvilleHousing a
JOIN DataCleaning..NashvilleHousing b
ON a.ParcelID = b.ParcelID AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


UPDATE a
SET a.PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM DataCleaning..NashvilleHousing a
JOIN DataCleaning..NashvilleHousing b
ON a.ParcelID = b.ParcelID AND a.[UniqueID ] <> b.[UniqueID ]



--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)
SELECT propertyAddress, SUBSTRING(propertyAddress, 1,CHARINDEX(',',propertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress,CHARINDEX(',',propertyAddress)+1,LEN(propertyAddress)) AS Address
FROM DataCleaning..NashvilleHousing


ALTER TABLE NashvilleHousing
ADD propertySplitAddress Nvarchar(255), propertySplitCity Nvarchar(255);

UPDATE DataCleaning..NashvilleHousing
SET propertySplitAddress = SUBSTRING(propertyAddress, 1,CHARINDEX(',',propertyAddress)-1);

UPDATE DataCleaning..NashvilleHousing
SET propertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',propertyAddress)+1,LEN(propertyAddress));

-- Lets look at the OwnerAddress
SELECT OwnerAddress
FROM DataCleaning..NashvilleHousing;


SELECT 
	PARSENAME(REPLACE(OwnerAddress,',','.'),1),
	PARSENAME(REPLACE(OwnerAddress,',','.'),2),
	PARSENAME(REPLACE(OwnerAddress,',','.'),3)
FROM DataCleaning..NashvilleHousing


ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255), OwnerSplitState Nvarchar(255), OwnerSplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3),
	OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),2),
	OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),1)
--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field
SELECT DISTINCT(SoldAsVacant),COUNT(SoldAsVacant)
FROM DataCleaning..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

UPDATE NashvilleHousing
	SET SoldAsVacant = CASE 
			WHEN SoldAsVacant = 'N' THEN 'No'
			WHEN SoldAsVacant = 'Y' THEN 'Yes'
			ELSE
				SoldAsVacant 
			END



-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates
SELECT * 
FROM DataCleaning..NashvilleHousing

WITH duplicateCTE AS (
SELECT *,
DENSE_RANK () OVER(
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
	ORDER BY	UniqueID
	) AS row_num
FROM DataCleaning..NashvilleHousing
)

DELETE 
FROM duplicateCTE
WHERE row_num > 1


SELECT * 
FROM duplicateCTE
WHERE row_num > 1
ORDER BY UniqueID


---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

ALTER TABLE DataCleaning..NashvilleHousing
DROP Column PropertyAddress, OwnerAddress,TaxDistrict

SELECT * 
FROM DataCleaning..NashvilleHousing

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
