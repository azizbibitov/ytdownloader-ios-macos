import os

DOWNLOADS_DIR = "downloads"
os.makedirs(DOWNLOADS_DIR, exist_ok=True)

_tasks: dict[str, dict] = {}
_video_cache: dict[str, dict] = {}


def save_task(task_id: str, data: dict) -> None:
    _tasks[task_id] = data


def get_task(task_id: str) -> dict | None:
    return _tasks.get(task_id)


def update_task(task_id: str, **kwargs) -> None:
    if task_id in _tasks:
        _tasks[task_id].update(kwargs)


def delete_task(task_id: str) -> None:
    _tasks.pop(task_id, None)


def file_path(task_id: str) -> str:
    return os.path.join(DOWNLOADS_DIR, f"{task_id}.mp4")


def get_file_path(task_id: str) -> str | None:
    task = get_task(task_id)
    return task.get("file_path") if task else None


def cache_video_info(url: str, data: dict) -> None:
    _video_cache[url] = data


def get_cached_video_info(url: str) -> dict | None:
    return _video_cache.get(url)
