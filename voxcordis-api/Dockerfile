# ── Base image ────────────────────────────────────────────────────────
FROM python:3.10-slim

# ── Set working directory ─────────────────────────────────────────────
WORKDIR /app

# ── Install system dependencies ───────────────────────────────────────
# libsndfile1 is required by librosa for audio file reading
RUN apt-get update && apt-get install -y \
    libsndfile1 \
    ffmpeg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ── Copy requirements first (Docker cache optimization) ───────────────
# NOTE: Build context is the monorepo root (voxcordis/)
# so files are prefixed with voxcordis-api/
COPY voxcordis-api/requirements.txt .

# ── Install Python dependencies ───────────────────────────────────────
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# ── Copy project files ────────────────────────────────────────────────
COPY voxcordis-api/ .

# ── Expose port ───────────────────────────────────────────────────────
EXPOSE 7860

# ── Start the API ─────────────────────────────────────────────────────
ENV PORT=7860
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT}"]
