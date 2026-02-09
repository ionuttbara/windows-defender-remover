@echo off
Echo Please wait...
takeown /f "C:\ProgramData\Microsoft\Windows Defender" /r /d y
icacls "C:\ProgramData\Microsoft\Windows Defender" /grant administrators:F /t
rd /s /q "C:\ProgramData\Microsoft\Windows Defender"

takeown /f "C:\Program Files\Windows Defender" /r /d y
icacls "C:\Program Files\Windows Defender" /grant administrators:F /t
rd /s /q "C:\Program Files\Windows Defender"

takeown /f "C:\Program Files (x86)\Windows Defender" /r /d y
icacls "C:\Program Files (x86)\Windows Defender" /grant administrators:F /t
rd /s /q "C:\Program Files (x86)\Windows Defender"

takeown /f "C:\Program Files\Windows Defender Advanced Threat Protection" /r /d y
icacls "C:\Program Files\Windows Defender Advanced Threat Protection" /grant administrators:F /t
rd /s /q "C:\Program Files\Windows Defender Advanced Threat Protection"

exit