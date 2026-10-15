"""ORM models. Importing this package registers all models with Base.metadata."""
from app.models.conversation import Conversation, Message
from app.models.credit import CreditLedger, Download
from app.models.document import (
    Document,
    DocumentAnalysis,
    DocumentDuplicate,
    DescriptionValidation,
)
from app.models.document_chunk import DocumentChunk
from app.models.mock_exam import MockAnswer, MockExam, MockQuestion
from app.models.notification import (
    Device,
    Notification,
    NotificationPreference,
)
from app.models.plan import StudyPlan, StudySession
from app.models.progress import TopicProgress
from app.models.session import Session
from app.models.subscription import Payment, Plan, Subscription
from app.models.user import EducationProfile, Profile, User

__all__ = [
    "User",
    "Profile",
    "EducationProfile",
    "Session",
    "StudyPlan",
    "StudySession",
    "TopicProgress",
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
    "Plan",
    "Subscription",
    "Payment",
    "Device",
    "Notification",
    "NotificationPreference",
]
