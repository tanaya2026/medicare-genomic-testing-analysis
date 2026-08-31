USE MedicareGenomicAnalysis;
GO
CREATE OR ALTER VIEW dbo.vw_CancerIncidenceVsGenomicTesting AS

-- Joins the genomic testing metrics with state-level cancer incidence stats
-- to compare service volume against actual disease burden for key test types.

WITH FilteredKPIs AS (
    SELECT 
        Year,
        Rndrng_Prvdr_Geo_Desc,
        TEST_Category,
        SUM(Tot_Srvcs) AS Total_Services
    FROM dbo.cms_2018_2024_combined
	-- Focus only on tumor profiling and hereditary cancer risk categories (since we are looking at cancer statistics only)
    WHERE TEST_Category IN ('Tumor Genomic Profiling', 'Hereditary Cancer Risk')
      AND HCPCS_Cd <> '81528'
    GROUP BY Year, Rndrng_Prvdr_Geo_Desc, TEST_Category
)
SELECT 
    k.Year,
    k.Rndrng_Prvdr_Geo_Desc AS State,
    k.TEST_Category,
    k.Total_Services,
    c.Age_Adjusted_Rate, -- Disease Burden Metric (using Age-Adjusted Rate)
    c.Count AS Cancer_Case_Count,
    c.Population AS State_Total_Population
FROM FilteredKPIs k
INNER JOIN dbo.cancer_incidence_stats c 
    ON k.Rndrng_Prvdr_Geo_Desc = c.States 
    AND k.Year = c.Year;
GO