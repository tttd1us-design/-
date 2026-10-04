# 검은 창 없이 백그라운드로 돌리기 (Windows)

화면에 계속 뜨는 검은 창은 **`python.exe`가 콘솔 창을 열기 때문**입니다.
**`pythonw.exe`**(끝에 w가 붙은 것)로 실행하면 창이 아예 생기지 않습니다.
아래 방법 중 하나만 고르면 됩니다.

| 상황 | 방법 | 난이도 |
|---|---|---|
| 지금 당장 한 번 숨겨서 실행 | ① `pythonw` 로 실행 | ★ |
| 더블클릭 / 시작프로그램으로 실행 | ② `run_hidden.vbs` | ★ |
| 부팅·로그온 시, 또는 N분마다 자동 실행 | ③ 작업 스케줄러 등록 | ★★ |
| 스크립트 안에서 또 다른 창이 뜸 | ④ `background_safe.py` | ★★ |

---

## ① 가장 간단: pythonw 로 실행

```bat
pythonw C:\bot\auto_content.py
```

- 창이 뜨지 않습니다. 종료하려면 작업 관리자 → `pythonw.exe` 끝내기.
- `print()` 결과는 화면에 안 보이므로 ④의 로그 파일 기능을 함께 쓰는 걸 권장합니다.

## ② 더블클릭으로 숨김 실행: run_hidden.vbs

```bat
wscript run_hidden.vbs C:\bot\auto_content.py
```

- 바탕화면 바로가기의 **대상**에 위 줄을 넣으면 더블클릭만으로 숨김 실행됩니다.
- `Win + R` → `shell:startup` 폴더에 그 바로가기를 넣으면 **윈도우 시작 시 자동 실행**됩니다.

## ③ 자동 실행: 작업 스케줄러 등록

PowerShell에서:

```powershell
# 로그온할 때마다 실행
.\register_hidden_task.ps1 -Script "C:\bot\auto_content.py"

# 30분마다 실행
.\register_hidden_task.ps1 -Script "C:\bot\auto_content.py" -EveryMinutes 30

# 지금 바로 테스트
Start-ScheduledTask -TaskName "AutoBot_auto_content"

# 해제
Unregister-ScheduledTask -TaskName "AutoBot_auto_content" -Confirm:$false
```

> 이미 작업 스케줄러에 `python.exe`로 등록된 작업이 있다면,
> 그 작업의 **동작 → 프로그램**을 `pythonw.exe`로 바꾸기만 해도 창이 사라집니다.

## ④ 스크립트에 넣을 코드: background_safe.py

`background_safe.py`를 내 스크립트와 **같은 폴더**에 두고, 맨 위에 두 줄을 추가합니다.

```python
import background_safe
background_safe.setup()   # 창 없이 실행되면 출력이 logs/스크립트명.log 로 저장됨
```

스크립트 안에서 `subprocess`로 다른 프로그램(ffmpeg, node 등)을 띄울 때 창이 또 뜬다면:

```python
background_safe.run_no_window(["ffmpeg", "-i", "in.mp4", "out.mp3"])
```

### 왜 필요한가요?
- `pythonw`로 실행하면 `sys.stdout`이 `None`이라 `sys.stdout.reconfigure(encoding="utf-8")`
  같은 코드나 에러 메시지가 **조용히 사라집니다.** → 문제가 생겨도 원인을 알 수 없게 됩니다.
- `setup()`은 이럴 때 출력을 UTF-8 로그 파일로 돌려서 나중에 확인할 수 있게 해줍니다.
- 기존 코드의 `if sys.platform == "win32": sys.stdout.reconfigure(...)` 블록은 `setup()`이 대신하므로 지워도 됩니다.

---

## 확인 체크리스트
1. 실행 후 작업 관리자 → 세부 정보 탭에 `pythonw.exe`가 보이면 정상 동작 중입니다.
2. `logs\스크립트명.log` 파일에 출력이 쌓이는지 확인합니다.
3. 창이 여전히 뜬다면 → 스크립트 내부의 `subprocess` / `os.system` 호출을 ④ 방식으로 바꿉니다.
