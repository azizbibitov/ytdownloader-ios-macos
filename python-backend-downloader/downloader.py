import asyncio
import logging
import uuid
import yt_dlp

import storage
from models import VideoInfoResponse, QualityOption, TaskProgress

logger = logging.getLogger(__name__)


class VideoService:

    def get_video_info(self, url: str) -> VideoInfoResponse:
        url = _clean_url(url)
        cached = storage.get_cached_video_info(url)
        if cached:
            logger.info(f"[video-info] cache hit: {url}")
            return VideoInfoResponse(**cached)

        logger.info(f"[video-info] fetching: {url}")
        ydl_opts = {
            "quiet": True,
            "no_warnings": True,
            "skip_download": True,
            "socket_timeout": 30,
            "retries": 3,
        }
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)

        qualities = _extract_qualities(info)
        result = VideoInfoResponse(
            id=info["id"],
            title=info["title"],
            thumbnail_url=info.get("thumbnail"),
            channel=info.get("channel") or info.get("uploader"),
            duration=info.get("duration", 0),
            qualities=qualities,
        )
        logger.info(f"[video-info] done: '{result.title}' by {result.channel} — {len(qualities)} qualities")
        storage.cache_video_info(url, result.model_dump())
        return result

    async def start_download(self, url: str, format_id: str) -> str:
        task_id = str(uuid.uuid4())
        logger.info(f"[download] start task={task_id} format={format_id} url={url}")
        storage.save_task(task_id, {
            "status": "pending",
            "percent": 0.0,
            "speed": None,
            "eta": None,
            "error": None,
            "file_path": None,
        })
        asyncio.create_task(self._run_download(task_id, url, format_id))
        return task_id

    async def _run_download(self, task_id: str, url: str, format_id: str) -> None:
        storage.update_task(task_id, status="downloading")
        out_template = storage.file_path(task_id).replace(".mp4", ".%(ext)s")

        stream_count = [0]

        def progress_hook(d: dict) -> None:
            if d["status"] == "downloading":
                raw = d.get("_percent_str", "0%").strip().replace("%", "")
                try:
                    percent = float(raw)
                except ValueError:
                    percent = 0.0
                # stream 1 maps to 0-45%, stream 2 maps to 45-90%
                if stream_count[0] == 0:
                    overall = percent * 0.45
                else:
                    overall = 45.0 + percent * 0.45
                storage.update_task(
                    task_id,
                    percent=round(overall, 1),
                    speed=d.get("_speed_str"),
                    eta=d.get("eta"),
                )
            elif d["status"] == "finished":
                stream_count[0] += 1
                if stream_count[0] >= 2:
                    storage.update_task(task_id, status="merging", percent=90.0)
                else:
                    storage.update_task(task_id, percent=45.0)

        ydl_opts = {
            "format": format_id,
            "outtmpl": out_template,
            "merge_output_format": "mp4",
            "progress_hooks": [progress_hook],
            "quiet": True,
            "no_warnings": True,
        }

        try:
            await asyncio.to_thread(_run_ytdlp, url, ydl_opts)
            storage.update_task(
                task_id,
                status="done",
                percent=100.0,
                file_path=storage.file_path(task_id),
            )
            logger.info(f"[download] done task={task_id}")
        except Exception as e:
            logger.error(f"[download] error task={task_id}: {e}")
            storage.update_task(task_id, status="error", error=str(e))

    def get_progress(self, task_id: str) -> TaskProgress | None:
        task = storage.get_task(task_id)
        if not task:
            return None
        return TaskProgress(
            status=task["status"],
            percent=task["percent"],
            speed=task.get("speed"),
            eta=task.get("eta"),
            error=task.get("error"),
        )


def _run_ytdlp(url: str, opts: dict) -> None:
    with yt_dlp.YoutubeDL(opts) as ydl:
        ydl.download([url])


def _extract_qualities(info: dict) -> list[QualityOption]:
    seen: set[str] = set()
    qualities: list[QualityOption] = []

    for fmt in info.get("formats", []):
        vcodec = fmt.get("vcodec", "none")
        acodec = fmt.get("acodec", "none")
        height = fmt.get("height")
        note = fmt.get("format_note", "")

        if not fmt.get("url"):
            continue
        if note == "storyboard":
            continue

        if vcodec == "none" and acodec != "none":
            abr = fmt.get("abr") or 0
            label = f"Audio {int(abr)}kbps" if abr else "Audio"
            if label not in seen:
                seen.add(label)
                qualities.append(QualityOption(
                    format_id=fmt["format_id"],
                    label=label,
                    ext=fmt.get("ext", "m4a"),
                    filesize=fmt.get("filesize"),
                    is_audio_only=True,
                ))

        elif vcodec != "none" and height:
            label = f"{height}p"
            if label not in seen:
                seen.add(label)
                # pair this video stream with the best available audio
                format_id = f"{fmt['format_id']}+bestaudio/best[height={height}]"
                qualities.append(QualityOption(
                    format_id=format_id,
                    label=label,
                    ext="mp4",
                    filesize=fmt.get("filesize"),
                    is_audio_only=False,
                ))

    qualities.sort(key=_sort_key, reverse=True)
    return qualities


def _sort_key(q: QualityOption) -> tuple:
    if q.is_audio_only:
        return (0, 0)
    try:
        return (1, int(q.label.replace("p", "")))
    except ValueError:
        return (1, 0)


video_service = VideoService()


def _clean_url(url: str) -> str:
    from urllib.parse import urlparse, urlencode, parse_qs, urlunparse
    parsed = urlparse(url)
    # keep only the 'v' param for regular videos, strip everything else
    params = parse_qs(parsed.query)
    clean_params = {k: v for k, v in params.items() if k == "v"}
    clean_query = urlencode(clean_params, doseq=True)
    return urlunparse(parsed._replace(query=clean_query))
