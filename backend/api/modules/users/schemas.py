from datetime import date
from pydantic import BaseModel


class UserOut(BaseModel):
    id: str
    email: str
    locale: str
    role: str

    class Config:
        from_attributes = True


class EducationProfileIn(BaseModel):
    country: str
    education_system: str
    level: str
    program: str | None = None
    target_exam: str | None = None
    target_exam_date: date | None = None


class EducationProfileOut(EducationProfileIn):
    class Config:
        from_attributes = True
