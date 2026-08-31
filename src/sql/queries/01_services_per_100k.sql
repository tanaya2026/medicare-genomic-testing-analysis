USE MedicareGenomicAnalysis;
GO

CREATE OR ALTER VIEW dbo.vw_StateUtilizationPer100k AS

-- Calculates the utilization rate per 100,000 Medicare beneficiaries
-- by combining the genomic KPI view with annual state enrollment data.

SELECT 
    k.Year,
    k.Rndrng_Prvdr_Geo_Desc,
    k.TEST_Category,
    k.Total_Services,
    k.Total_Spend,
    e.TOT_BENES AS State_Medicare_Population, -- Pulls total beneficiaries from enrollment table
    -- Services per 100k beneficiaries calculation:
    CASE 
        WHEN e.TOT_BENES > 0 THEN (CAST(k.Total_Services AS FLOAT) / e.TOT_BENES) * 100000
        ELSE 0 
    END AS Services_Per_100k
FROM dbo.vw_GenomicKPIs k
LEFT JOIN dbo.cms_enrollment_state_annual_2018_2024 e 
    ON k.Rndrng_Prvdr_Geo_Desc = e.BENE_STATE_DESC
    AND k.Year = e.YEAR;
GO