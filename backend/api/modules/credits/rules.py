"""
Section 29: credit rules as pure functions. Subscribed users bypass
the credit balance entirely; everyone else needs at least
DOWNLOAD_COST credits to download a resource.
"""

DOWNLOAD_COST = 1
NEW_USER_FREE_CREDITS = 3
CONTRIBUTION_APPROVAL_BONUS = 5   # credits granted per threshold crossed
CONTRIBUTIONS_PER_BONUS = 5       # section 29: "contribute 5 approved documents"


def can_download(balance: int, has_active_subscription: bool) -> bool:
    return has_active_subscription or balance >= DOWNLOAD_COST


def credits_from_new_approvals(previous_approved_count: int, new_approved_count: int) -> int:
    """
    Section 29's "contribute 5 approved documents -> unlock more
    access" rule, expressed as a pure function: awards
    CONTRIBUTION_APPROVAL_BONUS credits every time the student's
    approved-contribution count crosses a multiple of
    CONTRIBUTIONS_PER_BONUS.

    NOT wired to any real trigger yet: no document can reach "Approved"
    status without the admin/moderation workflow (Phase 16), which
    doesn't exist. This function is written and tested now so it's
    ready to be called with real counts the moment that workflow calls
    it — rather than faking an approval trigger today just to exercise
    it end-to-end.
    """
    previous_bonuses = previous_approved_count // CONTRIBUTIONS_PER_BONUS
    new_bonuses = new_approved_count // CONTRIBUTIONS_PER_BONUS
    return (new_bonuses - previous_bonuses) * CONTRIBUTION_APPROVAL_BONUS
