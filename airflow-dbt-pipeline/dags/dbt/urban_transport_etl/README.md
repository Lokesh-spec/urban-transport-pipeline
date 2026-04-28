# Chicago Taxi Analytics (dbt Project)

This repository contains a robust, Kimball-style Star Schema implemented in dbt to analyze Chicago taxi trip data. 
The objective of this project is to model raw taxi trip data into clear, analysis-ready dimensions and fact tables, and 
ultimately provide answers to a series of core business questions regarding transportation demand, company performance, and passenger behavior.

## Architecture

The project follows dbt best practices, organizing models into three distinct layers:

### 1. Staging (`models/staging/`)
The foundational layer where raw data from the data warehouse is cleaned and prepared.
- **`stg_taxi_trips`**: Applies data type casting, renaming, and deduplication logic over the raw taxi data feed.

### 2. Marts (`models/marts/`)
The core Kimball-style star schema, optimized for analytical queries.
- **Fact Table**:
  - **`fct_trips`**: Central fact table storing business metrics (fares, distance, duration) for individual trips.
- **Dimensions**:
  - **`dim_company`**: Taxi companies operating in the city.
  - **`dim_community_area`**: Standardized Chicago community areas serving as pickup or dropoff locations.
  - **`dim_date`**: Calendar date dimension for aggregations.
  - **`dim_time`**: Hour-of-day dimension to analyze intraday patterns.
  - **`dim_payment_type`**: Classification of trip payment methods.

### 3. Reports (`models/reports/`)
Business-facing models materialized as views/tables that answer specific analytical questions:
- **`rpt_peak_demand`**: Identifies peak demand hours and days across the transportation network.
- **`rpt_top_areas`**: Highlights the top community areas ranked by total pick-up trip volume.
- **`rpt_payment_preferences`**: Outlines the distribution and popularity of different payment types.
- **`rpt_company_performance`**: Ranks the top taxi companies based on total revenue generated.
- **`rpt_trip_flow`**: Analyzes the origin-to-destination volume flow between different community areas.
- **`rpt_trip_economics`**: Explores the relationship between trip categorization (duration/distance) and the typical fare.

## Project Configuration

- **Adapter Engine**: Standardized for Google BigQuery execution.
- **Materialization Strategies**: Staging models are materialized as tables/views, marts are persisted as `table`, and reports are generated as `table` (configured dynamically via `dbt_project.yml`).

## Data Quality & Testing

This project incorporates rigorous data quality checks using built-in dbt tests. There are currently **44 automated data tests** protecting the integrity of the data pipeline:
- `unique` and `not_null` assertions verify primary keys across all dimension and fact structures.
- `relationships` tests guarantee referential integrity from `fct_trips` back to the dimension tables (date, time, payment, company, community areas) using the nested `arguments` configuration syntax.

## Getting Started

1. Ensure you have `dbt-core` and the `dbt-bigquery` (or relevant) adapter installed.
2. Initialize your `profiles.yml` with the target `urban_transportation_analytics`.
3. Verify your environment by running:
   ```bash
   dbt debug
   ```
4. Build the core models and run tests:
   ```bash
   dbt build
   ```
