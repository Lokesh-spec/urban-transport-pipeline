# 🔐 ADC Authentication Setup Reference
## Urban Transportation Analytics Pipeline

---

## 📋 Overview

| Item | Details |
|------|---------|
| **Project** | Urban Transportation Analytics |
| **GCP Project** | `urban-transportation-analytics` |
| **Auth Method** | Application Default Credentials (ADC) |
| **Platform** | Astronomer Local (Airflow 3.0+) |
| **Date Completed** | January 2025 |

---

## 🎯 Problem Solved

| Before | After |
|--------|-------|
| ❌ Hardcoded service account keyfile | ✅ ADC (OAuth) |
| ❌ Security risk (keys in filesystem) | ✅ GCP-managed credentials |
| ❌ Manual key rotation | ✅ Automatic token refresh |
| ❌ Path-dependent configuration | ✅ Portable across environments |

---

## 🔧 Step-by-Step Setup

### Step 1: Authenticate on Host Machine

```bash
# One-time setup on your Mac (host machine)
gcloud auth application-default login

# Verify credentials exist
ls -la ~/.config/gcloud/application_default_credentials.json

# Revoke and re-login if needed
gcloud auth application-default revoke
gcloud auth application-default login
```

### Step 2: Update dbt profiles.yml
Location: include/dbt/profiles.yml

```bash
urban_transportation_analytics:
  outputs:
    dev:
      type: bigquery
      method: oauth                    # ✅ Uses ADC
      project: urban-transportation-analytics
      dataset: raw_urban_mobility_dev
      location: us-central1
      threads: 4
      timeout_seconds: 300
      retries: 1
      priority: interactive
      # ✅ No keyfile specified - ADC handles auth
      
  target: dev
```

### Key Changes:

Field	Before	After
method	service-account	oauth
keyfile	/path/to/key.json	(removed)

### Step 3: Create docker-compose.override.yml
Location: Project root (same level as .astro/ folder)

# docker-compose.override.yml
# ⚠️ NO version field (obsolete in Compose v2+)

``` yml
services:
  scheduler:
    volumes:
      - ~/.config/gcloud/application_default_credentials.json:/usr/local/airflow/.config/gcloud/application_default_credentials.json:ro
    environment:
      - GOOGLE_APPLICATION_CREDENTIALS=/usr/local/airflow/.config/gcloud/application_default_credentials.json
      - GOOGLE_CLOUD_PROJECT=urban-transportation-analytics

  api-server:
    volumes:
      - ~/.config/gcloud/application_default_credentials.json:/usr/local/airflow/.config/gcloud/application_default_credentials.json:ro
    environment:
      - GOOGLE_APPLICATION_CREDENTIALS=/usr/local/airflow/.config/gcloud/application_default_credentials.json
      - GOOGLE_CLOUD_PROJECT=urban-transportation-analytics

  dag-processor:
    volumes:
      - ~/.config/gcloud/application_default_credentials.json:/usr/local/airflow/.config/gcloud/application_default_credentials.json:ro
    environment:
      - GOOGLE_APPLICATION_CREDENTIALS=/usr/local/airflow/.config/gcloud/application_default_credentials.json
      - GOOGLE_CLOUD_PROJECT=urban-transportation-analytics

  triggerer:
    volumes:
      - ~/.config/gcloud/application_default_credentials.json:/usr/local/airflow/.config/gcloud/application_default_credentials.json:ro
    environment:
      - GOOGLE_APPLICATION_CREDENTIALS=/usr/local/airflow/.config/gcloud/application_default_credentials.json
      - GOOGLE_CLOUD_PROJECT=urban-transportation-analytics
```


#### Key Changes for Airflow 3.0+:
Service	Airflow 2.x	Airflow 3.0+
Web UI	webserver	api-server
Worker	worker	dag-processor

### Step 4: Restart Astronomer

``` bash
# Stop all containers
astro dev stop

# Start with new configuration
astro dev start

# Wait for containers to be ready
sleep 30
```

## Verification Commands
### Test 1: Verify Host Credentials

``` bash
ls -la ~/.config/gcloud/application_default_credentials.json
cat ~/.config/gcloud/application_default_credentials.json | head -5
```

### Test 2: Verify Container Mount
``` bash
astro dev bash -d
ls -la /usr/local/airflow/.config/gcloud/application_default_credentials.json
echo $GOOGLE_APPLICATION_CREDENTIALS
exit
```

### Test 3: Test BigQuery Connection
``` bash
echo "from google.cloud import bigquery; print(bigquery.Client().project)" | astro dev bash -d
``` 

### Test 4: Test dbt Connection
``` bash
astro dev bash -d
cd /usr/local/airflow/include/dbt
dbt debug --target dev
exit
```

Troubleshooting
Issue	Solution
Authenticated: False	Run gcloud auth application-default login on host
File not found in container	Check volume mount path in override file
Permission denied	Run chmod 644 ~/.config/gcloud/application_default_credentials.json
Service not found	Use api-server and dag-processor (not webserver/worker)
Invalid compose project	Remove version field from override file


┌─────────────────────────────────────────────────────────────┐
│                    HOST MACHINE (Mac)                       │
│  ~/.config/gcloud/application_default_credentials.json      │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Volume Mount (read-only)
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              DOCKER CONTAINERS (Astronomer)                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │  scheduler   │  │  api-server  │  │dag-processor │       │
│  │      +       │  │      +       │  │      +       │       │
│  │  triggerer   │  │              │  │              │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
│         │                   │                   │            │
│         └───────────────────┼───────────────────┘            │
│                             ▼                                │
│              GOOGLE_APPLICATION_CREDENTIALS                  │
│              (Environment Variable)                          │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ OAuth
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    GCP BigQuery                             │
│  Project: urban-transportation-analytics                    │
└─────────────────────────────────────────────────────────────┘

### Quick Reference Commands

``` bash
# Authenticate on host
gcloud auth application-default login

# Restart Astronomer
astro dev stop && astro dev start

# Test BigQuery connection
echo "from google.cloud import bigquery; print(bigquery.Client().project)" | astro dev bash -d

# Test dbt connection
astro dev bash -d
cd /usr/local/airflow/include/dbt
dbt debug --target dev
exit

# Enter dag-processor container
astro dev bash -d

# View container logs
astro dev logs -d

# Check running containers
astro dev ps
``` 

Verification Checklist
- Host ADC credentials exist (~/.config/gcloud/application_default_credentials.json)
- profiles.yml uses method: oauth (no keyfile)
- docker-compose.override.yml mounts credentials to all services
- docker-compose.override.yml has NO version field
- Service names match Airflow 3.0+ (api-server, dag-processor)
- BigQuery connection test returns project ID
- dbt debug shows ✓ Connected to BigQuery
- Service account keys added to .gitignore

Key Files Modified
File	Path	Change
profiles.yml	include/dbt/profiles.yml	Changed method to oauth, removed keyfile
docker-compose.override.yml	Project root	Added volume mounts for ADC credentials
.gitignore	Project root	Added *.json, *sa*.json, profiles.yml