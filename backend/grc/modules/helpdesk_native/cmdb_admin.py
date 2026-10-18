"""CMDB admin CRUD — flow #5b.

In-app management of the configuration-management database: CI Types, CI
Attribute definitions, Configuration Items, Relationship Types and the CI
relationship graph (source -> target, typed edge) that the React Flow map
renders.

Tenant-scoped throughout (same convention as masters.py / kb.py): every query
filters on `tenant_id(db)`, a cross-tenant id looks exactly like a missing id
(404), and `code` uniqueness is per-tenant. Reads are gated
`require_settings_view`; writes are gated `require_settings_manage` (same
settings:* segregation-of-duties group documented in common.py — CMDB
structure is config, not a ticket-queue action).

MODEL NOTE — CI Type "retire": HDCIType (grc/models/_62_helpdesk_itsm_models.py)
has no `enabled`/`status` column, so there is no soft-retire to flip. Instead
this module exposes a hard `DELETE /types/{id}` guarded the same way a soft
retire would be: if any CI still references the type, the delete is refused
(409) rather than orphaning those CIs. That guard is the "don't orphan"
invariant the spec asks for; CIs themselves still soft-retire via
`status="retired"` (reversible), since HDConfigurationItem *does* carry
`status`.

Idempotent relationship add: HDCIRelationship has a unique
(source_ci_id, target_ci_id, rel_type_id) constraint, so POST /relationships
checks for an existing row with that exact triple first and returns it instead
of racing the DB constraint.
"""
from __future__ import annotations

from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session

from ...models import (
    get_db,
    HDBusinessService,
    HDCIAttribute,
    HDCIRelationship,
    HDCIRelationshipType,
    HDCIType,
    HDConfigurationItem,
)
from .common import iso, require_settings_manage, require_settings_view, tenant_id

router = APIRouter(prefix="/helpdesk/admin/cmdb")

RETIRED = "retired"


# ═══════════════════════════════════════════════════════════════════════════
# shared helpers
# ═══════════════════════════════════════════════════════════════════════════
def _dup_code(db: Session, model, tid: int, code: str, exclude_id: Optional[int] = None) -> bool:
    q = db.query(model).filter(model.tenant_id == tid, model.code == code)
    if exclude_id is not None:
        q = q.filter(model.id != exclude_id)
    return q.first() is not None


def _get_or_404(db: Session, model, tid: int, obj_id: int):
    row = db.query(model).filter(model.id == obj_id, model.tenant_id == tid).first()
    if not row:
        raise HTTPException(status_code=404, detail="not found")
    return row


def _resolve_ci_type(db: Session, tid: int, ci_type_id: Optional[int]) -> Optional[HDCIType]:
    if ci_type_id is None:
        return None
    row = db.query(HDCIType).filter(HDCIType.id == ci_type_id, HDCIType.tenant_id == tid).first()
    if not row:
        raise HTTPException(status_code=400, detail="ci_type_id does not exist in this tenant")
    return row


def _resolve_business_service(db: Session, tid: int, business_service_id: Optional[int]):
    if business_service_id is None:
        return None
    row = (
        db.query(HDBusinessService)
        .filter(HDBusinessService.id == business_service_id, HDBusinessService.tenant_id == tid)
        .first()
    )
    if not row:
        raise HTTPException(status_code=400, detail="business_service_id does not exist in this tenant")
    return row


def _get_ci_in_tenant(db: Session, tid: int, ci_id: int) -> HDConfigurationItem:
    row = (
        db.query(HDConfigurationItem)
        .filter(HDConfigurationItem.id == ci_id, HDConfigurationItem.tenant_id == tid)
        .first()
    )
    if not row:
        raise HTTPException(status_code=400, detail=f"CI {ci_id} does not exist in this tenant")
    return row


def _get_rel_type_in_tenant(db: Session, tid: int, rel_type_id: int) -> HDCIRelationshipType:
    row = (
        db.query(HDCIRelationshipType)
        .filter(HDCIRelationshipType.id == rel_type_id, HDCIRelationshipType.tenant_id == tid)
        .first()
    )
    if not row:
        raise HTTPException(status_code=400, detail="rel_type_id does not exist in this tenant")
    return row


def _ci_type_row(t: HDCIType) -> dict:
    return {
        "id": t.id,
        "code": t.code,
        "name": t.name,
        "description": t.description,
        "icon": t.icon,
        "parent_id": t.parent_id,
        "parent": {"id": t.parent.id, "code": t.parent.code, "name": t.parent.name} if t.parent else None,
        "created": iso(t.created_at),
        "modified": iso(t.updated_at),
    }


def _attribute_row(a: HDCIAttribute) -> dict:
    return {
        "id": a.id,
        "ci_type_id": a.ci_type_id,
        "idx": a.idx,
        "name": a.name,
        "datatype": a.datatype,
        "required": bool(a.required),
        "options": a.options,
        "created": iso(a.created_at),
        "modified": iso(a.updated_at),
    }


def _ci_row(c: HDConfigurationItem) -> dict:
    return {
        "id": c.id,
        "code": c.code,
        "name": c.name,
        "ci_type_id": c.ci_type_id,
        "ci_type": c.ci_type.name if c.ci_type else None,
        "business_service_id": c.business_service_id,
        "business_service": c.business_service.name if c.business_service else None,
        "status": c.status,
        "criticality": c.criticality,
        "environment": c.environment,
        "owner": c.owner,
        "ava_asset_id": c.ava_asset_id,
        "attributes": c.attributes,
        "created": iso(c.created_at),
        "modified": iso(c.updated_at),
    }


def _rel_type_row(r: HDCIRelationshipType) -> dict:
    return {
        "id": r.id,
        "code": r.code,
        "name": r.name,
        "inverse_name": r.inverse_name,
        "created": iso(r.created_at),
        "modified": iso(r.updated_at),
    }


def _relationship_row(r: HDCIRelationship) -> dict:
    return {
        "id": r.id,
        "source_ci_id": r.source_ci_id,
        "source_ci": r.source_ci.code if r.source_ci else None,
        "target_ci_id": r.target_ci_id,
        "target_ci": r.target_ci.code if r.target_ci else None,
        "rel_type_id": r.rel_type_id,
        "rel_type": r.rel_type.name if r.rel_type else None,
        "created": iso(r.created_at),
    }


# ═══════════════════════════════════════════════════════════════════════════
# CI Types
# ═══════════════════════════════════════════════════════════════════════════
class CITypeCreate(BaseModel):
    code: str
    name: str
    description: Optional[str] = None
    parent_id: Optional[int] = None
    icon: Optional[str] = None


class CITypeUpdate(BaseModel):
    code: Optional[str] = None
    name: Optional[str] = None
    description: Optional[str] = None
    parent_id: Optional[int] = None
    icon: Optional[str] = None


@router.get("/types")
def list_ci_types(db: Session = Depends(get_db), _: bool = Depends(require_settings_view)):
    tid = tenant_id(db)
    rows = db.query(HDCIType).filter(HDCIType.tenant_id == tid).order_by(HDCIType.name.asc()).all()
    return {"ci_types": [_ci_type_row(t) for t in rows]}


@router.post("/types")
def create_ci_type(body: CITypeCreate, db: Session = Depends(get_db),
                    _: bool = Depends(require_settings_manage)):
    tid = tenant_id(db)
    code = (body.code or "").strip()
    if not code:
        raise HTTPException(status_code=400, detail="code is required")
    if _dup_code(db, HDCIType, tid, code):
        raise HTTPException(status_code=409, detail=f"CI type with code '{code}' already exists")
    if body.parent_id is not None:
        _resolve_ci_type(db, tid, body.parent_id)
    row = HDCIType(
        tenant_id=tid,
        code=code,
        name=body.name,
        description=body.description,
        parent_id=body.parent_id,
        icon=body.icon,
    )
    db.add(row)
    db.commit()
    return {"ok": True, "id": row.id}


@router.patch("/types/{type_id}")
def update_ci_type(type_id: int, body: CITypeUpdate, db: Session = Depends(get_db),
                    _: bool = Depends(require_settings_manage)):
    tid = tenant_id(db)
    row = _get_or_404(db, HDCIType, tid, type_id)
    data = body.model_dump(exclude_unset=True)
    if "code" in data:
        new_code = (data["code"] or "").strip()
        if not new_code:
            raise HTTPException(status_code=400, detail="code is required")
        if _dup_code(db, HDCIType, tid, new_code, exclude_id=row.id):
            raise HTTPException(status_code=409, detail=f"CI type with code '{new_code}' already exists")
        data["code"] = new_code
    if "parent_id" in data and data["parent_id"] is not None:
        if data["parent_id"] == row.id:
            raise HTTPException(status_code=400, detail="a CI type cannot be its own parent")
        _resolve_ci_type(db, tid, data["parent_id"])
    for k, v in data.items():
        setattr(row, k, v)
    db.commit()
    return {"ok": True}


@router.delete("/types/{type_id}")
def delete_ci_type(type_id: int, db: Session = Depends(get_db),
                    _: bool = Depends(require_settings_manage)):
    tid = tenant_id(db)
    row = _get_or_404(db, HDCIType, tid, type_id)
    in_use = (
        db.query(HDConfigurationItem)
        .filter(HDConfigurationItem.ci_type_id == row.id, HDConfigurationItem.tenant_id == tid)
        .first()
    )
    if in_use:
        raise HTTPException(status_code=409, detail="CI type is in use by one or more CIs")
    db.delete(row)
    db.commit()
    return {"ok": True}


# ═══════════════════════════════════════════════════════════════════════════
# CI Attributes (schema definitions per CI type)
# ═══════════════════════════════════════════════════════════════════════════
class AttributeCreate(BaseModel):
    name: str
    datatype: Optional[str] = "string"      # string|int|float|bool|date|enum
    required: Optional[bool] = None
    options: Optional[list] = None
    idx: Optional[int] = None


class AttributeUpdate(BaseModel):
    name: Optional[str] = None
    datatype: Optional[str] = None
    required: Optional[bool] = None
    options: Optional[list] = None
    idx: Optional[int] = None


def _get_attribute(db: Session, tid: int, attribute_id: int) -> HDCIAttribute:
    row = (
        db.query(HDCIAttribute)
        .join(HDCIType, HDCIAttribute.ci_type_id == HDCIType.id)
        .filter(HDCIAttribute.id == attribute_id, HDCIType.tenant_id == tid)
        .first()
    )
    if not row:
        raise HTTPException(status_code=404, detail="not found")
    return row


@router.get("/types/{type_id}/attributes")
def list_ci_attributes(type_id: int, db: Session = Depends(get_db),
                        _: bool = Depends(require_settings_view)):
    tid = tenant_id(db)
    _get_or_404(db, HDCIType, tid, type_id)
    rows = (
        db.query(HDCIAttribute)
        .filter(HDCIAttribute.ci_type_id == type_id)
        .order_by(HDCIAttribute.idx.asc().nullslast(), HDCIAttribute.name.asc())
        .all()
    )
    return {"attributes": [_attribute_row(a) for a in rows]}


@router.post("/types/{type_id}/attributes")
def create_ci_attribute(type_id: int, body: AttributeCreate, db: Session = Depends(get_db),
                         _: bool = Depends(require_settings_manage)):
    tid = tenant_id(db)
    _get_or_404(db, HDCIType, tid, type_id)
    name = (body.name or "").strip()
    if not name:
        raise HTTPException(status_code=400, detail="name is required")
    if db.query(HDCIAttribute).filter(HDCIAttribute.ci_type_id == type_id,
                                       HDCIAttribute.name == name).first():
        raise HTTPException(status_code=409, detail=f"attribute '{name}' already exists for this type")
    row = HDCIAttribute(
        ci_type_id=type_id,
        name=name,
        datatype=body.datatype or "string",
        required=bool(body.required),
        options=body.options,
        idx=body.idx,
    )
    db.add(row)
    db.commit()
    return {"ok": True, "id": row.id}


@router.patch("/attributes/{attribute_id}")
def update_ci_attribute(attribute_id: int, body: AttributeUpdate, db: Session = Depends(get_db),
                         _: bool = Depends(require_settings_manage)):
    tid = tenant_id(db)
    row = _get_attribute(db, tid, attribute_id)
    data = body.model_dump(exclude_unset=True)
    if "name" in data:
        new_name = (data["name"] or "").strip()
        if not new_name:
            raise HTTPException(status_code=400, detail="name is required")
        if db.query(HDCIAttribute).filter(HDCIAttribute.ci_type_id == row.ci_type_id,
                                           HDCIAttribute.name == new_name,
                                           HDCIAttribute.id != row.id).first():
            raise HTTPException(status_code=409, detail=f"attribute '{new_name}' already exists for this type")
        data["name"] = new_name
    for k, v in data.items():
        setattr(row, k, v)
    db.commit()
    return {"ok": True}


@router.delete("/attributes/{attribute_id}")
def delete_ci_attribute(attribute_id: int, db: Session = Depends(get_db),
                         _: bool = Depends(require_settings_manage)):
    tid = tenant_id(db)
    row = _get_attribute(db, tid, attribute_id)
    db.delete(row)
    db.commit()
    return {"ok": True}


# ═══════════════════════════════════════════════════════════════════════════
# Configuration Items (CIs)
# ═══════════════════════════════════════════════════════════════════════════
class CICreate(BaseModel):
    code: str
    name: str
    ci_type_id: Optional[int] = None
    business_service_id: Optional[int] = None
    status: Optional[str] = None
    criticality: Optional[str] = None
    environment: Optional[str] = None
    owner: Optional[str] = None
    ava_asset_id: Optional[int] = None
    attributes: Optional[dict] = None


class CIUpdate(BaseModel):
    code: Optional[str] = None
    name: Optional[str] = None
    ci_type_id: Optional[int] = None
    business_service_id: Optional[int] = None
    status: Optional[str] = None
    criticality: Optional[str] = None
    environment: Optional[str] = None
    owner: Optional[str] = None
    ava_asset_id: Optional[int] = None
    attributes: Optional[dict] = None


@router.get("/cis")
def list_cis(ci_type_id: Optional[int] = Query(None), business_service_id: Optional[int] = Query(None),
             db: Session = Depends(get_db), _: bool = Depends(require_settings_view)):
    tid = tenant_id(db)
    q = db.query(HDConfigurationItem).filter(HDConfigurationItem.tenant_id == tid)
    if ci_type_id is not None:
        q = q.filter(HDConfigurationItem.ci_type_id == ci_type_id)
    if business_service_id is not None:
        q = q.filter(HDConfigurationItem.business_service_id == business_service_id)
    rows = q.order_by(HDConfigurationItem.code.asc()).all()
    return {"cis": [_ci_row(c) for c in rows]}


@router.post("/cis")
def create_ci(body: CICreate, db: Session = Depends(get_db),
              _: bool = Depends(require_settings_manage)):
    tid = tenant_id(db)
    code = (body.code or "").strip()
    if not code:
        raise HTTPException(status_code=400, detail="code is required")
    if _dup_code(db, HDConfigurationItem, tid, code):
        raise HTTPException(status_code=409, detail=f"CI with code '{code}' already exists")
    _resolve_ci_type(db, tid, body.ci_type_id)
    _resolve_business_service(db, tid, body.business_service_id)
    row = HDConfigurationItem(
        tenant_id=tid,
        code=code,
        name=body.name,
        ci_type_id=body.ci_type_id,
        business_service_id=body.business_service_id,
        status=body.status or "in_use",
        criticality=body.criticality,
        environment=body.environment,
        owner=body.owner,
        ava_asset_id=body.ava_asset_id,
        attributes=body.attributes,
    )
    db.add(row)
    db.commit()
    return {"ok": True, "id": row.id}


@router.patch("/cis/{ci_id}")
def update_ci(ci_id: int, body: CIUpdate, db: Session = Depends(get_db),
              _: bool = Depends(require_settings_manage)):
    tid = tenant_id(db)
    row = _get_or_404(db, HDConfigurationItem, tid, ci_id)
    data = body.model_dump(exclude_unset=True)
    if "code" in data:
        new_code = (data["code"] or "").strip()
        if not new_code:
            raise HTTPException(status_code=400, detail="code is required")
        if _dup_code(db, HDConfigurationItem, tid, new_code, exclude_id=row.id):
            raise HTTPException(status_code=409, detail=f"CI with code '{new_code}' already exists")
        data["code"] = new_code
    if "ci_type_id" in data:
        _resolve_ci_type(db, tid, data["ci_type_id"])
    if "business_service_id" in data:
        _resolve_business_service(db, tid, data["business_service_id"])
    for k, v in data.items():
        setattr(row, k, v)
    db.commit()
    return {"ok": True}


@router.post("/cis/{ci_id}/retire")
def retire_ci(ci_id: int, db: Session = Depends(get_db),
              _: bool = Depends(require_settings_manage)):
    tid = tenant_id(db)
    row = _get_or_404(db, HDConfigurationItem, tid, ci_id)
    row.status = RETIRED
    db.commit()
    return {"ok": True}


# ═══════════════════════════════════════════════════════════════════════════
# Relationship Types
# ═══════════════════════════════════════════════════════════════════════════
class RelTypeCreate(BaseModel):
    code: str
    name: str
    inverse_name: Optional[str] = None


class RelTypeUpdate(BaseModel):
    code: Optional[str] = None
    name: Optional[str] = None
    inverse_name: Optional[str] = None


@router.get("/relationship-types")
def list_relationship_types(db: Session = Depends(get_db), _: bool = Depends(require_settings_view)):
    tid = tenant_id(db)
    rows = (
        db.query(HDCIRelationshipType)
        .filter(HDCIRelationshipType.tenant_id == tid)
        .order_by(HDCIRelationshipType.name.asc())
        .all()
    )
    return {"relationship_types": [_rel_type_row(r) for r in rows]}


@router.post("/relationship-types")
def create_relationship_type(body: RelTypeCreate, db: Session = Depends(get_db),
                              _: bool = Depends(require_settings_manage)):
    tid = tenant_id(db)
    code = (body.code or "").strip()
    if not code:
        raise HTTPException(status_code=400, detail="code is required")
    if _dup_code(db, HDCIRelationshipType, tid, code):
        raise HTTPException(status_code=409, detail=f"relationship type with code '{code}' already exists")
    row = HDCIRelationshipType(tenant_id=tid, code=code, name=body.name, inverse_name=body.inverse_name)
    db.add(row)
    db.commit()
    return {"ok": True, "id": row.id}


@router.patch("/relationship-types/{rel_type_id}")
def update_relationship_type(rel_type_id: int, body: RelTypeUpdate, db: Session = Depends(get_db),
                              _: bool = Depends(require_settings_manage)):
    tid = tenant_id(db)
    row = _get_or_404(db, HDCIRelationshipType, tid, rel_type_id)
    data = body.model_dump(exclude_unset=True)
    if "code" in data:
        new_code = (data["code"] or "").strip()
        if not new_code:
            raise HTTPException(status_code=400, detail="code is required")
        if _dup_code(db, HDCIRelationshipType, tid, new_code, exclude_id=row.id):
            raise HTTPException(status_code=409, detail=f"relationship type with code '{new_code}' already exists")
        data["code"] = new_code
    for k, v in data.items():
        setattr(row, k, v)
    db.commit()
    return {"ok": True}


# ═══════════════════════════════════════════════════════════════════════════
# Relationships (edges)
# ═══════════════════════════════════════════════════════════════════════════
class RelationshipCreate(BaseModel):
    source_ci_id: int
    target_ci_id: int
    rel_type_id: int


def _get_relationship_in_tenant(db: Session, tid: int, relationship_id: int) -> HDCIRelationship:
    row = (
        db.query(HDCIRelationship)
        .join(HDConfigurationItem, HDCIRelationship.source_ci_id == HDConfigurationItem.id)
        .filter(HDCIRelationship.id == relationship_id, HDConfigurationItem.tenant_id == tid)
        .first()
    )
    if not row:
        raise HTTPException(status_code=404, detail="not found")
    return row


@router.get("/relationships")
def list_relationships(db: Session = Depends(get_db), _: bool = Depends(require_settings_view)):
    tid = tenant_id(db)
    rows = (
        db.query(HDCIRelationship)
        .join(HDConfigurationItem, HDCIRelationship.source_ci_id == HDConfigurationItem.id)
        .filter(HDConfigurationItem.tenant_id == tid)
        .order_by(HDCIRelationship.id.asc())
        .all()
    )
    return {"relationships": [_relationship_row(r) for r in rows]}


@router.post("/relationships")
def create_relationship(body: RelationshipCreate, db: Session = Depends(get_db),
                         _: bool = Depends(require_settings_manage)):
    tid = tenant_id(db)
    _get_ci_in_tenant(db, tid, body.source_ci_id)
    _get_ci_in_tenant(db, tid, body.target_ci_id)
    _get_rel_type_in_tenant(db, tid, body.rel_type_id)

    existing = (
        db.query(HDCIRelationship)
        .filter(
            HDCIRelationship.source_ci_id == body.source_ci_id,
            HDCIRelationship.target_ci_id == body.target_ci_id,
            HDCIRelationship.rel_type_id == body.rel_type_id,
        )
        .first()
    )
    if existing:
        return {"ok": True, "id": existing.id}

    row = HDCIRelationship(
        source_ci_id=body.source_ci_id,
        target_ci_id=body.target_ci_id,
        rel_type_id=body.rel_type_id,
    )
    db.add(row)
    db.commit()
    return {"ok": True, "id": row.id}


@router.delete("/relationships/{relationship_id}")
def delete_relationship(relationship_id: int, db: Session = Depends(get_db),
                         _: bool = Depends(require_settings_manage)):
    tid = tenant_id(db)
    row = _get_relationship_in_tenant(db, tid, relationship_id)
    db.delete(row)
    db.commit()
    return {"ok": True}


# ═══════════════════════════════════════════════════════════════════════════
# Graph (tenant-scoped nodes + edges, for the React Flow CMDB map)
# ═══════════════════════════════════════════════════════════════════════════
@router.get("/graph")
def get_graph(db: Session = Depends(get_db), _: bool = Depends(require_settings_view)):
    tid = tenant_id(db)
    cis = db.query(HDConfigurationItem).filter(HDConfigurationItem.tenant_id == tid).all()
    nodes = [{
        "id": c.id,
        "code": c.code,
        "name": c.name,
        "ci_type_id": c.ci_type_id,
        "status": c.status,
    } for c in cis]

    rows = (
        db.query(HDCIRelationship)
        .join(HDConfigurationItem, HDCIRelationship.source_ci_id == HDConfigurationItem.id)
        .filter(HDConfigurationItem.tenant_id == tid)
        .all()
    )
    edges = [{
        "id": r.id,
        "source": r.source_ci_id,
        "target": r.target_ci_id,
        "rel_type_id": r.rel_type_id,
        "rel_name": r.rel_type.name if r.rel_type else None,
    } for r in rows]

    return {"nodes": nodes, "edges": edges}
