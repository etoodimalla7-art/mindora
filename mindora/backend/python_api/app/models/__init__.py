"""ORM models. Importing this package registers all models with Base.metadata."""
from app.models.ai_config import AIConfig, AIConfigVersion
from app.models.analytics_event import AnalyticsEvent
from app.models.audit_log import AuditLog
from app.models.content import ContentString, BroadcastNotification
from app.models.curriculum import Announcement, Chapter, Subject
from app.models.conversation import Conversation, Message
from app.models.credit import CreditLedger, Download
from app.models.direct_message import DirectConversation, DirectMessage
from app.models.document import (
    Document,
    DocumentAnalysis,
    DocumentDuplicate,
    DescriptionValidation,
)
from app.models.document_chunk import DocumentChunk
from app.models.exam_read_request import ExamReadRequest
from app.models.mock_exam import MockAnswer, MockExam, MockQuestion
from app.models.otp_code import OTPCode
from app.models.flashcard import FlashcardDeck, Flashcard
from app.models.notification import (
    Device,
    Notification,
    NotificationPreference,
    NotificationRule,
)
from app.models.paper import Paper
from app.models.plan import StudyPlan, StudySession
from app.models.progress import TopicProgress, UserProgress
from app.models.role import Role, UserRole
from app.models.session import Session
from app.models.subscription import Payment, Plan, Subscription
from app.models.user import EducationProfile, Profile, User
from app.models.study_group import StudyGroup, StudyGroupMember, GroupMessage
from app.models.support import SupportMessage, SupportTicket
from app.models.security import AdminLoginHistory, SecurityAlert
from app.models.app_settings import AppSetting, FeatureFlag

__all__ = [
    "User",
    "Profile",
    "EducationProfile",
    "Session",
    "StudyPlan",
    "StudySession",
    "TopicProgress",
    "UserProgress",
    "Document",
    "DocumentAnalysis",
    "DocumentDuplicate",
    "DescriptionValidation",
    "DocumentChunk",
    "CreditLedger",
    "Download",
    "Conversation",
    "Message",
    "MockExam",
    "MockQuestion",
    "MockAnswer",
    "Paper",
    "Plan",
    "Subscription",
    "Payment",
    "Device",
    "OTPCode",
    "FlashcardDeck",
    "Flashcard",
    "Notification",
    "NotificationPreference",
    "StudyGroup",
    "StudyGroupMember",
    "GroupMessage",
    "DirectConversation",
    "DirectMessage",
    "Role",
    "UserRole",
    "AuditLog",
    "AIConfig",
    "AIConfigVersion",
    "ContentString",
    "BroadcastNotification",

    "SupportTicket",
    "SupportMessage",

    "AdminLoginHistory",
    "SecurityAlert",

    "AppSetting",
    "FeatureFlag",
    "AnalyticsEvent",
    "Subject",
    "Chapter",
    "Announcement",
    "ExamReadRequest",
]
