# Urban Transportation Analytics

End-to-end analytics pipeline for Chicago taxi trip data using dbt, Airflow, and BigQuery. Transforms raw taxi feeds into a Kimball star schema with business-ready reports and an interactive Streamlit dashboard.

## Overview

This project implements a complete **ELT pipeline** that processes raw taxi transaction data into actionable analytics. The architecture follows medallion principles with staging, marts, and report layers, orchestrated by Airflow with Astronomer Cosmos.

## Features

- **Star Schema**: Kimball dimensional modeling with fact and dimension tables
- **Incremental Processing**: Efficient partitioned models for large-scale data
- **Data Quality**: 44 automated tests including custom metric validation
- **Orchestration**: Airflow DAGs with Cosmos dbt task groups
- **Interactive Dashboard**: Streamlit app with Plotly visualizations
- **CI/CD**: GitLab pipeline with Python linting, SQL linting, and dbt validation

## Architecture

```
Raw Data (BigQuery)
       ↓
Staging Layer (clean, dedupe, type-cast)
       ↓
Marts Layer (fact + dimensions)
       ↓
Reports Layer (business analytics)
       ↓
Dashboard (Streamlit + Plotly)
```

### Data Flow

1. **Source**: `raw_urban_mobility_dev.taxi_trips_raw` BigQuery table
2. **Staging**: `stg_taxi_trips` - cleans, deduplicates, and type-casts raw data
3. **Dimensions**: `dim_date`, `dim_time`, `dim_company`, `dim_payment_type`, `dim_community_area`
4. **Fact**: `fct_trips` - central fact table with surrogate keys
5. **Reports**: 6 business-facing analytics models

## Project Structure

```
urban_transportation_analytics/
├── README.md                          # This file
├── .env                               # Environment variables
├── .gitlab-ci.yml                     # CI/CD pipeline
└── airflow-dbt-pipeline/
    ├── requirements.txt               # Python dependencies
    ├── Dockerfile
    ├── airflow_settings.yaml          # Airflow configuration
    ├── .astro/
    │   ├── config.yaml
    │   └── test_dag_integrity_default.py
    ├── dags/
    │   ├── urban_transportation_analytics.py    # Main Airflow DAG
    │   └── dbt/
    │       └── urban_transport_etl/
    │           ├── dbt_project.yml              # dbt configuration
    │           ├── profiles.yml                 # BigQuery profile
    │           ├── models/
    │           │   ├── staging/
    │           │   │   ├── sources.yml
    │           │   │   ├── schema.yml
    │           │   │   └── stg_taxi_trips.sql
    │           │   ├── marts/
    │           │   │   ├── fct_trips.sql
    │           │   │   ├── dim_date.sql
    │           │   │   ├── dim_time.sql
    │           │   │   ├── dim_company.sql
    │           │   │   ├── dim_payment_type.sql
    │           │   │   └── dim_community_area.sql
    │           │   └── reports/
    │           │       ├── rpt_peak_demand.sql
    │           │       ├── rpt_company_performance.sql
    │           │       ├── rpt_payment_preferences.sql
    │           │       ├── rpt_top_areas.sql
    │           │       ├── rpt_trip_flow.sql
    │           │       └── rpt_trip_economics.sql
    │           ├── seeds/
    │           │   └── community_areas_mapping.csv
    │           ├── tests/
    │           │   └── assert_positive_metrics_taxi_trips.sql
    │           └── dashboard.py                 # Streamlit visualization
    └── tests/
        └── dags/test_dag_example.py
```

## Data Models

### Staging Layer

| Model | Description |
|-------|-------------|
| `stg_taxi_trips` | Cleaned, deduplicated, type-cast taxi trips (incremental) |

### Dimension Tables

| Model | Description |
|-------|-------------|
| `dim_date` | Date dimension for temporal analysis |
| `dim_time` | Time dimension with day parts (morning, afternoon, etc.) |
| `dim_company` | Taxi company entities |
| `dim_payment_type` | Payment method mappings |
| `dim_community_area` | Chicago community area mappings (from seed CSV) |

### Fact Table

| Model | Description |
|-------|-------------|
| `fct_trips` | Central fact table with metrics and surrogate keys (incremental) |

### Report Layer

| Model | Description |
|-------|-------------|
| `rpt_peak_demand` | Temporal demand patterns - peak days, hours, and day parts |
| `rpt_company_performance` | Revenue and trip metrics by taxi company |
| `rpt_payment_preferences` | Payment type distribution analysis |
| `rpt_top_areas` | Top pickup locations by volume |
| `rpt_trip_flow` | Origin-destination flow analysis |
| `rpt_trip_economics` | Fare analysis by distance category |

## Data Quality

The project implements comprehensive data quality checks:

- **44 automated tests** across all models
- **YAML validation**: `not_null`, `unique`, and relationship constraints
- **Custom tests**: `assert_positive_metrics_taxi_trips.sql` validates positive values for trip duration, distance, and fares
- **Schema tests**: Primary key uniqueness and foreign key relationships

## Getting Started

### Prerequisites

- Python 3.10+
- Docker (for Astro CLI)
- Google Cloud SDK
- BigQuery access with appropriate permissions
- Service account credentials

### Local Development with Astro

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd urban_transportation_analytics/airflow-dbt-pipeline
   ```

2. Install Astro CLI (if not already installed):
   ```bash
   curl -sSL install.astronomer.io | sudo bash -s
   ```

3. Start local Airflow:
   ```bash
   astro dev start
   ```

4. Set environment variables:
   ```bash
   export DBT_ROOT_PATH=/path/to/dbt
   export EMAIL_ID=your-email@example.com
   ```

5. Access Airflow UI at `http://localhost:8080`

### Running dbt Locally

1. Navigate to dbt project:
   ```bash
   cd airflow-dbt-pipeline/dags/dbt/urban_transport_etl
   ```

2. Install dependencies:
   ```bash
   pip install dbt-core dbt-bigquery
   ```

3. Run dbt:
   ```bash
   dbt deps
   dbt run
   dbt test
   ```

### Dashboard

Run the Streamlit dashboard:

```bash
cd airflow-dbt-pipeline/dags/dbt/urban_transport_etl
streamlit run dashboard.py
```

The dashboard displays:
- Key trip metrics (total trips, revenue, average fare)
- Peak demand charts by hour and day
- Geographic heatmaps for pickup/dropoff locations
- Payment type distribution pie charts
- Company performance comparisons

## CI/CD

The GitLab pipeline (`.gitlab-ci.yml`) runs on every push:

| Job | Description |
|-----|-------------|
| `lint-python` | Python linting with flake8 |
| `lint-sql` | SQL linting with sqlfluff (BigQuery dialect) |
| `dbt-validate` | dbt parse validation |

## Orchestration

The Airflow DAG (`urban_transportation_analytics.py`) uses Astronomer Cosmos to:

- Schedule dbt runs daily
- Visualize dbt dependency graphs
- Manage task execution with `max_active_runs` throttling
- Send failure alerts via email callback

## Configuration

### BigQuery Connection

Configure in `profiles.yml`:

```yaml
urban_transport_etl:
  target: dev
  outputs:
    dev:
      type: bigquery
      method: oauth
      project: your-project-id
      dataset: your-dataset
      location: us-central1
```

### Airflow Connections

Configure in `airflow_settings.yaml` or via Airflow UI:
- BigQuery connection
- Email notifications for failures

## Dependencies

```txt
astronomer-cosmos
dbt-core
dbt-bigquery
streamlit
pandas
google-cloud-bigquery
plotly.express
```

## Monitoring

- **Airflow UI**: DAG run status, task duration, logs
- **dbt Docs**: Generated documentation at `target/index.html`
- **BigQuery**: Query statistics and slot utilization
- **Data Quality**: Test failure alerts via email

## License

MIT
