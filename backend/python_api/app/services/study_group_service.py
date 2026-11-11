"""Study Groups service — CRUD, membership, messages (Phase 13)."""
from __future__ import annotations

import logging
import uuid
from datetime import datetime

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.errors import ForbiddenError, NotFoundError
from app.models.study_group import GroupMessage, StudyGroup, StudyGroupMember
from app.models.user import User
from app.schemas.study_group import (
    GroupMessageCreate,
    GroupMessageOut,
    StudyGroupCreate,
    StudyGroupMemberOut,
    StudyGroupOut,
)

logger = logging.getLogger(__name__)


class StudyGroupService:
    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    # ---------- Groups ----------

    async def create_group(
        self, user_id: uuid.UUID, payload: StudyGroupCreate
    ) -> StudyGroupOut:
        group = StudyGroup(
            name=payload.name.strip(),
            description=payload.description,
            exam_system=payload.exam_system,
            exam_level=payload.exam_level,
            subject=payload.subject,
            creator_id=user_id,
            is_private=payload.is_private,
            member_count=1,
        )
        self.session.add(group)
        await self.session.flush()
        self.session.add(StudyGroupMember(group_id=group.id, user_id=user_id))
        await self.session.commit()
        await self.session.refresh(group)
        out = StudyGroupOut.model_validate(group)
        out.is_member = True
        return out

    async def list_groups(
        self,
        user_id: uuid.UUID,
        *,
        subject: str | None = None,
        exam_system: str | None = None,
        exam_level: str | None = None,
        search: str | None = None,
        only_mine: bool = False,
        limit: int = 50,
        offset: int = 0,
    ) -> list[StudyGroupOut]:
        stmt = select(StudyGroup).where(StudyGroup.is_private.is_(False))
        if only_mine:
            stmt = stmt.join(
                StudyGroupMember,
                and_(
                    StudyGroupMember.group_id == StudyGroup.id,
                    StudyGroupMember.user_id == user_id,
                ),
            )
        if subject:
            stmt = stmt.where(StudyGroup.subject == subject)
        if exam_system:
            stmt = stmt.where(StudyGroup.exam_system == exam_system)
        if exam_level:
            stmt = stmt.where(StudyGroup.exam_level == exam_level)
        if search:
            pattern = f"%{search.strip()}%"
            stmt = stmt.where(StudyGroup.name.ilike(pattern))
        stmt = (
            stmt.order_by(StudyGroup.member_count.desc(), StudyGroup.created_at.desc())
            .limit(limit)
            .offset(offset)
        )

        rows = list((await self.session.execute(stmt)).scalars().all())
        if not rows:
            return []

        # Batch-check membership for all groups in a single query
        group_ids = [g.id for g in rows]
        my_memberships = set(
            (
                await self.session.execute(
                    select(StudyGroupMember.group_id).where(
                        StudyGroupMember.user_id == user_id,
                        StudyGroupMember.group_id.in_(group_ids),
                    )
                )
            ).scalars().all()
        )

        out_list: list[StudyGroupOut] = []
        for g in rows:
            out = StudyGroupOut.model_validate(g)
            out.is_member = g.id in my_memberships
            out_list.append(out)
        return out_list

    async def get_group(
        self, user_id: uuid.UUID, group_id: uuid.UUID
    ) -> StudyGroupOut:
        group = await self._get_or_404(group_id)
        out = StudyGroupOut.model_validate(group)
        out.is_member = await self._is_member(user_id, group_id)
        return out

    async def delete_group(self, user_id: uuid.UUID, group_id: uuid.UUID) -> None:
        group = await self._get_or_404(group_id)
        if group.creator_id != user_id:
            raise ForbiddenError("Only the creator can delete this group.")
        await self.session.delete(group)
        await self.session.commit()

    # ---------- Membership ----------

    async def list_members(
        self, group_id: uuid.UUID
    ) -> list[StudyGroupMemberOut]:
        await self._get_or_404(group_id)
        stmt = (
            select(StudyGroupMember)
            .options(selectinload(StudyGroupMember.user).selectinload(User.profile))
            .where(StudyGroupMember.group_id == group_id)
            .order_by(StudyGroupMember.joined_at.asc())
        )
        rows = list((await self.session.execute(stmt)).scalars().all())
        result: list[StudyGroupMemberOut] = []
        for m in rows:
            u = m.user
            result.append(
                StudyGroupMemberOut(
                    user_id=u.id,
                    full_name=u.full_name,
                    email=u.email,
                    avatar_url=(u.profile.avatar_url if u.profile else None),
                    joined_at=m.joined_at,
                )
            )
        return result

    async def join_group(
        self, user_id: uuid.UUID, group_id: uuid.UUID
    ) -> StudyGroupOut:
        group = await self._get_or_404(group_id)
        if await self._is_member(user_id, group_id):
            out = StudyGroupOut.model_validate(group)
            out.is_member = True
            return out

        self.session.add(StudyGroupMember(group_id=group_id, user_id=user_id))
        group.member_count = (group.member_count or 0) + 1
        await self.session.commit()
        await self.session.refresh(group)
        out = StudyGroupOut.model_validate(group)
        out.is_member = True
        return out

    async def leave_group(self, user_id: uuid.UUID, group_id: uuid.UUID) -> None:
        group = await self._get_or_404(group_id)
        membership = (
            await self.session.execute(
                select(StudyGroupMember).where(
                    and_(
                        StudyGroupMember.group_id == group_id,
                        StudyGroupMember.user_id == user_id,
                    )
                )
            )
        ).scalar_one_or_none()
        if membership is None:
            raise NotFoundError("You are not a member of this group.")
        await self.session.delete(membership)
        group.member_count = max((group.member_count or 1) - 1, 0)
        await self.session.commit()

    # ---------- Messages ----------

    async def list_messages(
        self,
        user_id: uuid.UUID,
        group_id: uuid.UUID,
        *,
        limit: int = 50,
        before: datetime | None = None,
    ) -> list[GroupMessageOut]:
        await self._assert_member(user_id, group_id)
        stmt = (
            select(GroupMessage)
            .options(selectinload(GroupMessage.user))
            .where(GroupMessage.group_id == group_id)
        )
        if before:
            stmt = stmt.where(GroupMessage.created_at < before)
        stmt = stmt.order_by(GroupMessage.created_at.desc()).limit(limit)
        rows = list((await self.session.execute(stmt)).scalars().all())
        rows.reverse()
        return [self._message_to_out(m) for m in rows]

    async def post_message(
        self,
        user_id: uuid.UUID,
        group_id: uuid.UUID,
        payload: GroupMessageCreate,
    ) -> GroupMessageOut:
        await self._assert_member(user_id, group_id)
        msg = GroupMessage(
            group_id=group_id,
            user_id=user_id,
            content=payload.content.strip(),
        )
        self.session.add(msg)
        await self.session.commit()
        await self.session.refresh(msg)
        loaded = (
            await self.session.execute(
                select(GroupMessage)
                .options(selectinload(GroupMessage.user))
                .where(GroupMessage.id == msg.id)
            )
        ).scalar_one()
        return self._message_to_out(loaded)

    # ---------- Helpers ----------

    async def _get_or_404(self, group_id: uuid.UUID) -> StudyGroup:
        group = (
            await self.session.execute(
                select(StudyGroup).where(StudyGroup.id == group_id)
            )
        ).scalar_one_or_none()
        if group is None:
            raise NotFoundError("Study group not found.")
        return group

    async def _is_member(self, user_id: uuid.UUID, group_id: uuid.UUID) -> bool:
        found = (
            await self.session.execute(
                select(StudyGroupMember.id).where(
                    and_(
                        StudyGroupMember.group_id == group_id,
                        StudyGroupMember.user_id == user_id,
                    )
                )
            )
        ).scalar_one_or_none()
        return found is not None

    async def _assert_member(self, user_id: uuid.UUID, group_id: uuid.UUID) -> None:
        if not await self._is_member(user_id, group_id):
            raise ForbiddenError("You must join this group first.")

    @staticmethod
    def _message_to_out(m: GroupMessage) -> GroupMessageOut:
        out = GroupMessageOut.model_validate(m)
        if m.user is not None:
            out.user_name = m.user.full_name or m.user.email
        return out
