# FilmPost

FilmPost is a lightweight iOS MVP that acts like an AI photography coach. A user picks one **subject** photo and one **background** photo, taps **Analyze**, and receives three cinematic photo directions that help them stage a stronger image *before* the shutter clicks.

It is intentionally **not** a filter app. The product focuses on pose, framing, light, color mood, camera distance, and **director-led cinema references** so the output reads as creative direction, not post-processing advice.

## Screens

| Upload | Analyzing | Director results | Swipeable card |
| --- | --- | --- | --- |
| ![Upload](docs/screenshots/01-upload.png) | ![Analyzing](docs/screenshots/02-loading.png) | ![Results](docs/screenshots/03-results.png) | ![Card](docs/screenshots/04-card.png) |

## Architecture

```text
FilmPost/
├── backend/                  FastAPI service that talks to OpenAI
│   ├── app/
│   │   ├── main.py           POST /v1/analyze endpoint
│   │   ├── services.py       Pillow downscale + AsyncOpenAI client
│   │   ├── prompts.py        Coaching system prompt + director-reference prompt
│   │   ├── models.py         Pydantic response schema (the contract)
│   │   └── config.py         Env-driven settings
│   └── tests/                Pytest suite with stubbed OpenAI service
├── ios/
│   ├── FilmPost/             SwiftUI app: upload → loading → results
│   ├── FilmPostCore/         Swift package: typed models + multipart client
│   └── project.yml           XcodeGen spec (no .xcodeproj checked in)
└── docs/screenshots/         Captures used in this README
```

**Data flow:** the app reads two `PhotosPicker` images → `FilmPostCore` builds a `multipart/form-data` request → `POST /v1/analyze` downscales each image (Pillow, 1568px long edge) → `client.responses.parse(text_format=AnalysisResponse)` enforces a typed JSON contract with director notes + cinema references → app renders three swipeable cards.

## Tech Stack

- **iOS:** SwiftUI, PhotosPicker, `@Observable`, iOS 17+, XcodeGen
- **Backend:** Python 3.11+, FastAPI, Pydantic v2, OpenAI Python SDK, Pillow
- **AI:** OpenAI vision-capable model (`gpt-4o-mini` by default) with structured-output parsing — the Pydantic model *is* the response schema

## Quick Start (mentor path)

### Prerequisites

- macOS with **Xcode 16+** (full Xcode, not just Command Line Tools)
- **Python 3.11+**
- **XcodeGen** — `brew install xcodegen`
- An **OpenAI API key** with access to a vision-capable model

### 1. Clone

```bash
git clone https://github.com/easyrider11/FilmPost.git
cd FilmPost
```

### 2. Run the backend

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
cp .env.example .env
# open .env and paste your OPENAI_API_KEY
uvicorn app.main:app --reload
```

API serves at `http://127.0.0.1:8000`. Health check: `curl http://127.0.0.1:8000/health`.

### 3. Run the iOS app

In another terminal:

```bash
cd ios
xcodegen generate
open FilmPost.xcodeproj
```

In Xcode: pick **iPhone 16** (or any iOS 17+ simulator), press **⌘R**.

### Backend environment variables

| Variable | Purpose | Default |
| --- | --- | --- |
| `OPENAI_API_KEY` | Required for live analysis. Without it `/v1/analyze` returns 503. | *(unset)* |
| `OPENAI_MODEL` | Vision model used for parsing | `gpt-4o-mini` |
| `FILMPOST_MAX_UPLOAD_BYTES` | Upload cap per image | `8388608` (8 MB) |
| `FILMPOST_CORS_ORIGINS` | JSON list of allowed origins | `["http://127.0.0.1:8000","http://localhost:8000"]` |

### Tests

```bash
cd backend && source .venv/bin/activate && pytest -q
```

The suite uses a stubbed `AnalysisService` — no OpenAI key required.

## Running on a Physical Device or TestFlight

The default backend URL in [ios/FilmPost/Info.plist](ios/FilmPost/Info.plist) is `http://127.0.0.1:8000`, which only resolves on the simulator. For a real device or TestFlight build you must:

1. **Set a signing team.** Open [ios/project.yml](ios/project.yml) and fill in `DEVELOPMENT_TEAM` with your Apple Developer team ID, then re-run `xcodegen generate`.
2. **Point the app at a reachable backend.** Either:
   - **LAN dev:** replace `FilmPostAPIBaseURL` with `http://<your-mac-LAN-ip>:8000` and add an ATS exception, or
   - **TestFlight-grade:** deploy `backend/` behind HTTPS (Fly.io, Render, Cloud Run, etc.) and use that URL.
3. **Archive & upload.** Xcode → *Product → Archive*, then *Distribute App → App Store Connect → Upload*.
4. **Add internal testers** in App Store Connect → TestFlight.

## Design Notes

- The Pydantic `AnalysisResponse` model in [backend/app/models.py](backend/app/models.py) doubles as the contract sent to OpenAI via `responses.parse(text_format=...)` — there is no separate JSON-schema file to keep in sync.
- The system prompt in [backend/app/prompts.py](backend/app/prompts.py) now enforces *contrast across three directions* plus a **cinema-reference layer**: each recommendation must tie the location to a recognizable film scene or director signature and explain what to borrow from it.
- Each result card now has three reading layers: a **director note**, a **cinema anchor** (film + director + scene takeaway), and the tactical on-set details (pose, composition, color, distance, light).
- Sample images live in [ios/FilmPost/Resources/DebugSamples](ios/FilmPost/Resources/DebugSamples) — launch with the `-auto-demo` argument to skip the picker for quick demos.

## Verified

- `pytest -q` → **5 passed**
- `xcodegen generate` → builds a clean `FilmPost.xcodeproj`
- End-to-end run on iPhone 16 simulator (iOS 18) hitting a local backend with a real OpenAI key — the refreshed screenshots above were captured from the current live build.

## Known Limitations

- No persistence, history, or saved shoots.
- No live camera capture or on-device composition overlays.
- No authentication, analytics, or moderation layer.
- Backend base URL is configured at build time, not in-app.
- The MVP returns **textual film references**, not licensed still-image assets; this keeps the feature demoable without adding copyright or third-party asset dependencies.
- Placeholder app icon — fine for review, not branding.

## License

MIT — see [LICENSE](LICENSE) if added, otherwise treat as MIT for evaluation purposes.
