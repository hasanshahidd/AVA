"""Knowledge base articles — STUB. Filled by the KB agent.

§A10 empty shape. TODO(convert): kb — read HDArticle grouped by
HDArticleCategory and aggregate per-article views / helpful / not_helpful.
"""
from __future__ import annotations

from sqlalchemy.orm import Session


def list_articles(db: Session, tid: int) -> dict:
    return {"articles": [], "categories": []}
