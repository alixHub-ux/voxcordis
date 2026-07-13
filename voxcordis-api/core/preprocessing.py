import io
import logging
import threading

import librosa
import numpy as np

from core.config import TARGET_SR

logger = logging.getLogger(__name__)

MIN_SAMPLES = TARGET_SR
MAX_SAMPLES = TARGET_SR * 3
RMS_TARGET  = 0.1

_yamnet_model = None
_tf = None
_lock = threading.Lock()


def _ensure_tf():
    global _tf
    if _tf is not None:
        return _tf

    with _lock:
        if _tf is not None:
            return _tf

        import tensorflow as tf
        _tf = tf

    return _tf


def _get_yamnet():
    global _yamnet_model
    if _yamnet_model is not None:
        return _yamnet_model

    with _lock:
        if _yamnet_model is not None:
            return _yamnet_model

        tf = _ensure_tf()
        import tensorflow_hub as hub

        logger.info("Loading YAMNet...")
        _yamnet_model = hub.load("https://tfhub.dev/google/yamnet/1")
        logger.info("YAMNet loaded successfully.")

    return _yamnet_model


def rms_normalize(y: np.ndarray) -> np.ndarray:
    rms = np.sqrt(np.mean(y ** 2))
    if rms > 0:
        y = y * (RMS_TARGET / rms)
    return y


def pad_truncate(y: np.ndarray) -> np.ndarray:
    if len(y) < MIN_SAMPLES:
        y = np.pad(y, (0, MIN_SAMPLES - len(y)), mode='constant')
    y = y[:MAX_SAMPLES]
    return y


def load_audio(file_bytes: bytes) -> np.ndarray:
    audio_io = io.BytesIO(file_bytes)
    y, _ = librosa.load(audio_io, sr=TARGET_SR, mono=True)
    y = rms_normalize(y)
    y = pad_truncate(y)
    return y


def extract_embedding(y: np.ndarray) -> np.ndarray:
    tf = _ensure_tf()
    yamnet = _get_yamnet()
    waveform = tf.cast(y, tf.float32)
    _, embeddings, _ = yamnet(waveform)
    mean_emb = tf.reduce_mean(embeddings, axis=0).numpy()
    return mean_emb.reshape(1, -1)
