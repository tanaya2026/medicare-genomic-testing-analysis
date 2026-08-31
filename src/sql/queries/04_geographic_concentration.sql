USE MedicareGenomicAnalysis;
GO

CREATE OR ALTER VIEW dbo.vw_GenomicTestLocationQuotient AS

-- Calculates Location Quotients to compare how heavily a state relies on a
-- specific genomic test category relative to national testing patterns.

WITH StateCategoryTotals AS (
	-- Get total services per state and test category
    SELECT Rndrng_Prvdr_Geo_Desc AS State, TEST_Category AS Test_Category, SUM(Total_Services) AS Category_Services
    FROM vw_GenomicKPIs
    GROUP BY Rndrng_Prvdr_Geo_Desc, TEST_Category
), 
StateTotals AS (
	-- Get overall total services per state across all categories
    SELECT Rndrng_Prvdr_Geo_Desc AS State, SUM(Total_Services) AS State_Total_Services
    FROM vw_GenomicKPIs
    GROUP BY Rndrng_Prvdr_Geo_Desc
), 
NationalCategoryTotals AS (
	-- Get national total services for each test category
    SELECT TEST_Category AS Test_Category, SUM(Total_Services) AS National_Category_Services
    FROM vw_GenomicKPIs
    GROUP BY TEST_Category
), 
NationalTotal AS (
	-- Get the grand total of all services nationwide
    SELECT SUM(Total_Services) AS Grand_Total FROM vw_GenomicKPIs
) 
-- Compute state share, national share, and the resulting Location Quotient
SELECT 
    sct.State,
    sct.Test_Category,
    sct.Category_Services,
    CAST(sct.Category_Services AS FLOAT) / st.State_Total_Services AS State_Category_Share,
    CAST(nct.National_Category_Services AS FLOAT) / nt.Grand_Total AS National_Category_Share,
    (CAST(sct.Category_Services AS FLOAT) / st.State_Total_Services) 
      / (CAST(nct.National_Category_Services AS FLOAT) / nt.Grand_Total) AS Location_Quotient
FROM StateCategoryTotals sct
JOIN StateTotals st ON sct.State = st.State
JOIN NationalCategoryTotals nct ON sct.Test_Category = nct.Test_Category
CROSS JOIN NationalTotal nt;
GO