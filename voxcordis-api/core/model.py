import numpy as np
import joblib
import tensorflow as tf
from tensorflow.keras.models import load_model
from pathlib import Path

# ── Paths ─────────────────────────────────────────────────────────────
BASE_DIR    = Path(__file__).resolve().parent.parent
MODEL_PATH  = BASE_DIR / "models" / "voxcordis_best.h5"
SCALER_PATH = BASE_DIR / "models" / "scaler.pkl"

# ── Load model and scaler once at startup ─────────────────────────────
print("Loading Voxcordis model...")
classifier = load_model(MODEL_PATH)
print("Model loaded successfully.")

print("Loading scaler...")
scaler = joblib.load(SCALER_PATH)
print("Scaler loaded successfully.")


def predict(embedding: np.ndarray) -> dict:
    """
    Takes a 1024-dimensional embedding vector,
    applies normalization and runs inference.

    Returns:
        dict with keys:
            - class_id    : int   (0, 1 or 2)
            - confidence  : float (0-100)
            - probabilities : dict {Healthy, Laryngeal, Cardiac}
    """
    # ── Step 1 : Normalize embedding ──────────────────────────────────
    embedding_scaled = scaler.transform(embedding)  # shape (1, 1024)

    # ── Step 2 : Run inference ────────────────────────────────────────
    probabilities = classifier.predict(embedding_scaled, verbose=0)[0]

    # ── Step 3 : Extract results ──────────────────────────────────────
    class_id   = int(np.argmax(probabilities))
    confidence = float(probabilities[class_id] * 100)

    return {
        "class_id"      : class_id,
        "confidence"    : round(confidence, 2),
        "probabilities" : {
            "Healthy"   : round(float(probabilities[0]) * 100, 2),
            "Laryngeal" : round(float(probabilities[1]) * 100, 2),
            "Cardiac"   : round(float(probabilities[2]) * 100, 2),
        }
    }