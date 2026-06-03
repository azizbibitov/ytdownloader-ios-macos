import logging

from fastapi import FastAPI, HTTPException, Query, BackgroundTasks
from fastapi.responses import FileResponse
import os

import downloader
import storage
from models import VideoInfoResponse, DownloadRequest, TaskCreatedResponse, TaskProgress

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)

app = FastAPI(title="YT Downloader API")


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.get("/")
async def root():
    return {"status": "ok"}


@app.get("/video-info", response_model=VideoInfoResponse)
async def get_video_info(url: str = Query(..., description="YouTube video URL")):
    try:
        return downloader.video_service.get_video_info(url)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/download", response_model=TaskCreatedResponse)
async def start_download(request: DownloadRequest):
    try:
        task_id = await downloader.video_service.start_download(request.url, request.format_id)
        return TaskCreatedResponse(task_id=task_id)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/progress/{task_id}", response_model=TaskProgress)
async def get_progress(task_id: str):
    progress = downloader.video_service.get_progress(task_id)
    if not progress:
        raise HTTPException(status_code=404, detail="Task not found")
    return progress


@app.get("/file/{task_id}")
async def get_file(task_id: str, background_tasks: BackgroundTasks):
    file_path = storage.get_file_path(task_id)
    if not file_path or not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="File not ready")
    background_tasks.add_task(_cleanup, task_id, file_path)
    return FileResponse(
        file_path,
        media_type="video/mp4",
        filename=f"{task_id}.mp4",
    )


def _cleanup(task_id: str, file_path: str) -> None:
    storage.delete_task(task_id)
    try:
        os.remove(file_path)
    except OSError:
        pass
