import librosa
import numpy as np
import tensorflow as tf
import tensorflow_hub as hub

# ── Constants ─────────────────────────────────────────────────────────
TARGET_SR   = 16000       # YAMNet required sample rate
MIN_SAMPLES = TARGET_SR   # 1 second minimum
MAX_SAMPLES = TARGET_SR * 3  # 3 seconds maximum
RMS_TARGET  = 0.1         # target RMS level

# ── Load YAMNet once at startup ───────────────────────────────────────
print("Loading YAMNet...")
yamnet_model = hub.load("https://tfhub.dev/google/yamnet/1")
print("YAMNet loaded successfully.")


def rms_normalize(y: np.ndarray) -> np.ndarray:
    """
    Equalizes audio volume across recordings.
    Prevents the model from learning microphone
    power differences rather than actual pathological patterns.
    """
    rms = np.sqrt(np.mean(y ** 2))
    if rms > 0:
        y = y * (RMS_TARGET / rms)
    return y


def pad_truncate(y: np.ndarray) -> np.ndarray:
    """
    Ensures all audio arrays have the same length.
    - Shorter than 1s → padded with zeros
    - Longer than 3s  → truncated
    """
    if len(y) < MIN_SAMPLES:
        y = np.pad(y, (0, MIN_SAMPLES - len(y)), mode='constant')
    y = y[:MAX_SAMPLES]
    return y


def load_audio(file_bytes: bytes) -> np.ndarray:
    """
    Loads audio from bytes, resamples to 16kHz mono,
    applies RMS normalization and padding/truncation.
    Returns a clean numpy array ready for YAMNet.
    """
    import io
    audio_io = io.BytesIO(file_bytes)
    y, _ = librosa.load(audio_io, sr=TARGET_SR, mono=True)
    y = rms_normalize(y)
    y = pad_truncate(y)
    return y


def extract_embedding(y: np.ndarray) -> np.ndarray:
    """
    Passes audio through YAMNet and returns
    a single 1024-dimensional embedding vector
    via mean pooling across frames.
    """
    waveform = tf.cast(y, tf.float32)
    _, embeddings, _ = yamnet_model(waveform)
    mean_emb = tf.reduce_mean(embeddings, axis=0).numpy()
    return mean_emb.reshape(1, -1)  # shape (1, 1024)