import os
import logging
from datetime import datetime, timedelta
from pathlib import Path

from airflow.decorators import dag
from airflow.operators.empty import EmptyOperator

from cosmos import DbtTaskGroup, ProjectConfig, ProfileConfig, RenderConfig, ExecutionConfig
from cosmos.constants import ExecutionMode

# Cloud Composer neatly syncs the DAGs folder, so we map dbt natively within it.
DEFAULT_DBT_ROOT_PATH = Path(__file__).parent / "dbt"
DBT_ROOT_PATH = Path(os.getenv("DBT_ROOT_PATH", DEFAULT_DBT_ROOT_PATH))

# Securely load email from .env or fallback to the provided default
EMAIL_ID = os.getenv("EMAIL_ID", "lokeshkv18@gmail.com")

project_config = ProjectConfig(
    dbt_project_path=(DBT_ROOT_PATH / "urban_transport_etl")
)

execution_config = ExecutionConfig(
    execution_mode=ExecutionMode.LOCAL
)

profile_config = ProfileConfig(
    profile_name="urban_transportation_analytics",
    target_name="dev",
    profiles_yml_filepath=(DBT_ROOT_PATH / "urban_transport_etl" / "profiles.yml")
)

def failure_alert(context):
    """Custom callback to execute when a task fails"""
    task_instance = context.get('task_instance')
    logging.error(f"FAILED TASK NOTIFICATION: Task {task_instance.task_id} failed in DAG {task_instance.dag_id}.")

default_args = {
    "owner": "airflow",
    "retries": 2,                          # Retry failing tasks up to 2 times
    "retry_delay": timedelta(minutes=2),   # Wait 2 minutes between retries
    "email_on_failure": True,              # Native Airflow email sending (Requires SMTP config)
    "email_on_retry": False,
    "email": [EMAIL_ID],                   # Pass the environment variable here
    "on_failure_callback": failure_alert,  # Runs custom Python logic on failure
}

@dag(
    start_date=datetime(2026, 4, 1),
    schedule="@hourly",                     # Usually good practice to have a standard schedule
    catchup=False,
    tags=["dbt", "cosmos"],
    max_active_runs=2,                     # Ensure max active DAG runs is exactly 2
    max_active_tasks=5,                    # Good practice: Throttles queries sent to BigQuery concurrently
    default_args=default_args,
)
def urban_transportation_analytics():
    start = EmptyOperator(task_id="start")
    
    urban_analytics = DbtTaskGroup(
        group_id="urban_analytics",
        project_config=project_config,
        execution_config=execution_config,
        profile_config=profile_config,
        # Render the entire dbt project instead of just a specific seed path
        render_config=RenderConfig()
    )
    
    end = EmptyOperator(task_id="end")

    start >> urban_analytics >> end

urban_transportation_analytics()