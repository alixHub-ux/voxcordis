import logging

import numpy as np
import joblib
from tensorflow.keras.models import load_model

from core.config import MODEL_PATH, SCALER_PATH

logger = logging.getLogger(__name__)

# ── Load model and scaler once at startup ─────────────────────────────
logger.info("Loading Voxcordis model...")
classifier = load_model(MODEL_PATH, compile=False)
logger.info("Model loaded successfully.")

logger.info("Loading scaler...")
scaler = joblib.load(SCALER_PATH)
logger.info("Scaler loaded successfully.")


def predict(embedding: np.ndarray) -> dict:
    embedding_scaled = scaler.transform(embedding)
    probabilities = classifier.predict(embedding_scaled, verbose=0)[0]

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
