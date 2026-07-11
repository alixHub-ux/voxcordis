from fastapi import APIRouter, Depends, File, UploadFile, HTTPException
from sqlalchemy.orm import Session
import json
import logging

from db import get_session
from db_models import Analysis
from core.preprocessing import load_audio, extract_embedding
from core.model import predict
from core.risk import build_response
from core.auth import get_current_user
from core.config import MAX_FILE_SIZE, ALLOWED_FORMATS

router = APIRouter()
logger = logging.getLogger(__name__)


@router.post("/predict")
async def predict_endpoint(file: UploadFile = File(...), session: Session = Depends(get_session), current_user = Depends(get_current_user)):
    content_type = file.content_type or "application/octet-stream"
    if content_type not in ALLOWED_FORMATS:
        if content_type == "application/octet-stream":
            filename = file.filename or ""
            if not filename.lower().endswith((".wav", ".mp3", ".mp4", ".m4a", ".wave")):
                raise HTTPException(status_code=415, detail=f"Unsupported file format: {content_type}")
        else:
            raise HTTPException(status_code=415, detail=f"Unsupported file format: {content_type}")
    file_bytes = await file.read()
    if len(file_bytes) > MAX_FILE_SIZE:
        raise HTTPException(status_code=413, detail=f"File too large ({len(file_bytes)} bytes)")

    try:
        audio = load_audio(file_bytes)
        embedding = extract_embedding(audio)
        prediction = predict(embedding)
    except Exception as exc:
        logger.error("Prediction failed: %s", exc)
        raise HTTPException(status_code=500, detail=str(exc))

    # persist analysis metadata (never store raw audio)
    analysis = Analysis(
        user_id = current_user.id,
        class_id = int(prediction["class_id"]),
        confidence = float(prediction["confidence"]),
        probabilities = json.dumps(prediction.get("probabilities", {}))
    )
    session.add(analysis)
    session.commit()
    session.refresh(analysis)

    response = build_response(prediction)

    risk_mapping = {"LOW": 0, "LOW_MEDIUM": 1, "MEDIUM": 2, "WATCH": 2, "HIGH": 2, "UNCERTAIN": 0}
    return {
        "id": analysis.id,
        "predicted_class": int(prediction["class_id"]),
        "confidence": float(prediction["confidence"]),
        "risk_level_index": risk_mapping.get(response["risk_level"], 0),
        "model_version": "1.1.0",
        "result": response,
        "probabilities": prediction.get("probabilities", {}),
    }


@router.get("/history")
def history(session: Session = Depends(get_session), current_user = Depends(get_current_user)):
    results = session.query(Analysis).filter(Analysis.user_id == current_user.id).order_by(Analysis.created_at.desc()).all()
    return [{"id": r.id, "class_id": r.class_id, "confidence": r.confidence, "probabilities": json.loads(r.probabilities), "created_at": r.created_at.isoformat()} for r in results]


@router.get("/{analysis_id}")
def get_analysis(analysis_id: int, session: Session = Depends(get_session), current_user = Depends(get_current_user)):
    analysis = session.query(Analysis).filter(Analysis.id == analysis_id).first()
    if not analysis or analysis.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Analysis not found")
    return {"id": analysis.id, "class_id": analysis.class_id, "confidence": analysis.confidence, "probabilities": json.loads(analysis.probabilities), "created_at": analysis.created_at.isoformat()}
