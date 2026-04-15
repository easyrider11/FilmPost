# FilmPost

FilmPost is a lightweight iOS MVP that acts like an AI photography coach. A user selects one subject photo and one background photo, taps `Analyze`, and gets three cinematic photo directions that help them stage a stronger image before shooting.

It is intentionally not a filter app. The product focuses on pose, framing, light, color mood, and camera distance so the output feels like creative direction rather than post-processing advice.

## Architecture Overview

- `ios/FilmPost`: SwiftUI iOS app with the upload flow, loading state, and swipeable result cards.
- `ios/FilmPostCore`: small Swift package used by the app for typed models and multipart networking.
- `backend/app`: FastAPI API that accepts two uploads, calls OpenAI, validates the structured response, and returns JSON to the app.

## Tech Stack

- iOS: SwiftUI, PhotosPicker, Observation, XcodeGen, iOS 17+
- Backend: Python 3, FastAPI, Pydantic, OpenAI Python SDK
- AI: OpenAI vision-capable model with structured output parsing

## Repo Layout

```text
FilmPost/
├── backend/
│   ├── app/
│   └── tests/
├── ios/
│   ├── FilmPost/
│   ├── FilmPostCore/
│   └── project.yml
├── design.nd
└── README.md
```

## Running The Backend

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
cp .env.example .env
uvicorn app.main:app --reload
```

The API will start on `http://127.0.0.1:8000`.

### Backend Environment Variables

- `OPENAI_API_KEY`: required for real analysis requests
- `OPENAI_MODEL`: optional, defaults to `gpt-4o-mini`
- `FILMPOST_MAX_UPLOAD_BYTES`: optional upload cap, defaults to `8388608`
- `FILMPOST_CORS_ORIGINS`: optional JSON array of allowed origins, defaults to `["*"]`

### Backend Tests

```bash
cd backend
source .venv/bin/activate
pytest -q
```

## Running The iOS App

Generate the project from `xcodegen`, then open it in Xcode:

```bash
cd ios
xcodegen generate
open FilmPost.xcodeproj
```

Important local setup notes:

- The default backend URL is `http://127.0.0.1:8000` in [ios/FilmPost/Info.plist](/Users/PC/Documents/GitHub/FilmPost/ios/FilmPost/Info.plist:1). That works for the iOS Simulator when the backend runs on the same Mac.
- For a physical device, replace `FilmPostAPIBaseURL` with your Mac's LAN IP or a deployed HTTPS backend.
- `DEVELOPMENT_TEAM` is intentionally blank in [ios/project.yml](/Users/PC/Documents/GitHub/FilmPost/ios/project.yml:1). Add your Apple team before archiving or shipping to TestFlight.

## How The AI Flow Works

1. The app reads the chosen subject and background images from `PhotosPicker`.
2. `FilmPostCore` builds a multipart request with `subject_image` and `background_image`.
3. `POST /v1/analyze` receives both uploads.
4. The backend sends both images plus a coaching-focused system prompt to OpenAI.
5. OpenAI returns structured JSON parsed into a typed `AnalysisResponse`.
6. The app renders the three recommendations as horizontally swipeable cards.

## Verification Notes

- Backend tests pass locally: `5 passed`.
- `swift build` succeeds for the `FilmPostCore` package.
- Full `swift test` / `xcodebuild` execution is currently blocked on this machine because the active developer directory points to Command Line Tools instead of a full Xcode SDK.

## Known Limitations

- No persistence, history, or saved shoots yet.
- No live camera capture or on-device composition overlays.
- No authentication, analytics, or moderation layer in this MVP.
- The iOS app currently relies on a manually configured backend base URL for device testing.
- The placeholder app icon is suitable for demos but not final branding.

## What Is Left For A Full TestFlight Release

- Add a valid `OPENAI_API_KEY` in `backend/.env`.
- Set the Xcode signing team and bundle details.
- Point the app at a stable HTTPS backend for device and beta testing.
- Add privacy copy, analytics, crash reporting, and request logging.
- Run full iOS build and test passes from a machine with Xcode selected via `xcode-select`.
