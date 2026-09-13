"""Local dev backend launcher — loads .env then serves the /grc mount on :4000.

reload=True auto-restarts the worker on .py edits, so backend fixes apply without
a manual restart. env_file keeps .env loaded in each reloaded worker (reload
workers are fresh processes, so they don't inherit the top-level load_dotenv).
"""
from dotenv import load_dotenv
load_dotenv(".env")
import uvicorn

if __name__ == "__main__":
    # reload_dirs scopes the watcher to the app package — watching backend/ would
    # also poll the venvs (thousands of files) and thrash.
    uvicorn.run("grc_dev_server:application", host="127.0.0.1", port=4100,
                reload=True, reload_dirs=["grc"], env_file=".env")
