--Selecting the data to use and ordering it by Location and Date

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths (Where total cases not 0)
-- Likelyhood of dying if you get covid in US
SELECT location,date,total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE total_cases != 0 AND location LIKE '%states%' AND continent IS NOT null
ORDER BY 1,2

-- Looking at Total Cases vs Population in US
-- What percentage of population contracted covid
SELECT location,date,total_cases,population, (total_cases/population)*100 AS PercentOfPopulationWithCovid
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT null 
ORDER BY 1,2

-- Countries with highest infection rates compared to population
SELECT location, population, MAX (total_cases) AS HighestRecordedInfectionNumber, MAX((total_cases/population)*100) AS PercentOfPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT null
GROUP BY location, population
ORDER BY PercentOfPopulationInfected desc

-- Countries with highest death rates compared to population
SELECT location, population, MAX (total_cases) AS HighestRecordedInfectionNumber, MAX(total_deaths) AS TotalDeaths, MAX((total_deaths/population)*100) AS PercentOfPopulationDeceased
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT null
GROUP BY location, population
ORDER BY PercentOfPopulationDeceased desc --location asc

-- Looking At highest in CONTINENTS

SELECT DISTINCT continent, MAX(total_deaths) AS TotalDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeaths desc




-- GLOBAL COUNTS Per Day where New Cases Reported were no ZERO or NULL
SELECT date, SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, SUM(new_deaths)/SUM(new_cases) AS DeathPercentage
FROM PortfolioProject..CovidDeaths 
WHERE continent IS NOT NULL AND new_cases != 0
GROUP BY date
ORDER BY 1,2

--
SELECT SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, SUM(new_deaths)/SUM(new_cases) AS DeathPercentage
FROM PortfolioProject..CovidDeaths 
WHERE continent IS NOT NULL AND new_cases != 0
--GROUP BY date
ORDER BY 1,2


--Pulling in CovidVaccinations Table

SELECT* 
FROM PortfolioProject..CovidVaccinations

--Joining tables 

SELECT*
FROM PortfolioProject..CovidDeaths dea JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date


-- Looking at Total Population vs Vaccination -- USING CTE (Virtual Table) --

WITH PopVsVac(continent, location, date, population, new_vaccinations, RollingVaccineCount)
AS 
(
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccineCount
	--, (RollingVaccineCount/population)*100
	FROM PortfolioProject..CovidDeaths dea JOIN PortfolioProject..CovidVaccinations vac
			ON dea.location = vac.location AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
)
SELECT*, (RollingVaccineCount/Population)*100
FROM PopVsVac


-- USING A TEMP TABLE

-- Tried rerunning, had to drop table since it was ran previously

DROP TABLE IF EXISTS #PercentPopulationVaccinated -- Just incase of alterations
CREATE TABLE #PercentPopulationVaccinated
(
	continent nvarchar(255), 
	location nvarchar(255),
	Date datetime,
	population numeric,
	new_vaccinations numeric,
	RollingVaccineCount numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccineCount
--, (RollingVaccineCount/population)*100
FROM PortfolioProject..CovidDeaths dea JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL

SELECT*, (RollingVaccineCount/Population)*100
FROM #PercentPopulationVaccinated


-- CREATING VIEWS to store data for visualization ============================================================================


--View Counting Vaccinations through time partitioned by location---------------------------------
--DROP VIEW IF EXISTS PercentPopulationVaccinated

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccineCount
--, (RollingVaccineCount/population)*100
FROM PortfolioProject..CovidDeaths dea JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM PercentPopulationVaccinated

-- View of Percent of People infected in each location (Country)----------------------------------
--DROP VIEW IF EXISTS PercentPopulationInfected

CREATE VIEW PercentPopulationInfected  AS
SELECT location, population, MAX (total_cases) AS HighestRecordedInfectionNumber, MAX((total_cases/population)*100) AS PercentOfPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT null
GROUP BY location, population
--ORDER BY PercentOfPopulationInfected desc (Can't use order by in view)

--View Percent of infected people deceased in each location-------------------------------------
--DROP VIEW IF EXISTS PercentOfPeopleDeceased

CREATE VIEW PercentageOfPopulationDeceased AS
SELECT location, population, MAX(total_cases) AS HighestCaseCount, MAX(total_deaths) AS HighestDeathCount
, MAX((total_deaths/population)*100) AS HighestPercentOfPopulationDeceased
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
--ORDER BY HighestPercentOfPopulationDeceased DESC


--View Total Deaths broken down by region and then income--------------------------------------------

CREATE VIEW TotalRegionalDeaths AS
SELECT DISTINCT location, MAX(total_deaths) AS TotalDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
--ORDER BY TotalDeaths desc

--++++++++ Visualization Queries ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--QUERIES FOR Visualization

-- 1 -- Worlwide covid death rate
SELECT SUM(total_cases) AS TotalCovidCases, SUM(new_deaths) AS TotalCovidDeaths, (SUM(new_deaths)/SUM(new_cases))*100 AS CovidDeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL AND new_cases != 0
ORDER BY 1,2


-- 2 --Total Covid deaths per continent (Oceania Included)
SELECT location, SUM(new_deaths) AS TotalCovidDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL AND location IN ('ASIA', 'Europe', 'North America', 'South America', 'Africa', 'Oceania')
GROUP BY location
ORDER BY TotalCovidDeaths DESC

-- 3 -- Infection Rate over Population per country
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population)*100 AS PercentPopulationInfected 
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- 4 -- Covid infection rate per date interval in countries
SELECT Location, Population, Date, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
GROUP BY Location, Population, Date
ORDER BY PercentPopulationInfected DESC
