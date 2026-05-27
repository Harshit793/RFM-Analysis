# Customer Retention Strategy — RFM Segmentation & A/B Test Analysis

## Business Problem
An e-commerce platform needed to identify customers at risk of permanent churn and measure whether a discount coupon campaign could bring them back — before they were lost for good.

## What I Did
Built an end-to-end customer retention analysis on the [Olist Brazilian E-Commerce dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (96,477 customers) across three stages:

**1. RFM Segmentation (T-SQL)**
Scored every customer on Recency, Frequency, and Monetary value using percentile-based ranking via SQL window functions. Applied weighted composite scoring (R: 50%, M: 40%, F: 10%) — frequency was down-weighted because 71% of customers had placed exactly 1 order, making it a near-zero variance dimension. Segmented customers into Top, Loyal, At Risk, and Immediate Attention using a SQL view connected directly to Power BI.

**2. Retention Campaign A/B Test (Python)**
Isolated the At Risk cohort (32,386 customers, avg 305 days since last order, holding 33% of total revenue). Designed a 60-day A/B test — 80% Treatment (10% discount coupon) vs 20% Control (no discount). Validated group balance before experiment. Measured conversion lift using a chi-square significance test.

**3. GMV Tier Analysis (Python)**
Broke down conversion rates across customer spend tiers (<$100, $100–200, $200–300, >$300) to determine whether a tiered discount strategy was needed.

## Key Findings

| Metric | Value |
|---|---|
| At Risk customers | 32,386 (33.5% of base) |
| Revenue at risk | $5.1M (33% of total) |
| Treatment conversion rate | 24.9% |
| Control conversion rate | 12.0% |
| Absolute lift | +12.9 pp |
| p-value | < 0.0001 ✅ |
| Campaign ROI | 280% ($3.80 returned per $1 spent) |
| Conversion rate across GMV tiers | Uniform (24.4% – 25.5%) |

## Business Recommendation
Scale the flat 10% discount campaign to the full At Risk cohort — no tiered pricing needed as the discount drives near-uniform conversion across all spend levels. Prioritise the >$300 GMV tier in campaign execution to maximise revenue recovered per discount dollar spent. For the Immediate Attention segment (avg 425 days inactive), a separate reactivation intervention is recommended — discounts alone are unlikely to be sufficient at this recency gap.

## Tools
| Tool | Purpose |
|---|---|
| T-SQL (SQL Server) | Data prep, RFM scoring, view creation |
| Python (pandas, scipy, matplotlib) | A/B test design, significance testing, ROI analysis |
| Power BI | Customer retention dashboard |

## Repository Structure
```
rfm-customer-retention/
│
├── README.md
├── sql/
│   └── rfm_analysis.sql          # RFM segmentation logic — CTEs + SQL view
├── notebook/
│   └── rfm_ab_test.ipynb         # A/B test experiment with full outputs
└── dashboard/
    └── RFM_Analysis.pbix         # Power BI retention dashboard
```

## Dataset
[Olist Brazilian E-Commerce — Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
