# Build and test image for the Minesweeper kata (Python 3.12, pytest).
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# 1. Dependencies first: this layer is cached until requirements.txt changes.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 2. Source and tests change most often, so they are copied last.
COPY minesweeper/ minesweeper/
COPY tests/ tests/

# 3. Run as a non-root user.
RUN useradd --create-home kata
USER kata

# Default command: run the whole test suite.
CMD ["python", "-m", "pytest", "tests/", "-v", "--tb=short", "-p", "no:cacheprovider"]
