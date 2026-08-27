USE MedicareGenomicAnalysis;
GO

-- Creates the main KPI view by summarizing the raw combined Medicare data 
-- down to the year, state, and test category level.
CREATE OR ALTER VIEW dbo.vw_GenomicKPIs AS
SELECT 
    Year,
    Rndrng_Prvdr_Geo_Desc,
    TEST_Category,

    -- Core totals
    SUM(Tot_Srvcs) AS Total_Services,
    SUM(Tot_Benes) AS Total_Beneficiaries,
    SUM(Avg_Mdcr_Pymt_Amt * Tot_Srvcs) AS Total_Spend,
    
    -- Calculate cost per service, avoiding divide-by-zero errors
    CASE 
        WHEN SUM(Tot_Srvcs) > 0 THEN SUM(Avg_Mdcr_Pymt_Amt * Tot_Srvcs) / SUM(Tot_Srvcs)
        ELSE 0 
    END AS Cost_Per_Service
FROM dbo.cms_2018_2024_combined
GROUP BY 
    Year,
    Rndrng_Prvdr_Geo_Desc,
    TEST_Category;
GO