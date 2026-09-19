from pydantic import BaseModel


class SubjectOut(BaseModel):
    id: str
    name: str
    education_system: str
    level: str

    class Config:
        from_attributes = True


class TopicOut(BaseModel):
    id: str
    title: str
    order_index: int

    class Config:
        from_attributes = True
