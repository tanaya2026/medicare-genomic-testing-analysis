USE MedicareGenomicAnalysis;
GO
-- Joins the genomic testing metrics with state-level cancer incidence stats
-- to compare service volume against actual disease burden for key test types.
SELECT 
    k.Year,
    k.Rndrng_Prvdr_Geo_Desc AS State,
    k.TEST_Category,
    k.Total_Services,
    c.Age_Adjusted_Rate,    -- Disease Burden Metric (using Age-Adjusted Rate)
    c.Count AS Cancer_Case_Count,
    c.Population AS State_Total_Population
FROM dbo.vw_GenomicKPIs k
INNER JOIN dbo.cancer_incidence_stats c 
    ON k.Rndrng_Prvdr_Geo_Desc = c.States 
    AND k.Year = c.Year
	-- Focus only on tumor profiling and hereditary cancer risk categories (since we are looking at cancer statistics only)
WHERE k.TEST_Category IN ('Tumor Genomic Profiling', 'Hereditary Cancer Risk');
GO