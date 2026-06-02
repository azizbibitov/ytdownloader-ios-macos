# Backend - Python FastAPI + yt-dlp

## Overview

The backend is a Python FastAPI server that handles YouTube video extraction and downloading. The iOS/macOS app calls this backend instead of trying to extract YouTube streams directly on-device.

**Why a backend?**
- yt-dlp runs on Python - it cannot run on iOS
- YouTube now only provides 360p as a combined (video+audio) stream on-device
- The backend can download video and audio streams separately and merge them using ffmpeg, giving access to all qualities (4K, 1080p, 720p, etc.)

---

## Architecture - 3-Tier

```
iOS App  →  HTTP (JSON)  →  Web Layer (main.py)
                                    ↓
                          Service Layer (downloader.py)
                                    ↓
                           Data Layer (storage.py)
                                    ↓
                         yt-dlp + File System
```

| File | Layer | Responsibility |
|---|---|---|
| `main.py` | Web | FastAPI routes - receives HTTP, returns HTTP |
| `downloader.py` | Service | Business logic - yt-dlp extraction and download |
| `storage.py` | Data | Task state and video info cache |
| `models.py` | Shared | Pydantic models used across all layers |

**Import rule:** dependencies only flow downward. `main.py` → `downloader.py` → `storage.py`. Never upward.

---

## API Endpoints

### `GET /health`
Keep-alive ping. Returns `{"status": "ok"}`.

---

### `GET /video-info?url=<youtube_url>`
Extracts video metadata and all available quality options.

**Request:**
```
GET /video-info?url=https://youtube.com/watch?v=dQw4w9WgXcQ
```

**Response:**
```json
{
  "id": "dQw4w9WgXcQ",
  "title": "Rick Astley - Never Gonna Give You Up",
  "thumbnail_url": "https://i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg",
  "channel": "Rick Astley",
  "duration": 212,
  "qualities": [
    {
      "format_id": "137+bestaudio/best[height=1080]",
      "label": "1080p",
      "ext": "mp4",
      "filesize": 98765432,
      "is_audio_only": false
    },
    {
      "format_id": "136+bestaudio/best[height=720]",
      "label": "720p",
      "ext": "mp4",
      "filesize": 54321678,
      "is_audio_only": false
    },
    {
      "format_id": "140",
      "label": "Audio 128kbps",
      "ext": "m4a",
      "filesize": 3456789,
      "is_audio_only": true
    }
  ]
}
```

Results are cached in memory per URL to avoid redundant yt-dlp calls.

---

### `POST /download`
Starts a download+merge job on the server. Returns a `task_id` immediately while the download runs in the background.

**Request body:**
```json
{
  "url": "https://youtube.com/watch?v=dQw4w9WgXcQ",
  "format_id": "137+bestaudio/best[height=1080]"
}
```

**Response:**
```json
{
  "task_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

---

### `GET /progress/<task_id>`
Poll this endpoint to track download progress.

**Response:**
```json
{
  "status": "downloading",
  "percent": 47.3,
  "speed": "2.50MiB/s",
  "eta": 12,
  "error": null
}
```

**Status values:**
| Status | Meaning |
|---|---|
| `pending` | Job queued, not started yet |
| `downloading` | yt-dlp actively downloading |
| `merging` | ffmpeg merging video + audio |
| `done` | File ready, call `/file/<task_id>` |
| `error` | Something failed, check `error` field |

---

### `GET /file/<task_id>`
Downloads the finished merged MP4 file. Only available when status is `done`.

After the file is served, it is automatically deleted from the server to free up disk space.

---

## Download Flow

```
iOS app                          Backend
  |                                 |
  |-- POST /download -------------> |
  |                    generates task_id
  |<-- { task_id } --------------- |
  |                    spawns background task
  |                    yt-dlp downloads video stream
  |                    yt-dlp downloads audio stream
  |-- GET /progress/task_id ------> |
  |<-- { status: "downloading" } -- |
  |        (repeat every second)
  |-- GET /progress/task_id ------> |
  |<-- { status: "merging" } ------ |
  |-- GET /progress/task_id ------> |
  |<-- { status: "done" } --------- |
  |                                 |
  |-- GET /file/task_id ----------> |
  |<-- MP4 file (streamed) -------- |
  |        (file deleted after serving)
```

---

## Local Development

**Requirements:** Python 3.11+, ffmpeg installed

```bash
cd python-backend-downloader

# Install dependencies
pip install -r requirements.txt

# Run locally
uvicorn main:app --reload --port 8000

# API docs available at:
# http://localhost:8000/docs
```

Update `apple-ios-macos/youtube-downloader/Shared/Config.swift`:
```swift
static let backendURL = "http://localhost:8000"
```

For testing on a real iPhone (same WiFi):
```bash
uvicorn main:app --host 0.0.0.0 --port 8000
```
Then use your Mac's local IP (e.g. `http://192.168.1.x:8000`) in `Config.swift`.

---

## Deployment - Hugging Face Spaces

The backend is deployed as a Docker container on Hugging Face Spaces (free tier).

**Specs:** 2 CPU cores, 16GB RAM, 50GB disk
**Sleep:** Goes to sleep after 48 hours of inactivity
**Keep-alive:** GitHub Actions pings `/health` every 12 hours (see `.github/workflows/keep-alive.yml`)

**Deploy steps:**
```bash
cd python-backend-downloader
git init
git remote add hf https://huggingface.co/spaces/YOUR_HF_USERNAME/yt-downloader-backend
git add .
git commit -m "Deploy backend"
git push hf main
```

After deploy, update `Config.swift`:
```swift
static let backendURL = "https://YOUR_HF_USERNAME-yt-downloader-backend.hf.space"
```

---

## Files

```
python-backend-downloader/
├── main.py          - Web layer: FastAPI routes
├── downloader.py    - Service layer: yt-dlp logic
├── storage.py       - Data layer: task state, file paths, cache
├── models.py        - Shared Pydantic models
├── Dockerfile       - Docker config for HF Spaces
├── README.md        - HF Spaces config (frontmatter)
└── requirements.txt
```
