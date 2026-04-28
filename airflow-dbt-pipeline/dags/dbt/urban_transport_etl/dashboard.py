"""
dashboard.py
-----------
A Streamlit dashboard visualizing Chicago Taxi Analytics data materialized
in BigQuery by dbt models. This script defines the UI layout, executes 
queries against our models, and renders interactive Plotly charts.
"""
import streamlit as st
import pandas as pd
from google.cloud import bigquery
import plotly.express as px

# Configure standard Streamlit page settings
st.set_page_config(page_title="Chicago Taxi Analytics", page_icon="🚕", layout="wide")

# -----------------------------
# BigQuery Client
# -----------------------------
@st.cache_resource
def get_client():
    """Instantiate and cache the BigQuery client pointing to our billing project."""
    return bigquery.Client(project="urban-transportation-analytics")

@st.cache_data(ttl=3600)
def load_data(query: str) -> pd.DataFrame:
    """
    Execute a static SQL query against BigQuery and return a pandas DataFrame.
    Data is cached for 1 hour to optimize performance and billing.
    """
    client = get_client()
    return client.query(query).to_dataframe()

# -----------------------------
# Queries (centralized)
# -----------------------------
QUERIES = {
    "kpis": """
        SELECT 
            COUNT(*) AS total_trips,
            SUM(trip_total) AS total_revenue,
            AVG(trip_total) AS avg_fare
        FROM raw_urban_mobility_dev.fct_trips
    """,

    "peak": """
        SELECT trip_date, peak_hour, total_trip_count 
        FROM raw_urban_mobility_dev.rpt_peak_demand
    """,

    "areas": """
        SELECT community_name, total_pickups 
        FROM raw_urban_mobility_dev.rpt_top_areas
        ORDER BY total_pickups DESC
        LIMIT 15
    """,

    "payment": """
        SELECT payment_type, trip_count 
        FROM raw_urban_mobility_dev.rpt_payment_preferences
    """,

    "company": """
        SELECT company_name, total_revenue 
        FROM raw_urban_mobility_dev.rpt_company_performance
        ORDER BY total_revenue DESC
        LIMIT 10
    """,

    "economics": """
        SELECT trip_distance_category, avg_fare 
        FROM raw_urban_mobility_dev.rpt_trip_economics
    """,

    "flow": """
        SELECT pickup_area, dropoff_area, trip_flow_volume 
        FROM raw_urban_mobility_dev.rpt_trip_flow
        ORDER BY trip_flow_volume DESC
        LIMIT 15
    """
}

# -----------------------------
# App
# -----------------------------
def main():
    """
    Main execution loop for rendering the Streamlit UI components, executing 
    queries concurrently where possible, and initializing Plotly elements.
    """
    st.title("🚕 Chicago Taxi Analytics Dashboard")
    st.markdown("End-to-end analytics pipeline (GCS → BigQuery → dbt → Streamlit)")

    st.divider()

    # -----------------------------
    # KPIs
    # -----------------------------
    try:
        df_kpi = load_data(QUERIES["kpis"])
        col1, col2, col3 = st.columns(3)

        col1.metric("Total Trips", f"{df_kpi['total_trips'][0]:,}")
        col2.metric("Total Revenue", f"${df_kpi['total_revenue'][0]:,.0f}")
        col3.metric("Avg Fare", f"${df_kpi['avg_fare'][0]:.2f}")
    except Exception as e:
        st.error(f"KPI load failed: {e}")

    st.divider()

    # -----------------------------
    # Row 1
    # -----------------------------
    col1, col2 = st.columns(2)

    with col1:
        st.subheader("📈 Peak Demand Over Time")
        try:
            df = load_data(QUERIES["peak"])
            df["datetime"] = pd.to_datetime(df["trip_date"]) + pd.to_timedelta(df["peak_hour"], unit="h")
            df = df.sort_values("datetime")

            fig = px.line(df, x="datetime", y="total_trip_count")
            st.plotly_chart(fig, use_container_width=True)
        except Exception as e:
            st.error(e)

    with col2:
        st.subheader("📍 Top Pickup Areas")
        try:
            df = load_data(QUERIES["areas"])
            fig = px.bar(df, x="total_pickups", y="community_name", orientation="h")
            fig.update_yaxes(categoryorder="total ascending")
            st.plotly_chart(fig, use_container_width=True)
        except Exception as e:
            st.error(e)

    st.divider()

    # -----------------------------
    # Row 2
    # -----------------------------
    col1, col2 = st.columns(2)

    with col1:
        st.subheader("💳 Payment Preferences")
        try:
            df = load_data(QUERIES["payment"])
            fig = px.pie(df, values="trip_count", names="payment_type", hole=0.4)
            st.plotly_chart(fig, use_container_width=True)
        except Exception as e:
            st.error(e)

    with col2:
        st.subheader("🏢 Company Performance")
        try:
            df = load_data(QUERIES["company"])
            fig = px.bar(df, x="company_name", y="total_revenue")
            st.plotly_chart(fig, use_container_width=True)
        except Exception as e:
            st.error(e)

    st.divider()

    # -----------------------------
    # Row 3
    # -----------------------------
    col1, col2 = st.columns(2)

    with col1:
        st.subheader("🛣️ Trip Economics")
        try:
            df = load_data(QUERIES["economics"])
            fig = px.bar(df, x="trip_distance_category", y="avg_fare")
            st.plotly_chart(fig, use_container_width=True)
        except Exception as e:
            st.error(e)

    with col2:
        st.subheader("🔄 Top Routes")
        try:
            df = load_data(QUERIES["flow"])
            df["route"] = df["pickup_area"] + " → " + df["dropoff_area"]
            fig = px.bar(df, x="trip_flow_volume", y="route", orientation="h")
            fig.update_yaxes(categoryorder="total ascending")
            st.plotly_chart(fig, use_container_width=True)
        except Exception as e:
            st.error(e)

    st.divider()

    st.caption("Data source: BigQuery • Modeled via dbt • Visualized in Streamlit")

if __name__ == "__main__":
    main()