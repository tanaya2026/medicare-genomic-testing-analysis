USE MedicareGenomicAnalysis;
GO

CREATE OR ALTER VIEW dbo.vw_YearlyCategoryGrowth AS

-- Calculates year-over-year growth percentages for services and spending
-- across each genomic test category using window lag functions.

WITH YearlyCategoryKPIs AS (
    -- Roll up total services and spend by Year and Test Category
    SELECT 
        Year,
        TEST_Category,
        SUM(Total_Services) AS Total_Services,
        SUM(Total_Spend) AS Total_Spend
    FROM dbo.vw_GenomicKPIs
    GROUP BY Year, TEST_Category
),
LaggedData AS (
    -- Using LAG() to look up the previous year's numbers for the same category
    SELECT 
        Year,
        TEST_Category,
        Total_Services,
        LAG(Total_Services, 1) OVER (PARTITION BY TEST_Category ORDER BY Year) AS Prev_Year_Services,
        Total_Spend,
        LAG(Total_Spend, 1) OVER (PARTITION BY TEST_Category ORDER BY Year) AS Prev_Year_Spend
    FROM YearlyCategoryKPIs
)
-- Calculate the percentage change
SELECT 
    Year,
    TEST_Category,
    Total_Services,
    Prev_Year_Services,
    CASE 
        WHEN Prev_Year_Services >= 50 THEN ROUND(((CAST(Total_Services AS FLOAT) - Prev_Year_Services) / Prev_Year_Services) * 100, 2)
        ELSE NULL 
    END AS Services_YoY_Growth_Pct,
    Total_Spend,
    CASE 
        WHEN Prev_Year_Spend >= 100000 THEN ROUND(((CAST(Total_Spend AS FLOAT) - Prev_Year_Spend) / Prev_Year_Spend) * 100, 2)
        ELSE NULL 
    END AS Spend_YoY_Growth_Pct
FROM LaggedData;
GO
