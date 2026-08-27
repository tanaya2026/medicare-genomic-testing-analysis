USE MedicareGenomicAnalysis;
GO

-- Calculates state-level Z-scores to spot statistical outliers (|Z| > 2)
-- across utilization rates, total spending, and average cost per service.

WITH StateYear AS (
    SELECT
        k.Rndrng_Prvdr_Geo_Desc, k.Year,
        SUM(k.Total_Services) AS Total_Services,
        SUM(k.Total_Spend) AS Total_Spend,
		-- Protect against division by zero if services are missing
        SUM(k.Total_Spend) / NULLIF(SUM(k.Total_Services),0) AS Cost_Per_Service,
        e.TOT_BENES AS Total_Beneficiaries,
		-- Normalize testing volume per 100k Medicare beneficiaries
        (CAST(SUM(k.Total_Services) AS FLOAT) / NULLIF(e.TOT_BENES,0)) * 100000 AS Services_Per_100k
    FROM vw_GenomicKPIs k
    JOIN cms_enrollment_state_annual_2018_2024 e
        ON k.Rndrng_Prvdr_Geo_Desc = e.BENE_STATE_DESC AND k.Year = e.YEAR
    GROUP BY k.Rndrng_Prvdr_Geo_Desc, k.Year, e.TOT_BENES
),
StateAvg AS (
	-- Average out the yearly metrics per state across the full timeframe
    SELECT
        Rndrng_Prvdr_Geo_Desc,
        AVG(Services_Per_100k) AS Avg_Services_Per_100k,
        SUM(Total_Spend) AS Total_Spend_AllYears,
        AVG(Cost_Per_Service) AS Avg_Cost_Per_Service
    FROM StateYear
    GROUP BY Rndrng_Prvdr_Geo_Desc
),
Zscored AS (
	-- Compute Z-scores using window functions across the national distribution
    SELECT *,
        (Avg_Services_Per_100k - AVG(Avg_Services_Per_100k) OVER()) / NULLIF(STDEV(Avg_Services_Per_100k) OVER(),0) AS Z_Utilization,
        (Total_Spend_AllYears - AVG(Total_Spend_AllYears) OVER()) / NULLIF(STDEV(Total_Spend_AllYears) OVER(),0) AS Z_Spend,
        (Avg_Cost_Per_Service - AVG(Avg_Cost_Per_Service) OVER()) / NULLIF(STDEV(Avg_Cost_Per_Service) OVER(),0) AS Z_CostPerService
    FROM StateAvg
)
-- Flag states that sit more than 2 standard deviations away from the mean
SELECT *,
    CASE WHEN ABS(Z_Utilization) > 2 THEN 'Outlier' ELSE 'Normal' END AS Utilization_Flag,
    CASE WHEN ABS(Z_Spend) > 2 THEN 'Outlier' ELSE 'Normal' END AS Spend_Flag,
    CASE WHEN ABS(Z_CostPerService) > 2 THEN 'Outlier' ELSE 'Normal' END AS CostPerService_Flag
FROM Zscored
ORDER BY Z_Utilization DESC;