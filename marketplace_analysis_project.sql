CREATE DATABASE marketplace_analysis;
USE marketplace_analysis;
SHOW TABLES;
RENAME TABLE `orders_v2 - orders_v2.csv` TO orders_v2;
SHOW TABLES;
RENAME TABLE `products_v2 - products_v2.csv` TO products_v2;
RENAME TABLE `logistics_cost_v2 - logistics_cost_v2.csv` TO logistics_cost_v2;
RENAME TABLE `payment_fees_v2 - payment_fees_v2.csv` TO payment_fees_v2;
RENAME TABLE `discounts_v2 - discounts_v2.csv` TO discounts_v2;
RENAME TABLE `returns_v2 - returns_v2.csv` TO returns_v2;
SELECT * FROM orders_v2;
USE marketplace_analysis;
TASK-1.
SELECT 
    SUM(o.quantity * o.selling_price) AS total_revenue,

    SUM(l.shipping_cost + l.reverse_shipping_cost) +
    SUM((o.quantity * o.selling_price) * p.fee_percentage / 100) +
    SUM(d.discount_amount) AS total_cost,

    SUM(o.quantity * o.selling_price) -
    (
        SUM(l.shipping_cost + l.reverse_shipping_cost) +
        SUM((o.quantity * o.selling_price) * p.fee_percentage / 100) +
        SUM(d.discount_amount)
    ) AS total_profit

FROM orders_v2 o

LEFT JOIN logistics_cost_v2 l
ON o.order_id = l.order_id

LEFT JOIN payment_fees_v2 p
ON o.payment_method = p.payment_method

LEFT JOIN discounts_v2 d
ON o.order_id = d.order_id;
TASK-2.
SELECT 
    pr.category,
    ROUND(SUM(o.quantity * o.selling_price),2) AS total_sales,
    ROUND(SUM(o.quantity * pr.cost_price),2) AS total_cost,
    ROUND(SUM((o.quantity * o.selling_price) - (o.quantity * pr.cost_price)),2) AS total_profit
FROM orders_v2 o
JOIN products_v2 pr
ON o.product_id = pr.product_id
WHERE pr.category IS NOT NULL
GROUP BY pr.category
ORDER BY total_sales DESC;
TASK-3.
SELECT 
    o.product_id,
    pr.brand,
    pr.sub_category,

    SUM(o.quantity * o.selling_price) AS total_sales,

    SUM(l.shipping_cost + l.reverse_shipping_cost) +
    SUM((o.quantity * o.selling_price) * p.fee_percentage / 100) +
    SUM(d.discount_amount) AS total_cost,

    SUM(o.quantity * o.selling_price) -
    (
        SUM(l.shipping_cost + l.reverse_shipping_cost) +
        SUM((o.quantity * o.selling_price) * p.fee_percentage / 100) +
        SUM(d.discount_amount)
    ) AS total_profit

FROM orders_v2 o

LEFT JOIN products_v2 pr
ON o.product_id = pr.product_id

LEFT JOIN logistics_cost_v2 l
ON o.order_id = l.order_id

LEFT JOIN payment_fees_v2 p
ON o.payment_method = p.payment_method

LEFT JOIN discounts_v2 d
ON o.order_id = d.order_id

GROUP BY o.product_id, pr.brand, pr.sub_category

HAVING total_profit < 0;
There are no products with negative total profit in my dataset.
Confirm by removing the filter
Run the same query without the loss condition to see all products and their profits.
SELECT 
    o.product_id,
    pr.brand,
    pr.sub_category,

    SUM(o.quantity * o.selling_price) AS total_sales,

    SUM(l.shipping_cost + l.reverse_shipping_cost) +
    SUM((o.quantity * o.selling_price) * p.fee_percentage / 100) +
    SUM(d.discount_amount) AS total_cost,

    SUM(o.quantity * o.selling_price) -
    (
        SUM(l.shipping_cost + l.reverse_shipping_cost) +
        SUM((o.quantity * o.selling_price) * p.fee_percentage / 100) +
        SUM(d.discount_amount)
    ) AS total_profit

FROM orders_v2 o

LEFT JOIN products_v2 pr
ON o.product_id = pr.product_id

LEFT JOIN logistics_cost_v2 l
ON o.order_id = l.order_id

LEFT JOIN payment_fees_v2 p
ON o.payment_method = p.payment_method

LEFT JOIN discounts_v2 d
ON o.order_id = d.order_id

GROUP BY o.product_id, pr.brand, pr.sub_category;
So no product is loss-making.
Task-4.
SELECT 
    COUNT(DISTINCT order_id) AS total_discount_orders,
    SUM(discount_amount) AS total_discount_given
FROM discounts_v2;
TASK-5.
SELECT 
    payment_method,
    COUNT(order_id) AS total_orders,
    SUM(quantity * selling_price) AS total_sales
FROM orders_v2
GROUP BY payment_method;
TASK-6.
SELECT 
    CASE 
        WHEN d.discount_amount > 0 THEN 'Discounted Orders'
        ELSE 'Non-Discounted Orders'
    END AS order_type,

    COUNT(DISTINCT o.order_id) AS total_orders,

    AVG(
        (o.quantity * o.selling_price) -
        (
            IFNULL(l.shipping_cost,0) +
            IFNULL(l.reverse_shipping_cost,0) +
            ((o.quantity * o.selling_price) * IFNULL(p.fee_percentage,0) / 100) +
            IFNULL(d.discount_amount,0)
        )
    ) AS avg_profit_per_order

FROM orders_v2 o

LEFT JOIN logistics_cost_v2 l
ON o.order_id = l.order_id

LEFT JOIN payment_fees_v2 p
ON o.payment_method = p.payment_method

LEFT JOIN discounts_v2 d
ON o.order_id = d.order_id

GROUP BY order_type;
TASK-7.
SELECT 
    SUM(o.quantity * o.selling_price) AS revenue_lost,

    SUM(
        (o.quantity * o.selling_price) -
        (
            IFNULL(l.shipping_cost,0) +
            IFNULL(l.reverse_shipping_cost,0) +
            ((o.quantity * o.selling_price) * IFNULL(p.fee_percentage,0) / 100) +
            IFNULL(d.discount_amount,0)
        )
    ) AS profit_lost

FROM returns_v2 r

LEFT JOIN orders_v2 o
ON r.order_id = o.order_id

LEFT JOIN logistics_cost_v2 l
ON o.order_id = l.order_id

LEFT JOIN payment_fees_v2 p
ON o.payment_method = p.payment_method

LEFT JOIN discounts_v2 d
ON o.order_id = d.order_id;
TASK-8.
SELECT 
    r.return_reason,
    COUNT(r.order_id) AS total_returns,
    SUM(o.quantity * o.selling_price) AS revenue_lost

FROM returns_v2 r

LEFT JOIN orders_v2 o
ON r.order_id = o.order_id

GROUP BY r.return_reason
ORDER BY revenue_lost DESC;
TASK-9.
SELECT 
    o.order_id,
    (o.quantity * o.selling_price) AS order_value,
    (l.shipping_cost + l.reverse_shipping_cost) AS logistics_cost,
    ((l.shipping_cost + l.reverse_shipping_cost) / 
     (o.quantity * o.selling_price)) * 100 AS logistics_percentage

FROM orders_v2 o

LEFT JOIN logistics_cost_v2 l
ON o.order_id = l.order_id

WHERE (l.shipping_cost + l.reverse_shipping_cost) >
      0.2 * (o.quantity * o.selling_price)

ORDER BY logistics_percentage DESC;
To find the top 10 orders with the highest logistics percentage:
SELECT 
    o.order_id,
    (o.quantity * o.selling_price) AS order_value,
    l.shipping_cost AS logistics_cost,
    (l.shipping_cost / (o.quantity * o.selling_price)) * 100 AS logistics_percentage
FROM 
    orders_v2 o
JOIN 
    logistics_cost_v2 l
ON 
    o.order_id = l.order_id
ORDER BY 
    logistics_percentage DESC
LIMIT 10;
TASK-10.
SELECT 
    o.payment_method,

    SUM(o.quantity * o.selling_price) AS total_sales,

    SUM((o.quantity * o.selling_price) * p.fee_percentage / 100) AS total_payment_fee,

    SUM(
        (o.quantity * o.selling_price) -
        (
            IFNULL(l.shipping_cost,0) +
            IFNULL(l.reverse_shipping_cost,0) +
            ((o.quantity * o.selling_price) * p.fee_percentage / 100) +
            IFNULL(d.discount_amount,0)
        )
    ) AS net_profit

FROM orders_v2 o

LEFT JOIN payment_fees_v2 p
ON o.payment_method = p.payment_method

LEFT JOIN logistics_cost_v2 l
ON o.order_id = l.order_id

LEFT JOIN discounts_v2 d
ON o.order_id = d.order_id

GROUP BY o.payment_method

ORDER BY total_payment_fee DESC;
TASK-11.
Leakage per Order
USE marketplace_analysis;
SELECT 
    o.order_id,
    (o.quantity * o.selling_price) AS order_value,
    IFNULL(d.discount_amount,0) AS discount_loss,
    IFNULL(l.shipping_cost,0) + IFNULL(l.reverse_shipping_cost,0) AS logistics_loss,
    ((o.quantity * o.selling_price) * IFNULL(p.fee_percentage,0) / 100) AS payment_fee_loss,
    CASE 
        WHEN r.order_id IS NOT NULL THEN (o.quantity * o.selling_price)
        ELSE 0
    END AS return_loss

FROM orders_v2 o

LEFT JOIN discounts_v2 d
ON o.order_id = d.order_id

LEFT JOIN logistics_cost_v2 l
ON o.order_id = l.order_id

LEFT JOIN payment_fees_v2 p
ON o.payment_method = p.payment_method

LEFT JOIN returns_v2 r
ON o.order_id = r.order_id;
Total Leakage Overall
SELECT 

SUM(IFNULL(d.discount_amount,0)) AS total_discount_loss,

SUM(IFNULL(l.shipping_cost,0) + IFNULL(l.reverse_shipping_cost,0)) AS total_logistics_loss,

SUM((o.quantity * o.selling_price) * IFNULL(p.fee_percentage,0) / 100) AS total_payment_fee_loss,

SUM(
    CASE 
        WHEN r.order_id IS NOT NULL 
        THEN (o.quantity * o.selling_price)
        ELSE 0
    END
) AS total_return_loss

FROM orders_v2 o

LEFT JOIN discounts_v2 d
ON o.order_id = d.order_id

LEFT JOIN logistics_cost_v2 l
ON o.order_id = l.order_id

LEFT JOIN payment_fees_v2 p
ON o.payment_method = p.payment_method

LEFT JOIN returns_v2 r
ON o.order_id = r.order_id;
TASK-12.
USE marketplace_analysis;
SELECT 
    o.product_id,
    p.brand,
    p.sub_category,

    SUM(o.quantity * o.selling_price) AS total_sales,

    SUM(
        (o.quantity * o.selling_price) -
        (
            IFNULL(l.shipping_cost,0) +
            IFNULL(l.reverse_shipping_cost,0) +
            ((o.quantity * o.selling_price) * IFNULL(f.fee_percentage,0) / 100) +
            IFNULL(d.discount_amount,0)
        )
    ) AS net_profit

FROM orders_v2 o

LEFT JOIN products_v2 p
ON o.product_id = p.product_id

LEFT JOIN logistics_cost_v2 l
ON o.order_id = l.order_id

LEFT JOIN payment_fees_v2 f
ON o.payment_method = f.payment_method

LEFT JOIN discounts_v2 d
ON o.order_id = d.order_id

GROUP BY o.product_id, p.brand, p.sub_category

ORDER BY net_profit DESC;
top 10 products by net_profit
WITH product_agg AS (
    SELECT 
        p.product_id,
        p.brand,
        p.sub_category,
        SUM(o.quantity * o.selling_price) AS total_revenue,
        SUM(o.quantity * p.cost_price) AS total_cost,
        COALESCE(SUM(l.shipping_cost), 0) AS total_logistics
    FROM 
        products_v2 p
    JOIN 
        orders_v2 o ON p.product_id = o.product_id
    LEFT JOIN 
        logistics_cost_v2 l ON o.order_id = l.order_id
    GROUP BY 
        p.product_id, p.brand, p.sub_category
),
product_profit AS (
    SELECT
        product_id,
        brand,
        sub_category,
        total_revenue,
        total_cost,
        total_logistics,
        total_revenue - total_cost - total_logistics AS net_profit
    FROM
        product_agg
),
ranked_products AS (
    SELECT 
        product_id,
        brand,
        sub_category,
        net_profit,
        ROW_NUMBER() OVER (ORDER BY net_profit DESC) AS rank_desc,
        ROW_NUMBER() OVER (ORDER BY net_profit ASC) AS rank_asc
    FROM 
        product_profit
)
SELECT
    product_id,
    brand,
    sub_category,
    net_profit,
    CASE 
        WHEN rank_desc <= 3 THEN 'Top 3'
        WHEN rank_asc <= 3 THEN 'Bottom 3'
        ELSE ''
    END AS highlight_flag
FROM
    ranked_products
WHERE rank_desc <= 10   -- top 10 products
ORDER BY
    net_profit DESC;
TASK-13.
USE marketplace_analysis;
SELECT 
    p.category,

    AVG(
        (
            (o.quantity * o.selling_price) -
            (
                IFNULL(l.shipping_cost,0) +
                IFNULL(l.reverse_shipping_cost,0) +
                ((o.quantity * o.selling_price) * IFNULL(f.fee_percentage,0) / 100) +
                IFNULL(d.discount_amount,0)
            )
        ) / (o.quantity * o.selling_price)
    ) AS avg_profit_margin,

    STDDEV(
        (
            (o.quantity * o.selling_price) -
            (
                IFNULL(l.shipping_cost,0) +
                IFNULL(l.reverse_shipping_cost,0) +
                ((o.quantity * o.selling_price) * IFNULL(f.fee_percentage,0) / 100) +
                IFNULL(d.discount_amount,0)
            )
        ) / (o.quantity * o.selling_price)
    ) AS margin_variation

FROM orders_v2 o

LEFT JOIN products_v2 p
ON o.product_id = p.product_id

LEFT JOIN logistics_cost_v2 l
ON o.order_id = l.order_id

LEFT JOIN payment_fees_v2 f
ON o.payment_method = f.payment_method

LEFT JOIN discounts_v2 d
ON o.order_id = d.order_id

GROUP BY p.category

ORDER BY margin_variation DESC;
TASK-14.
SELECT 
    o.customer_id,
    COUNT(DISTINCT r.order_id) AS returned_orders,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT r.order_id) / COUNT(DISTINCT o.order_id) AS customer_return_rate
FROM orders_v2 o
LEFT JOIN returns_v2 r
ON o.order_id = r.order_id
GROUP BY o.customer_id
HAVING customer_return_rate >
(
    SELECT 
        COUNT(DISTINCT r.order_id) / COUNT(DISTINCT o.order_id)
    FROM orders_v2 o
    LEFT JOIN returns_v2 r
    ON o.order_id = r.order_id
)
ORDER BY customer_return_rate DESC;
the top 10 high-risk customers
SELECT
    o.customer_id,
    COUNT(o.order_id) AS total_orders,
    COUNT(r.order_id) AS total_returns,
    (COUNT(r.order_id) / COUNT(o.order_id)) AS return_rate
FROM
    orders_v2 o
LEFT JOIN
    returns_v2 r ON o.order_id = r.order_id
GROUP BY
    o.customer_id
ORDER BY
    return_rate DESC
LIMIT 10;
TASK-15.
SELECT 
    SUM(o.quantity * o.selling_price) AS total_sales,

    SUM(
        (o.quantity * o.selling_price) -
        (
            IFNULL(d.discount_amount,0) +
            IFNULL(l.shipping_cost,0) +
            IFNULL(l.reverse_shipping_cost,0) +
            ((o.quantity * o.selling_price) * IFNULL(p.fee_percentage,0) / 100)
        )
    ) AS total_profit,

    SUM(IFNULL(d.discount_amount,0)) AS total_discounts,

    SUM(
        CASE 
            WHEN r.order_id IS NOT NULL 
            THEN (o.quantity * o.selling_price)
            ELSE 0
        END
    ) AS total_returns_loss,

    SUM(IFNULL(l.shipping_cost,0) + IFNULL(l.reverse_shipping_cost,0)) AS total_logistics_cost,

    SUM((o.quantity * o.selling_price) * IFNULL(p.fee_percentage,0) / 100) AS total_payment_fees

FROM orders_v2 o
LEFT JOIN discounts_v2 d 
ON o.order_id = d.order_id

LEFT JOIN logistics_cost_v2 l 
ON o.order_id = l.order_id

LEFT JOIN payment_fees_v2 p 
ON o.payment_method = p.payment_method

LEFT JOIN returns_v2 r 
ON o.order_id = r.order_id;






