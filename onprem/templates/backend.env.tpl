# CAIVA on-prem backend config — written by install.sh (chmod 600). Secrets are per-install.
MASTER_DATABASE_URL=postgresql://grc_app:__DB_PW__@127.0.0.1:5432/cyber_master
TENANT_DB_URL_TEMPLATE=postgresql://grc_app:__DB_PW__@127.0.0.1:5432/cyber_{slug}
POSTGRES_ADMIN_URL=postgresql://grc_app:__DB_PW__@127.0.0.1:5432/postgres
REDIS_URL=redis://127.0.0.1:6379/0
CELERY_BROKER_URL=redis://127.0.0.1:6379/1
CELERY_RESULT_BACKEND=redis://127.0.0.1:6379/2
TENANT_JOB_RATE_PER_MIN=120
SESSION_SECRET=__SESSION_SECRET__
CONNECTOR_MASTER_KEY=__CONNECTOR_KEY__
MSF_RPC_PASSWORD=__MSF_PW__
EXTERNAL_ID_SALT=__SALT__
AUTH_COOKIE_DOMAIN=
REPL_DEPLOYMENT=1
ALLOWED_ORIGIN_REGEX=
ALLOWED_ORIGINS=https://__HOST__
PUBLIC_API_BASE_URL=https://__HOST__
FRONTEND_BASE_URL=https://__HOST__
# Single tenant: the bare host serves this tenant; libraries are canonical here.
DEFAULT_TENANT_SLUG=__SLUG__
CANONICAL_LIBRARY_SOURCE_SLUG=__SLUG__
DISABLE_TENANT_STARTUP_SEED=1
UPLOAD_ROOT=uploads
AVA_BACKEND_URL=http://127.0.0.1:4000
AVA_AGENT_DIST=/opt/caiva/agent-dist
AVA_SCAN_INGEST_DIR=/opt/caiva/scan-ingest
# Optional internet features — leave blank for an air-gapped install (AI features stay off).
OPENAI_API_KEY='__OPENAI_KEY__'
AI_INTEGRATIONS_OPENAI_API_KEY='__OPENAI_KEY__'
OPENAI_MODEL=gpt-4o-mini
AVA_OPENAI_MODEL=gpt-4o-mini
AI_AUTOLINK_MIN_CONFIDENCE=high
# Optional email (alerts / reports)
SMTP_HOST='__SMTP_HOST__'
SMTP_PORT=__SMTP_PORT__
SMTP_USER='__SMTP_USER__'
SMTP_PASSWORD='__SMTP_PASSWORD__'
SMTP_FROM_EMAIL='__SMTP_FROM__'
# Discovery / pentest
DISCOVERY_MAX_WORKERS=16
DISCOVERY_PROBE_TIMEOUT=3
# In-scope ranges for exploit validation (space separated IPs / CIDRs / hosts). Empty = none.
AVA_EXPLOIT_SCOPE='__EXPLOIT_SCOPE__'
# Optional: higher NVD / GitHub API limits when internet is allowed
NVD_API_KEY=
GITHUB_TOKEN=
AVA_WORKER_CONCURRENCY=2
HELPDESK_AUTO_TICKET=true
HELPDESK_AUTO_SEVERITIES=critical
HELPDESK_AUTO_INTERNET_FACING=true
DISABLE_EMBEDDED_WORKFLOW_RUNTIME=1
DISABLE_COMPLYCHAT_EMBED_WORKER=1
COMPLYCHAT_EMBED_WORKER_AUTOSTART=false
