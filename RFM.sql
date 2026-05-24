-- Delivered Orders → Filter only completed orders

CREATE or alter VIEW vw_customer_rfm_segmentation as
WITH delivered_orders AS
(
    SELECT
        customer_id,
        order_id,
        CAST(order_purchase_timestamp AS DATE) AS purchase_date
    FROM dbo.olist_orders_dataset
    WHERE order_status = 'delivered'
),

-- Payment per Order → Aggregate GMV per order
-- A single order can have multiple payment records
-- (e.g., credit card + voucher)

payment_per_order AS
(
    SELECT
        order_id,
        ROUND(SUM(payment_value), 2) AS amount
    FROM dbo.olist_order_payments_dataset
    GROUP BY order_id
),

-- Join delivered orders with aggregated payments

order_with_payment AS
(
    SELECT
        do.customer_id,
        do.order_id,
        do.purchase_date,
        po.amount
    FROM delivered_orders do
    INNER JOIN payment_per_order po
        ON do.order_id = po.order_id
),

-- Compute Raw RFM Metrics
--
-- Recency   = Days since last order
-- Frequency = Number of delivered orders
-- Monetary  = Total amount spent
--
-- Snapshot Date = Max purchase date + 1 day

rfm_raw AS
(
    SELECT
        customer_id,
        DATEDIFF
        (
            DAY,
            MAX(purchase_date),
            DATEADD
            (
                DAY,
                1,
                (SELECT MAX(purchase_date)
                 FROM order_with_payment)
            )
        ) AS recency,

        COUNT(order_id) AS frequency,
        SUM(amount) AS monetary

    FROM order_with_payment
    GROUP BY customer_id
),

-- Convert raw metrics into percentile scores (0–10)
--
-- Recency: Lower is better → invert rank
-- Frequency: Higher is better
-- Monetary: Higher is better

rfm_scored AS
(
    SELECT
        customer_id,
        recency,
        frequency,
        monetary,

        ROUND(
            (
                1 - PERCENT_RANK() OVER (ORDER BY recency ASC)
            ) * 10,
            0
        ) AS recent_rnk,

        ROUND(
            PERCENT_RANK() OVER (ORDER BY frequency ASC) * 10,
            0
        ) AS frequency_rnk,

        ROUND(
            PERCENT_RANK() OVER (ORDER BY monetary ASC) * 10,
            0
        ) AS monetary_rnk

    FROM rfm_raw
),

-- Weighted RFM Score
--
-- Recency  = 50%
-- Frequency = 10%
-- Monetary  = 40%

rfm_composite AS
(
    SELECT
        customer_id,
        recency,
        frequency,
        monetary,
        recent_rnk,
        frequency_rnk,
        monetary_rnk,

        ROUND
        (
            recent_rnk * 0.5 +
            frequency_rnk * 0.1 +
            monetary_rnk * 0.4,
            0
        ) AS score,

        ROUND
        (
            PERCENT_RANK() OVER
            (
                ORDER BY
                    ROUND
                    (
                        recent_rnk * 0.5 +
                        frequency_rnk * 0.1 +
                        monetary_rnk * 0.4,
                        0
                    ) ASC
            ) * 10,
            0
        ) AS rfm_score

    FROM rfm_scored
)

-- Customer Segmentation

SELECT
        customer_id,
        recency,
        frequency,
        monetary,
        recent_rnk,
        frequency_rnk,
        monetary_rnk,
        score,
        rfm_score,
    CASE
        WHEN rfm_score >= 8 THEN 'Top Customer'
        WHEN rfm_score >= 5 THEN 'Loyal Customer'
        WHEN rfm_score >= 2 THEN 'At Risk'
        ELSE 'Immediate Attention'
    END AS segment,
    DENSE_RANK() over(order by monetary desc) as monetary_rank
FROM rfm_composite; 


select * from vw_customer_rfm_segmentation