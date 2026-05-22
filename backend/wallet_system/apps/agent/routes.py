from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from apps.core.database import get_session
from apps.auth.dependencies import get_current_active_user
from apps.auth import models as auth_models

from .schemas import AgentExecuteRequest, AgentExecuteResponse, AgentCapability
from .services import WalletAIAgentService

router = APIRouter(prefix="/agent", tags=["AI Agent"])


@router.get("/capabilities", response_model=list[AgentCapability])
def list_capabilities():
    return WalletAIAgentService.list_capabilities()


@router.post("/execute", response_model=AgentExecuteResponse)
def execute_agent_action(
    payload: AgentExecuteRequest,
    db: Session = Depends(get_session),
    current_user: auth_models.User = Depends(get_current_active_user),
):
    return WalletAIAgentService.execute(
        db=db,
        current_user=current_user,
        request=payload,
    )
