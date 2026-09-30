-- =========================================================
-- Zwischenprojekt: Umsatz einer Pizzeria (Pizza Place Sales, 2015)
-- Tool: SQLite Online · Author: Sergii Vdovenkov
-- Language: code & comments in English, results (FAZIT) in German
-- Conventions:
--   JOIN ... USING (key)  when the key has the same name in both tables
--   CAST(price AS REAL), CAST(quantity AS INTEGER) in every formula (safeguard, required by the task)
--   strftime('%m'|'%w'|'%H', ...) for dates (SQLite has no EXTRACT)
--   orders = COUNT(DISTINCT order_id), pizzas = SUM(quantity)
-- =========================================================


-- =========================================================
-- Step 0: Data check
-- =========================================================

-- 0.1 Row count per table
SELECT COUNT(*) AS row_count FROM orders;         -- 21350
SELECT COUNT(*) AS row_count FROM order_details;  -- 48620
SELECT COUNT(*) AS row_count FROM pizzas;         -- 96
SELECT COUNT(*) AS row_count FROM pizza_types;    -- 32

-- 0.2 Missing values per column (NULL or empty string)
SELECT
  SUM(CASE WHEN order_id IS NULL OR order_id = '' THEN 1 ELSE 0 END) AS order_id_missing,
  SUM(CASE WHEN date     IS NULL OR date     = '' THEN 1 ELSE 0 END) AS date_missing,
  SUM(CASE WHEN time     IS NULL OR time     = '' THEN 1 ELSE 0 END) AS time_missing
FROM orders;                                      -- 0 | 0 | 0

SELECT
  SUM(CASE WHEN order_details_id IS NULL OR order_details_id = '' THEN 1 ELSE 0 END) AS order_details_id_missing,
  SUM(CASE WHEN order_id IS NULL OR order_id = '' THEN 1 ELSE 0 END) AS order_id_missing,
  SUM(CASE WHEN pizza_id IS NULL OR pizza_id = '' THEN 1 ELSE 0 END) AS pizza_id_missing,
  SUM(CASE WHEN quantity IS NULL OR quantity = '' THEN 1 ELSE 0 END) AS quantity_missing
FROM order_details;                               -- 0 | 0 | 0 | 0

SELECT
  SUM(CASE WHEN pizza_id      IS NULL OR pizza_id      = '' THEN 1 ELSE 0 END) AS pizza_id_missing,
  SUM(CASE WHEN pizza_type_id IS NULL OR pizza_type_id = '' THEN 1 ELSE 0 END) AS pizza_type_id_missing,
  SUM(CASE WHEN size          IS NULL OR size          = '' THEN 1 ELSE 0 END) AS size_missing,
  SUM(CASE WHEN price         IS NULL OR price         = '' THEN 1 ELSE 0 END) AS price_missing
FROM pizzas;                                      -- 0 | 0 | 0 | 0

SELECT
  SUM(CASE WHEN pizza_type_id IS NULL OR pizza_type_id = '' THEN 1 ELSE 0 END) AS pizza_type_id_missing,
  SUM(CASE WHEN name          IS NULL OR name          = '' THEN 1 ELSE 0 END) AS name_missing,
  SUM(CASE WHEN category      IS NULL OR category      = '' THEN 1 ELSE 0 END) AS category_missing,
  SUM(CASE WHEN ingredients   IS NULL OR ingredients   = '' THEN 1 ELSE 0 END) AS ingredients_missing
FROM pizza_types;                                 -- 0 | 0 | 0 | 0


-- 0.3 Column types after import (typeof shows the real type of the value)
SELECT
  typeof(pizza_id)      AS pizza_id_type,
  typeof(pizza_type_id) AS pizza_type_id_type,
  typeof(size)          AS size_type,
  typeof(price)         AS price_type
FROM pizzas
LIMIT 1;                                          -- text | text | text | real

SELECT typeof(quantity) AS quantity_type
FROM order_details
LIMIT 1;                                          -- integer
-- price and quantity are already numeric - CAST in formulas is a safeguard (required by the task)

-- =========================================================
-- Q1: Annual KPIs 2015
-- Revenue, orders, pizzas sold, avg order value, avg pizzas per order
-- =========================================================

-- Step 1: base figures from one JOIN (price in pizzas, quantity in order_details)
WITH base AS (
  SELECT
    -- revenue = price × quantity per line, then summed
    SUM(CAST(p.price AS REAL) * CAST(od.quantity AS INTEGER)) AS total_revenue,

    -- DISTINCT: one order has several lines
    COUNT(DISTINCT od.order_id)                               AS total_orders,

    -- pizzas = SUM(quantity), not COUNT(*): one line can hold 2–4 pizzas
    SUM(CAST(od.quantity AS INTEGER))                         AS pizzas_sold
  FROM order_details od
  JOIN pizzas p USING (pizza_id)   -- same column name in both tables
)

-- Step 2: averages derived from base figures
SELECT
  ROUND(total_revenue, 2)                            AS total_revenue,
  total_orders,
  pizzas_sold,
  -- avg order value = revenue / orders (not AVG over lines)
  ROUND(total_revenue / total_orders, 2)             AS avg_order_value,
  -- CAST to REAL: integer / integer would drop decimals (2 instead of 2.32)
  ROUND(CAST(pizzas_sold AS REAL) / total_orders, 2) AS avg_pizzas_per_order
FROM base;

-- Result:
-- total_revenue 817860.05 | total_orders 21350 | pizzas_sold 49574
-- avg_order_value 38.31   | avg_pizzas_per_order 2.32


-- >>> FAZIT (was die Daten zeigen und was daraus folgt):
-- • 2015: Umsatz 817.860 $ (total_revenue), 21.350 Bestellungen (total_orders),
--   49.574 Pizzen (pizzas_sold).
-- • Ø Bestellwert 38,31 $ (817.860 / 21.350), Ø 2,32 Pizzen pro Bestellung
--   (49.574 / 21.350) — typisch ist eine Bestellung für 2–3 Personen.
-- • Was folgt: Diese 5 Kennzahlen sind die Ausgangsbasis. Jede Änderung an
--   Speisekarte, Schichtplan oder Aktion wird daran gemessen
--   (z. B. steigt der Ø Bestellwert über 38,31 $?).

-- Tableau tile:
-- DE: «818 Tsd. $ Umsatz aus 21.350 Bestellungen — Ø 38,31 $ pro Bestellung»


-- =========================================================
-- Q2: Development by months (revenue, orders, change vs previous month)
-- =========================================================

-- Step 1: CTE monthly = 12 rows (one per month)
WITH monthly AS (
  SELECT
    -- month number as text: 03 from 2015-03-14
    strftime('%m', o.date)                                              AS month,
    -- revenue = price x quantity per line, then summed per month
    ROUND(SUM(CAST(p.price AS REAL) * CAST(od.quantity AS INTEGER)), 2) AS revenue,
    -- DISTINCT: one order has several lines
    COUNT(DISTINCT o.order_id)                                          AS orders
  FROM orders o
  JOIN order_details od USING (order_id)
  JOIN pizzas p         USING (pizza_id)
  GROUP BY month
)

-- Step 2: window function LAG puts previous month next to the current one
SELECT
  month,
  revenue,
  orders,
  -- (current - previous) / previous * 100
  -- OVER (ORDER BY month): "previous" = the row of the previous month
  -- January has no previous month, so NULL
  ROUND((revenue - LAG(revenue) OVER (ORDER BY month))
        / LAG(revenue) OVER (ORDER BY month) * 100, 1) AS pct_vs_prev_month
FROM monthly
ORDER BY month;

-- Result (month | revenue | orders | pct_vs_prev_month):
-- 01 | 69793.30 | 1845 | NULL     07 | 72557.90 | 1935 |  6.3
-- 02 | 65159.60 | 1685 | -6.6     08 | 68278.25 | 1841 | -5.9
-- 03 | 70397.10 | 1840 |  8.0     09 | 64180.05 | 1661 | -6.0
-- 04 | 68736.80 | 1799 | -2.4     10 | 64027.60 | 1646 | -0.2
-- 05 | 71402.75 | 1853 |  3.9     11 | 70395.35 | 1792 |  9.9
-- 06 | 68230.20 | 1773 | -4.4     12 | 64701.15 | 1680 | -8.1


-- >>> FAZIT (was die Daten zeigen):
-- • Stärkster Monat: Juli mit 72.557,90 $ (revenue) und 1.935 Bestellungen (orders).
-- • Schwächster Monat: Oktober mit 64.027,60 $ (revenue) und 1.646 Bestellungen (orders).
-- • Abstand 8.530,30 $ (72.557,90 - 64.027,60), das sind 13,3 % vom Oktober (8.530,30 / 64.027,60).
-- • Größter Anstieg zum Vormonat: November +9,9 %, größter Rückgang: Dezember -8,1 % (pct_vs_prev_month).
-- • Kein klarer Jahrestrend: 4 Monate mit Anstieg, 7 mit Rückgang, Dezember 7,3 % unter Januar (64.701,15 / 69.793,30 - 1).
-- • Nächste Schritte: Anzahl der Tage mit Bestellungen pro Monat prüfen (COUNT(DISTINCT date)) - das könnte den schwachen Oktober erklären.


-- Tableau tile:
-- DE: «Juli am stärksten (72.558 $), Oktober am schwächsten (64.028 $)»


-- =========================================================
-- Q3: Load by weekday and hour (peak and quiet times)
-- Only table orders: date, time, order_id are all there - no JOIN needed
-- =========================================================

-- Q3a: average orders per one weekday
SELECT
  -- strftime('%w') returns text '0'..'6', 0 = Sunday in SQLite
  CASE strftime('%w', date)
    WHEN '1' THEN 'Monday'
    WHEN '2' THEN 'Tuesday'
    WHEN '3' THEN 'Wednesday'
    WHEN '4' THEN 'Thursday'
    WHEN '5' THEN 'Friday'
    WHEN '6' THEN 'Saturday'
    WHEN '0' THEN 'Sunday'
  END                                                      AS weekday,
  -- one row in orders = one order, so COUNT(*) is correct here
  COUNT(*)                                                 AS orders,
  -- number of such days in the year (48 Mondays vs 52 Tuesdays)
  COUNT(DISTINCT date)                                     AS days,
  -- integer / integer needs CAST
  ROUND(CAST(COUNT(*) AS REAL) / COUNT(DISTINCT date), 1)  AS avg_orders_per_day
FROM orders
GROUP BY weekday
ORDER BY avg_orders_per_day DESC;

-- Result (weekday | orders | days | avg_orders_per_day):
-- Friday 3538 | 50 | 70.8     Saturday 3158 | 52 | 60.7    Tuesday 2973 | 52 | 57.2
-- Thursday 3239 | 52 | 62.3   Wednesday 3024 | 52 | 58.2   Monday 2794 | 48 | 58.2
-- Sunday 2624 | 52 | 50.5

-- Q3b: orders per hour
SELECT
  -- hour as text '09'..'23'
  strftime('%H', time)                                     AS hour,
  COUNT(*)                                                 AS orders,
  -- every hour shares the same base of 358 days, so one common divisor
  ROUND(CAST(COUNT(*) AS REAL) / (SELECT COUNT(DISTINCT date) FROM orders), 1) AS avg_orders_per_day
FROM orders
GROUP BY hour
ORDER BY hour;

-- Result (hour | orders | avg_orders_per_day):
-- 09 | 1 | 0.0     12 | 2520 | 7.0   15 | 1468 | 4.1   18 | 2399 | 6.7   21 | 1198 | 3.3
-- 10 | 8 | 0.0     13 | 2455 | 6.9   16 | 1920 | 5.4   19 | 2009 | 5.6   22 |  663 | 1.9
-- 11 | 1231 | 3.4  14 | 1472 | 4.1   17 | 2336 | 6.5   20 | 1642 | 4.6   23 |   28 | 0.1


-- >>> FAZIT (was die Daten zeigen):
-- • Stärkster Tag: Freitag mit 70,8 Bestellungen pro Tag (avg_orders_per_day, 3.538 / 50).
-- • Ruhigster Tag: Sonntag mit 50,5 pro Tag (2.624 / 52), 29 % weniger als Freitag (50,5 / 70,8 - 1).
-- • Dienstag, Mittwoch und Montag liegen gleichauf bei 57-58 Bestellungen pro Tag.
-- • Zwei Stoßzeiten: Mittag 12-13 Uhr (2.520 und 2.455 Bestellungen, orders, 7,0 und 6,9 pro Tag) und Abend 17-18 Uhr (2.336 und 2.399).
-- • Ruhige Phase zwischen den Spitzen: 14-15 Uhr, 4,1 Bestellungen pro Tag.
-- • Fast leer: 9, 10 und 23 Uhr - 1, 8 und 28 Bestellungen im ganzen Jahr (orders).


-- Tableau tile:
-- DE: «Stoßzeiten: Freitag, 12-13 und 17-18 Uhr - ruhig: Sonntag, 14-15 Uhr»


-- =========================================================
-- Q4: Bestsellers and slow sellers (top 5 / last 5 by revenue and by quantity)
-- Level = pizza TYPE (all sizes together): group by pt.name (32), not pizza_id (96)
-- =========================================================

SELECT
  pt.name                                                              AS pizza_name,
  -- revenue per line (each size has its own price), then summed per type
  ROUND(SUM(CAST(p.price AS REAL) * CAST(od.quantity AS INTEGER)), 2)  AS revenue,
  SUM(CAST(od.quantity AS INTEGER))                                    AS qty_sold
FROM order_details od
JOIN pizzas p       USING (pizza_id)        -- price, pizza_type_id
JOIN pizza_types pt USING (pizza_type_id)   -- pizza name
GROUP BY pt.name
-- run 4 times, changing only the last line
--   ORDER BY revenue  DESC LIMIT 5   -> top 5 by revenue
--   ORDER BY revenue  ASC  LIMIT 5   -> last 5 by revenue
--   ORDER BY qty_sold DESC LIMIT 5   -> top 5 by quantity
--   ORDER BY qty_sold ASC  LIMIT 5   -> last 5 by quantity
ORDER BY revenue DESC
LIMIT 5;

-- Result (pizza_name | revenue | qty_sold):
-- Top 5 revenue:  Thai Chicken 43434.25 | 2371 · Barbecue Chicken 42768.00 | 2432 · California Chicken 41409.50 | 2370
--                 Classic Deluxe 38180.50 | 2453 · Spicy Italian 34831.25 | 1924
-- Last 5 revenue: Brie Carre 11588.50 | 490 · Green Garden 13955.75 | 997 · Spinach Supreme 15277.75 | 950
--                 Mediterranean 15360.50 | 934 · Spinach Pesto 15596.00 | 970
-- Top 5 qty:      Classic Deluxe 2453 · Barbecue Chicken 2432 · Hawaiian 2422 (32273.25) · Pepperoni 2418 (30161.75) · Thai Chicken 2371
-- Last 5 qty:     Brie Carre 490 · Mediterranean 934 · Calabrese 937 (15934.25) · Spinach Supreme 950 · Soppressata 961 (16425.75)


-- >>> FAZIT (was die Daten zeigen):
-- • Umsatzstärkste Sorte: Thai Chicken mit 43.434,25 $ (revenue); meistverkaufte: Classic Deluxe mit 2.453 Stück (qty_sold).
-- • Die Top-5-Listen stimmen zu 3 von 5 überein: Thai Chicken, Barbecue Chicken, Classic Deluxe.
--   Nur nach Umsatz vorn: California Chicken und Spicy Italian, nur nach Menge: Hawaiian und Pepperoni -
--   viel verkauft (2.422 und 2.418 Stück), aber weniger Umsatz (32.273,25 und 30.161,75 $).
-- • Auch die letzten 5 stimmen zu 3 von 5 überein: Brie Carre, Mediterranean, Spinach Supreme.
-- • Brie Carre ist in beiden Listen Letzter: 11.588,50 $ und 490 Stück, 5-mal weniger als der Mengen-Spitzenreiter (2.453 / 490).
-- • Nächste Schritte: in Q6 die Ladenhüter nach Umsatzanteil prüfen und die Größen von Brie Carre ansehen (nur S).


-- Tableau tile:
-- DE: «Top: Thai Chicken (43.434 $) - Schlusslicht: Brie Carre (11.589 $, 490 Stück)»


-- =========================================================
-- Q5: Categories and sizes (revenue share, best-selling sizes)
-- Share = revenue of the group / total revenue * 100
-- =========================================================

-- Q5a: revenue share per category (share via scalar subquery)
SELECT
  pt.category                                                          AS category,
  ROUND(SUM(CAST(p.price AS REAL) * CAST(od.quantity AS INTEGER)), 2)  AS revenue,
  ROUND(
    -- numerator: revenue of this category (per GROUP BY)
    SUM(CAST(p.price AS REAL) * CAST(od.quantity AS INTEGER)) * 100.0
    -- denominator: subquery = total revenue, one number for all rows
    / (SELECT SUM(CAST(p2.price AS REAL) * CAST(od2.quantity AS INTEGER))
       FROM order_details od2
       JOIN pizzas p2 USING (pizza_id))
  , 1)                                                                 AS revenue_share_pct
FROM order_details od
JOIN pizzas p       USING (pizza_id)
JOIN pizza_types pt USING (pizza_type_id)   -- category is in pizza_types
GROUP BY pt.category
ORDER BY revenue DESC;

-- Result (category | revenue | revenue_share_pct):
-- Classic 220053.10 | 26.9 · Supreme 208197.00 | 25.5 · Chicken 195919.50 | 24.0 · Veggie 193690.45 | 23.7

-- Q5b: revenue share and quantity per size (size is in pizzas - no pizza_types needed)
SELECT
  p.size                                                               AS size,
  ROUND(SUM(CAST(p.price AS REAL) * CAST(od.quantity AS INTEGER)), 2)  AS revenue,
  SUM(CAST(od.quantity AS INTEGER))                                    AS qty_sold,
  ROUND(
    SUM(CAST(p.price AS REAL) * CAST(od.quantity AS INTEGER)) * 100.0
    / (SELECT SUM(CAST(p2.price AS REAL) * CAST(od2.quantity AS INTEGER))
       FROM order_details od2
       JOIN pizzas p2 USING (pizza_id))
  , 1)                                                                 AS revenue_share_pct
FROM order_details od
JOIN pizzas p USING (pizza_id)
GROUP BY p.size
ORDER BY revenue DESC;

-- Q5b (★ alternative): the same share via window function SUM() OVER ()
WITH by_size AS (
  SELECT
    p.size                                                    AS size,
    SUM(CAST(p.price AS REAL) * CAST(od.quantity AS INTEGER)) AS revenue,
    SUM(CAST(od.quantity AS INTEGER))                         AS qty_sold
  FROM order_details od
  JOIN pizzas p USING (pizza_id)
  GROUP BY p.size
)
SELECT
  size,
  ROUND(revenue, 2)                                AS revenue,
  qty_sold,
  -- OVER () = window over all 5 rows: total revenue next to each row
  ROUND(revenue * 100.0 / SUM(revenue) OVER (), 1) AS revenue_share_pct
FROM by_size
ORDER BY revenue DESC;

-- Result (size | revenue | qty_sold | revenue_share_pct):
-- L 375318.70 | 18956 | 45.9 · M 249382.25 | 15635 | 30.5 · S 178076.50 | 14403 | 21.8
-- XL 14076.00 | 552 | 1.7 · XXL 1006.60 | 28 | 0.1


-- >>> FAZIT (was die Daten zeigen):
-- • Die Kategorien liegen nah beieinander: von 26,9 % (Classic, 220.053,10 $) bis 23,7 % (Veggie, 193.690,45 $), Abstand 3,2 Prozentpunkte (26,9 - 23,7).
-- • Größe L verkauft sich am besten: 45,9 % des Umsatzes (375.318,70 $) und 18.956 Stück (qty_sold) - auch nach Menge Platz 1.
-- • L und M zusammen: 76,4 % des Umsatzes (45,9 + 30,5).
-- • XL und XXL: nur 1,8 % des Umsatzes (1,7 + 0,1) und 580 Stück (552 + 28).
-- • Nächste Schritte: XL/XXL gibt es nur bei einer Sorte (the_greek) - in Q6 zusammen mit den Streichkandidaten prüfen.


-- Tableau tile:
-- DE: «Größe L bringt 46 % des Umsatzes - Kategorien fast gleich (24-27 %)»


-- =========================================================
-- Q6: Candidates for removal (smallest revenue share and sales)
-- Rule (analyst's choice, stated openly)
--   HAVING share < 2 %                  -> shortlist
--   CASE share < 1.9 % AND qty < 1000   -> 'remove', else 'watch'
-- =========================================================

-- Q6a: shortlist with HAVING + decision with CASE
-- CTE floor 1: revenue, qty and share per pizza type, HAVING keeps only share < 2 %
-- (HAVING filters groups after GROUP BY, WHERE would filter rows before it)
WITH by_type AS (
  SELECT
    pt.name                                   AS pizza_name,
    ROUND(SUM(CAST(p.price AS REAL) * CAST(od.quantity AS INTEGER)), 2)                           AS revenue,
    SUM(CAST(od.quantity AS INTEGER))         AS qty_sold,
    ROUND(SUM(CAST(p.price AS REAL) * CAST(od.quantity AS INTEGER)) * 100.0
          / (SELECT SUM(CAST(p2.price AS REAL) * CAST(od2.quantity AS INTEGER))
           FROM order_details od2
           JOIN pizzas p2 USING (pizza_id)), 2)                         AS revenue_share_pct
  FROM order_details od
  JOIN pizzas p       USING (pizza_id)
  JOIN pizza_types pt USING (pizza_type_id)
  GROUP BY pt.name
  HAVING revenue_share_pct < 2.0
)
SELECT
  pizza_name, revenue, qty_sold, revenue_share_pct,
  CASE
    WHEN revenue_share_pct < 1.9 AND qty_sold < 1000 THEN 'remove'
    ELSE 'watch'
  END AS decision
FROM by_type
ORDER BY revenue;
-- floor 2: CASE reads the ready columns - no repeated formulas

-- Result (pizza_name | revenue | qty_sold | revenue_share_pct | decision):
-- Brie Carre       11588.50 | 490 | 1.42 | remove
-- Green Garden     13955.75 | 997 | 1.71 | remove
-- Spinach Supreme  15277.75 | 950 | 1.87 | remove
-- Mediterranean    15360.50 | 934 | 1.88 | remove
-- Spinach Pesto    15596.00 | 970 | 1.91 | watch
-- Calabrese        15934.25 | 937 | 1.95 | watch
-- Italian Veggie   16019.25 | 981 | 1.96 | watch

-- Q6b (★): cumulative revenue share from the weakest pizza up
-- SUM() OVER (ORDER BY revenue) = running total: each row adds itself to all rows above
WITH by_type AS (
  SELECT
    pt.name                           AS pizza_name,
    SUM(CAST(p.price AS REAL) * CAST(od.quantity AS INTEGER))                             AS revenue,
    SUM(CAST(od.quantity AS INTEGER)) AS qty_sold
  FROM order_details od
  JOIN pizzas p       USING (pizza_id)
  JOIN pizza_types pt USING (pizza_type_id)
  GROUP BY pt.name
)
SELECT
  pizza_name,
  ROUND(revenue, 2)                                                    AS revenue,
  qty_sold,
  ROUND(revenue * 100.0 / SUM(revenue) OVER (), 2)                     AS revenue_share_pct,
  ROUND(SUM(revenue) OVER (ORDER BY revenue), 2)                       AS cum_revenue,
  ROUND(SUM(revenue) OVER (ORDER BY revenue) * 100.0 / SUM(revenue) OVER (), 2) AS cum_share_pct
FROM by_type
ORDER BY revenue
LIMIT 7;

-- Result (pizza_name | revenue | cum_revenue | cum_share_pct):
-- Brie Carre 11588.50 | 11588.50 | 1.42 · Green Garden 13955.75 | 25544.25 | 3.12
-- Spinach Supreme 15277.75 | 40822.00 | 4.99 · Mediterranean 15360.50 | 56182.50 | 6.87
-- Spinach Pesto 15596.00 | 71778.50 | 8.78 · Calabrese 15934.25 | 87712.75 | 10.72
-- Italian Veggie 16019.25 | 103732.00 | 12.68


-- >>> FAZIT (was die Daten zeigen):
-- • 7 Sorten haben weniger als 2 % Umsatzanteil (revenue_share_pct).
-- • 4 davon haben den kleinsten Anteil (< 1,9 %) und weniger als 1.000 verkaufte Stück: Brie Carre, Green Garden, Spinach Supreme, Mediterranean.
-- • Zusammen 56.182,50 $ (cum_revenue), das sind 6,87 % des Umsatzes (cum_share_pct).
-- • Brie Carre ist am schwächsten: 11.588,50 $ (1,42 %) und 490 Stück.
-- • 6,87 % ist die Obergrenze des Verlusts: ein Teil der Gäste bestellt eine andere Sorte.
-- • Nächste Schritte: gemeinsame Zutaten dieser Sorten prüfen (verderbende Zutaten sind der Anlass der Anfrage).


-- Tableau tile:
-- DE: «4 Sorten streichen: nur 6,9 % des Umsatzes betroffen»


-- =========================================================
-- Q7: Large orders (4+ pizzas per order) - share of orders and revenue
-- Key idea: first change the level from LINE to ORDER (CTE), then group orders by size
-- =========================================================

-- floor 1 (CTE order_level): one row = one order, 21 350 rows
-- pizzas_in_order = SUM(quantity) per order - "4 or more pizzas" is about pieces, not lines
-- floor 2: CASE gives each order a label, GROUP BY the label, shares via subquery on the CTE
WITH order_level AS (
  SELECT
    od.order_id,
    SUM(CAST(od.quantity AS INTEGER)) AS pizzas_in_order,
    SUM(CAST(p.price AS REAL) * CAST(od.quantity AS INTEGER)) AS order_revenue
  FROM order_details od
  JOIN pizzas p USING (pizza_id)
  GROUP BY od.order_id
)
SELECT
  CASE
    WHEN pizzas_in_order >= 4 THEN 'large (4+)'
    ELSE 'regular (1-3)'
  END                                          AS order_size,
  COUNT(*)                                     AS orders,
  ROUND(COUNT(*) * 100.0
        / (SELECT COUNT(*) FROM order_level), 1)            AS orders_share_pct,
  ROUND(SUM(order_revenue), 2)                 AS revenue,
  ROUND(SUM(order_revenue) * 100.0
        / (SELECT SUM(order_revenue) FROM order_level), 1)  AS revenue_share_pct,
  ROUND(AVG(order_revenue), 2)                 AS avg_order_value
FROM order_level
GROUP BY order_size;

-- Result (order_size | orders | orders_share_pct | revenue | revenue_share_pct | avg_order_value):
-- large (4+)     |  3880 | 18.2 | 322570.90 | 39.4 | 83.14
-- regular (1-3)  | 17470 | 81.8 | 495289.15 | 60.6 | 28.35


-- >>> FAZIT (was die Daten zeigen):
-- • 3.880 Bestellungen (orders) mit 4+ Pizzen - 18,2 % aller Bestellungen (orders_share_pct).
-- • Sie bringen 322.570,90 $ (revenue) - 39,4 % des Umsatzes (revenue_share_pct).
-- • Ø Bestellwert 83,14 $ gegenüber 28,35 $ bei normalen Bestellungen - 2,9-mal höher (83,14 / 28,35).
-- • Jede 5. Bestellung bringt fast 2 von 5 Umsatz-Dollar.
-- • Nächste Schritte: Wann kommen große Bestellungen (Wochentag, Uhrzeit)? Passt das zur Mittagszeit an Werktagen (Hypothese «Firmen»)?


-- Tableau tile:
-- DE: «18 % der Bestellungen mit 4+ Pizzen bringen 39 % des Umsatzes»


-- =========================================================
-- Q8: Promotion - which weekdays and hours, and what is the potential
-- Combines Q3 (weak hours) and Q5 (best-selling size L)
-- Window from Q3: 14-15 h = dip between lunch peak (7,0 orders/day) and dinner peak, 4,1 orders/day, every day
-- =========================================================

-- WHERE filters ROWS before grouping: only lines of orders placed at 14:00-15:59
WITH window_sales AS (
  SELECT
    SUM(CAST(p.price AS REAL) * CAST(od.quantity AS INTEGER))                      AS revenue,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.date)     AS days
  FROM orders o
  JOIN order_details od USING (order_id)
  JOIN pizzas p         USING (pizza_id)
  WHERE strftime('%H', o.time) IN ('14', '15')
)
SELECT
  ROUND(revenue, 2)                                AS window_revenue,
  orders,
  days,
  ROUND(revenue * 100.0
        / (SELECT SUM(CAST(p2.price AS REAL) * CAST(od2.quantity AS INTEGER))
           FROM order_details od2
           JOIN pizzas p2 USING (pizza_id)), 1)    AS revenue_share_pct,
  ROUND(revenue / days, 2)                         AS revenue_per_day,
  ROUND(revenue * 0.10, 2)                         AS plus_10pct
FROM window_sales;

-- Result (window_revenue | orders | days | revenue_share_pct | revenue_per_day | plus_10pct):
-- 112193.70 | 2940 | 358 | 13.7 | 313.39 | 11219.37

-- Proposed promotion:
-- «Nachmittags-Deal» daily 14:00-16:00: L pizza for the M price (L = 45,9 % of revenue, Q5)


-- >>> FAZIT (was die Daten zeigen):
-- • Zeitfenster 14-15 Uhr im Jahr: 112.193,70 $ (window_revenue), 2.940 Bestellungen (orders), 358 Tage (days).
-- • Das sind 13,7 % des Jahresumsatzes (revenue_share_pct), 313,39 $ pro Tag (revenue_per_day).
-- • +10 % in diesem Fenster = 11.219,37 $ pro Jahr (plus_10pct), ca. 31 $ pro Tag (313,39 × 0,10).
-- • Nächste Schritte: Wirkung per Test prüfen (A/B oder vorher/nachher, 4-6 Wochen) - der Rabatt L→M senkt die Marge, Nettoeffekt = Zuwachs minus Rabatt.


-- Tableau tile:
-- DE: «Nachmittags-Deal 14-16 Uhr: +10 % = +11.219 $ pro Jahr»


-- =========================================================
-- Step 5: sales_lines - one table for Tableau (★ as VIEW = bonus)
-- 1 row = 1 order line (grain of order_details), JOIN of all 4 tables, 12 fields
-- VIEW = saved query: stores no data, is recalculated on every SELECT
-- =========================================================
DROP VIEW IF EXISTS sales_lines;

CREATE VIEW sales_lines AS
SELECT
  o.order_id                                   AS order_id,
  o.date                                       AS order_date,
  o.time                                       AS order_time,
  strftime('%m', o.date)                       AS month,
  CASE strftime('%w', o.date)
    WHEN '1' THEN 'Monday'    WHEN '2' THEN 'Tuesday'
    WHEN '3' THEN 'Wednesday' WHEN '4' THEN 'Thursday'
    WHEN '5' THEN 'Friday'    WHEN '6' THEN 'Saturday'
    WHEN '0' THEN 'Sunday'
  END                                          AS weekday,
  strftime('%H', o.time)                       AS hour,
  pt.name                                      AS pizza_name,
  pt.category                                  AS category,
  p.size                                       AS size,
  CAST(p.price AS REAL)                        AS unit_price,
  CAST(od.quantity AS INTEGER)                 AS quantity,
  CAST(p.price AS REAL) * CAST(od.quantity AS INTEGER) AS revenue
FROM orders o
JOIN order_details od USING (order_id)
JOIN pizzas p         USING (pizza_id)
JOIN pizza_types pt   USING (pizza_type_id);

-- Control: row count must equal order_details (more rows = JOIN duplicated data)
SELECT
  COUNT(*)                  AS row_count,      -- 48620 = order_details
  ROUND(SUM(revenue), 2)    AS total_revenue,  -- 817860.05 = Q1
  SUM(quantity)             AS pizzas_sold,    -- 49574 = Q1
  COUNT(DISTINCT order_id)  AS orders          -- 21350 = Q1
FROM sales_lines;

SELECT * FROM sales_lines;   -- run, then Export -> CSV -> exports/sales_lines.csv

-- Result: 48620 | 817860.05 | 49574 | 21350 - all match
