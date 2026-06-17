import io
import logging

import librosa
import numpy as np
import tensorflow as tf
import tensorflow_hub as hub

from core.config import TARGET_SR

logger = logging.getLogger(__name__)

# ── Constants ─────────────────────────────────────────────────────────
MIN_SAMPLES = TARGET_SR       # 1 second minimum
MAX_SAMPLES = TARGET_SR * 3   # 3 seconds maximum
RMS_TARGET  = 0.1             # target RMS level

# ── Load YAMNet once at startup ───────────────────────────────────────
logger.info("Loading YAMNet...")
yamnet_model = hub.load("https://tfhub.dev/google/yamnet/1")
logger.info("YAMNet loaded successfully.")


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
    waveform = tf.cast(y, tf.float32)
    _, embeddings, _ = yamnet_model(waveform)
    mean_emb = tf.reduce_mean(embeddings, axis=0).numpy()
    return mean_emb.reshape(1, -1)
