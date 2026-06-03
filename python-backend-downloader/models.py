from pydantic import BaseModel


class QualityOption(BaseModel):
    format_id: str
    label: str
    ext: str
    filesize: int | None
    is_audio_only: bool


class VideoInfoResponse(BaseModel):
    id: str
    title: str
    thumbnail_url: str | None
    channel: str | None
    duration: int
    qualities: list[QualityOption]


class DownloadRequest(BaseModel):
    url: str
    format_id: str


class TaskCreatedResponse(BaseModel):
    task_id: str


class TaskProgress(BaseModel):
    status: str  # pending | downloading | merging | done | error
    percent: float
    speed: str | None
    eta: int | None
    error: str | None
