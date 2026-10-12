"""Knowledge base articles (contract §A10).

Native port of the Frappe proxy's `/articles` handler (helpdesk/router.py):
HDArticle grouped by HDArticleCategory, with per-article views / helpful /
not_helpful. Tenant-scoped; empty tenant → empty lists, never 4xx (§E).
"""
from __future__ import annotations

from collections import Counter

from sqlalchemy.orm import Session

from ...models import HDArticle
from .common import iso


def list_articles(db: Session, tid: int) -> dict:
    """§A10. Per-article helpful/not_helpful have no native store yet (the model
    map defers HD Article Feedback), so they serialize as 0 — exactly what the
    proxy returns for an article with no feedback rows. `categories` is the
    proxy's name→count breakdown (sorted), unread by the UI but part of the shape."""
    rows = (
        db.query(HDArticle)
        .filter(HDArticle.tenant_id == tid)
        .order_by(HDArticle.updated_at.desc())
        .all()
    )
    cats: Counter = Counter()
    articles = []
    for a in rows:
        cat = (a.category.category_name if a.category and a.category.category_name
               else "Uncategorised")
        cats[cat] += 1
        articles.append({
            "name": str(a.id),
            "title": a.title,
            "category": cat,
            "status": a.status,
            "author": a.author,
            "modified": iso(a.updated_at),
            "views": a.views or 0,
            "helpful": 0,
            "not_helpful": 0,
        })
    return {
        "articles": articles,
        "categories": [{"name": n, "count": c} for n, c in sorted(cats.items())],
    }
