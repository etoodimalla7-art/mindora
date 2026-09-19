from pydantic import BaseModel


class PastPaperOut(BaseModel):
    id: str
    title: str
    level: str
    year: int
    session: str | None
    subject_name: str
    examination_name: str
    country: str
    system: str
    is_bookmarked: bool = False


class PastPaperFiltersOut(BaseModel):
    countries: list[str]
    systems: list[str]
    levels: list[str]
    subjects: list[str]
    years: list[int]
