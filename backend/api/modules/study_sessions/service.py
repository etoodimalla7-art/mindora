from api.core.errors import NotFoundError, ValidationFailedError
from api.modules.study_sessions.repository import StudySessionsRepository


class StudySessionsService:
    def __init__(self, repo: StudySessionsRepository):
        self.repo = repo

    async def get_today(self, user_id: str):
        return await self.repo.get_today(user_id)

    async def start(self, session_id: str, user_id: str):
        session = await self.repo.get_by_id(session_id, user_id)
        if not session:
            raise NotFoundError("This study session no longer exists.")
        return session  # timer/session-interface state is client-side for now

    async def complete(self, session_id: str, user_id: str):
        session = await self.repo.get_by_id(session_id, user_id)
        if not session:
            raise NotFoundError("This study session no longer exists.")
        if session.status == "completed":
            raise ValidationFailedError("This session is already marked complete.")
        return await self.repo.set_status(session, "completed")

    async def skip(self, session_id: str, user_id: str):
        session = await self.repo.get_by_id(session_id, user_id)
        if not session:
            raise NotFoundError("This study session no longer exists.")
        return await self.repo.set_status(session, "missed")
