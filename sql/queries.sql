sql
-- =========================================
-- Zwischenprojekt: Pizza Place Sales (2015)
-- SQLite Online
-- =========================================


aass

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
FROM orders;

Как работает: CASE ставит 1, если ячейка пустая, иначе 0, а SUM складывает эти единицы, то есть считает пропуски.

Почему OR = '': при импорте CSV пустая ячейка часто становится пустой строкой, а не NULL.

-- order_details
SELECT
  SUM(CASE WHEN order_details_id IS NULL OR order_details_id = '' THEN 1 ELSE 0 END) AS order_details_id_missing,
  SUM(CASE WHEN order_id IS NULL OR order_id = '' THEN 1 ELSE 0 END) AS order_id_missing,
  SUM(CASE WHEN pizza_id IS NULL OR pizza_id = '' THEN 1 ELSE 0 END) AS pizza_id_missing,
  SUM(CASE WHEN quantity IS NULL OR quantity = '' THEN 1 ELSE 0 END) AS quantity_missing
FROM order_details;

-- pizzas
SELECT
  SUM(CASE WHEN pizza_id      IS NULL OR pizza_id      = '' THEN 1 ELSE 0 END) AS pizza_id_missing,
  SUM(CASE WHEN pizza_type_id IS NULL OR pizza_type_id = '' THEN 1 ELSE 0 END) AS pizza_type_id_missing,
  SUM(CASE WHEN size          IS NULL OR size          = '' THEN 1 ELSE 0 END) AS size_missing,
  SUM(CASE WHEN price         IS NULL OR price         = '' THEN 1 ELSE 0 END) AS price_missing
FROM pizzas;

-- pizza_types
SELECT
  SUM(CASE WHEN pizza_type_id IS NULL OR pizza_type_id = '' THEN 1 ELSE 0 END) AS pizza_type_id_missing,
  SUM(CASE WHEN name          IS NULL OR name          = '' THEN 1 ELSE 0 END) AS name_missing,
  SUM(CASE WHEN category      IS NULL OR category      = '' THEN 1 ELSE 0 END) AS category_missing,
  SUM(CASE WHEN ingredients   IS NULL OR ingredients   = '' THEN 1 ELSE 0 END) AS ingredients_missing
FROM pizza_types;



-- =========================================================
-- Q1: Annual KPIs 2015
--     Ключові показники року 2015
-- Revenue, orders, pizzas sold, avg order value, avg pizzas per order
-- Виручка, замовлення, продані піци, середній чек, піц на замовлення
-- =========================================================

-- Step 1: base figures from one JOIN (price in pizzas, quantity in order_details)
-- Крок 1: базові цифри з одного JOIN (ціна — у pizzas, кількість — у order_details)
WITH base AS (
  SELECT
    -- revenue = price × quantity per line, then summed
    -- виручка = ціна × кількість по кожному рядку, потім сума
    SUM(CAST(p.price AS REAL) * CAST(od.quantity AS INTEGER)) AS total_revenue,

    -- DISTINCT: one order has several lines
    -- DISTINCT: одне замовлення має кілька рядків
    COUNT(DISTINCT od.order_id)                               AS total_orders,

    -- pizzas = SUM(quantity), not COUNT(*): one line can hold 2–4 pizzas
    -- піци = SUM(quantity), а не COUNT(*): в одному рядку буває 2–4 піци
    SUM(CAST(od.quantity AS INTEGER))                         AS pizzas_sold
  FROM order_details od
  JOIN pizzas p ON od.pizza_id = p.pizza_id
)

-- Step 2: averages derived from base figures
-- Крок 2: середні значення з базових цифр
SELECT
  ROUND(total_revenue, 2)                            AS total_revenue,
  total_orders,
  pizzas_sold,
  -- avg order value = revenue / orders (not AVG over lines)
  -- середній чек = виручка / замовлення (не AVG по рядках)
  ROUND(total_revenue / total_orders, 2)             AS avg_order_value,
  -- CAST to REAL: integer / integer would drop decimals (2 instead of 2.32)
  -- CAST до REAL: ціле / ціле відкине дробову частину (2 замість 2.32)
  ROUND(CAST(pizzas_sold AS REAL) / total_orders, 2) AS avg_pizzas_per_order
FROM base;




