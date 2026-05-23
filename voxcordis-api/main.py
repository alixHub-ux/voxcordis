from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from core.preprocessing import load_audio, extract_embedding
from core.model import predict
from core.risk import build_response
from schemas.response import PredictionResponse

# ── Run directly ──────────────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=True)

# ── App initialization ────────────────────────────────────────────────
app = FastAPI(
    title       = "Voxcordis API",
    description = (
        "REST API for cardiovascular risk screening "
        "through voice analysis. "
        "Powered by YAMNet + TensorFlow."
    ),
    version     = "1.0.0",
    contact     = {
        "name"  : "VEBAMBA A Carine",
        "email" : "carinecontact.dev@gmail.com"
    }
)

# ── CORS Middleware ───────────────────────────────────────────────────
# Allows the Android app and any frontend to call the API
app.add_middleware(
    CORSMiddleware,
    allow_origins     = ["*"],
    allow_credentials = True,
    allow_methods     = ["*"],
    allow_headers     = ["*"],
)


# ── Health check ──────────────────────────────────────────────────────
@app.get("/")
def root():
    """
    Health check endpoint.
    Returns API status and version.
    """
    return {
        "status"      : "online",
        "app"         : "Voxcordis API",
        "version"     : "1.0.0",
        "description" : "Cardiovascular risk screening through voice analysis"
    }


# ── Predict endpoint ──────────────────────────────────────────────────
@app.post("/predict", response_model=PredictionResponse)
async def predict_voice(file: UploadFile = File(...)):
    """
    Main prediction endpoint.

    Accepts a .wav audio file and returns a risk assessment.

    Pipeline :
        1. Load and preprocess audio (16kHz, RMS norm, 3s)
        2. Extract YAMNet embedding (1024 dimensions)
        3. Normalize with StandardScaler
        4. Run classifier inference
        5. Build risk-level response

    Args:
        file : UploadFile — audio file (.wav, .mp3, .m4a)

    Returns:
        PredictionResponse — risk level, message, advice, disclaimer
    """

    # ── Step 1 : Validate file format ─────────────────────────────────
    allowed_formats = ["audio/wav", "audio/mpeg",
                       "audio/mp4", "audio/x-wav",
                       "audio/wave", "application/octet-stream"]

    if file.content_type not in allowed_formats:
        raise HTTPException(
            status_code = 415,
            detail      = (
                f"Unsupported file format: {file.content_type}. "
                f"Please upload a .wav, .mp3 or .m4a file."
            )
        )

    # ── Step 2 : Read file bytes ───────────────────────────────────────
    try:
        file_bytes = await file.read()
    except Exception:
        raise HTTPException(
            status_code = 400,
            detail      = "Failed to read audio file. Please try again."
        )

    # ── Step 3 : Load and preprocess audio ────────────────────────────
    try:
        audio = load_audio(file_bytes)
    except Exception:
        raise HTTPException(
            status_code = 422,
            detail      = (
                "Failed to process audio file. "
                "Please ensure the file is a valid audio recording."
            )
        )

    # ── Step 4 : Extract YAMNet embedding ────────────────────────────
    try:
        embedding = extract_embedding(audio)
    except Exception:
        raise HTTPException(
            status_code = 500,
            detail      = "Failed to extract audio features."
        )

    # ── Step 5 : Run model inference ──────────────────────────────────
    try:
        prediction = predict(embedding)
    except Exception:
        raise HTTPException(
            status_code = 500,
            detail      = "Model inference failed. Please try again."
        )

    # ── Step 6 : Build and return response ────────────────────────────
    response = build_response(prediction)
    return response