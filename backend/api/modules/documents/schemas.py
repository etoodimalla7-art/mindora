from pydantic import BaseModel, Field


class DocumentOut(BaseModel):
    id: str
    title: str | None
    description: str | None
    category: str | None
    level: str | None
    language: str | None
    original_filename: str
    status: str

    class Config:
        from_attributes = True


class DocumentMetadataIn(BaseModel):
    title: str = Field(min_length=3, max_length=255)
    # Lower bound (500 words) is enforced by validate_description at the
    # service layer, since word-counting isn't a Pydantic-native check;
    # this upper bound is defense-in-depth so a pathologically huge
    # payload gets rejected before it reaches that logic at all.
    description: str = Field(max_length=50000)
    category: str
    level: str
    language: str


class DocumentExamMetadataIn(BaseModel):
    is_exam: bool
    exam_system: str | None = None
    exam_name: str | None = None
    exam_level: str | None = None
    exam_subject: str | None = None
    exam_year: int | None = None
    exam_session: str | None = None


class DocumentStatusOut(BaseModel):
    status: str
    problems: list[str] = []
    warnings: list[str] = []
