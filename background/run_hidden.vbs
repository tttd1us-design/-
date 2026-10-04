' run_hidden.vbs
' 파이썬 스크립트를 "검은 창 없이" 백그라운드로 실행합니다.
'
' 사용법 (명령 프롬프트 또는 바로가기 대상):
'   wscript.exe "C:\경로\run_hidden.vbs" "C:\경로\내스크립트.py" [추가 인자...]
'
' 동작:
'   - 스크립트가 있는 폴더를 작업 폴더로 지정 (.env 등 상대경로 파일을 찾을 수 있게)
'   - pythonw.exe 로 실행 (콘솔 창 자체가 생기지 않음)
'   - 창 모드 0 = 숨김, False = 끝날 때까지 기다리지 않음

Option Explicit

Dim shell, fso, args, script, workDir, cmd, i

Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
Set args = WScript.Arguments

If args.Count = 0 Then
    MsgBox "실행할 .py 파일 경로를 인자로 넘겨주세요." & vbCrLf & _
           "예) wscript run_hidden.vbs C:\bot\auto_content.py", vbExclamation, "run_hidden"
    WScript.Quit 1
End If

script = fso.GetAbsolutePathName(args(0))
workDir = fso.GetParentFolderName(script)

cmd = "pythonw.exe """ & script & """"
For i = 1 To args.Count - 1
    cmd = cmd & " """ & args(i) & """"
Next

shell.CurrentDirectory = workDir
shell.Run cmd, 0, False
