import logging
import numpy as np
import joblib
import tensorflow as tf
import keras

# ── CORRECTION : Supprimer quantization_config avant le chargement ──
from keras.src.layers.core.dense import Dense as _Dense
_original_dense_init = _Dense.__init__

def _patched_dense_init(self, *args, **kwargs):
    kwargs.pop('quantization_config', None)  # On ignore ce paramètre
    return _original_dense_init(self, *args, **kwargs)

_Dense.__init__ = _patched_dense_init
# ─────────────────────────────────────────────────────────────────────

from tensorflow.keras.models import load_model

from core.config import MODEL_PATH, SCALER_PATH

logger = logging.getLogger(__name__)

# ── Chargement du modèle et du scaler au démarrage ───────────────────
logger.info("Chargement du modèle Voxcordis...")
classifier = load_model(MODEL_PATH, compile=False)

print("================================")
print("TensorFlow:", tf.__version__)
print("Keras:", keras.__version__)
print("TF Keras:", tf.keras.__version__)
print("================================")
logger.info("Modèle chargé avec succès.")

logger.info("Chargement du scaler...")
scaler = joblib.load(SCALER_PATH)
logger.info("Scaler chargé avec succès.")


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