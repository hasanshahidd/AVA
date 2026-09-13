"""Serve the MAIN checkout's backend on :4000 regardless of launch cwd.

Written for the context-mapping test run (launched from a worktree session's
preview). reload is OFF: Windows uvicorn --reload wedges — after backend edits,
stop + start this server instead. Safe to delete; the day-to-day launcher
remains _run_dev.py.
"""
import os
os.chdir(os.path.dirname(os.path.abspath(__file__)))

from dotenv import load_dotenv
load_dotenv(".env")
import uvicorn

if __name__ == "__main__":
    uvicorn.run("grc_dev_server:application", host="127.0.0.1", port=4000,
                reload=False, env_file=".env")
