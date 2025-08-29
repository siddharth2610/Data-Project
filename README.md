# Submission for Manual AE Data Challenge
### By Siddharth Ganeriwala

## Overview

This SQL modeling project creates a comprehensive customer analytics framework designed to calculate key business metrics including retention, acquisition, and churn. The model transforms three source tables into a unified analytical table that enables time-series analysis of customer behavior.

## Architecture

### Source Tables

#### 1. acq_orders
- **Purpose**: Customer category dimension
- **Key Fields**:
  - `customer_id`
  - `taxonomy_business_category_group`
- Unique on customer_id


#### 2. customers
- **Purpose**: Customer country dimension
- **Description**: Master customer table containing geographical information
- **Key Fields**:
  - `customer_id`
  - `customer_country`
- Unique on customer_id


#### 3. activity
- **Purpose**: Subscription lifecycle tracking
- **Description**: Records customer subscription periods with start and end dates
- **Key Fields**:
  - `customer_id`
  - `subscription_id`
  - `from_date`
  - `to_date`

### Target Table

#### user_stats (Main Analytical Table)
- **Structure**: Date Grid × Customer ID Matrix
- **Purpose**: Primary table for retention, acquisition, and churn calculations
- **Key Features**:
  - Complete date range coverage
  - All customer IDs with dimensional attributes
  - Daily customer activity status (`is_active` flag)
  - Integrated customer dimensions from source tables

## Data Model Design

### Date Grid Implementation
- **Coverage**: Complete date range spanning all subscription periods
- **Granularity**: Daily level
- **Purpose**: Enables time-series analysis and cohort studies

### Customer Dimensions Integration
- **Category Dimension**: From `acq_orders` table
- **Geographic Dimension**: From `customers` table (country-based)
- **Activity Status**: Derived from `activity` table subscription periods

### Key Calculated Fields
- **is_active**: Boolean flag indicating customer activity status for each date
- **Customer Category**: Categorization from acquisition data
- **Country**: Geographic segmentation
- **Subscription Status**: Active/inactive based on subscription date ranges

## Use Cases

### 1. Retention Analysis
- Track customer retention rates over time
- Cohort-based retention studies
- Segment retention by category and geography
  
### Retention Rate Calculation
```sql
-- Monthly retention rate by customer category
SELECT
category_group,
DATE_TRUNC(created_date, MONTH) AS cohort_month, 
DATE_TRUNC(date, MONTH) AS month, 
COUNT(DISTINCT customer_id) AS count_users_in_cohort, 
ROUND(COUNT(DISTINCT CASE WHEN is_active = 1 THEN customer_id ELSE NULL END)*100/COUNT(DISTINCT customer_id),2) AS per_customer_retained

FROM user_stats

GROUP BY ALL
ORDER BY 1,2,3
```

### 2. Acquisition Metrics
- New customer acquisition tracking
- Acquisition trends by category and country
- Customer onboarding analysis

### Acquisition Tracking
```sql
-- New customer acquisitions by  category
SELECT
category_group,
DATE_TRUNC(created_date, MONTH) AS acquisition_month, 
COUNT(DISTINCT customer_id) AS count_customers_acquired, 

FROM user_stats

GROUP BY ALL
ORDER BY 1,2
```

## Implementation Benefits

### Data Advantages
- **Unified View**: Single source of truth for customer analytics
- **Time-Series Ready**: Daily granularity enables trend analysis
- **Dimension Rich**: Multiple segmentation options available
- **Calculation Optimized**: Pre-structured for key metric calculations

## Maintenance and Updates

### Data Refresh Strategy
- **Frequency**: Daily refresh recommended
- **Incremental Updates**: Process only new/changed data
- **Data Quality Checks**: Validate completeness and consistency

### Monitoring
- **Row Count Validation**: Ensure complete date × customer coverage
- **Activity Flag Accuracy**: Validate against source subscription data
- **Dimension Consistency**: Check for missing or inconsistent dimension data
