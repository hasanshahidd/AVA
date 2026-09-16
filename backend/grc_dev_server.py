"""Local dev launcher — serves the GRC app under the /grc prefix.

The Next.js frontend rewrites /api/* -> http://127.0.0.1:4000/grc/* (see
grc-frontend/next.config.js), so for local development the backend must answer
under /grc. The application routes are mounted at root in grc/main.py; this thin
wrapper mounts that app at /grc so the proxy resolves without touching app code.

Run from the backend/ directory:
    python -m uvicorn grc_dev_server:application --host 127.0.0.1 --port 4000
"""
import logging
import os

from fastapi import FastAPI

from grc.main import app as _inner

application = FastAPI(title="GRC dev /grc mount")
application.mount("/grc", _inner)


@application.on_event("startup")
def _dev_startup():
    # Starlette does NOT run a MOUNTED sub-app's on_event("startup"), so grc.main's
    # startup hooks don't fire under this dev /grc mount. Re-attach the poll+sync
    # loop to any in-flight hosted (Flow 1) scan here so a scan launched before a
    # restart still syncs. (Prod runs grc.main:app directly, where its own
    # on_startup handles this.)
    try:
        from grc.modules.integrations.services.hosted_scan import resume_inflight_hosted_scans
        resume_inflight_hosted_scans(os.getenv("AVA_TENANT_SLUG", "ava"))
    except Exception:  # noqa: BLE001
        logging.getLogger(__name__).warning("dev hosted-scan resume-on-startup skipped", exc_info=True)


@application.get("/health")
def _health():
    return {"status": "ok", "mounted": "/grc"}
