#средний чек за период с 01.06.2015 по 01.06.2016, средняя сумма покупок за месяц, количество всех операций по клиенту за период;

SELECT t.ID_client, COUNT(t.Id_check) AS total_operations, SUM(t.Sum_payment) / COUNT(t.Id_check) AS avg_receipt,
SUM(t.Sum_payment) / 12 AS avg_monthly_purchase
FROM TRANSACTIONS t
JOIN (
    SELECT ID_client FROM TRANSACTIONS
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY ID_client
    HAVING COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m-01')) = 12
    ) active_clients ON t.ID_client = active_clients.ID_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY t.ID_client;

#средняя сумма чека в месяц;
SELECT DATE_FORMAT(date_new, '%Y-%m') AS month, AVG(Sum_payment) AS avg_receipt
FROM TRANSACTIONS
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY month;

#среднее количество операций в месяц;
SELECT DATE_FORMAT(date_new, '%Y-%m') AS month, COUNT(Id_check) / COUNT(DISTINCT ID_client) AS avg_operations_per_client
FROM TRANSACTIONS
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY month;

#среднее количество клиентов, которые совершали операции;
SELECT COUNT(DISTINCT ID_client) AS avg_clients_per_month
FROM TRANSACTIONS;

#долю от общего количества операций за год и долю в месяц от общей суммы операций;
WITH total_operations AS (SELECT COUNT(Id_check) AS year_operations
    FROM TRANSACTIONS
    WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
)
SELECT DATE_FORMAT(date_new, '%Y-%m') AS month,COUNT(Id_check) AS monthly_operations,
    (COUNT(Id_check) / (SELECT year_operations FROM total_operations)) * 100 AS operations_share
FROM TRANSACTIONS
WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY month;

WITH total_sum AS (SELECT SUM(Sum_payment) AS year_sum
    FROM TRANSACTIONS
    WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
)
SELECT DATE_FORMAT(date_new, '%Y-%m') AS month,SUM(Sum_payment) AS monthly_sum,
    (SUM(Sum_payment) / (SELECT year_sum FROM total_sum)) * 100 AS sum_share
FROM TRANSACTIONS
WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY month;

#вывести % соотношение M/F/NA в каждом месяце с их долей затрат;
SELECT DATE_FORMAT(t.date_new, '%Y-%m') AS month,
-- % клиентов по полу (M/F/NA) в каждом месяце
    COUNT(DISTINCT CASE WHEN c.Gender = 'M' THEN t.ID_client END) / COUNT(DISTINCT t.ID_client) * 100 AS male_client_pct,
    COUNT(DISTINCT CASE WHEN c.Gender = 'F' THEN t.ID_client END) / COUNT(DISTINCT t.ID_client) * 100 AS female_client_pct,
    COUNT(DISTINCT CASE WHEN c.Gender IS NULL OR c.Gender NOT IN ('M', 'F') THEN t.ID_client END) / COUNT(DISTINCT t.ID_client) * 100 AS na_client_pct,

    -- Долю затрат каждого пола в общем объеме затрат за месяц
    SUM(CASE WHEN c.Gender = 'M' THEN t.Sum_payment ELSE 0 END) / SUM(t.Sum_payment) * 100 AS male_spend_pct,
    SUM(CASE WHEN c.Gender = 'F' THEN t.Sum_payment ELSE 0 END) / SUM(t.Sum_payment) * 100 AS female_spend_pct,
    SUM(CASE WHEN c.Gender IS NULL OR c.Gender NOT IN ('M', 'F') THEN t.Sum_payment ELSE 0 END) / SUM(t.Sum_payment) * 100 AS na_spend_pct

FROM TRANSACTIONS t
LEFT JOIN Customers c ON t.ID_client = c.ID_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY month
ORDER BY month;

#возрастные группы клиентов с шагом 10 лет и отдельно клиентов, у которых нет данной информации,
# с параметрами сумма и количество операций за весь период, и поквартально - средние показатели и %.


SELECT 
    DATE_FORMAT(t.date_new, '%Y-Q%q') AS quarter,
    CASE 
        WHEN c.Age BETWEEN 10 AND 19 THEN '10-19'
        WHEN c.Age BETWEEN 20 AND 29 THEN '20-29'
        WHEN c.Age BETWEEN 30 AND 39 THEN '30-39'
        WHEN c.Age BETWEEN 40 AND 49 THEN '40-49'
        WHEN c.Age BETWEEN 50 AND 59 THEN '50-59'
        WHEN c.Age BETWEEN 60 AND 69 THEN '60-69'
        WHEN c.Age >= 70 THEN '70+'
        ELSE 'Unknown'
    END AS age_group,

    SUM(t.Sum_payment) AS total_sum, COUNT(t.ID_client) AS total_operations, AVG(t.Sum_payment) AS avg_sum,
    COUNT(t.ID_client) / COUNT(DISTINCT DATE_FORMAT(t.date_new, '%Y-Q%q')) AS avg_operations_per_quarter
FROM TRANSACTIONS t
LEFT JOIN Customers c ON t.ID_client = c.ID_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY quarter, age_group
ORDER BY quarter, age_group;
