SELECT * FROM CovidProject..CovidDeaths
ORDER BY 3,4

--SELECT * FROM CovidProject..CovidVaccinations
--ORDER BY 3,4


SELECT Location,date, total_cases, new_cases, total_deaths, population
FROM CovidProject..CovidDeaths
ORDER BY 1,2

--addressing problem data types in a few columns up front:

ALTER TABLE CovidProject..CovidDeaths
ALTER COLUMN date datetime

ALTER TABLE CovidProject..CovidDeaths
ALTER COLUMN total_deaths float

ALTER TABLE CovidProject..CovidDeaths
ALTER COLUMN total_cases float

ALTER TABLE CovidProject..CovidDeaths
ALTER COLUMN total_cases float

ALTER TABLE CovidProject..CovidDeaths
ALTER COLUMN Population float

ALTER TABLE CovidProject..CovidDeaths
ALTER COLUMN new_cases float

ALTER TABLE CovidProject..CovidDeaths
ALTER COLUMN new_deaths float

-- Looking at total cases vs total deaths
-- Communicates likelihood of death from Covid in a Perspective country

SELECT Location, date, total_cases,total_deaths, (total_deaths/NULLIF(total_cases,0) * 100) AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE Location LIKE '%states%'AND
ISNULL(continent,'')<>''
ORDER BY 1,2

-- Looking at Total Cases vs. Population
-- communicates percent of population infected by Covid

SELECT Location, date, total_cases,Population, (total_cases/NULLIF(population,0) * 100) AS InfectedPercentage
FROM CovidProject..CovidDeaths
WHERE ISNULL(continent,'')<>''
ORDER BY Location, date

-- Looking at Highest Infection rate vs. Population

SELECT Location,Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/NULLIF(population,0) * 100)) AS InfectedPercentage
FROM CovidProject..CovidDeaths
WHERE ISNULL(continent,'')<>''
GROUP BY Location, Population
ORDER BY InfectedPercentage DESC

--Looking at Countries with highest death count per population

SELECT Location,MAX(total_deaths) as TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE ISNULL(continent,'')<>''
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- Taking a look by Continent now, rather than Country:

-- Looing at continents with highest death count per population

SELECT location,MAX(total_deaths) as TotalDeathCount
FROM CovidProject..CovidDeaths
WHERE continent = '' and location NOT LIKE '%income%'
GROUP BY location
ORDER BY TotalDeathCount DESC



-- Global Numbers

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/NULLIF(SUM(new_cases),0)*100 AS DeathPercentage
FROM CovidProject..CovidDeaths
WHERE ISNULL(continent,'')<>''
ORDER BY total_cases, total_deaths



--Looking at Total Population vs. Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingPeopleVaccinated
FROM CovidProject..CovidDeaths dea
INNER JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE ISNULL(dea.continent,'')<>''
ORDER BY dea.location, dea.date

--Using a CTE

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)

AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingPeopleVaccinated
FROM CovidProject..CovidDeaths dea
INNER JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE ISNULL(dea.continent,'')<>''
)

SELECT *,(RollingPeopleVaccinated/Population)*100
FROM PopvsVac

-- TEMP TABLE

DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date date, 
Population float,
New_vaccinations float, 
RollingPeopleVaccinated float
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingPeopleVaccinated
FROM CovidProject..CovidDeaths dea
INNER JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE ISNULL(dea.continent,'')<>''

SELECT *, (RollingPeopleVaccinated/Population) *100 AS PercentPopulationVaxxed
FROM #PercentPopulationVaccinated
ORDER BY Location, Date


-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
 SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS RollingPeopleVaccinated
FROM CovidProject..CovidDeaths dea
INNER JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE ISNULL(dea.continent,'')<>''


SELECT * 
FROM PercentPopulationVaccinated