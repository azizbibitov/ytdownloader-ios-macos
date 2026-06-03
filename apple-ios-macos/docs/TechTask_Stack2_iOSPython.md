# Technical Task — YouTube Downloader (Stack 2: iOS + Python Backend)

## Overview
A native iOS app that communicates with a local Python FastAPI backend running yt-dlp. The backend handles all downloading and merging (including 1080p), and streams the finished file back to the iOS app. Best for learning full-stack mobile development.

---

## Tech Stack

| Layer | Technology |
|---|---|
| iOS UI | SwiftUI |
| iOS Networking | URLSession |
| iOS Playback | AVPlayer / AVKit |
| iOS Storage | FileManager |
| iOS Architecture | MVVM |
| Backend Language | Python 3.11+ |
| Backend Framework | FastAPI |
| YouTube Engine | yt-dlp |
| Task Queue | Background asyncio tasks |
| File Serving | FastAPI StreamingResponse |

---

## Architecture

```
SwiftUI Views
    ↓
ViewModels (ObservableObject)
    ↓
APIClient (URLSession)
    ↓ HTTP REST
FastAPI Backend (localhost:8000)
    ↓
yt-dlp
    ↓
Downloaded + Merged File
    ↓ StreamingResponse
Back to iOS → FileManager → AVPlayer
```

---

## Backend API

### Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/info?url=` | Fetch video metadata |
| POST | `/download` | Start download task |
| GET | `/progress/{task_id}` | Poll download progress |
| GET | `/file/{task_id}` | Stream file to iOS |
| DELETE | `/task/{task_id}` | Cancel and clean up |

### Request / Response Examples

**GET /info**
```json
// Response
{
  "title": "Video Title",
  "thumbnail": "https://...",
  "duration": 312,
  "channel": "Channel Name",
  "qualities": [
    { "format_id": "137", "quality": "1080p", "ext": "mp4", "filesize": 104857600 },
    { "format_id": "136", "quality": "720p",  "ext": "mp4", "filesize": 52428800  },
    { "format_id": "135", "quality": "480p",  "ext": "mp4", "filesize": 26214400  },
    { "format_id": "140", "quality": "Audio", "ext": "m4a", "filesize": 5242880   }
  ]
}
```

**POST /download**
```json
// Request
{ "url": "https://youtube.com/watch?v=...", "format_id": "137" }

// Response
{ "task_id": "abc123" }
```

**GET /progress/{task_id}**
```json
{
  "status": "downloading",  // "pending" | "downloading" | "merging" | "done" | "error"
  "percent": 67.4,
  "speed": "2.3 MB/s",
  "eta": 14
}
```

---

## Backend Code Structure

```
backend/
├── main.py              # FastAPI app, routes
├── downloader.py        # yt-dlp wrapper, task management
├── models.py            # Pydantic request/response models
├── requirements.txt
└── downloads/           # Temp folder for downloaded files
```

**requirements.txt**
```
fastapi
uvicorn
yt-dlp
python-multipart
```

**Run backend:**
```bash
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

---

## Screens

### Screen 1 — Home / Search
**Purpose:** Entry point. User pastes a YouTube URL and fetches video info.

**Elements:**
- App logo / title at top
- Rounded text field with YouTube URL placeholder
- Paste button inside text field
- "Fetch Video" primary button
- Loading skeleton while fetching from backend
- Video card after fetch:
  - Thumbnail (rounded corners, shadow)
  - Title (2 lines max, bold)
  - Duration badge (top-right corner of thumbnail)
  - Channel name (secondary text)
  - "Download" button

**Design Notes:**
- Dark background (#0F0F0F)
- Red accent (#FF0000) for buttons
- Thumbnail with 12pt corner radius
- Duration badge: dark semi-transparent pill overlaid on thumbnail
- Error state: red inline message below text field (invalid URL etc.)
- Keyboard dismisses on tap outside

---

### Screen 2 — Quality Picker (Bottom Sheet)
**Purpose:** User selects download quality before starting backend download.

**Elements:**
- Handle bar at top
- "Choose Quality" title
- Quality rows:
  - Icon (video/audio SF Symbol)
  - Quality label (1080p HD, 720p, 480p, Audio Only)
  - File size (from backend response)
  - Checkmark when selected
- "Start Download" full-width button at bottom
- Note: "1080p requires merging video + audio (handled automatically)"

**Design Notes:**
- `.presentationDetents([.medium])`
- Selected row: red accent tint background (10% opacity)
- Dividers between rows (subtle, #2A2A2A)
- File sizes in secondary gray text
- Button disabled until quality selected

---

### Screen 3 — Downloads
**Purpose:** Shows active and completed downloads. Polls backend for progress.

**Elements:**
- Segmented control: "Active" / "Completed"
- **Active tab:**
  - Card per download:
    - Thumbnail + title
    - Status label ("Downloading..." / "Merging video+audio...")
    - Animated progress bar
    - Speed + ETA label
    - Cancel button
- **Completed tab:**
  - List rows:
    - Thumbnail + title + file size + download date
    - Tap → open Player
    - Swipe left → Delete
    - Swipe right → Share

**Design Notes:**
- Poll `/progress/{task_id}` every 1 second using `Timer.publish`
- Progress bar animated smoothly with `withAnimation`
- "Merging..." status shown in orange (different from downloading red)
- Empty state: illustration + "No downloads yet"
- Cards: #1A1A1A surface, 12pt radius, subtle shadow

---

### Screen 4 — Player
**Purpose:** Full-screen in-app video playback from local file.

**Elements:**
- AVPlayer fullscreen
- Custom overlay controls:
  - Play / Pause (center)
  - Seek bar with current time / duration
  - Rewind 10s / Forward 10s
  - Share button (top right)
  - Save to Files button (top right)
  - Close button (top left)
- Double tap left/right: seek ±10s
- Tap anywhere: toggle controls visibility

**Design Notes:**
- Controls auto-hide after 3 seconds of inactivity
- Fade in/out animation for controls overlay
- Seek bar: red thumb, white track
- Support landscape and portrait
- Hide status bar in fullscreen

---

## Features

**iOS App:**
- Fetch video metadata via backend
- Select quality
- Start download on backend, receive task_id
- Poll progress every 1 second
- Download finished file from backend to local storage
- Background download support
- Cancel active download (calls DELETE endpoint)
- In-app AVPlayer playback
- Share / Save to Files
- Persist completed downloads list (CoreData or UserDefaults)
- Swipe to delete local file

**Backend:**
- Fetch video info with yt-dlp
- Download video in selected quality
- Auto-merge video+audio for 1080p (yt-dlp handles this with FFmpeg)
- Track progress per task_id
- Serve file as streaming response
- Auto-cleanup temp files after serving

---

## Design System

| Token | Value |
|---|---|
| Background | #0F0F0F |
| Surface | #1A1A1A |
| Surface Elevated | #252525 |
| Accent | #FF0000 |
| Warning | #FF9500 |
| Text Primary | #FFFFFF |
| Text Secondary | #AAAAAA |
| Divider | #2A2A2A |
| Corner Radius | 12pt |
| Font | SF Pro (system default) |

---

## iOS Folder Structure

```
YouTubeDownloader/
├── App/
│   └── YouTubeDownloaderApp.swift
├── Views/
│   ├── HomeView.swift
│   ├── QualityPickerSheet.swift
│   ├── DownloadsView.swift
│   └── PlayerView.swift
├── ViewModels/
│   ├── HomeViewModel.swift
│   └── DownloadsViewModel.swift
├── Services/
│   ├── APIClient.swift         # All HTTP calls to backend
│   └── DownloadService.swift   # URLSession file download
├── Models/
│   ├── VideoInfo.swift
│   ├── DownloadTask.swift
│   └── QualityOption.swift
└── Utils/
    ├── FileManager+Extensions.swift
    └── DateFormatter+Extensions.swift
```

---

## What You Learn

**iOS side:**
- SwiftUI MVVM architecture
- URLSession for REST API calls + file downloading
- Timer-based polling for progress
- AVKit / AVPlayer for video playback
- FileManager for local file storage
- Bottom sheets, swipe actions, segmented controls

**Backend side:**
- FastAPI REST API design
- yt-dlp integration (the industry standard YouTube downloader)
- Async task management in Python
- Streaming file responses
- Background task handling

---

## Figma Design Recommendations

- Design for iPhone 15 Pro frame (393 x 852pt)
- Use Auto Layout (not fixed positions)
- Create a Figma color styles library from the design system above
- Design all 4 screens + empty states + error states
- Use SF Symbols plugin for icons (matches iOS exactly)
- Add a component for the download card (used in both active and completed)
- Design the bottom sheet as a separate component
- Show skeleton loading state for Home screen fetch
- Add progress bar component with red fill
- Export assets as PDF vector for Xcode
- Prototype the flow: Home → Quality Sheet → Downloads → Player
