/*

Cleaning Data in SQL

*/

SELECT *
FROM PortfolioProject..NashvilleHousing

---------------------------------------------------------------------------------------------------------------------

--++ Standadize Date Format ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- Converting from date time format to just date

SELECT SaleDateConverted, CONVERT(date, SaleDate)
FROM PortfolioProject..NashvilleHousing

--UPDATE NashvilleHousing
--SET SaleDate = CONVERT(Date, SaleDate)


ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)


--++Populating Propertyt Address Data ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- Inserting data in for Null values in property address
-- Populating address of properties with same ParcelID
--Using *ISNULL* to check if data a.propertyaddress is null and filling it with b.propertyaddress

SELECT *
FROM PortfolioProject..NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
	JOIN PortfolioProject..NashvilleHousing b
		ON a.ParcelID = b.ParcelID
		AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
	JOIN PortfolioProject..NashvilleHousing b
		ON a.ParcelID = b.ParcelID
		AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


--++ Breaking Down Address Into parts (Street, City, State)++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- USING comma delimination, SUBSTRING(ColumnName, Delim#, Length), and CHARINDEX('WhatToFind', ColumnName)

SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing


SELECT SUBSTRING( PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Street
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City

FROM PortfolioProject..NashvilleHousing

--
ALTER TABLE NashvilleHousing
ADD PropertyStreet nvarchar(255);

UPDATE NashvilleHousing
SET PropertyStreet = SUBSTRING( PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

--

--
ALTER TABLE NashvilleHousing
ADD PropertyCity nvarchar(255);

UPDATE NashvilleHousing
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

--


-- Dreaking Down Owner Address -----------------------------------------------------------

SELECT OwnerAddress
FROM PortfolioProject..NashvilleHousing

--Using PARSENAME(ColumnName, Period#) -- Only works with periods -- REPLACE(ColumnName, 'WhatToFind', 'WhatToChangeTo')

SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerStreet
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS OwnerCity
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS OwnerState
FROM PortfolioProject..NashvilleHousing


--
ALTER TABLE NashvilleHousing
ADD OwnerStreet nvarchar(255);

UPDATE NashvilleHousing
SET OwnerStreet = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

--

--
ALTER TABLE NashvilleHousing
ADD OwnerCity nvarchar(255);

UPDATE NashvilleHousing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
--

--
ALTER TABLE NashvilleHousing
ADD OwnerState nvarchar(255);

UPDATE NashvilleHousing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
--

-- Breaking Down Owner Name ---------------------------------------------------------------------------------

SELECT OwnerName 
, SUBSTRING(OwnerName, 1, CHARINDEX(',', OwnerName)) AS OwnerLastName
, SUBSTRING(OwnerName, CHARINDEX(',', OwnerName) + 1, LEN(OwnerName)) AS OwnerFirstNames
FROM PortfolioProject.dbo.NashvilleHousing
WHERE OwnerName IS NOT NULL

ALTER TABLE NashvilleHousing
ADD OwnerLastName nvarchar(255);

ALTER TABLE NashvilleHousing
ADD OwnerFirstNames nvarchar(255);

UPDATE NashvilleHousing
SET OwnerLastName = SUBSTRING(OwnerName, 1, CHARINDEX(',', OwnerName))

UPDATE NashvilleHousing
SET OwnerFirstNames = SUBSTRING(OwnerName, CHARINDEX(',', OwnerName) + 1, LEN(OwnerName)) 



--++ Change Y and N to Yes and No in "Sold as Vacant" Field +++++++++++++++++++++++++++++++++++++++++++++++++++++++


SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2


SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
  END
FROM PortfolioProject..NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant =  CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END


--++ Remove Duplicates +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- Judging duplicate if ParcelID, PropertyAddress, SalePrice, SaleDate, And LegalReferance are all the same for more than one property
-- USING CTE

WITH RowNumCTE AS
(
SELECT *,
 ROW_NUMBER() OVER(
 PARTITION BY ParcelID,
			  PropertyAddress,
			  SalePrice,
			  SaleDate,
			  LegalReference
			  ORDER BY UniqueID
			  )Row_Num

FROM PortfolioProject.dbo.NashvilleHousing
)
SELECT*
--DELETE
FROM RowNumCTE
WHERE Row_Num > 1
ORDER BY PropertyAddress
--ORDER BY ParcelID


--++ Deleting Unused/Altered Columns +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

SELECT*
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN  OwnerAddress, PropertyAddress, SaleDate, OwnerName