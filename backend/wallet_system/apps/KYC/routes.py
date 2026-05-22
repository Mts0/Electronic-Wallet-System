# apps/KYC/routes.py

from typing import List, Optional

from fastapi import APIRouter, Depends, status, Query, UploadFile, File, HTTPException
from sqlalchemy.orm import Session

from ..core.database import get_session
from ..auth.dependencies import get_current_active_user
from ..staff import models as staff_models
from . import schemas, models
from .services import KYCService, KYCFileStorage
from .dependencies import get_my_kyc, get_kyc_or_404, require_staff_with_permission

router = APIRouter(prefix="/kyc", tags=["KYC"])


# ========= جزء العميل =========

@router.get(
    "/my",
    response_model=schemas.UserKYCOut,
)
def get_my_kyc_info(
    kyc: models.UserKYC = Depends(get_my_kyc),
):
    return kyc


@router.post(
    "/me",
    response_model=schemas.UserKYCOut,
    status_code=status.HTTP_201_CREATED,
)
def submit_my_kyc(
    payload: schemas.UserKYCDraftCreate,  #  بيانات فقط
    db: Session = Depends(get_session),
    current_user=Depends(get_current_active_user),
):
    """
    الخطوة 1: تقديم/تحديث بيانات KYC فقط (بدون صور).
    - ينشئ أو يحدث سجل KYC بحالة DRAFT.
    """
    kyc = KYCService.submit_kyc_for_user(db, current_user.user_id, payload)
    return kyc


@router.patch(
    "/me",
    response_model=schemas.UserKYCOut,
)
def update_my_kyc(
    payload: schemas.UserKYCUpdate,  #  بيانات فقط
    db: Session = Depends(get_session),
    current_user=Depends(get_current_active_user),
):
    """
    تعديل بيانات KYC فقط (بدون صور). يعيد الحالة إلى DRAFT.
    """
    kyc = KYCService.update_kyc_for_user(db, current_user.user_id, payload)
    return kyc


@router.post(
    "/me/upload",
    response_model=schemas.UserKYCOut,
)
async def upload_my_kyc_images(
    id_front: UploadFile = File(...),
    id_back: UploadFile = File(...),
    selfie: UploadFile = File(...),
    db: Session = Depends(get_session),
    current_user=Depends(get_current_active_user),
):
    """
    الخطوة 2: رفع صور الهوية وربطها بسجل KYC الموجود.
    - يشترط وجود سجل KYC (تم إرسال البيانات أولاً).
    - بعد رفع الصور الثلاث -> تتحول الحالة إلى PENDING.
    """
    kyc = KYCService.get_by_user_id(db, current_user.user_id)
    if not kyc:
        raise HTTPException(status_code=400, detail="لا يوجد طلب KYC. أرسل البيانات أولًا عبر POST /kyc/me")

    if kyc.status == schemas.KYCStatus.APPROVED.value:
        raise HTTPException(status_code=400, detail="KYC معتمد مسبقًا، لا يمكن رفع صور جديدة.")

    #  نأخذ id_type من السجل نفسه (ولا نثق بالعميل)
    id_type_str = kyc.id_type  # مخزن كسلسلة في DB (مثل NATIONAL_ID)

    front_path = await KYCFileStorage.save_image(
        user_id=current_user.user_id, id_type=id_type_str, kind="front", file=id_front
    )
    back_path = await KYCFileStorage.save_image(
        user_id=current_user.user_id, id_type=id_type_str, kind="back", file=id_back
    )
    selfie_path = await KYCFileStorage.save_image(
        user_id=current_user.user_id, id_type=id_type_str, kind="selfie", file=selfie
    )

    #  تحديث DB
    kyc.id_front_image = front_path
    kyc.id_back_image = back_path
    kyc.selfie_image = selfie_path

    #  جاهز لمراجعة الموظف
    kyc.status = schemas.KYCStatus.PENDING.value
    kyc.rejection_reason = None
    kyc.verified_by = None
    kyc.verified_at = None

    db.add(kyc)
    db.commit()
    return KYCService.get_by_user_id(db, current_user.user_id)


# ========= جزء الموظف (STAFF) =========

@router.get(
    "",
    response_model=List[schemas.UserKYCOut],
)
def list_kyc_requests(
    status_filter: Optional[schemas.KYCStatus] = Query(None),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_session),
    staff: staff_models.Staff = Depends(require_staff_with_permission("view_kyc")),
):
    kycs = KYCService.list_all(
        db=db,
        status_filter=status_filter,
        limit=limit,
    )
    return kycs


@router.get(
    "/{kyc_id}",
    response_model=schemas.UserKYCOut,
)
def get_kyc_details(
    kyc: models.UserKYC = Depends(get_kyc_or_404),
    staff: staff_models.Staff = Depends(require_staff_with_permission("view_kyc")),
):
    return kyc


@router.post(
    "/{kyc_id}/review",
    response_model=schemas.UserKYCOut,
)
def review_kyc(
    payload: schemas.KYCReviewDecision,
    db: Session = Depends(get_session),
    kyc: models.UserKYC = Depends(get_kyc_or_404),
    staff: staff_models.Staff = Depends(require_staff_with_permission("review_kyc")),
):
    updated = KYCService.review_kyc(
        db=db,
        kyc=kyc,
        decision=payload,
        staff_id=staff.staff_id,
    )
    return updated