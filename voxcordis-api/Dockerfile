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
COPY requirements.txt .

# ── Install Python dependencies ───────────────────────────────────────
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# ── Copy project files ────────────────────────────────────────────────
COPY . .

# ── Expose port ───────────────────────────────────────────────────────
EXPOSE 8080

# ── Start the API ─────────────────────────────────────────────────────
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]