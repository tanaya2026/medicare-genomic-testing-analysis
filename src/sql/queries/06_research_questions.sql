USE MedicareGenomicAnalysis;
GO

-- Answer Research Questions for our project by querying existing views.

-- Utilization #1
SELECT 
    SUM(Total_Services) AS Total_Services_All_Years,
    SUM(Total_Beneficiaries) AS Total_Beneficiaries_All_Years,
    SUM(Total_Spend) AS Total_Spend_All_Years
FROM vw_GenomicKPIs;

-- Utilization #2
SELECT 
    Year,
    SUM(Total_Services) AS Total_Services,
    SUM(Total_Spend) AS Total_Spend
FROM vw_GenomicKPIs
GROUP BY Year
ORDER BY Year;

WITH Yearly AS (
    SELECT Year, SUM(Total_Services) AS Total_Services
    FROM vw_GenomicKPIs
    GROUP BY Year
)
SELECT 
    Year,
    Total_Services,
    LAG(Total_Services) OVER (ORDER BY Year) AS Prev_Year,
    ROUND(
        (CAST(Total_Services AS FLOAT) - LAG(Total_Services) OVER (ORDER BY Year))
        / LAG(Total_Services) OVER (ORDER BY Year) * 100, 1
    ) AS YoY_Pct_Change
FROM Yearly
ORDER BY Year;

-- Utilization #3
SELECT TOP 10
    Year, TEST_Category, Total_Services, Prev_Year_Services, Services_YoY_Growth_Pct
FROM vw_YearlyCategoryGrowth
WHERE Services_YoY_Growth_Pct IS NOT NULL
ORDER BY Services_YoY_Growth_Pct DESC;

--Geographic #4
SELECT TOP 5
    Rndrng_Prvdr_Geo_Desc AS State,
    SUM(Total_Services) AS Total_Services
FROM vw_GenomicKPIs
GROUP BY Rndrng_Prvdr_Geo_Desc
ORDER BY Total_Services DESC;

SELECT TOP 5
    Rndrng_Prvdr_Geo_Desc AS State,
    SUM(Total_Services) AS Total_Services
FROM vw_GenomicKPIs
GROUP BY Rndrng_Prvdr_Geo_Desc
ORDER BY Total_Services ASC;


--Geographic #5
SELECT TOP 5
    Rndrng_Prvdr_Geo_Desc,
    AVG(Services_Per_100k) AS Avg_Services_Per_100k
FROM vw_StateUtilizationPer100k 
GROUP BY Rndrng_Prvdr_Geo_Desc
ORDER BY Avg_Services_Per_100k DESC;

SELECT TOP 5
    Rndrng_Prvdr_Geo_Desc,
    AVG(Services_Per_100k) AS Avg_Services_Per_100k
FROM vw_StateUtilizationPer100k
GROUP BY Rndrng_Prvdr_Geo_Desc
ORDER BY Avg_Services_Per_100k ASC;

--Geographic #6
SELECT TOP 10
    State,
    Test_Category,
    Location_Quotient
FROM vw_GenomicTestLocationQuotient
WHERE Location_Quotient IS NOT NULL
ORDER BY Location_Quotient DESC;

--Financial #9a.
SELECT 
    TEST_Category,
    SUM(Total_Spend) AS Total_Spend
FROM vw_GenomicKPIs
GROUP BY TEST_Category
ORDER BY Total_Spend DESC;

--Financial #9b.
SELECT TOP 5 Rndrng_Prvdr_Geo_Desc AS State, SUM(Total_Spend) AS Total_Spend
FROM vw_GenomicKPIs
GROUP BY Rndrng_Prvdr_Geo_Desc
ORDER BY Total_Spend DESC;

SELECT TOP 5 Rndrng_Prvdr_Geo_Desc AS State, SUM(Total_Spend) AS Total_Spend
FROM vw_GenomicKPIs
GROUP BY Rndrng_Prvdr_Geo_Desc
ORDER BY Total_Spend ASC;

--Financial #10
WITH Yearly AS (
    SELECT Year, SUM(Total_Services) AS Total_Services, SUM(Total_Spend) AS Total_Spend
    FROM vw_GenomicKPIs
    GROUP BY Year
)
SELECT 
    Year,
    ROUND((CAST(Total_Services AS FLOAT) - LAG(Total_Services) OVER (ORDER BY Year)) / LAG(Total_Services) OVER (ORDER BY Year) * 100, 1) AS Services_YoY_Pct,
    ROUND((CAST(Total_Spend AS FLOAT) - LAG(Total_Spend) OVER (ORDER BY Year)) / LAG(Total_Spend) OVER (ORDER BY Year) * 100, 1) AS Spend_YoY_Pct
FROM Yearly
ORDER BY Year;

-- Business Analytics #13.
SELECT Rndrng_Prvdr_Geo_Desc,
       Utilization_Flag, Z_Utilization,
       Spend_Flag, Z_Spend,
       CostPerService_Flag, Z_CostPerService
FROM vw_StateGenomicZScoreOutliers
WHERE Utilization_Flag = 'Outlier' 
   OR Spend_Flag = 'Outlier' 
   OR CostPerService_Flag = 'Outlier'
ORDER BY Rndrng_Prvdr_Geo_Desc;