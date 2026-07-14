import logging
import threading

import numpy as np
import joblib

logger = logging.getLogger(__name__)

_classifier = None
_scaler = None
_lock = threading.Lock()


def _load():
    global _classifier, _scaler
    if _classifier is not None:
        return

    with _lock:
        if _classifier is not None:
            return

        import tensorflow as tf
        import keras

        # ── CORRECTION : Supprimer quantization_config avant le chargement ──
        from keras.src.layers.core.dense import Dense as _Dense
        _original_dense_init = _Dense.__init__

        def _patched_dense_init(self, *args, **kwargs):
            kwargs.pop('quantization_config', None)
            return _original_dense_init(self, *args, **kwargs)

        _Dense.__init__ = _patched_dense_init

        from tensorflow.keras.models import load_model
        from core.config import MODEL_PATH, SCALER_PATH

        logger.info("Chargement du modèle Voxcordis...")
        _classifier = load_model(MODEL_PATH, compile=False)

        print("================================")
        print("TensorFlow:", tf.__version__)
        print("Keras:", keras.__version__)
        print("TF Keras:", tf.keras.__version__)
        print("================================")
        logger.info("Modèle chargé avec succès.")

        logger.info("Chargement du scaler...")
        _scaler = joblib.load(SCALER_PATH)
        logger.info("Scaler chargé avec succès.")


def predict(embedding: np.ndarray) -> dict:
    _load()

    embedding_scaled = _scaler.transform(embedding)
    probabilities = _classifier.predict(embedding_scaled, verbose=0)[0]

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