import os
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

# Disable per-IP rate limiting before the FastAPI app is imported in any
# test. The limit lives at app import time (built from Settings), so we
# need this set before `from app.main import app` runs anywhere. Tests
# exercise the analyze endpoint in tight loops; without this we'd hit the
# 10/minute ceiling and start asserting against 429s instead of behaviour.
os.environ.setdefault("FILMPOST_RATE_LIMIT_ENABLED", "false")
