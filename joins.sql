--1 inner join
SELECT DISTINCT p.ticker, mc.quarter_end, mc.market_cap
FROM prices p
INNER JOIN market_cap mc ON p.ticker = mc.ticker
WHERE p.date BETWEEN '2019-10-01' AND '2019-12-31'
  AND mc.quarter_end = '2019-12-31';

--2 left join
SELECT p.ticker, 
       COUNT(DISTINCT p.date) as trading_days,
       mc.quarter_end,
       mc.market_cap
FROM prices p
LEFT JOIN market_cap mc ON p.ticker = mc.ticker 
                        AND EXTRACT(YEAR FROM mc.quarter_end) = 2020
WHERE EXTRACT(YEAR FROM p.date) = 2020
GROUP BY p.ticker, mc.quarter_end, mc.market_cap
ORDER BY p.ticker;

--3 right join
SELECT mc.ticker, 
       mc.quarter_end, 
       mc.market_cap,
       COUNT(p.date) as price_records_count
FROM prices p
RIGHT JOIN market_cap mc ON p.ticker = mc.ticker
GROUP BY mc.ticker, mc.quarter_end, mc.market_cap
ORDER BY mc.quarter_end, mc.ticker;

--4 anti join
SELECT DISTINCT p.ticker
FROM prices p
LEFT JOIN market_cap mc ON p.ticker = mc.ticker
WHERE mc.ticker IS NULL;
-----
SELECT DISTINCT p.ticker
FROM prices p
WHERE NOT EXISTS (
    SELECT 1 FROM market_cap mc 
    WHERE mc.ticker = p.ticker
);

--5 semi join
-- Using EXISTS
SELECT DISTINCT p.ticker
FROM prices p
WHERE EXISTS (
    SELECT 1 FROM market_cap mc 
    WHERE mc.ticker = p.ticker
);

--- Using IN
SELECT DISTINCT p.ticker
FROM prices p
WHERE p.ticker IN (SELECT ticker FROM market_cap);

--self join 
-- Compare Q1 vs Q4 average closing prices for each ticker
SELECT p1.ticker,
       AVG(p1.close) as q1_avg_close,
       AVG(p2.close) as q4_avg_close,
       (AVG(p2.close) - AVG(p1.close)) / AVG(p1.close) * 100 as pct_change
FROM prices p1
INNER JOIN prices p2 ON p1.ticker = p2.ticker
WHERE EXTRACT(QUARTER FROM p1.date) = 1 
  AND EXTRACT(QUARTER FROM p2.date) = 4
  AND EXTRACT(YEAR FROM p1.date) = EXTRACT(YEAR FROM p2.date)
  AND EXTRACT(YEAR FROM p1.date) = 2019
GROUP BY p1.ticker
HAVING COUNT(p1.date) > 10 AND COUNT(p2.date) > 10
ORDER BY pct_change DESC;

--mix
WITH quarterly_prices AS (
    SELECT ticker,
           EXTRACT(YEAR FROM date) as year,
           EXTRACT(QUARTER FROM date) as quarter,
           AVG(close) as avg_close,
           COUNT(*) as trading_days
    FROM prices
    WHERE EXTRACT(YEAR FROM date) BETWEEN 2018 AND 2020
    GROUP BY ticker, EXTRACT(YEAR FROM date), EXTRACT(QUARTER FROM date)
)
SELECT qp.ticker,
       qp.year,
       qp.quarter,
       qp.avg_close,
       qp.trading_days,
       mc.market_cap,
       CASE 
           WHEN mc.market_cap IS NULL THEN 'Missing Market Cap'
           WHEN qp.trading_days < 30 THEN 'Insufficient Trading Data'
           ELSE 'Complete'
       END as data_quality
FROM quarterly_prices qp
LEFT JOIN market_cap mc ON qp.ticker = mc.ticker 
                        AND qp.year = EXTRACT(YEAR FROM mc.quarter_end)
                        AND qp.quarter = EXTRACT(QUARTER FROM mc.quarter_end)
ORDER BY qp.ticker, qp.year, qp.quarter;