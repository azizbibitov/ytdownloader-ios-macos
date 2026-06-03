# Technical Task — YouTube Downloader (Stack 1: Pure iOS)

## Overview
A native iOS app that downloads YouTube videos directly on-device using XCDYouTubeKit to fetch stream URLs, URLSession to download, and AVPlayer for playback. No backend required.

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI |
| YouTube | XCDYouTubeKit (SPM) |
| Networking | URLSession |
| Playback | AVPlayer / AVKit |
| Storage | FileManager |
| Architecture | MVVM |

---

## Architecture

```
SwiftUI Views
    ↓
ViewModels (ObservableObject)
    ↓
YouTubeService (XCDYouTubeKit → stream URLs)
    ↓
DownloadService (URLSession → local file)
    ↓
FileManager (local storage)
    ↓
AVPlayer (playback)
```

---

## Screens

### Screen 1 — Home / Search
**Purpose:** Entry point. User pastes a YouTube URL and fetches video info.

**Elements:**
- Large app logo / title at top
- Rounded text field with YouTube URL placeholder
- "Fetch Video" primary button
- Loading skeleton while fetching
- Video card appears after fetch:
  - Thumbnail (rounded corners)
  - Title (2 lines max)
  - Duration badge
  - Channel name
  - "Select Quality" button

**Design Notes:**
- Dark background (#0F0F0F) — YouTube-inspired
- Red accent (#FF0000) for primary buttons
- Text field with subtle border, not filled background
- Thumbnail with 12pt corner radius and subtle shadow
- Paste button inside text field (right side) for quick paste

---

### Screen 2 — Quality Picker (Bottom Sheet)
**Purpose:** User selects download quality before downloading.

**Elements:**
- Handle bar at top
- "Select Quality" title
- List of available qualities:
  - 1080p — MP4
  - 720p — MP4
  - 480p — MP4
  - 360p — MP4
  - Audio Only — M4A
- Each row: quality label + file size estimate + checkmark when selected
- "Download" primary button at bottom

**Design Notes:**
- Present as `.sheet` or `.presentationDetents([.medium])`
- Each quality row has subtle divider
- Selected row highlighted with red accent background (10% opacity)
- File size in gray secondary text
- Download button full width, red, rounded

---

### Screen 3 — Downloads
**Purpose:** Shows active downloads with progress and completed downloads list.

**Elements:**
- Segmented control: "Downloading" / "Completed"
- **Downloading tab:**
  - Card per active download
  - Thumbnail + title
  - Progress bar (animated)
  - Percentage label
  - Cancel button (X icon)
- **Completed tab:**
  - List of downloaded videos
  - Thumbnail + title + file size + date
  - Swipe to delete
  - Tap to play

**Design Notes:**
- Progress bar in red accent color
- Cards with dark surface (#1A1A1A) and 12pt corner radius
- Empty state illustration when no downloads
- Smooth progress animation with `withAnimation`

---

### Screen 4 — Player
**Purpose:** Full-screen video playback.

**Elements:**
- AVPlayer fullscreen view
- Custom controls overlay:
  - Play / Pause
  - Seek bar
  - Current time / total duration
  - Share button
  - Save to Photos button
- Double tap left/right to seek ±10s
- Pinch to zoom

**Design Notes:**
- Controls auto-hide after 3 seconds
- Controls fade in/out with animation
- Status bar hidden in fullscreen
- Support both portrait and landscape

---

## Features

- Fetch video metadata (title, thumbnail, duration, available qualities)
- Download selected quality to local storage
- Background download support (URLSession background configuration)
- Download progress tracking
- Cancel active download
- In-app playback with AVPlayer
- Share video file
- Save to Photos / Files app
- Swipe to delete downloaded video
- Persist downloads list across app launches (UserDefaults or CoreData)

---

## Limitations (Known)

- XCDYouTubeKit may break when YouTube changes internal API
- 1080p on YouTube is video-only stream (no audio merged) — audio and video are separate streams, merging requires FFmpeg which is complex on-device
- Recommended max quality: **720p** (has merged audio+video stream)
- No playlist support

---

## Design System

| Token | Value |
|---|---|
| Background | #0F0F0F |
| Surface | #1A1A1A |
| Accent | #FF0000 |
| Text Primary | #FFFFFF |
| Text Secondary | #AAAAAA |
| Corner Radius | 12pt |
| Font | SF Pro (system default) |

---

## Dependencies (SPM)

```
https://github.com/0xced/XCDYouTubeKit
```

---

## Folder Structure

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
│   ├── YouTubeService.swift
│   └── DownloadService.swift
├── Models/
│   ├── VideoInfo.swift
│   └── DownloadItem.swift
└── Utils/
    └── FileManager+Extensions.swift
```

---

## Figma Design Recommendations

- Design for iPhone 15 Pro frame (393 x 852pt)
- Use Auto Layout in Figma (constraints, not fixed positions)
- Create a color styles library matching the design system above
- Design all 4 screens in light mockup first, then apply dark theme
- Add micro-interactions: button press states, loading skeletons
- Use SF Symbols for icons (search "SF Symbols" Figma plugin)
- Show empty states for downloads list
- Design the bottom sheet quality picker as a separate frame
- Export assets as PDF (vector) for Xcode, not PNG
