from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.db import get_db
from api.core.errors import envelope
from api.core.serialization import orm_to_dict
from api.modules.catalog.repository import CatalogRepository
from api.modules.catalog.schemas import SubjectOut

router = APIRouter(prefix="/catalog", tags=["catalog"])


@router.get("/subjects")
async def list_subjects(
    education_system: str | None = Query(default=None),
    level: str | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
):
    repo = CatalogRepository(db)
    subjects = await repo.list_subjects(education_system, level)
    return envelope(data=[SubjectOut.model_validate(orm_to_dict(s)).model_dump() for s in subjects])
