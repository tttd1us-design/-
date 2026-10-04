"""background_safe.py

pythonw.exe(창 없음)로 돌릴 때 필요한 두 가지를 해결하는 헬퍼입니다.

1) pythonw 에서는 sys.stdout / sys.stderr 가 None 이라
   sys.stdout.reconfigure(...) 나 에러 출력이 조용히 실패합니다.
   -> 출력을 logs/<스크립트명>.log 파일로 보냅니다.

2) 스크립트 안에서 subprocess 로 다른 프로그램을 띄우면
   그 프로그램의 검은 창이 또 뜹니다.
   -> run_no_window() 를 쓰면 창 없이 실행됩니다.

사용법 (메인 스크립트 맨 위, 다른 import 보다 먼저):

    import background_safe
    background_safe.setup()

    # subprocess 대신
    background_safe.run_no_window(["ffmpeg", "-i", "a.mp4", "b.mp3"])
"""

import os
import subprocess
import sys

CREATE_NO_WINDOW = 0x08000000


def setup(log_dir=None):
    """콘솔이 없으면 stdout/stderr 를 UTF-8 로그 파일로 돌리고,
    콘솔이 있으면 기존처럼 UTF-8 로 재설정합니다."""
    main = os.path.abspath(sys.argv[0]) if sys.argv and sys.argv[0] else os.getcwd()
    base_dir = os.path.dirname(main)
    os.chdir(base_dir)  # .env 등 상대경로 파일을 항상 찾도록

    if sys.stdout is None or sys.stderr is None:
        log_dir = log_dir or os.path.join(base_dir, "logs")
        os.makedirs(log_dir, exist_ok=True)
        name = os.path.splitext(os.path.basename(main))[0] or "app"
        log = open(os.path.join(log_dir, name + ".log"), "a", encoding="utf-8", buffering=1)
        sys.stdout = sys.stdout or log
        sys.stderr = sys.stderr or log
    elif sys.platform == "win32":
        for stream in (sys.stdout, sys.stderr):
            try:
                stream.reconfigure(encoding="utf-8")
            except (AttributeError, ValueError):
                pass


def run_no_window(cmd, **kwargs):
    """subprocess.run 과 같지만, Windows 에서 새 콘솔 창을 만들지 않습니다."""
    if sys.platform == "win32":
        kwargs["creationflags"] = kwargs.get("creationflags", 0) | CREATE_NO_WINDOW
    return subprocess.run(cmd, **kwargs)


def popen_no_window(cmd, **kwargs):
    """subprocess.Popen 과 같지만, Windows 에서 새 콘솔 창을 만들지 않습니다."""
    if sys.platform == "win32":
        kwargs["creationflags"] = kwargs.get("creationflags", 0) | CREATE_NO_WINDOW
    return subprocess.Popen(cmd, **kwargs)
