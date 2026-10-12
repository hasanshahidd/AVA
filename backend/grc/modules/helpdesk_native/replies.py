"""Saved / canned replies — STUB. Filled by the replies agent.

§A11, §A16–§A19. Reads return the empty shape; mutating POST/PUT/DELETE return
{"ok": true} (§ mutating-POST contract). TODO(convert): replies — back these
with HDSavedReply (title/message/scope), and have list_canned_responses return
`message` (HTML body) too so "insert canned reply" inserts real text (§A11 FLAG).
"""
from __future__ import annotations

from sqlalchemy.orm import Session


def list_saved_replies(db: Session, tid: int) -> dict:
    return {"saved_replies": []}


def list_canned_responses(db: Session, tid: int) -> dict:
    return {"responses": []}


def create_saved_reply(db: Session, tid: int, payload: dict) -> dict:
    return {"ok": True}


def update_saved_reply(db: Session, tid: int, name: str, payload: dict) -> dict:
    return {"ok": True}


def delete_saved_reply(db: Session, tid: int, name: str) -> dict:
    return {"ok": True}
