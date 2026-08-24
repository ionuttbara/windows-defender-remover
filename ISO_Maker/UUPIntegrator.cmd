<!-- : Begin batch script
@setlocal DisableDelayedExpansion
@set uivr=v121s
@echo off
:: Change to 1 to enable debug mode
set _Debug=0

:: ### Auto processing option ###
:: 1 - create ISO with install.wim
:: 2 - create ISO with install.esd
:: 3 - create install.wim only
:: 4 - create install.esd only
set AutoStart=0

:: Change to 1 to integrate updates (if detected) into install.wim/winre.wim
:: Change to 2 to add updates externally to iso distribution
set AddUpdates=1

:: Change to 1 to cleanup images to delta-compress superseded components (Warning: on 18362 and later, this removes the base RTM Edition packages)
set Cleanup=1

:: Change to 1 to rebase image and remove superseded components (faster than default delta-compress)
:: require first to set Cleanup=1
:: change to 2 to run rebase after each LCU for builds 26052 and later
set ResetBase=2

:: Change to 1 to enable .NET 3.5 feature with updates
set NetFx3=0

:: Change to 1 to start create_virtual_editions.cmd directly after conversion
set StartVirtual=0

:: Change to 1 to convert install.wim to install.esd
set wim2esd=0

:: Change to 1 to split install.wim into multiple install.swm
:: note: if both options are 1, install.esd takes precedence
set wim2swm=0

:: Change to 1 for not creating ISO file, result distribution folder will be kept
set SkipISO=0

:: Change to 1 for not adding winre.wim into install.wim/install.esd
set SkipWinRE=0

:: Change to 1 to force updating winre.wim with Cumulative Update regardless if SafeOS update detected
:: ignored and auto disabled for builds 26052 and later
set LCUwinre=0

:: Change to 1 to expand Cumulative Update and install from loose files via update.mum
:: applicable only for builds 22621 and later
:: auto enabled for builds 26052 and later, change to 2 to disable
set LCUmsuExpand=0

:: Change to 1 to disable updating process optimization by using editions upgrade (Home>Pro / ServerStandard>ServerDatacenter)
:: auto enabled for builds 26000 and later, change to 2 to disable
set DisableUpdatingUpgrade=0

:: Change to 1 to update ISO boot files bootmgr/memtest/efisys.bin from Cumulative Update
:: this also update new UEFI CA 2023 boot files if detected
set UpdtBootFiles=0

:: Change to 1 to use dism.exe for creating boot.wim
set ForceDism=0

:: Change to 1 to keep converted Reference ESDs
set RefESD=0

:: Change to 1 to skip creating Cumulative Update MSU for builds 21382 - 25330
set SkipLCUmsu=0

:: Change to 1 for not integrating EdgeChromium with Enablement Package or Cumulative Update
:: Change to 2 for alternative workaround to avoid EdgeChromium with Cumulative Update only
set SkipEdge=0

:: Change to 1 to exit the process on completion without prompt
set AutoExit=0

:: ### Drivers Options ###

:: Change to 1 to add drivers to install.wim and boot.wim / winre.wim
set AddDrivers=0

:: custom folder path for drivers - default is "Drivers" folder next to the script
:: the folder must contain subfolder for each drivers target:
:: ALL   / drivers will be added to all wim files
:: OS    / drivers will be added to install.wim only
:: WinPE / drivers will be added to boot.wim / winre.wim only
set "Drv_Source=\Drivers"

:: ### Store Apps for builds 22563 and later ###

:: Change to 1 for not integrating store apps into install.wim
set SkipApps=0

:: # Control added Apps for Client editions (except Team)
:: 0 / all referenced Apps
:: 1 / only Store, Security Health, App Installer, StartExperiencesApp
:: 2 / level 1 + Photos, Camera, Notepad, Paint
:: 3 / level 2 + Terminal, Widgets, Mail / Outlook, Clipchamp
:: 4 / level 3 + Media apps (Music, Video, Codecs, Phone Link) / not for N editions
set AppsLevel=0

:: # Control preference for Apps which are available as stubs
:: 0 / install as stub app
:: 1 / install as full app
set StubAppsFull=1

:: Enable using CustomAppsList.txt or CustomAppsList2.txt to pick and choose added Apps (takes precedence over AppsLevel)
:: CustomAppsList2.txt will be used if detected
set CustomList=0

:: ###################################################################

set DeleteSource=0
set "SortEditions="

set "_Null=1>nul 2>nul"
set DisableRebuildWim=0
set "_wrb="
if %DisableRebuildWim% equ 1 set "_wrb=rem."

set _UUP=
set qerel=
set _elev=
set "_args="
set "_args=%~1"
if not defined _args goto :NoProgArgs
if "%~1"=="" set "_args="&goto :NoProgArgs
set "_args="
for %%# in (%*) do (
if /i "%%~#"=="-elevated" (set _elev=1
) else if /i "%%~#"=="-qedit" (set qerel=1
) else (set "_args=%%~#")
)

:NoProgArgs
@color 07
set "xOS=amd64"
if /i "%PROCESSOR_ARCHITECTURE%"=="arm64" set "xOS=arm64"
if /i "%PROCESSOR_ARCHITECTURE%"=="x86" if "%PROCESSOR_ARCHITEW6432%"=="" set "xOS=x86"
if /i "%PROCESSOR_ARCHITEW6432%"=="amd64" set "xOS=amd64"
if /i "%PROCESSOR_ARCHITEW6432%"=="arm64" set "xOS=arm64"
set "xDS=bin\bin64;bin;temp"
if /i not %xOS%==amd64 set "xDS=bin;temp"
set "SysPath=%SystemRoot%\System32"
set "Path=%xDS%;%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
set "SysPath=%SystemRoot%\Sysnative"
set "Path=%xDS%;%SystemRoot%\Sysnative;%SystemRoot%;%SystemRoot%\Sysnative\Wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%Path%"
)
set "_err=echo: &echo ==== ERROR ===="
set "_psc=powershell -nop -c"
set winbuild=1
for /f "tokens=6 delims=[]. " %%# in ('ver') do set winbuild=%%#
set _cwmi=0
for %%# in (wmic.exe) do @if not "%%~$PATH:#"=="" (
cmd /c "wmic path Win32_ComputerSystem get CreationClassName /value" 2>nul | find /i "ComputerSystem" 1>nul && set _cwmi=1
)
set _pwsh=1
for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" set _pwsh=0
cmd /c "%_psc% "$ExecutionContext.SessionState.LanguageMode"" | find /i "FullLanguage" 1>nul || (set _pwsh=0)
call :pr_color
if %_cwmi% equ 0 if %_pwsh% equ 0 goto :E_PWS

set _uac=-elevated
%_Null% reg.exe query HKU\S-1-5-19 && (
  goto :Passed
  ) || (
  if defined _elev goto :E_Admin
)

set _PSarg="""%~f0""" %_uac%
if defined _args set _PSarg="""%~f0""" """%_args%""" %_uac%
set _PSarg=%_PSarg:'=''%

(%_Null% cscript //NoLogo "%~f0?.wsf" //job:ELAV /File:"%~f0" %* %_uac%) && (
  exit /b
  ) || (
  call setlocal EnableDelayedExpansion
  %_Null% %_psc% "start cmd.exe -Arg '/c \"!_PSarg!\"' -verb runas" && (
    exit /b
    ) || (
    goto :E_Admin
  )
)

:Passed
if %winbuild% LSS 10586 (
reg.exe query HKCU\Console /v QuickEdit 2>nul | find /i "0x0" >nul && set qerel=1
)
if defined qerel goto :skipQE
if %_pwsh% EQU 0 goto :skipQE
set _PSarg="""%~f0""" -qedit
if defined _args set _PSarg="""%~f0""" """%_args%""" -qedit
set _PSarg=%_PSarg:'=''%
set "d1=$t=[AppDomain]::CurrentDomain.DefineDynamicAssembly(4, 1).DefineDynamicModule(2, $False).DefineType(0);"
set "d2=$t.DefinePInvokeMethod('GetStdHandle', 'kernel32.dll', 22, 1, [IntPtr], @([Int32]), 1, 3).SetImplementationFlags(128);"
set "d3=$t.DefinePInvokeMethod('SetConsoleMode', 'kernel32.dll', 22, 1, [Boolean], @([IntPtr], [Int32]), 1, 3).SetImplementationFlags(128);"
set "d4=$k=$t.CreateType(); $b=$k::SetConsoleMode($k::GetStdHandle(-10), 0x0080);"
setlocal EnableDelayedExpansion
%_psc% "!d1! !d2! !d3! !d4! & cmd.exe '/c' '!_PSarg!'" &exit /b
exit /b

:skipQE
set "logerr=%~dp0ErrorLog_%random%.txt"
set "_batf=%~f0"
set "_log=%~dpn0"
set "_work=%~dp0"
set "_work=%_work:~0,-1%"
set _drv=%~d0
set "_cabdir=%_drv%\W10UIuup"
set _UNC=0
if "%_work:~0,2%"=="\\" (
set _UNC=1
) else (
net use %_drv% %_Null%
if not errorlevel 1 set _UNC=1
)
if %_UNC% EQU 1 set "_cabdir=%~dp0temp\W10UIuup"
for /f "skip=2 tokens=2*" %%a in ('reg.exe query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Desktop') do call set "_dsk=%%b"
if exist "%PUBLIC%\Desktop\desktop.ini" set "_dsk=%PUBLIC%\Desktop"
call :preVars
setlocal EnableDelayedExpansion
if exist "!_work!\UUPs\*.esd" set "_UUP=!_work!\UUPs"
if defined _args if exist "!_args!\*.esd" set "_UUP=!_args!"

if %_Debug% equ 0 (
  set "_Nul1=1>nul"
  set "_Nul2=2>nul"
  set "_Nul6=2^>nul"
  set "_Nul3=1>nul 2>nul"
  set "_Pause=pause >nul"
  set "_Contn=echo Press any key to continue..."
  set "_Exit=echo Press any key to exit."
  set "_Supp="
  goto :Begin
)
  set "_Nul1="
  set "_Nul2="
  set "_Nul6="
  set "_Nul3="
  set "_Pause=rem."
  set "_Contn=rem."
  set "_Exit=rem."
  set "_Supp=1>nul"
copy /y nul "!_work!\#.rw" %_Null% && (if exist "!_work!\#.rw" del /f /q "!_work!\#.rw") || (set "_log=!_dsk!\%~n0")
echo.
echo Running in Debug Mode...
echo The window will be closed when finished
@echo on
@prompt $G
@call :Begin >"!_log!_tmp.log" 2>&1 &cmd /u /c type "!_log!_tmp.log">"!_log!_Debug.log"&del /f /q "!_log!_tmp.log"
@color 07
@title %ComSpec%
@exit /b

:Begin
title UUP -^> ISO %uivr%
set "_dLog=%SystemRoot%\Logs\DISM"
call :checkadk
set W10UI=0
if %winbuild% geq 10240 (
set W10UI=1
) else (
if %_ADK% equ 1 set W10UI=1
)
call :postVars
if defined _UUP goto :check
if %_Debug% neq 0 goto :check
setlocal DisableDelayedExpansion

:prompt
@cls
set _UUP=
echo.
echo Enter the path to UUP source directory
echo %_ln1%
echo.
set /p _UUP=
if not defined _UUP set _Debug=1&goto :QUIT
set "_UUP=%_UUP:"=%"
if "%_UUP:~-1%"=="\" set "_UUP=%_UUP:~0,-1%"
if not exist "%_UUP%\*.esd" (
%_err%
echo Specified path is not a valid UUP source
echo.
%_Contn%&%_Pause%
goto :prompt
)
setlocal EnableDelayedExpansion

:check
if %_Debug% neq 0 (
if defined _args echo "!_args!"
echo "!_work!"
)
pushd "!_work!"
set _fils=(7z.dll,7z.exe,bcdedit.exe,bfi.exe,bootmui.txt,bootwim.txt,cdimage.exe,imagex.exe,libwim-15.dll,offlinereg.exe,offreg.dll,wimlib-imagex.exe,PSFExtractor.exe,cabarc.exe)
for %%# in %_fils% do (
if not exist ".\bin\%%#" (set _bin=%%#&goto :E_Bin)
)
if not defined _UUP (
(echo.&echo UUP source directory is not specified, or valid)>>"!logerr!"
exit /b
)
if not exist "ConvertConfig.ini" goto :proceed
findstr /i \[convert-UUP\] ConvertConfig.ini %_Nul1% || goto :proceed
for %%# in (
AutoStart
AddUpdates
Cleanup
ResetBase
NetFx3
StartVirtual
SkipISO
SkipWinRE
LCUwinre
LCUmsuExpand
DisableUpdatingUpgrade
UpdtBootFiles
wim2esd
wim2swm
ForceDism
RefESD
SkipLCUmsu
SkipEdge
AutoExit
AddDrivers
Drv_Source
SkipApps
AppsLevel
StubAppsFull
CustomList
) do (
call :ReadINI %%#
)
findstr /b /i vDeleteSource ConvertConfig.ini %_Nul1% && for /f "tokens=2 delims==" %%# in ('findstr /b /i vDeleteSource ConvertConfig.ini') do set "DeleteSource=%%#"
findstr /b /i vSortEditions ConvertConfig.ini %_Nul1% && for /f "tokens=1* delims==" %%A in ('findstr /b /i vSortEditions ConvertConfig.ini') do set "SortEditions=%%B"
goto :proceed

:ReadINI
findstr /b /i %1 ConvertConfig.ini %_Nul1% && for /f "tokens=2 delims==" %%# in ('findstr /b /i %1 ConvertConfig.ini') do set "%1=%%#"
goto :eof

:proceed
:: @color 1F
echo.
echo === Detecting UUP editions files . . .
echo.
if %_Debug% neq 0 (
if %AutoStart% equ 0 set AutoStart=2
)
set _configured=0
set u_msulcu=%LCUmsuExpand%
set u_winre=%LCUwinre%
set u_upgrade=%DisableUpdatingUpgrade%
if exist bin\temp\ rmdir /s /q bin\temp\
if exist temp\ rmdir /s /q temp\
if exist bin\expand.exe if not exist bin\dpx.dll del /f /q bin\expand.exe
mkdir bin\temp
mkdir temp
set _updexist=0
if exist "!_UUP!\*Windows1*-KB*.msu" set _updexist=1
if exist "!_UUP!\*Windows1*-KB*.cab" set _updexist=1
if exist "!_UUP!\SSU-*-*.cab" set _updexist=1
set _pmcppc=0
if exist "!_UUP!\*Microsoft-Windows-Printing-PMCPPC-FoD-Package*.cab" set _pmcppc=1
if exist "!_UUP!\*Microsoft-Windows-Printing-PMCPPC-FoD-Package*.esd" set _pmcppc=1
dir /b /ad "!_UUP!\*Package*" %_Nul3% && set EXPRESS=1
for %%# in (
Core,CoreN,CoreSingleLanguage,CoreCountrySpecific
Professional,ProfessionalN,ProfessionalEducation,ProfessionalEducationN,ProfessionalWorkstation,ProfessionalWorkstationN
Education,EducationN,Enterprise,EnterpriseN,EnterpriseG,EnterpriseGN,EnterpriseS,EnterpriseSN,ServerRdsh
PPIPro,IoTEnterprise,IoTEnterpriseK,IoTEnterpriseS,IoTEnterpriseSK
Cloud,CloudN,CloudE,CloudEN,CloudEdition,CloudEditionN,CloudEditionL,CloudEditionLN
Starter,StarterN,ProfessionalCountrySpecific,ProfessionalSingleLanguage
ServerStandardCore,ServerStandard,ServerDatacenterCore,ServerDatacenter,ServerTurbineCore,ServerTurbine,ServerAzureStackHCICor
WNC
) do (
if exist "!_UUP!\%%#_*.esd" (dir /b /a:-d "!_UUP!\%%#_*.esd">>temp\uups_esd.txt %_Nul2%) else if exist "!_UUP!\MetadataESD_%%#_*.esd" (dir /b /a:-d "!_UUP!\MetadataESD_%%#_*.esd">>temp\uups_esd.txt %_Nul2%)
)
for /f "tokens=3 delims=: " %%# in ('find /v /c "" temp\uups_esd.txt %_Nul6%') do set uups_esd_num=%%#
if %uups_esd_num% equ 0 goto :E_ESD
for /L %%# in (1,1,%uups_esd_num%) do call :uups_esd %%#
if defined eWIMLIB goto :QUIT
if %uups_esd_num% gtr 1 goto :MULTIMENU
set "MetadataESD=!_UUP!\%uups_esd1%"&set "_flg=%edition1%"&set "arch=%arch1%"&set "langid=%langid1%"&set "editionid=%edition1%"&set "_oName=%_oname1%"&set "_Srvr=%_ESDSrv1%"
goto :MAINMENU

:MULTIMENU
if %AutoStart% equ 1 (set AIO=1&set WIMFILE=install.wim&goto :ISO)
if %AutoStart% equ 2 (set AIO=1&set WIMFILE=install.esd&goto :ISO)
if %AutoStart% equ 3 (set AIO=1&set WIMFILE=install.wim&goto :Single)
if %AutoStart% equ 4 (set AIO=1&set WIMFILE=install.esd&goto :Single)
@cls
set _index=
echo.
echo       UUP source contains multiple editions:
echo %_ln2%
echo.
for /L %%# in (1,1,%uups_esd_num%) do (
echo %%#. !_name%%#!
)
echo %_ln2%
echo.
echo Enter zero '0' to create AIO
echo Enter individual edition number to create solely
echo Enter multiple editions numbers to create, separated with spaces
echo %_ln1%
echo.
set /p _index= ^> Enter your option and press "Enter": 
if not defined _index set _Debug=1&goto :QUIT
if "%_index%"=="0" (set "_tag= AIO"&set "_ta2=AIO"&set AIO=1&goto :MAINMENU)
for %%# in (%_index%) do call :setindex %%#
if %_count% equ 1 for /L %%# in (1,1,%uups_esd_num%) do (
if %_index1% equ %%# set "MetadataESD=!_UUP!\!uups_esd%%#!"&set "_flg=!edition%%#!"&set "arch=!arch%%#!"&set "langid=!langid%%#!"&set "editionid=!edition%%#!"&set "_oName=!_oname%%#!"&set "_Srvr=!_ESDSrv%%#!"&goto :MAINMENU
)
set "_ta2=AIO"
goto :MAINMENU

:setindex
set /a _count+=1
set _index%_count%=%1
goto :eof

:optDrivers
if "!Drv_Source!"=="\Drivers" set "Drv_Source=!_work!\Drivers"
set "DrvSrcALL="
set "DrvSrcOS="
set "DrvSrcPE="
if %AddDrivers% neq 0 if %W10UI% neq 0 if exist "!Drv_Source!\" (
pushd "!Drv_Source!"
if exist ALL\ dir /b /s "ALL\*.inf" %_Nul3% && set "DrvSrcALL=!Drv_Source!\ALL"
if exist OS\ dir /b /s "OS\*.inf" %_Nul3% && set "DrvSrcOS=!Drv_Source!\OS"
if exist WinPE\ dir /b /s "WinPE\*.inf" %_Nul3% && set "DrvSrcPE=!Drv_Source!\WinPE"
popd
)
set DrvOpt=
set OSDrv=
if defined DrvSrcALL set DrvOpt=1&set OSDrv=1
if defined DrvSrcOS set DrvOpt=1&set OSDrv=1
if defined DrvSrcPE set DrvOpt=1
goto :eof

:MAINMENU
if %AutoStart% equ 1 (set WIMFILE=install.wim&goto :ISO)
if %AutoStart% equ 2 (set WIMFILE=install.esd&goto :ISO)
if %AutoStart% equ 3 (set WIMFILE=install.wim&goto :Single)
if %AutoStart% equ 4 (set WIMFILE=install.esd&goto :Single)
@cls
set userinp=
echo %_ln2%
echo.
echo.       0 - Exit
echo.       1 - Create%_tag% ISO with install.wim
echo.       2 - Create%_tag% install.wim
echo.       3 - UUP Edition info
if %EXPRESS% equ 0 (
echo.       4 - Create%_tag% ISO with install.esd
echo.       5 - Create%_tag% install.esd
)
echo.       6 - Configuration Options
echo %_ln1%
echo.
set /p userinp= ^> Enter your option and press "Enter": 
if not defined userinp set _Debug=1&goto :QUIT
set userinp=%userinp:~0,1%
if %userinp% equ 0 (set _Debug=1&goto :QUIT)
if %userinp% equ 6 goto :CONFMENU
if %userinp% equ 5 if %EXPRESS% equ 0 (set WIMFILE=install.esd&goto :Single)
if %userinp% equ 4 if %EXPRESS% equ 0 (set WIMFILE=install.esd&goto :ISO)
if %userinp% equ 3 goto :INFO%_ta2%
if %userinp% equ 2 (set WIMFILE=install.wim&goto :Single)
if %userinp% equ 1 (set WIMFILE=install.wim&goto :ISO)
goto :MAINMENU

:CONFMENU
@cls
set userinp=
set _optStub=No
set _optList=No
if %StubAppsFull% neq 0 set _optStub=Yes
if %CustomList% neq 0 set _optList=Yes
echo %_ln2%
echo.
echo. 0 - Return to Main Menu
if %_updexist% equ 1 if %W10UI% equ 0 (
if %AddUpdates% equ 2 (echo. 1 - AddUpdates   : Yes {External}) else if %AddUpdates% equ 1 (echo. 1 - AddUpdates   : No  {ADK missing}) else (echo. 1 - AddUpdates   : No)
)
if %_updexist% equ 1 if %W10UI% neq 0 (
if %AddUpdates% equ 2 (echo. 1 - AddUpdates   : Yes {External}) else if %AddUpdates% equ 1 (echo. 1 - AddUpdates   : Yes {Integrate}) else (echo. 1 - AddUpdates   : No)
if %AddUpdates% equ 1 (
  if %Cleanup% equ 0 (echo. 2 - Cleanup      : No) else (if %ResetBase% equ 0 (echo. 2 - Cleanup      : Yes {ResetBase : No}) else (echo. 2 - Cleanup      : Yes {ResetBase : Yes {%ResetBase%}}))
  )
if %AddUpdates% neq 0 (
  if %NetFx3% neq 0 (echo. 3 - NetFx3       : Yes) else (echo. 3 - NetFx3       : No)
  )
)
if %StartVirtual% neq 0 (echo. 4 - StartVirtual : Yes) else (echo. 4 - StartVirtual : No)
if %wim2esd% neq 0 (echo. 5 - WIM2ESD      : Yes) else (if %wim2swm% neq 0 (echo. 5 - WIM2SWM      : Yes) else (echo. 5 - WIM2ESD/SWM  : No))
if %SkipISO% neq 0 (echo. 6 - SkipISO      : Yes) else (echo. 6 - SkipISO      : No)
if %SkipWinRE% neq 0 (echo. 7 - SkipWinRE    : Yes) else (echo. 7 - SkipWinRE    : No)
if %W10UI% neq 0 (
if %ForceDism% neq 0 (echo. 8 - ForceDism    : Yes) else (echo. 8 - ForceDism    : No)
)
if %RefESD% neq 0 (echo. 9 - RefESD       : Yes) else (echo. 9 - RefESD       : No)
if %W10UI% neq 0 (
  if %DisableUpdatingUpgrade% neq 0 (echo. U - DisableUpdatingUpgrade : Yes) else (echo. U - DisableUpdatingUpgrade : No)
)
if %_updexist% equ 1 if %W10UI% neq 0 (
if %AddUpdates% equ 1 (
  if %LCUwinre% equ 1 (echo. R - LCUwinre     : Yes) else (echo. R - LCUwinre     : No  {%LCUwinre%})
  if %UpdtBootFiles% equ 1 (echo. B - UpdtBootFiles: Yes) else (echo. B - UpdtBootFiles: No)
  if %SkipEdge% neq 0 (echo. E - SkipEdge     : Yes {%SkipEdge%}) else (echo. E - SkipEdge     : No)
  )
)
if %SkipLCUmsu% neq 0 (echo. M - SkipLCUmsu   : Yes) else (echo. M - SkipLCUmsu   : No)
if %W10UI% neq 0 (
  if %AddDrivers% neq 0 (echo. D - AddDrivers   : Yes) else (echo. D - AddDrivers   : No)
  echo.
  if %SkipApps% neq 0 (echo. A - SkipApps     : Yes) else (echo. A - SkipApps     : No)
)
if %W10UI% neq 0 if %SkipApps% equ 0 (
  echo. S - StubAppsFull : %_optStub% # C - CustomList: %_optList% # L - AppsLevel: %AppsLevel%
)
echo %_ln1%
echo.
set /p userinp= ^> Enter your option and press "Enter": 
if not defined userinp goto :MAINMENU
set userinp=%userinp:~0,1%
if %userinp%==0 goto :MAINMENU
if /i %userinp%==U (if %W10UI% neq 0 (if %DisableUpdatingUpgrade% equ 0 (set DisableUpdatingUpgrade=1) else (set DisableUpdatingUpgrade=0)))&goto :CONFMENU
if /i %userinp%==L (if %W10UI% neq 0 if %SkipApps% equ 0 (if %AppsLevel% equ 0 (set AppsLevel=1) else if %AppsLevel% equ 1 (set AppsLevel=2) else if %AppsLevel% equ 2 (set AppsLevel=3) else if %AppsLevel% equ 3 (set AppsLevel=4) else (set AppsLevel=0)))&goto :CONFMENU
if /i %userinp%==C (if %W10UI% neq 0 if %SkipApps% equ 0 (if %CustomList% equ 0 (set CustomList=1) else (set CustomList=0)))&goto :CONFMENU
if /i %userinp%==S (if %W10UI% neq 0 if %SkipApps% equ 0 (if %StubAppsFull% equ 0 (set StubAppsFull=1) else (set StubAppsFull=0)))&goto :CONFMENU
if /i %userinp%==A (if %W10UI% neq 0 (if %SkipApps% equ 0 (set SkipApps=1) else (set SkipApps=0)))&goto :CONFMENU
if /i %userinp%==D (if %W10UI% neq 0 (if %AddDrivers% equ 0 (set AddDrivers=1) else (set AddDrivers=0)))&goto :CONFMENU
if /i %userinp%==M (if %SkipLCUmsu% equ 0 (set SkipLCUmsu=1) else (set SkipLCUmsu=0))&goto :CONFMENU
if /i %userinp%==E (if %AddUpdates% equ 1 (if %SkipEdge% equ 0 (set SkipEdge=1) else if %SkipEdge% equ 1 (set SkipEdge=2) else (set SkipEdge=0)))&goto :CONFMENU
if /i %userinp%==B (if %AddUpdates% equ 1 (if %UpdtBootFiles% equ 0 (set UpdtBootFiles=1) else (set UpdtBootFiles=0)))&goto :CONFMENU
if /i %userinp%==R (if %AddUpdates% equ 1 (if %LCUwinre% equ 0 (set LCUwinre=1) else if %LCUwinre% equ 1 (set LCUwinre=2) else (set LCUwinre=0)))&goto :CONFMENU
if %userinp%==9 (if %RefESD% equ 0 (set RefESD=1) else (set RefESD=0))&goto :CONFMENU
if %userinp%==8 (if %W10UI% neq 0 (if %ForceDism% equ 0 (set ForceDism=1) else (set ForceDism=0)))&goto :CONFMENU
if %userinp%==7 (if %SkipWinRE% equ 0 (set SkipWinRE=1) else (set SkipWinRE=0))&goto :CONFMENU
if %userinp%==6 (if %SkipISO% equ 0 (set SkipISO=1) else (set SkipISO=0))&goto :CONFMENU
if %userinp%==5 (if %wim2esd% equ 1 (set wim2esd=0) else (set wim2esd=1&if %wim2swm% equ 0 (set wim2swm=1) else (set wim2swm=0)))&goto :CONFMENU
if %userinp%==4 (if %StartVirtual% equ 0 (set StartVirtual=1) else (set StartVirtual=0))&goto :CONFMENU
if %userinp%==3 if %AddUpdates% neq 0 (if %NetFx3% equ 0 (set NetFx3=1) else (set NetFx3=0))&goto :CONFMENU
if %userinp%==2 if %AddUpdates% equ 1 (if %Cleanup% equ 1 (set Cleanup=0) else (set Cleanup=1&if %ResetBase% equ 0 (set ResetBase=1) else if %ResetBase% equ 1 (set ResetBase=2) else (set ResetBase=0)))&goto :CONFMENU
if %userinp%==1 (if %AddUpdates% equ 0 (set AddUpdates=1) else if %AddUpdates% equ 1 (set AddUpdates=2) else (set AddUpdates=0))&goto :CONFMENU
goto :CONFMENU

:ISO
@cls
call :dk_color1 %Gray% "=== Running UUP Converter %uivr% ===" 4 5
call :checkQE
set _initial=1
if %_updexist% equ 0 set AddUpdates=0
if %PREPARED% equ 0 call :PREPARE
call :optDrivers
if %_build% equ 25398 set SkipApps=1
if %_SrvESD% equ 1 set StubAppsFull=1
if %_IPA% equ 1 if %SkipApps% equ 0 set _runIPA=1
if %CustomList% neq 0 if exist "CustomAppsList*.txt" set _appsCustom=1
if /i %arch%==arm64 if %winbuild% lss 9600 if %AddUpdates% equ 1 (
if %_build% geq 17763 (set AddUpdates=2) else (set AddUpdates=0)
)
if %Cleanup% equ 0 set ResetBase=0
if %AIO% neq 1 if %_count% leq 1 (
if /i "%editionid%"=="PPIPro" set StartVirtual=0
if /i "%editionid%"=="WNC" set StartVirtual=0
)
if %_build% lss 17063 (set StartVirtual=0)
if %_build% lss 17763 if %AddUpdates% equ 2 (set AddUpdates=1)
if %_build% lss 17763 if %AddUpdates% equ 1 if %W10UI% equ 0 (set AddUpdates=0)
if %_build% geq 17763 if %AddUpdates% equ 1 if %W10UI% equ 0 (set AddUpdates=2)
if %_build% lss 17763 if %AddUpdates% equ 1 (set Cleanup=1)
if %_build% geq 22000 (
if %LCUwinre% equ 2 (set LCUwinre=0)
if %_build% geq 26052 (set LCUwinre=0)
)
if %_build% lss 22621 set LCUmsuExpand=0
if %_build% geq 26052 (
if %LCUmsuExpand% equ 2 (set LCUmsuExpand=0) else (set LCUmsuExpand=1)
)
if %_build% geq 25380 (
if %Cleanup% equ 0 set DisableUpdatingUpgrade=1
)
if %_build% geq 26000 (
if %DisableUpdatingUpgrade% equ 2 (set DisableUpdatingUpgrade=0) else (set DisableUpdatingUpgrade=1)
)
if %_build% geq 27965 (set NetFx3=0)
if %WIMFILE%==install.wim (
if %AddUpdates% neq 1 if %wim2esd% equ 1 (set WIMFILE=install.esd)
)
if %WIMFILE%==install.esd (
set wim2esd=0
if %AddUpdates% equ 1 (set WIMFILE=install.wim&set wim2esd=1)
if %_runIPA% equ 1 (set WIMFILE=install.wim&set wim2esd=1)
if defined DrvOpt (set WIMFILE=install.wim&set wim2esd=1)
)
if %_Debug% neq 0 set wim2esd=0
for %%# in (
AutoStart
AddUpdates
Cleanup
ResetBase
NetFx3
StartVirtual
SkipISO
SkipWinRE
LCUwinre
LCUmsuExpand
DisableUpdatingUpgrade
UpdtBootFiles
wim2esd
wim2swm
ForceDism
RefESD
SkipLCUmsu
SkipEdge
AutoExit
AddDrivers
SkipApps
AppsLevel
StubAppsFull
CustomList
DeleteSource
) do (
if !%%#! neq 0 set _configured=1
)
if defined SortEditions set _configured=1
for %%# in (
u_msulcu
u_winre
u_upgrade
) do (
if !%%#! neq 0 set _configured=1
)
if %_configured% equ 1 (
call :dk_color1 %Blue% "=== Configured Options . . ." 4 5
  if %AutoStart% neq 0 echo AutoStart %AutoStart%
  if %AddUpdates% neq 0 echo AddUpdates %AddUpdates%
  if %AddUpdates% equ 1 (
  if %Cleanup% neq 0 echo Cleanup
  if %Cleanup% neq 0 if %ResetBase% neq 0 echo ResetBase
  if %u_winre% neq 0 (echo LCUwinre %u_winre%) else (if %LCUwinre% neq 0 echo LCUwinre %LCUwinre%)
  if %u_msulcu% neq 0 (echo LCUmsuExpand %u_msulcu%) else (if %LCUmsuExpand% neq 0 echo LCUmsuExpand %LCUmsuExpand%)
  if %u_upgrade% neq 0 (echo DisableUpdatingUpgrade %u_upgrade%) else (if %DisableUpdatingUpgrade% neq 0 echo DisableUpdatingUpgrade %DisableUpdatingUpgrade%)
  )
  if %AddUpdates% neq 0 if %NetFx3% neq 0 echo NetFx3
  if %StartVirtual% neq 0 (
  echo StartVirtual
  if %DeleteSource% neq 0 echo DeleteSource
  )
  for %%# in (
  SkipISO
  SkipWinRE
  UpdtBootFiles
  wim2esd
  wim2swm
  ForceDism
  RefESD
  AutoExit
  AddDrivers
  ) do (
  if !%%#! neq 0 echo %%#
  )
  if defined SortEditions echo SortEditions: %SortEditions%
)
if %_build% geq 21382 if %SkipLCUmsu% neq 0 echo SkipLCUmsu
if %_build% geq 18362 if %AddUpdates% equ 1 if %SkipEdge% neq 0 echo SkipEdge %SkipEdge%
if %_build% geq 22563 if %W10UI% neq 0 (
if %SkipApps% neq 0 echo SkipApps
if %SkipApps% equ 0 (if %AppsLevel% neq 0 echo AppsLevel %AppsLevel%
if %StubAppsFull% neq 0 echo StubAppsFull
if %_appsCustom% neq 0 echo CustomAppsList)
)
if %_runIPA% equ 1 call :appx_sort
if %_IPA% equ 1 if %SkipApps% equ 1 (
if %_OPA% equ 1 call :appx_sort
)
call :uups_ref
call :dk_color1 %Blue% "=== Creating Setup Media Layout . . ." 4
if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
mkdir ISOFOLDER
wimlib-imagex.exe apply "!MetadataESD!" 1 ISOFOLDER\ --no-acls --no-attributes %_Null%
set ERRTEMP=%ERRORLEVEL%
if %ERRTEMP% neq 0 goto :E_Apply
if exist ISOFOLDER\MediaMeta.xml del /f /q ISOFOLDER\MediaMeta.xml %_Nul3%
:: rmdir /s /q ISOFOLDER\sources\uup\ %_Nul3%
if %_build% geq 18890 if %_build% lss 27500 (
wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\Boot\Fonts\* --dest-dir=ISOFOLDER\boot\fonts --no-acls --no-attributes %_Nul3%
xcopy /CRY ISOFOLDER\boot\fonts\* ISOFOLDER\efi\microsoft\boot\fonts\ %_Nul3%
)
if %_build% lss 17063 if exist ISOFOLDER\sources\ei.cfg (
if %AIO% equ 1 del /f /q ISOFOLDER\sources\ei.cfg %_Nul3%
if %_count% gtr 1 del /f /q ISOFOLDER\sources\ei.cfg %_Nul3%
)
if %_build% geq 17063 (
if exist "!_UUP!\ei.cfg" (copy /y "!_UUP!\ei.cfg" ISOFOLDER\sources\ei.cfg %_Nul3%) else if exist "ei.cfg" (copy /y "ei.cfg" ISOFOLDER\sources\ei.cfg %_Nul3%) 
if exist "!_UUP!\pid.txt" (copy /y "!_UUP!\pid.txt" ISOFOLDER\sources\pid.txt %_Nul3%) else if exist "pid.txt" (copy /y "pid.txt" ISOFOLDER\sources\pid.txt %_Nul3%) 
)
if %AIO% neq 1 if %_count% leq 1 if /i "%editionid%"=="PPIPro" (
(
echo [PID]
echo Value=XKCNC-J26Q9-KFHD2-FKTHY-KD72Y
)>ISOFOLDER\sources\pid.txt
)
for /f "tokens=5-10 delims=: " %%G in ('wimlib-imagex.exe info "!MetadataESD!" 3 ^| find /i "Last Modification Time"') do (set mmm=%%G&set "isotime=%%H/%%L,%%I:%%J:%%K")
for %%# in (Jan:01 Feb:02 Mar:03 Apr:04 May:05 Jun:06 Jul:07 Aug:08 Sep:09 Oct:10 Nov:11 Dec:12) do for /f "tokens=1,2 delims=:" %%A in ("%%#") do (
if /i %mmm%==%%A set "isotime=%%B/%isotime%"
)
set _file=ISOFOLDER\sources\%WIMFILE%
set _rtrn=RetISO
goto :InstallWim
:RetISO
if %WIMFILE%==install.esd (
set wim2swm=0
if %_Debug% neq 0 set SkipWinRE=1
)
set _rtrn=BakISO
goto :WinreWim
:BakISO
call :dk_color1 %Blue% "=== Creating boot.wim . . ." 4
if %AddUpdates% equ 2 if %_updexist% equ 1 (
call :uups_du
)
if %relite% equ 0 (set _srcwim=temp\winre.wim) else (set _srcwim=temp\boot.wim)
copy /y %_srcwim% ISOFOLDER\sources\boot.wim %_Nul1%
wimlib-imagex.exe info ISOFOLDER\sources\boot.wim 1 "Microsoft Windows PE (%arch%)" "Microsoft Windows PE (%arch%)" --image-property FLAGS=9 %_Nul3%
wimlib-imagex.exe update ISOFOLDER\sources\boot.wim 1 --command="delete '\Windows\system32\winpeshl.ini'" %_Nul3%
if %ForceDism% equ 0 (
call :BootPE
) else (
call :BootADK
)
if %RefESD% neq 0 call :uups_backup
if exist "!_cabdir!\" (
if %AddUpdates% equ 1 if %_updexist% equ 1 call :dk_color1 %Blue% "=== Removing temporary files . . ." 4
rmdir /s /q "!_cabdir!\" %_Nul3%
)
if %_extVirt% equ 1 if %DeleteSource% neq 1 (
set DVDLABEL=CCSA_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%MULTI_%archl%FRE_%langid%
)
if %StartVirtual% neq 0 if %_SrvESD% equ 0 if %_extVirt% equ 0 (
  ren ISOFOLDER %DVDISO%
  if %SkipISO% neq 0 (set qmsg=Finished. You chose not to create iso file.) else (set qmsg=Finished.)
  if %AutoStart% neq 0 (goto :V_Auto) else (goto :V_Manu)
)
set wimsort=0
for /f "tokens=3 delims=: " %%# in ('imagex /info ISOFOLDER\sources\%WimFile% ^|findstr /i /b /c:"Image Count"') do set finalimages=%%#
if defined SortEditions if %finalimages% gtr 1 if %_SrvESD% equ 0 (
if %_extVirt% equ 1 (set wimsort=1) else if %StartVirtual% equ 0 (set wimsort=1)
)
if %wimsort% equ 1 (
call :dk_color1 %Blue% "=== Sorting Edition{s} . . ." 4 5
call :doSort
)
set isiso=1
set _rtrn=finISO
goto :esdSWM
:finISO
:: === INCEPUT MODIFICARI PERSONALIZARE FINALA ISO ===
call :dk_color1 %Blue% "=== Aplicare personalizari finale structura ISO . . ." 4
if exist "!_work!\autounattend.xml" (
    echo Adaugare autounattend.xml in radacina si Panther...
    copy /y "!_work!\autounattend.xml" "ISOFOLDER\" %_Nul3%
    if not exist "ISOFOLDER\sources\$OEM$\$$\Panther" mkdir "ISOFOLDER\sources\$OEM$\$$\Panther" %_Nul3%
    copy /y "!_work!\autounattend.xml" "ISOFOLDER\sources\$OEM$\$$\Panther\" %_Nul3%
) else (
    call :dk_color1 %_Yellow% "[INFO] autounattend.xml nu a fost gasit langa script. Se omite copierea."
)

if exist "ISOFOLDER\support\" (
    echo Eliminare folder /support din structura ISO...
    rmdir /s /q "ISOFOLDER\support\" %_Nul3%
)
:: === SFARSIT MODIFICARI PERSONALIZARE FINALA ISO ===

if %SkipISO% neq 0 (
  ren ISOFOLDER %DVDISO%
  set qmsg=Finished. You chose not to create iso file.
  goto :QUIT
)

call :dk_color1 %Blue% "=== Creating ISO . . ." 4
if /i not %arch%==arm64 (
cdimage.exe -bootdata:2#p0,e,b"ISOFOLDER\boot\etfsboot.com"#pEF,e,b"ISOFOLDER\efi\Microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -t%isotime% -l%DVDLABEL% ISOFOLDER %DVDISO%.ISO %_Supp%
) else (
cdimage.exe -bootdata:1#pEF,e,b"ISOFOLDER\efi\Microsoft\boot\efisys.bin" -o -m -u2 -udfver102 -t%isotime% -l%DVDLABEL% ISOFOLDER %DVDISO%.ISO %_Supp%
)
set ERRTEMP=%ERRORLEVEL%
if %ERRTEMP% neq 0 goto :E_ISO
set qmsg=Finished.
goto :QUIT

:Single
@cls
call :dk_color1 %Gray% "=== Running UUP Converter %uivr% ===" 4 5
call :checkQE
set _initial=1
if %_updexist% equ 0 set AddUpdates=0
if %PREPARED% equ 0 call :PREPARE
call :optDrivers
if %_build% equ 25398 set SkipApps=1
if %_SrvESD% equ 1 set StubAppsFull=1
if %_IPA% equ 1 if %SkipApps% equ 0 set _runIPA=1
if %CustomList% neq 0 if exist "CustomAppsList*.txt" set _appsCustom=1
if %W10UI% equ 0 (set AddUpdates=0)
if /i %arch%==arm64 if %winbuild% lss 9600 if %AddUpdates% equ 1 (set AddUpdates=0)
if %Cleanup% equ 0 set ResetBase=0
if %_build% lss 17763 if %AddUpdates% equ 1 (set Cleanup=1)
if %_build% geq 22000 (
if %LCUwinre% equ 2 (set LCUwinre=0)
if %_build% geq 26052 (set LCUwinre=0)
)
if %_build% lss 22621 set LCUmsuExpand=0
if %_build% geq 26052 (
if %LCUmsuExpand% equ 2 (set LCUmsuExpand=0) else (set LCUmsuExpand=1)
)
if %_build% geq 25380 (
if %Cleanup% equ 0 set DisableUpdatingUpgrade=1
)
if %_build% geq 26000 (
if %DisableUpdatingUpgrade% equ 2 (set DisableUpdatingUpgrade=0) else (set DisableUpdatingUpgrade=1)
)
if %_build% geq 27965 (set NetFx3=0)
if %WIMFILE%==install.wim (
if %AddUpdates% neq 1 if %wim2esd% equ 1 (set WIMFILE=install.esd)
)
if %WIMFILE%==install.esd (
set wim2esd=0
if %AddUpdates% equ 1 (set WIMFILE=install.wim&set wim2esd=1)
if %_runIPA% equ 1 (set WIMFILE=install.wim&set wim2esd=1)
if defined DrvOpt (set WIMFILE=install.wim&set wim2esd=1)
)
if %_Debug% neq 0 set wim2esd=0
if exist "!_work!\%WIMFILE%" (
call :dk_color1 %Red% "An %WIMFILE% file is already present in the current folder" 4 5
(echo.&echo An %WIMFILE% file is already present in the current folder)>>"!logerr!"
goto :QUIT
)
for %%# in (
AutoStart
AddUpdates
Cleanup
ResetBase
SkipWinRE
LCUwinre
LCUmsuExpand
DisableUpdatingUpgrade
wim2esd
wim2swm
RefESD
SkipLCUmsu
SkipEdge
AutoExit
AddDrivers
SkipApps
AppsLevel
StubAppsFull
CustomList
) do (
if !%%#! neq 0 set _configured=1
)
if %_configured% equ 1 (
call :dk_color1 %Blue% "=== Configured Options . . ." 4 5
  if %AutoStart% neq 0 echo AutoStart %AutoStart%
  if %AddUpdates% equ 1 (
  echo AddUpdates %AddUpdates%
  if %Cleanup% neq 0 echo Cleanup
  if %Cleanup% neq 0 if %ResetBase% neq 0 echo ResetBase
  if %u_winre% neq 0 (echo LCUwinre %u_winre%) else (if %LCUwinre% neq 0 echo LCUwinre %LCUwinre%)
  if %u_msulcu% neq 0 (echo LCUmsuExpand %u_msulcu%) else (if %LCUmsuExpand% neq 0 echo LCUmsuExpand %LCUmsuExpand%)
  if %u_upgrade% neq 0 (echo DisableUpdatingUpgrade %u_upgrade%) else (if %DisableUpdatingUpgrade% neq 0 echo DisableUpdatingUpgrade %DisableUpdatingUpgrade%)
  )
  for %%# in (
  SkipWinRE
  wim2esd
  wim2swm
  RefESD
  AutoExit
  AddDrivers
  ) do (
  if !%%#! neq 0 echo %%#
  )
)
if %_build% geq 21382 if %SkipLCUmsu% neq 0 echo SkipLCUmsu
if %_build% geq 18362 if %AddUpdates% equ 1 if %SkipEdge% neq 0 echo SkipEdge %SkipEdge%
if %_build% geq 22563 if %W10UI% neq 0 (
if %SkipApps% neq 0 echo SkipApps
if %SkipApps% equ 0 (if %AppsLevel% neq 0 echo AppsLevel %AppsLevel%
if %StubAppsFull% neq 0 echo StubAppsFull
if %_appsCustom% neq 0 echo CustomAppsList)
)
if %_runIPA% equ 1 call :appx_sort
if %_IPA% equ 1 if %SkipApps% equ 1 (
if %_OPA% equ 1 call :appx_sort
)
call :uups_ref
if %AIO% equ 1 set "MetadataESD=!_UUP!\%uups_esd1%"&set "_flg=%edition1%"&set "_Srvr=%_ESDSrv1%"
if %_count% gtr 1 set "MetadataESD=!_UUP!\!uups_esd%_index1%!"&set "_flg=!edition%_index1%!"&set "_Srvr=!_ESDSrv%_index1%!"
set _file=%WIMFILE%
set _rtrn=RetWIM
goto :InstallWim
:RetWIM
if %WIMFILE%==install.esd (
set wim2swm=0
if %_Debug% neq 0 set SkipWinRE=1
)
set _rtrn=BakWIM
if %SkipWinRE% equ 0 goto :WinreWim
:BakWIM
if %RefESD% neq 0 call :uups_backup
if exist "!_cabdir!\" (
if %AddUpdates% equ 1 if %_updexist% equ 1 call :dk_color1 %Blue% "=== Removing temporary files . . ." 4
rmdir /s /q "!_cabdir!\" %_Nul3%
)
set isiso=0
set _rtrn=finWIM
goto :esdSWM
:finWIM
set qmsg=Finished.
goto :QUIT

:esdSWM
set cnvrt=%_file:~0,-4%
if %isiso% equ 1 pushd "ISOFOLDER\sources"
for /f %%# in ('dir /b /a:-d %WIMFILE%') do set "_size=000000%%~z#"
if %isiso% equ 1 popd
if "%_size%" lss "0000004194304000" set wim2swm=0
if %wim2esd% equ 0 if %wim2swm% equ 0 goto :%_rtrn%
if %wim2esd% equ 0 if %wim2swm% equ 1 goto :swmESD
call :dk_color1 %Blue% "=== Converting install.wim to install.esd . . ." 4 5
wimlib-imagex.exe export %cnvrt%.wim all %cnvrt%.esd --compress=LZMS --solid %_Supp%
set ERRTEMP=%ERRORLEVEL%
if %ERRTEMP% neq 0 (
call :dk_color1 %Red% "Errors were reported during export. Discarding install.esd" 4
(echo.&echo Errors were reported during export. Discarding install.esd)>>"!logerr!"
del /f /q %cnvrt%.esd %_Nul3%
)
if exist %cnvrt%.esd del /f /q %cnvrt%.wim
goto :%_rtrn%
:swmESD
call :dk_color1 %Blue% "=== Splitting install.wim into install*.swm . . ." 4 5
wimlib-imagex.exe split %cnvrt%.wim %cnvrt%.swm 3500 %_Supp%
set ERRTEMP=%ERRORLEVEL%
if %ERRTEMP% neq 0 (
call :dk_color1 %Red% "Errors were reported during split. Discarding install*.swm" 4
(echo.&echo Errors were reported during split. Discarding install*.swm)>>"!logerr!"
del /f /q %cnvrt%*.swm %_Nul3%
)
if exist %cnvrt%*.swm del /f /q %cnvrt%.wim
goto :%_rtrn%

:InstallWim
call :DismHostON
call :dk_color1 %Blue% "=== Creating %WIMFILE% . . ." 4 5
if exist "temp\*.ESD" (set _rrr=--ref="temp\*.esd") else (set "_rrr=")
if %WIMFILE%==install.wim set _rrr=%_rrr% --compress=LZX
wimlib-imagex.exe export "!MetadataESD!" 3 %_file% --ref="!_UUP!\*.esd" %_rrr% %_Supp%
set ERRTEMP=%ERRORLEVEL%
if %ERRTEMP% neq 0 goto :E_Export
if !_Srvr! equ 1 (
wimlib-imagex.exe info %_file% 1 "%_wsr% %_flg%" "%_wsr% %_flg%" --image-property DISPLAYNAME="!_dName!" --image-property DISPLAYDESCRIPTION="!_dDesc!" --image-property FLAGS=%_flg% %_Nul3%
) else if !FixDisplay! equ 1 (
wimlib-imagex.exe info %_file% 1 "!_os!" "!_os!" --image-property DISPLAYNAME="!_dName!" --image-property DISPLAYDESCRIPTION="!_dDesc!" --image-property FLAGS=%_flg% %_Nul3%
) else (
wimlib-imagex.exe info %_file% 1 --image-property DISPLAYNAME="!_dName!" --image-property DISPLAYDESCRIPTION="!_dDesc!" --image-property FLAGS=%_flg% %_Nul3%
)
set _img=1
if %_count% gtr 1 for /L %%i in (2,1,%_count%) do (
for /L %%# in (1,1,%uups_esd_num%) do if !_index%%i! equ %%# (
  wimlib-imagex.exe export "!_UUP!\!uups_esd%%#!" 3 %_file% --ref="!_UUP!\*.esd" %_rrr% %_Supp%
  call set ERRTEMP=!ERRORLEVEL!
  if !ERRTEMP! neq 0 goto :E_Export
  set /a _img+=1
  if !_ESDSrv%%#! equ 1 (
    wimlib-imagex.exe info %_file% !_img! "%_wsr% !edition%%#!" "%_wsr% !edition%%#!" --image-property DISPLAYNAME="!_dName%%#!" --image-property DISPLAYDESCRIPTION="!_dDesc%%#!" --image-property FLAGS=!edition%%#! %_Nul3%
    ) else if !FixDisplay! equ 1 (
    wimlib-imagex.exe info %_file% !_img! "!_os%%#!" "!_os%%#!" --image-property DISPLAYNAME="!_dName%%#!" --image-property DISPLAYDESCRIPTION="!_dDesc%%#!" --image-property FLAGS=!edition%%#! %_Nul3%
    ) else (
    wimlib-imagex.exe info %_file% !_img! --image-property DISPLAYNAME="!_dName%%#!" --image-property DISPLAYDESCRIPTION="!_dDesc%%#!" --image-property FLAGS=!edition%%#! %_Nul3%
    )
  )
)
if %AIO% equ 1 for /L %%# in (2,1,%uups_esd_num%) do (
wimlib-imagex.exe export "!_UUP!\!uups_esd%%#!" 3 %_file% --ref="!_UUP!\*.esd" %_rrr% %_Supp%
call set ERRTEMP=!ERRORLEVEL!
if !ERRTEMP! neq 0 goto :E_Export
if !_ESDSrv%%#! equ 1 (
  wimlib-imagex.exe info %_file% %%# "%_wsr% !edition%%#!" "%_wsr% !edition%%#!" --image-property DISPLAYNAME="!_dName%%#!" --image-property DISPLAYDESCRIPTION="!_dDesc%%#!" --image-property FLAGS=!edition%%#! %_Nul3%
  ) else if !FixDisplay! equ 1 (
  wimlib-imagex.exe info %_file% %%# "!_os%%#!" "!_os%%#!" --image-property DISPLAYNAME="!_dName%%#!" --image-property DISPLAYDESCRIPTION="!_dDesc%%#!" --image-property FLAGS=!edition%%#! %_Nul3%
  ) else (
  wimlib-imagex.exe info %_file% %%# --image-property DISPLAYNAME="!_dName%%#!" --image-property DISPLAYDESCRIPTION="!_dDesc%%#!" --image-property FLAGS=!edition%%#! %_Nul3%
  )
)
if %_updexist% equ 1 if %_build% geq 22000 if exist "%SysPath%\ucrtbase.dll" if not exist "bin\dpx.dll" if not exist "temp\dpx.dll" call :uups_dll dpx
if %_reMSU% equ 1 if %_build% geq 25336 call :uups_msu
if %_reMSU% equ 1 if %_build% lss 25336 (
if exist "!_UUP!\*Windows1*-KB*.wim" (call :uups_msu) else (if %SkipLCUmsu% equ 0 call :uups_msu)
)
if exist "!_cabdir!\" rmdir /s /q "!_cabdir!\"
del /f /q %_dLog%\* %_Nul3%
if not exist "%_dLog%\" mkdir "%_dLog%" %_Nul3%
if not exist "%SystemRoot%\temp\" mkdir "%SystemRoot%\temp" %_Nul3%
del /f /q %SystemRoot%\temp\*.mum %_Nul3%
set mounted=0
set _runDRV=0
if %AddUpdates% neq 1 if %W10UI% neq 0 if %_runIPA% equ 1 (
set mounted=1
if %_file%==%WIMFILE% (call :uups_update %WIMFILE% appx) else (call :uups_update install.iso appx)
)
if %AddUpdates% equ 1 if %_updexist% equ 1 (
set mounted=1
if %_file%==%WIMFILE% (call :uups_update %WIMFILE%) else (call :uups_update install.iso)
)
set _runDRV=1
if defined DrvOpt if %mounted% equ 0 (
if %_file%==%WIMFILE% (call :uups_update %WIMFILE%) else (call :uups_update install.iso)
)
if %_file%==%WIMFILE% goto :%_rtrn%
if %AddUpdates% equ 2 if %_updexist% equ 1 (
call :uups_external
)
goto :%_rtrn%

:WinreWim
call :dk_color1 %Blue% "=== Creating winre.wim . . ." 4 5
wimlib-imagex.exe export "!MetadataESD!" 2 temp\winre.wim --compress=LZX --boot %_Supp%
set ERRTEMP=%ERRORLEVEL%
if %ERRTEMP% neq 0 goto :E_Export
set mounted=0
set _runDRV=0
if %uwinpe% equ 1 if %AddUpdates% equ 1 if %_updexist% equ 1 (
set mounted=1
call :uups_update temp\winre.wim
)
set _runDRV=1
if defined DrvOpt if %mounted% equ 0 (
call :uups_update temp\winre.wim
)
if %relite% neq 0 (
echo.
ren temp\winre.wim boot.wim
wimlib-imagex.exe export temp\boot.wim 2 temp\winre.wim --compress=LZX --boot %_Supp%
wimlib-imagex.exe delete temp\boot.wim 2 --soft %_Nul3%
)
if %SkipWinRE% neq 0 goto :%_rtrn%
call :dk_color1 %Blue% "=== Adding winre.wim to %WIMFILE% . . ." 4
for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info %_file% ^| findstr /c:"Image Count"') do set imgcount=%%#
for /L %%# in (1,1,%imgcount%) do (
  wimlib-imagex.exe update %_file% %%# --command="add 'temp\winre.wim' '\windows\system32\recovery\winre.wim'" %_Null%
)
goto :%_rtrn%

:BootADK
if %W10UI% equ 0 goto :BootPE
if exist "%_mount%\" rmdir /s /q "%_mount%\"
if not exist "%_mount%\" mkdir "%_mount%"
%_dism1% /Mount-Wim /Wimfile:ISOFOLDER\sources\boot.wim /Index:1 /MountDir:"%_mount%" %_Supp%
set ERRTEMP=%ERRORLEVEL%
if %ERRTEMP% neq 0 (
call :dismount
rmdir /s /q "%_mount%\"
(echo.&echo Failed mounting boot.wim)>>"!logerr!"
goto :BootPE
)
call :wds_add
if %_build% geq 26052 if exist "%_mount%\Windows\Servicing\Packages\WinPE-Rejuv-Package~*.mum" (
for /f "delims=" %%# in ('dir /b /a:-d "%_mount%\Windows\Servicing\Packages\WinPE-Rejuv-Package~*.mum"') do (
  %_dism1% /Image:"%_mount%" /LogPath:"%_dLog%\DismNUL.log" /Remove-Package /PackageName:%%~n# %_Nul3%
  )
call :wds_rem
%_dism1% /Commit-Image /MountDir:"%_mount%" /Append %_Supp%
call :wds_add
set relite=1
set ready2=1
)
%_dism1% /Image:"%_mount%" /LogPath:"%_dLog%\DismNUL.log" /Set-TargetPath:X:\$windows.~bt\


if !errorlevel! neq 0 (
  (echo.&echo Dism.exe Set-TargetPath for boot.wim failed)>>"!logerr!"
  )
call :wds_rem
%_dism1% /Unmount-Wim /MountDir:"%_mount%" /Commit %_Supp%
set ERRTEMP=%ERRORLEVEL%
if %ERRTEMP% neq 0 (
call :dismount
rmdir /s /q "%_mount%\"
(echo.&echo Failed unmounting boot.wim)>>"!logerr!"
goto :BootPEf
)
rmdir /s /q "%_mount%\"
goto :BootST

:BootPE
wimlib-imagex.exe extract ISOFOLDER\sources\boot.wim 1 Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls --no-attributes %_Null%
offlinereg.exe .\bin\temp\SOFTWARE "Microsoft\Windows NT\CurrentVersion\WinPE" setvalue InstRoot X:\$windows.~bt\ %_Nul3%
offlinereg.exe .\bin\temp\SOFTWARE.new "Microsoft\Windows NT\CurrentVersion" setvalue SystemRoot X:\$windows.~bt\Windows %_Nul3%
del /f /q .\bin\temp\SOFTWARE
ren .\bin\temp\SOFTWARE.new SOFTWARE
type nul>bin\boot-wim.txt
>>bin\boot-wim.txt echo add 'bin^\temp^\SOFTWARE' '^\Windows^\System32^\config^\SOFTWARE'
set "_bkimg="
if exist "ISOFOLDER\sources\winpe.jpg" del /f /q ISOFOLDER\sources\winpe.jpg %_Nul3%
wimlib-imagex.exe extract ISOFOLDER\sources\boot.wim 1 Windows\System32\winpe.jpg --dest-dir=ISOFOLDER\sources --no-acls --no-attributes --nullglob %_Null%
for %%# in (background_cli.bmp, background_svr.bmp, background_cli.png, background_svr.png, winpe.jpg) do (if exist "ISOFOLDER\sources\%%#" if not defined _bkimg set "_bkimg=%%#")
if defined _bkimg if not exist "ISOFOLDER\sources\winpe.jpg" (
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%_bkimg%' '^\Windows^\system32^\winpe.jpg'
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%_bkimg%' '^\Windows^\system32^\winre.jpg'
)
wimlib-imagex.exe update ISOFOLDER\sources\boot.wim 1 < bin\boot-wim.txt %_Null%
rmdir /s /q bin\temp\

:BootST
wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\system32\xmllite.dll --dest-dir=ISOFOLDER\sources --no-acls --no-attributes %_Nul3%
type nul>bin\boot-wim.txt
if not defined ready2 (
>>bin\boot-wim.txt echo delete '^\Windows^\system32^\winpeshl.ini'
)
>>bin\boot-wim.txt echo add 'ISOFOLDER^\setup.exe' '^\setup.exe'
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\inf^\setup.cfg' '^\sources^\inf^\setup.cfg'
if not defined _bkimg (
if exist "ISOFOLDER\sources\winpe.jpg" del /f /q ISOFOLDER\sources\winpe.jpg %_Nul3%
wimlib-imagex.exe extract ISOFOLDER\sources\boot.wim 1 Windows\System32\winpe.jpg --dest-dir=ISOFOLDER\sources --no-acls --no-attributes --nullglob %_Null%
for %%# in (background_cli.bmp, background_svr.bmp, background_cli.png, background_svr.png, winpe.jpg) do (if exist "ISOFOLDER\sources\%%#" if not defined _bkimg set "_bkimg=%%#")
)
if defined _bkimg (
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%_bkimg%' '^\sources^\background.bmp'
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%_bkimg%' '^\Windows^\system32^\setup.bmp'
)
if defined _bkimg if not exist "ISOFOLDER\sources\winpe.jpg" (
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%_bkimg%' '^\Windows^\system32^\winpe.jpg'
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%_bkimg%' '^\Windows^\system32^\winre.jpg'
)
for /f %%# in (bin\bootwim.txt) do if exist "ISOFOLDER\sources\%%#" @(
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%%#' '^\sources^\%%#'
)
for /f %%# in (bin\bootmui.txt) do if exist "ISOFOLDER\sources\%langid%\%%#" @(
>>bin\boot-wim.txt echo add 'ISOFOLDER^\sources^\%langid%^\%%#' '^\sources^\%langid%^\%%#'
)
if not defined ready2 (
wimlib-imagex.exe export %_srcwim% 1 ISOFOLDER\sources\boot.wim "Microsoft Windows Setup (%arch%)" "Microsoft Windows Setup (%arch%)" --boot %_Supp%
) else (
wimlib-imagex.exe info ISOFOLDER\sources\boot.wim 2 "Microsoft Windows Setup (%arch%)" "Microsoft Windows Setup (%arch%)" --boot %_Nul3%
)
wimlib-imagex.exe update ISOFOLDER\sources\boot.wim 2 < bin\boot-wim.txt %_Null%
wimlib-imagex.exe info ISOFOLDER\sources\boot.wim 2 --image-property FLAGS=2 %_Nul3%


if defined _bkimg (
wimlib-imagex.exe update ISOFOLDER\sources\boot.wim 1 --command="add 'ISOFOLDER\sources\%_bkimg%' '\Windows\system32\winpe.jpg'" %_Nul3%
)
if %relite% neq 0 (
call :dk_color1 %Blue% "=== Rebuilding boot.wim . . ." 4 5
%_wrb% wimlib-imagex.exe optimize ISOFOLDER\sources\boot.wim %_Supp%
)
del /f /q bin\boot-wim.txt %_Nul3%
del /f /q ISOFOLDER\sources\xmllite.dll %_Nul3%
del /f /q ISOFOLDER\sources\winpe.jpg %_Nul3%
exit /b


:INFO
if %PREPARED% equ 0 call :PREPARE
@cls
call :dk_color2 %_White% "                " %Blue% "=== UUP Contents Info ===" 0 8
echo      Arch: %arch%
echo  Language: %langid%
echo   Version: %ver1%.%ver2%.%_build%.%svcbuild%
echo    Branch: %branch%
echo        OS: %_os%
echo.
%_Contn%&%_Pause%
goto :MAINMENU

:INFOAIO
if %PREPARED% equ 0 call :PREPARE
@cls
call :dk_color2 %_White% "                " %Blue% "=== UUP Contents Info ===" 0 8
echo      Arch: %arch%
echo   Version: %ver1%.%ver2%.%_build%.%svcbuild%
echo    Branch: %branch%
echo  Editions:
for /L %%# in (1,1,%uups_esd_num%) do (
echo %%#. !_name%%#!
)
echo.
%_Contn%&%_Pause%
goto :MAINMENU

:PREPARE
if %_initial% equ 0 @cls
call :dk_color1 %Blue% "=== Checking UUP Info . . ."
set PREPARED=1
if %AIO% equ 1 set "MetadataESD=!_UUP!\%uups_esd1%"&set "_flg=%edition1%"&set "arch=%arch1%"&set "langid=%langid1%"&set "_oName=%_oname1%"&set "_Srvr=%_ESDSrv1%"
if %_count% gtr 1 set "MetadataESD=!_UUP!\!uups_esd%_index1%!"&set "_flg=!edition%_index1%!"&set "arch=!arch%_index1%!"&set "langid=!langid%_index1%!"&set "_oName=!_oname%_index1%!"&set "_Srvr=!_ESDSrv%_index1%!"
imagex /info "!MetadataESD!" 3 >bin\info.txt 2>&1
for /f "tokens=3 delims=<>" %%# in ('find /i "<MAJOR>" bin\info.txt') do set ver1=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<MINOR>" bin\info.txt') do set ver2=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<BUILD>" bin\info.txt') do set _build=%%#
for /f "tokens=3 delims=<>" %%# in ('find /i "<SPBUILD>" bin\info.txt') do set svcbuild=%%#
for /f "tokens=3 delims=<>" %%# in ('imagex /info "!MetadataESD!" 3 ^| find /i "<DISPLAYNAME>" %_Nul6%') do if /i "%%#"=="/DISPLAYNAME" (set FixDisplay=1)
set /a _fixSV=%_build%+1
if %uups_esd_num% gtr 1 for /L %%A in (2,1,%uups_esd_num%) do (
imagex /info "!_UUP!\!uups_esd%%A!" 3 >bin\info%%A.txt 2>&1
)
for /f "tokens=*" %%A in ('chcp') do for %%B in (%%A) do set "oemcp=%%~nB"
>nul chcp 65001
cmd.exe /u /c type bin\info.txt>bin\infou.txt
if %uups_esd_num% gtr 1 for /L %%A in (2,1,%uups_esd_num%) do (
cmd.exe /u /c type bin\info%%A.txt>bin\info%%Au.txt
)
for /f "tokens=3 delims=<>" %%# in ('find /i "<NAME>" bin\infou.txt') do (set "_dName=%%#"&set "_os=%%#")
for /f "tokens=3 delims=<>" %%# in ('find /i "<DESCRIPTION>" bin\infou.txt') do set "_dDesc=%%#"
for %%# in (ru-ru,zh-cn,zh-tw,zh-hk) do if /i %langid%==%%# set "_os=!_oName!"
if %uups_esd_num% gtr 1 for /L %%A in (2,1,%uups_esd_num%) do (
for /f "tokens=3 delims=<>" %%# in ('find /i "<NAME>" bin\info%%Au.txt') do (set "_dName%%A=%%#"&set "_os%%A=%%#")
for /f "tokens=3 delims=<>" %%# in ('find /i "<DESCRIPTION>" bin\info%%Au.txt') do set "_dDesc%%A=%%#"
for %%# in (ru-ru,zh-cn,zh-tw,zh-hk) do if /i !langid%%A!==%%# set "_os%%A=!_oName%%A!"
)
>nul chcp %oemcp%
del /f /q bin\info*.txt
if %_build% geq 21382 if exist "!_UUP!\*.AggregatedMetadata*.cab" if exist "!_UUP!\*Windows1*-KB*.cab" if exist "!_UUP!\*Windows1*-KB*.psf" set _reMSU=1
if %_build% geq 22621 if exist "!_UUP!\*.AggregatedMetadata*.cab" if exist "!_UUP!\*Windows1*-KB*.wim" if exist "!_UUP!\*Windows1*-KB*.psf" set _reMSU=1
if %_build% geq 22563 (
if exist "!_UUP!\*.appx*" set _OPA=1
if exist "!_UUP!\*.msix*" set _OPA=1
)
if %_build% geq 22563 if exist "!_UUP!\*.AggregatedMetadata*.cab" (
if %_OPA% equ 1 set _IPA=1
if exist "!_UUP!\Apps\*_8wekyb3d8bbwe" set _IPA=1
)
if %_build% geq 22621 if exist "!_UUP!\*Edge*.wim" (
set _wimEdge=1
if not exist "!_UUP!\Edge.wim" for /f %%# in ('dir /b /a:-d "!_UUP!\*Edge*.wim"') do rename "!_UUP!\%%#" Edge.wim %_Nul3%
)
set _dpx=0
if %_updexist% equ 1 if %_build% geq 22000 if exist "%SysPath%\ucrtbase.dll" if exist "!_UUP!\*DesktopDeployment*.cab" (
if /i %arch%==%xOS% set _dpx=1
if /i %arch%==x64 if /i %xOS%==amd64 set _dpx=1
)
if %_dpx% equ 1 (
for /f "delims=" %%# in ('dir /b /a:-d "!_UUP!\*DesktopDeployment*.cab"') do expand.exe -f:dpx.dll "!_UUP!\%%#" .\temp %_Null%
copy /y %SysPath%\expand.exe temp\ %_Nul3%
)
wimlib-imagex.exe extract "!MetadataESD!" 1 sources\ei.cfg --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
if exist "bin\temp\ei.cfg" type .\bin\temp\ei.cfg %_Nul2% | find /i "Volume" %_Nul1% && set VOL=1
wimlib-imagex.exe extract "!MetadataESD!" 1 sources\setuphost.exe --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
7z.exe l .\bin\temp\setuphost.exe >.\bin\temp\version.txt 2>&1
if %_build% geq 22478 (
wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\System32\UpdateAgent.dll --dest-dir=.\bin\temp --no-acls --no-attributes --ref="!_UUP!\*.esd" %_Nul3%
if exist "bin\temp\UpdateAgent.dll" 7z.exe l .\bin\temp\UpdateAgent.dll >.\bin\temp\version.txt 2>&1
)
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" .\bin\temp\version.txt" %_Nul6%') do (set uupver=%%i.%%j&set uupmaj=%%i&set uupmin=%%j&set branch=%%k&set uupdate=%%l)
set revver=%uupver%&set revmaj=%uupmaj%&set revmin=%uupmin%
set "tok=6,7"&set "toe=5,6,7"
if /i %arch%==x86 (set _ss=x86) else if /i %arch%==x64 (set _ss=amd64) else (set _ss=arm64)
wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\WinSxS\Manifests\%_ss%_microsoft-windows-coreos-revision*.manifest --dest-dir=.\bin\temp --no-acls --no-attributes --ref="!_UUP!\*.esd" %_Nul3%
if exist "bin\temp\*_microsoft-windows-coreos-revision*.manifest" for /f "tokens=%tok% delims=_." %%i in ('dir /b /a:-d /od .\bin\temp\*_microsoft-windows-coreos-revision*.manifest') do (set revver=%%i.%%j&set revmaj=%%i&set revmin=%%j)
if %_build% geq 15063 (
wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls --no-attributes %_Null%
set "isokey=Microsoft\Windows NT\CurrentVersion\Update\TargetingInfo\Installed"
for /f %%i in ('"offlinereg.exe .\bin\temp\SOFTWARE "!isokey!" enumkeys %_Nul6% ^| findstr /i /r "Client\.OS Server\.OS WNC\.OS WCOSDevice""') do if not errorlevel 1 (
  for /f "tokens=3 delims==:" %%A in ('"offlinereg.exe .\bin\temp\SOFTWARE "!isokey!\%%i" getvalue Branch %_Nul6%"') do set "revbranch=%%~A"
  for /f "tokens=5,6 delims==:." %%A in ('"offlinereg.exe .\bin\temp\SOFTWARE "!isokey!\%%i" getvalue Version %_Nul6%"') do if %%A gtr !revmaj! (
    set "revver=%%~A.%%B
    set revmaj=%%~A
    set "revmin=%%B
    )
  )
)
if defined revbranch set branch=%revbranch%
call :fixBranch %revmaj%
if %uupmin% lss %revmin% (
set uupver=%revver%
set uupmin=%revmin%
wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\Servicing\Packages\Package_for_RollupFix*.mum --dest-dir=.\bin\temp --no-acls --no-attributes %_Nul3%
for /f %%# in ('dir /b /a:-d /od bin\temp\Package_for_RollupFix*.mum') do copy /y "bin\temp\%%#" %SystemRoot%\temp\update.mum %_Nul1%
call :datemum uupdate placebo
)
set _legacy=
set _useold=0
if /i "%branch%"=="WinBuild" set _useold=1
if /i "%branch%"=="GitEnlistment" set _useold=1
if /i "%uupdate%"=="winpbld" set _useold=1
if %_useold% equ 1 (
wimlib-imagex.exe extract "!MetadataESD!" 3 Windows\System32\config\SOFTWARE --dest-dir=.\bin\temp --no-acls --no-attributes %_Null%
for /f "tokens=3 delims==:" %%# in ('"offlinereg.exe .\bin\temp\SOFTWARE "Microsoft\Windows NT\CurrentVersion" getvalue BuildLabEx" %_Nul6%') do if not errorlevel 1 (for /f "tokens=1-5 delims=." %%i in ('echo %%~#') do set _legacy=%%i.%%j.%%m.%%l&set branch=%%l)
)
if defined _legacy (set _label=%_legacy%) else (set _label=%uupver%.%uupdate%.%branch%)
rmdir /s /q bin\temp\
set "apiver=0"
if %_ADK% equ 1 if exist "%DandIRoot%\%xOS%\DISM\dismapi.dll" (
7z.exe l "%DandIRoot%\%xOS%\DISM\dismapi.dll" >.\bin\version.txt 2>&1
for /f "tokens=3 delims=." %%i in ('"findstr /i /b "FileVersion" .\bin\version.txt" %_Nul6%') do set "apiver=%%i"
del /f /q .\bin\version.txt %_Nul3%
)
set _bit=%arch%
if /i %arch%==arm64 set _bit=arm
set c_pkg=
set c_ver=0
set c_num=0
set s_pkg=
set ssvr_aa=0
set ssvr_bl=0
set ssvr_mj=0
set ssvr_mn=0
set savc=0&set savr=1&set rbvr=0
if %_build% geq 18362 (set savc=3&set savr=3)
if %_build% geq 25380 (set rbvr=1)

:setlabel
if %_SrvESD% equ 1 (set _label=%_label%_SERVER) else (set _label=%_label%_CLIENT)
for %%# in (A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
set _label=!_label:%%#=%%#!
set branch=!branch:%%#=%%#!
set langid=!langid:%%#=%%#!
set editionid=!editionid:%%#=%%#!
)
if /i %arch%==x86 set archl=X86
if /i %arch%==x64 set archl=X64
if /i %arch%==arm64 set archl=A64

if %_SrvESD% equ 1 (
if %AIO% equ 1 set DVDLABEL=SSS_%archl%FRE_%langid%_DV9&set DVDISO=%_label%_%archl%FRE_%langid%&exit /b
if %_count% gtr 1 set DVDLABEL=SSS_%archl%FRE_%langid%_DV9&set DVDISO=%_label%_%archl%FRE_%langid%&exit /b
)
set _ddv=DV5
if %_build% geq 22621 set _ddv=DV9
if %AIO% equ 1 set DVDLABEL=CCSA_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%MULTI_%archl%FRE_%langid%&exit /b
if %_count% gtr 1 set DVDLABEL=CCSA_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%MULTI_%archl%FRE_%langid%&exit /b

:virtlabel
set _ddv=DV5
if %_build% geq 22621 set _ddv=DV9
set DVDLABEL=CCSA_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%%editionid%_RET_%archl%FRE_%langid%
if %_SrvESD% equ 1 set DVDLABEL=SSS_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%-%editionid%_RET_%archl%FRE_%langid%
if /i %editionid%==Core set DVDLABEL=CCRA_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%CORE_OEMRET_%archl%FRE_%langid%&exit /b
if /i %editionid%==CoreN set DVDLABEL=CCRNA_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%COREN_OEMRET_%archl%FRE_%langid%&exit /b
if /i %editionid%==CoreSingleLanguage set DVDLABEL=CSLA_%archl%FREO_%langid%_%_ddv%&set DVDISO=%_label%SINGLELANGUAGE_OEM_%archl%FRE_%langid%&exit /b
if /i %editionid%==CoreCountrySpecific set DVDLABEL=CCHA_%archl%FREO_%langid%_%_ddv%&set DVDISO=%_label%CHINA_OEM_%archl%FRE_%langid%&exit /b
if /i %editionid%==Professional (if %VOL% equ 1 (set DVDLABEL=CPRA_%archl%FREV_%langid%_%_ddv%&set DVDISO=%_label%PROFESSIONALVL_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CPRA_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%PRO_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==ProfessionalN (if %VOL% equ 1 (set DVDLABEL=CPRNA_%archl%FREV_%langid%_%_ddv%&set DVDISO=%_label%PROFESSIONALNVL_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CPRNA_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%PRON_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==Education (if %VOL% equ 1 (set DVDLABEL=CEDA_%archl%FREV_%langid%_%_ddv%&set DVDISO=%_label%EDUCATION_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CEDA_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%EDUCATION_RET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==EducationN (if %VOL% equ 1 (set DVDLABEL=CEDNA_%archl%FREV_%langid%_%_ddv%&set DVDISO=%_label%EDUCATIONN_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CEDNA_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%EDUCATIONN_RET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==Enterprise set DVDLABEL=CENA_%archl%FREV_%langid%_%_ddv%&set DVDISO=%_label%ENTERPRISE_VOL_%archl%FRE_%langid%&exit /b
if /i %editionid%==EnterpriseN set DVDLABEL=CENNA_%archl%FREV_%langid%_%_ddv%&set DVDISO=%_label%ENTERPRISEN_VOL_%archl%FRE_%langid%&exit /b
if /i %editionid%==Cloud set DVDLABEL=CWCA_%archl%FREO_%langid%_%_ddv%&set DVDISO=%_label%CLOUD_OEM_%archl%FRE_%langid%&exit /b
if /i %editionid%==CloudN set DVDLABEL=CWCNNA_%archl%FREO_%langid%_%_ddv%&set DVDISO=%_label%CLOUDN_OEM_%archl%FRE_%langid%&exit /b
if /i %editionid%==PPIPro set DVDLABEL=CPPIA_%archl%FREO_%langid%_%_ddv%&set DVDISO=%_label%PPIPRO_OEM_%archl%FRE_%langid%&exit /b
if /i %editionid%==EnterpriseG set DVDLABEL=CENG_%archl%FREV_%langid%_%_ddv%&set DVDISO=%_label%ENTERPRISEG_VOL_%archl%FRE_%langid%&exit /b
if /i %editionid%==EnterpriseGN set DVDLABEL=CENGN_%archl%FREV_%langid%_%_ddv%&set DVDISO=%_label%ENTERPRISEGN_VOL_%archl%FRE_%langid%&exit /b
if /i %editionid%==EnterpriseS set DVDLABEL=CES_%archl%FREV_%langid%_%_ddv%&set DVDISO=%_label%ENTERPRISES_VOL_%archl%FRE_%langid%&exit /b
if /i %editionid%==EnterpriseSN set DVDLABEL=CESNN_%archl%FREV_%langid%_%_ddv%&set DVDISO=%_label%ENTERPRISESN_VOL_%archl%FRE_%langid%&exit /b
if /i %editionid%==ProfessionalEducation (if %VOL% equ 1 (set DVDLABEL=CPREA_%archl%FREV_%langid%_%_ddv%&set DVDISO=%_label%PROEDUCATION_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CPREA_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%PROEDUCATION_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==ProfessionalEducationN (if %VOL% equ 1 (set DVDLABEL=CPRENA_%archl%FREV_%langid%_%_ddv%&set DVDISO=%_label%PROEDUCATIONN_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CPRENA_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%PROEDUCATIONN_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==ProfessionalWorkstation (if %VOL% equ 1 (set DVDLABEL=CPRWA_%archl%FREV_%langid%_%_ddv%&set DVDISO=%_label%PROWORKSTATION_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CPRWA_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%PROWORKSTATION_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==ProfessionalWorkstationN (if %VOL% equ 1 (set DVDLABEL=CPRWNA_%archl%FREV_%langid%_%_ddv%&set DVDISO=%_label%PROWORKSTATIONN_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CPRWNA_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%PROWORKSTATIONN_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==ProfessionalSingleLanguage set DVDLABEL=CPRSLA_%archl%FREO_%langid%_%_ddv%&set DVDISO=%_label%PROSINGLELANGUAGE_OEM_%archl%FRE_%langid%&exit /b
if /i %editionid%==ProfessionalCountrySpecific set DVDLABEL=CPRCHA_%archl%FREO_%langid%_%_ddv%&set DVDISO=%_label%PROCHINA_OEM_%archl%FRE_%langid%&exit /b
if /i %editionid%==CloudEdition (if %VOL% equ 1 (set DVDLABEL=CWCA_%archl%FREV_%langid%_%_ddv%&set DVDISO=%_label%CLOUD_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CWCA_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%CLOUD_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==CloudEditionN (if %VOL% equ 1 (set DVDLABEL=CWCNNA_%archl%FREV_%langid%_%_ddv%&set DVDISO=%_label%CLOUDN_VOL_%archl%FRE_%langid%) else (set DVDLABEL=CWCNNA_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%CLOUDN_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==ServerStandard (if %VOL% equ 1 (set DVDLABEL=SSS_%archl%FREV_%langid%_%_ddv%&set DVDISO=%_label%STANDARD_VOL_%archl%FRE_%langid%) else (set DVDLABEL=SSS_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%STANDARD_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==ServerStandardCore (if %VOL% equ 1 (set DVDLABEL=SSS_%archl%FREV_%langid%_%_ddv%&set DVDISO=%_label%STANDARDCORE_VOL_%archl%FRE_%langid%) else (set DVDLABEL=SSS_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%STANDARDCORE_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==ServerDatacenter (if %VOL% equ 1 (set DVDLABEL=SSS_%archl%FREV_%langid%_%_ddv%&set DVDISO=%_label%DATACENTER_VOL_%archl%FRE_%langid%) else (set DVDLABEL=SSS_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%DATACENTER_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==ServerDatacenterCore (if %VOL% equ 1 (set DVDLABEL=SSS_%archl%FREV_%langid%_%_ddv%&set DVDISO=%_label%DATACENTERCORE_VOL_%archl%FRE_%langid%) else (set DVDLABEL=SSS_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%DATACENTERCORE_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==ServerTurbine (if %VOL% equ 1 (set DVDLABEL=SADC_%archl%FREV_%langid%_%_ddv%&set DVDISO=%_label%TURBINE_VOL_%archl%FRE_%langid%) else (set DVDLABEL=SADC_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%TURBINE_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==ServerTurbineCore (if %VOL% equ 1 (set DVDLABEL=SADC_%archl%FREV_%langid%_%_ddv%&set DVDISO=%_label%TURBINECOR_VOL_%archl%FRE_%langid%) else (set DVDLABEL=SADC_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%TURBINECOR_OEMRET_%archl%FRE_%langid%))&exit /b
if /i %editionid%==ServerAzureStackHCICor set DVDLABEL=SASH_%archl%FRE_%langid%_%_ddv%&set DVDISO=%_label%AZURESTACKHCI_RET_%archl%FRE_%langid%&exit /b
exit /b

:fixBranch
if %1==18363 if /i "%branch:~0,4%"=="19h1" set branch=19h2%branch:~4%
if %1==19042 if /i "%branch:~0,2%"=="vb" set branch=20h2%branch:~2%
if %1==19043 if /i "%branch:~0,2%"=="vb" set branch=21h1%branch:~2%
if %1==19044 if /i "%branch:~0,2%"=="vb" set branch=21h2%branch:~2%
if %1==19045 if /i "%branch:~0,2%"=="vb" set branch=22h2%branch:~2%
if %1==20349 if /i "%branch:~0,2%"=="fe" set branch=22h2%branch:~2%
if %1==22631 if /i "%branch:~0,2%"=="ni" (echo %branch% | find /i "beta" %_Nul1% || set branch=23h2_ni%branch:~2%)
if %1==26200 if /i "%branch:~0,2%"=="ge" (echo %branch% | findstr /i /r "beta prerelease" %_Nul1% || set branch=25h2_ge%branch:~2%)
exit /b

:fixVerBrn
set "_ti=!%2!"
set "_tv=!%3!"
set "_tb=!%4!"
if %1==18363 (
if /i "%_ti:~0,4%"=="19h1" set _ti=19h2%_ti:~4%
if %_tv:~0,5%==18362 set _tv=18363%_tv:~5%
if /i "%_tb:~0,4%"=="19h1" set _tb=19h2%_tb:~4%
)
if %1==19042 (
if /i "%_ti:~0,2%"=="vb" set _ti=20h2%_ti:~2%
if %_tv:~0,5%==19041 set _tv=19042%_tv:~5%
if /i "%_tb:~0,2%"=="vb" set _tb=20h2%_tb:~2%
)
if %1==19043 (
if /i "%_ti:~0,2%"=="vb" set _ti=21h1%_ti:~2%
if %_tv:~0,5%==19041 set _tv=19043%_tv:~5%
if /i "%_tb:~0,2%"=="vb" set _tb=21h1%_tb:~2%
)
if %1==19044 (
if /i "%_ti:~0,2%"=="vb" set _ti=21h2%_ti:~2%
if %_tv:~0,5%==19041 set _tv=19044%_tv:~5%
if /i "%_tb:~0,2%"=="vb" set _tb=21h2%_tb:~2%
)
if %1==19045 (
if /i "%_ti:~0,2%"=="vb" set _ti=22h2%_ti:~2%
if %_tv:~0,5%==19041 set _tv=19045%_tv:~5%
if /i "%_tb:~0,2%"=="vb" set _tb=22h2%_tb:~2%
)
if %1==20349 (
if /i "%_ti:~0,2%"=="fe" set _ti=22h2%_ti:~2%
if %_tv:~0,5%==20348 set _tv=20349%_tv:~5%
if /i "%_tb:~0,2%"=="fe" set _tb=22h2%_tb:~2%
)
if %1==%_fixSV% if %_build% geq 21382 (
if %_tv:~0,5%==%_build% set _tv=%_fixSV%%_tv:~5%
)
if %1==22631 (
if /i "%_ti:~0,2%"=="ni" (echo %_ti% | find /i "beta" %_Nul1% || set _ti=23h2_ni%_ti:~2%)
if %_tv:~0,5%==22621 set _tv=22631%_tv:~5%
if /i "%_tb:~0,2%"=="ni" (echo %_tb% | find /i "beta" %_Nul1% || set _tb=23h2_ni%_tb:~2%)
)
if %1==26200 (
if /i "%_ti:~0,2%"=="ge" (echo %_ti% | findstr /i /r "beta prerelease" %_Nul1% || set _ti=25h2_ge%_ti:~2%)
if %_tv:~0,5%==26100 set _tv=26200%_tv:~5%
if /i "%_tb:~0,2%"=="ge" (echo %_tb% | findstr /i /r "beta prerelease" %_Nul1% || set _tb=25h2_ge%_tb:~2%)
)
set "%2=%_ti%"
set "%3=%_tv%"
set "%4=%_tb%"
exit /b

:datemum
set "mumfile=%SystemRoot%\temp\update.mum"
set "chkfile=!mumfile:\=\\!"
if %_cwmi% equ 1 for /f "tokens=2 delims==" %%# in ('wmic datafile where "name='!chkfile!'" get LastModified /value') do set "mumdate=%%#"
if %_cwmi% equ 0 for /f %%# in ('%_psc% "([WMI]'CIM_DataFile.Name=''!chkfile!''').LastModified"') do set "mumdate=%%#"
set "%1=!mumdate:~2,2!!mumdate:~4,2!!mumdate:~6,2!-!mumdate:~8,4!"
set "%2=!mumdate:~4,2!/!mumdate:~6,2!/!mumdate:~0,4!,!mumdate:~8,2!:!mumdate:~10,2!:!mumdate:~12,2!"
exit /b

:uups_ref
call :dk_color1 %Blue% "=== Preparing Reference ESDs . . ." 4
if %RefESD% neq 0 (set _level=LZX) else (set _level=XPRESS)
if exist "!_UUP!\*.xml.cab" if exist "!_UUP!\Metadata\*" move /y "!_UUP!\*.xml.cab" "!_UUP!\Metadata\" %_Nul3%
set _doEcho=
if exist "!_UUP!\*.cab" (
for /f "tokens=* delims=" %%# in ('dir /b /a:-d "!_UUP!\*.cab"') do (
	del /f /q temp\update.mum %_Null%
	expand.exe -f:update.mum "!_UUP!\%%#" .\temp %_Null%
	if exist "temp\update.mum" call :uups_cab "%%#"
	)
)
if %EXPRESS% equ 1 (
for /f "tokens=* delims=" %%# in ('dir /b /a:d /o:-n "!_UUP!\"') do call :uups_dir "%%#"
)
if exist "!_UUP!\Metadata\*.xml.cab" copy /y "!_UUP!\Metadata\*.xml.cab" "!_UUP!\" %_Nul3%
exit /b

:uups_dir
set cbsp=%~1
if exist "!_work!\temp\%cbsp%.ESD" exit /b
echo %cbsp%| findstr /i /r "Windows.*-KB SSU-.* RetailDemo Holographic-Desktop-FOD" %_Nul1% && exit /b
if /i "%cbsp%"=="Metadata" exit /b
if not defined _doEcho echo.
echo DIR-^>ESD: %cbsp%
rmdir /s /q "!_UUP!\%~1\$dpx$.tmp\" %_Nul3%
wimlib-imagex.exe capture "!_UUP!\%~1" "temp\%cbsp%.ESD" --compress=%_level% --check --no-acls --norpfix "Edition Package" "Edition Package" %_Null%
set _doEcho=1
exit /b

:uups_cab
set cbsp=%~n1
if exist "!_work!\temp\%cbsp%.ESD" exit /b
echo %cbsp%| findstr /i /r "Windows.*-KB SSU-.* RetailDemo Holographic-Desktop-FOD" %_Nul1% && exit /b
if not defined _doEcho echo.
echo %cbsp%
set /a _ref+=1
set /a _rnd=%random%
set _dst=%_drv%\_tmp%_ref%
if exist "%_dst%" (set _dst=%_drv%\_tmp%_rnd%)
mkdir %_dst% %_Nul3%
expand.exe -f:* "!_UUP!\%cbsp%.cab" %_dst%\ %_Null%
wimlib-imagex.exe capture "%_dst%" "temp\%cbsp%.ESD" --compress=%_level% --check --no-acls --norpfix "Edition Package" "Edition Package" %_Null%
rmdir /s /q %_dst%\ %_Nul3%
if exist "%_dst%\" (
mkdir %_drv%\_del %_Null%
robocopy %_drv%\_del %_dst% /MIR /R:1 /W:1 /NFL /NDL /NP /NJH /NJS %_Null%
rmdir /s /q %_drv%\_del\ %_Null%
rmdir /s /q %_dst%\ %_Null%
)
set _doEcho=1
exit /b

:uups_esd
set _ESDSrv%1=0
for /f "tokens=2 delims=]" %%# in ('find /v /n "" temp\uups_esd.txt ^| find "[%1]"') do set uups_esd=%%#
set "uups_esd%1=%uups_esd%"
wimlib-imagex.exe info "!_UUP!\%uups_esd%" 3 %_Nul3%
set ERRTEMP=%ERRORLEVEL%
if %ERRTEMP% equ 73 (
%_err%
echo %uups_esd% file is corrupted
echo.
(echo.&echo %uups_esd% file is corrupted)>>"!logerr!"
set eWIMLIB=1
exit /b
)
if %ERRTEMP% neq 0 (
%_err%
echo Could not parse info from %uups_esd%
echo.
(echo.&echo Could not parse info from %uups_esd%)>>"!logerr!"
set eWIMLIB=1
exit /b
)
imagex /info "!_UUP!\%uups_esd%" 3 >bin\info.txt 2>&1
for /f "tokens=3 delims=<>" %%# in ('find /i "<DEFAULT>" bin\info.txt') do set "langid%1=%%#"
for /f "tokens=3 delims=<>" %%# in ('find /i "<EDITIONID>" bin\info.txt') do set "edition%1=%%#"
for /f "tokens=3 delims=<>" %%# in ('find /i "<ARCH>" bin\info.txt') do (if %%# equ 0 (set "arch%1=x86") else if %%# equ 9 (set "arch%1=x64") else (set "arch%1=arm64"))
for /f "tokens=3 delims=<>" %%# in ('find /i "<NAME>" bin\info.txt') do set "_oname%1=%%#"
for /f "tokens=3 delims=<>" %%# in ('find /i "<BUILD>" bin\info.txt') do set _obuild%1=%%#
set "_wtx=Windows 10"
find /i "<NAME>" bin\info.txt %_Nul2% | find /i "Windows 11" %_Nul1% && (set "_wtx=Windows 11")
find /i "<NAME>" bin\info.txt %_Nul2% | find /i "Windows 12" %_Nul1% && (set "_wtx=Windows 12")
echo !edition%1!|findstr /i /b "Server" %_Nul3% && (set _SrvESD=1&set _ESDSrv%1=1)
set "_wsr=Windows Server 2022"
if !_ESDSrv%1! equ 1 (
find /i "<NAME>" bin\info.txt %_Nul2% | find /i " 2025" %_Nul1% && (set "_wsr=Windows Server 2025")
if !_obuild%1! geq 26010 (set "_wsr=Windows Server 2025")
)
if !_ESDSrv%1! equ 1 findstr /i /c:"Server Core" bin\info.txt %_Nul3% && (
if /i "!edition%1!"=="ServerStandard" set "edition%1=ServerStandardCore"
if /i "!edition%1!"=="ServerDatacenter" set "edition%1=ServerDatacenterCore"
if /i "!edition%1!"=="ServerTurbine" set "edition%1=ServerTurbineCore"
)
set uLang=0
for %%# in (ru-ru,zh-cn,zh-tw,zh-hk) do if /i !langid%1!==%%# set uLang=1
if %uLang% equ 1 for %%# in (
"Cloud:%_wtx% S"
"CloudN:%_wtx% S N"
"CloudE:%_wtx% Lean"
"CloudEN:%_wtx% Lean N"
"CloudEdition:%_wtx% SE"
"CloudEditionN:%_wtx% SE N"
"CloudEditionL:%_wtx% LE"
"CloudEditionLN:%_wtx% LE N"
"Core:%_wtx% Home"
"CoreN:%_wtx% Home N"
"CoreSingleLanguage:%_wtx% Home Single Language"
"CoreCountrySpecific:%_wtx% Home China"
"Professional:%_wtx% Pro"
"ProfessionalN:%_wtx% Pro N"
"ProfessionalEducation:%_wtx% Pro Education"
"ProfessionalEducationN:%_wtx% Pro Education N"
"ProfessionalWorkstation:%_wtx% Pro for Workstations"
"ProfessionalWorkstationN:%_wtx% Pro N for Workstations"
"ProfessionalSingleLanguage:%_wtx% Pro Single Language"
"ProfessionalCountrySpecific:%_wtx% Pro China Only"
"PPIPro:%_wtx% Team"
"Education:%_wtx% Education"
"EducationN:%_wtx% Education N"
"Enterprise:%_wtx% Enterprise"
"EnterpriseN:%_wtx% Enterprise N"
"EnterpriseG:%_wtx% Enterprise G"
"EnterpriseGN:%_wtx% Enterprise G N"
"EnterpriseS:%_wtx% Enterprise LTSC"
"EnterpriseSN:%_wtx% Enterprise N LTSC"
"IoTEnterprise:%_wtx% IoT Enterprise"
"IoTEnterpriseS:%_wtx% IoT Enterprise LTSC"
"IoTEnterpriseK:%_wtx% IoT Enterprise Subscription"
"IoTEnterpriseSK:%_wtx% IoT Enterprise LTSC Subscription"
"ServerRdsh:%_wtx% Enterprise multi-session"
"Starter:%_wtx% Starter"
"StarterN:%_wtx% Starter N"
"WNC:%_wtx% Cloud PC"
"ServerStandardCore:%_wsr% Standard"
"ServerStandard:%_wsr% Standard (Desktop Experience)"
"ServerDatacenterCore:%_wsr% Datacenter"
"ServerDatacenter:%_wsr% Datacenter (Desktop Experience)"
"ServerTurbineCore:%_wsr% Datacenter Azure Edition"
"ServerTurbine:%_wsr% Datacenter Azure Edition (Desktop Experience)"
"ServerAzureStackHCICor:Azure Stack HCI"
) do for /f "tokens=1,2 delims=:" %%A in ("%%~#") do (
if !edition%1!==%%A set "_oname%1=%%B"
)
set "_name%1=!_oname%1! [!arch%1! / !langid%1!]"
del /f /q bin\info*.txt
exit /b

:uups_dll
set "_f_=%1.dll"
if "%_f_%"=="dpx.dll" (set "_t_=temp") else (set "_t_=!_cabdir!")
set _ddc=DesktopDeployment.cab
set _dsp=System32
set _wow=0
set _nat=0
if /i %arch%==%xOS% set _nat=1
if /i %arch%==x64 if /i %xOS%==amd64 set _nat=1
if %_nat% equ 0 (
set _ddc=DesktopDeployment_x86.cab
set _dsp=SysWOW64
set _wow=1
if not "%_f_%"=="dpx.dll" set "_pspsfx=%SystemRoot%\SysWOW64\WindowsPowerShell\v1.0\powershell.exe -nop -c"
)
if exist "%_t_%\%_f_%" goto :get_end
set msuwim=0
set "uupmsu="
if exist "!_UUP!\*Windows1*-KB*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*Windows1*-KB*.msu"') do (
expand.exe -d -f:*Windows*.psf "!_UUP!\%%#" %_Nul2% | findstr /i %arch%\.psf %_Nul3% && (set "uupmsu=%%#")
wimlib-imagex.exe dir "!_UUP!\%%#" %_Nul2% | findstr /i %arch%\.psf %_Nul3% && (set "uupmsu=%%#"&set msuwim=1)
)
if defined uupmsu if not exist "temp\%_ddc%" (
if %msuwim% equ 0 expand.exe -f:%_ddc% "!_UUP!\%uupmsu%" .\temp %_Nul3%
if %msuwim% equ 1 wimlib-imagex.exe extract "!_UUP!\%uupmsu%" 1 %_ddc% --dest-dir=.\temp %_Nul3%
)
if exist "temp\%_ddc%" (expand.exe -f:%_f_% "temp\%_ddc%" "%_t_%" %_Nul3%) else (wimlib-imagex.exe extract %_file% 1 Windows\%_dsp%\%_f_% --dest-dir="%_t_%" --no-acls --no-attributes %_Nul3%)
:get_end
if exist "%_t_%\%_f_%" if "%_f_%"=="dpx.dll" (
copy /y %SystemRoot%\%_dsp%\expand.exe temp\ %_Nul3%
)
exit /b

:uups_msu
call :dk_color1 %Blue% "=== Creating Cumulative Update MSU . . ." 4
pushd "!_UUP!"
set "_MSUdll=dpx.dll ReserveManager.dll TurboStack.dll UpdateAgent.dll UpdateCompression.dll wcp.dll"
set "_MSUonf=onepackage.AggregatedMetadata.cab"
set IncludeSSU=1
set /a _rnd=%random%
for /f "delims=" %%# in ('dir /b /a:-d "*.AggregatedMetadata*.cab"') do if /i "%%#"=="%_MSUonf%" (
set /a _rnd+=1
ren "%%#" "org!_rnd!.cab"
)
for /f "delims=" %%# in ('dir /b /a:-d "*.AggregatedMetadata*.cab"') do (set "metaf=%%#"&call :doMSU)
if exist "zzz.ddf" del /f /q "zzz.ddf"
if exist "_tWIM\" rmdir /s /q "_tWIM\" %_Nul3%
if exist "_tSSU\" rmdir /s /q "_tSSU\" %_Nul3%
if exist "_tMSU\" rmdir /s /q "_tMSU\" %_Nul3%
popd
exit /b

:doMSU
set "_MSUssu="
set optSSU=%IncludeSSU%
set _mcfail=0
if exist "_tMSU\" rmdir /s /q "_tMSU\" %_Nul3%
mkdir "_tMSU"
expand.exe -f:LCUCompDB*.xml.cab "%metaf%" "_tMSU" %_Null%
expand.exe -f:SSUCompDB*.xml.cab "%metaf%" "_tMSU" %_Null%
expand.exe -f:*.AggregatedMetadata*.cab "%metaf%" "_tMSU" %_Null%
if not exist "_tMSU\LCUCompDB*.xml.cab" if not exist "_tMSU\*.AggregatedMetadata*.cab" (
rem. echo.
rem. echo LCUCompDB file is missing
goto :eof
)
if exist "_tMSU\SSU*-express.xml.cab" del /f /q "_tMSU\SSU*-express.xml.cab"

set xtn=cab
if not exist "_tMSU\*.AggregatedMetadata*.cab" goto :skpwim
set xtn=wim
for /f %%# in ('dir /b /a:-d "_tMSU\*.AggregatedMetadata*.cab"') do expand.exe -f:*.xml "_tMSU\%%#" "_tMSU" %_Null%
if not exist "_tMSU\LCUCompDB*.xml" (
rem. echo.
rem. echo LCUCompDB file is missing
goto :eof
)
for /f %%# in ('dir /b /a:-d "_tMSU\LCUCompDB*.xml"') do (
%_Null% makecab.exe /D Compress=ON /D CompressionType=MSZIP "_tMSU\%%~n#.xml" "_tMSU\%%~n#.xml.cab"
)
if exist "_tMSU\SSUCompDB*.xml" for /f %%# in ('dir /b /a:-d "_tMSU\SSUCompDB*.xml"') do (
%_Null% makecab.exe /D Compress=ON /D CompressionType=MSZIP "_tMSU\%%~n#.xml" "_tMSU\%%~n#.xml.cab"
)
if not exist "_tMSU\LCUCompDB*.xml.cab" (
rem. echo.
rem. echo makecab.exe LCUCompDB file failed
goto :eof
)
del /f /q "_tMSU\*.xml" %_Nul3%

:skpwim
set "_MSUkbn="
for /f "tokens=2 delims=_." %%# in ('dir /b /a:-d "_tMSU\LCUCompDB*.xml.cab"') do (
set "_MSUkbn=%%#"
)
if exist "*Windows1*%_MSUkbn%*%arch%*.msu" (
echo.
echo LCU %_MSUkbn% msu file already exist, skip operation.
goto :eof
)
if not exist "*Windows1*%_MSUkbn%*%arch%*.psf" (
rem. echo.
rem. echo %_MSUkbn% psf file is missing
goto :eof
)
if exist "*Windows1*%_MSUkbn%*%arch%*.cab" (
set xmf=cab
) else if exist "*Windows1*%_MSUkbn%*%arch%*.wim" (
set xmf=wim
) else (
rem. echo.
rem. echo %_MSUkbn% %xtn% file is missing
goto :eof
)

for /f %%# in ('dir /b /a:-d "_tMSU\LCUCompDB_%_MSUkbn%*.xml.cab"') do set "_MSUcdb=%%#"
rem. for /f "tokens=3 delims=-_" %%# in ('dir /b /a:-d "Windows1*%_MSUkbn%*.psf"') do set "arch=%%~n#"
for /f "delims=" %%# in ('dir /b /a:-d "*Windows1*%_MSUkbn%*%arch%*.%xmf%"') do set "_MSUcab=%%#"
for /f "delims=" %%# in ('dir /b /a:-d "*Windows1*%_MSUkbn%*%arch%*.psf"') do set "_MSUpsf=%%#"
set "_MSUkbf=Windows10.0-%_MSUkbn%-%arch%"
echo %_MSUcab%| findstr /i "Windows11\." %_Nul1% && set "_MSUkbf=Windows11.0-%_MSUkbn%-%arch%"
echo %_MSUcab%| findstr /i "Windows12\." %_Nul1% && set "_MSUkbf=Windows12.0-%_MSUkbn%-%arch%"

if not exist "SSU-*%arch%*.cab" set optSSU=0&goto :skpssu
for /f "delims=" %%# in ('dir /b /a:-d "SSU-*%arch%*.cab"') do (set "_chk=%%#"&call :doSSU)
if not defined _MSUssu set optSSU=0&goto :skpssu
goto :skpssu

:doSSU
if defined _MSUssu goto :eof
if exist "_tMSU\update.mum" del /f /q "_tMSU\update.mum"
expand.exe -f:update.mum "%_chk%" "_tMSU" %_Null%
set "_SSUkbn="
if exist "_tMSU\update.mum" for /f "tokens=3 delims== " %%# in ('findstr /i releaseType "_tMSU\update.mum"') do set _SSUkbn=%%~#
if "%_SSUkbn%"=="" goto :eof
if not exist "_tMSU\SSUCompDB_%_SSUkbn%*.xml.cab" goto :eof
for /f %%# in ('dir /b /a:-d "_tMSU\SSUCompDB_%_SSUkbn%*.xml.cab"') do set "_MSUsdb=%%#"
for /f "tokens=2 delims=-" %%# in ('dir /b /a:-d "%_chk%"') do set "_MSUtsu=SSU-%%#-%arch%.cab"
set "_MSUssu=%_chk%"
goto :eof

:skpssu
set "_MSUddc="
set "_MSUddd=DesktopDeployment_x86.cab"
if exist "*DesktopDeployment*.cab" (
for /f "delims=" %%# in ('dir /b /a:-d "*DesktopDeployment*.cab" ^|find /i /v "%_MSUddd%"') do set "_MSUddc=%%#"
)
rem. if exist "%SysPath%\ucrtbase.dll" call :dodpx
if not defined _MSUddc (
call set "_MSUddc=_tMSU\DesktopDeployment.cab"
call set "_MSUddd=_tMSU\DesktopDeployment_x86.cab"
call :DDCAB
)
if %_mcfail% equ 1 goto :eof
if /i not %arch%==x86 if not exist "DesktopDeployment_x86.cab" if not exist "_tMSU\DesktopDeployment_x86.cab" (
call set "_MSUddd=_tMSU\DesktopDeployment_x86.cab"
call :DDC86
)
if %_mcfail% equ 1 goto :eof
call :crDDF _tMSU\%_MSUonf%
(echo "_tMSU\%_MSUcdb%" "%_MSUcdb%"
if %optSSU% equ 1 echo "_tMSU\%_MSUsdb%" "%_MSUsdb%"
)>>zzz.ddf
%_Null% makecab.exe /F zzz.ddf /D Compress=ON /D CompressionType=MSZIP
if %ERRORLEVEL% neq 0 (
call :dk_color1 %Red% "makecab.exe %_MSUonf% failed, skip operation." 4
(echo.&echo makecab.exe %_MSUonf% failed)>>"!logerr!"
goto :eof
)
if %xmf%==wim goto :msu_wim
call :crDDF %_MSUkbf%.msu
(echo "%_MSUddc%" "DesktopDeployment.cab"
if exist "%_MSUddd%" if /i not %arch%==x86 echo "%_MSUddd%" "DesktopDeployment_x86.cab"
echo "_tMSU\%_MSUonf%" "%_MSUonf%"
if %optSSU% equ 1 echo "%_MSUssu%" "%_MSUtsu%"
echo "%_MSUcab%" "%_MSUkbf%.cab"
echo "%_MSUpsf%" "%_MSUkbf%.psf"
)>>zzz.ddf
%_Null% makecab.exe /F zzz.ddf /D Compress=OFF
if %ERRORLEVEL% neq 0 (
call :dk_color1 %Red% "makecab.exe %_MSUkbf%.msu failed, skip operation." 4
(echo.&echo makecab.exe %_MSUkbf%.msu failed)>>"!logerr!"
goto :eof
)
rem. call :undpx
goto :eof

:msu_wim
echo.
echo Creating: %_MSUkbf%.msu
if exist "_tWIM\" rmdir /s /q "_tWIM\" %_Nul3%
mkdir "_tWIM"
copy /y "%_MSUddc%" "_tWIM\DesktopDeployment.cab" %_Nul3%
if exist "%_MSUddd%" if /i not %arch%==x86 copy /y "%_MSUddd%" "_tWIM\DesktopDeployment_x86.cab" %_Nul3%
copy /y "_tMSU\%_MSUonf%" "_tWIM\%_MSUonf%" %_Nul3%
if %optSSU% equ 1 copy /y "%_MSUssu%" "_tWIM\%_MSUtsu%" %_Nul3%
copy /y "%_MSUcab%" "_tWIM\%_MSUkbf%.wim" %_Nul3%
copy /y "%_MSUpsf%" "_tWIM\%_MSUkbf%.psf" %_Nul3%
popd
%_Nul3% wimlib-imagex.exe capture "!_UUP!\_tWIM" "!_UUP!\%_MSUkbf%.msu" content --compress=none --nocheck --no-acls
if %ERRORLEVEL% neq 0 (
call :dk_color1 %Red% "capture %_MSUkbf%.msu failed, skip operation." 4
(echo.&echo capture %_MSUkbf%.msu failed)>>"!logerr!"
pushd "!_UUP!"
goto :eof
)
pushd "!_UUP!"
rem. call :undpx
goto :eof

:DDCAB
echo.
echo Extracting required files...
if exist "_tSSU\" rmdir /s /q "_tSSU\" %_Nul3%
mkdir "_tSSU\000"
if not defined _MSUssu goto :ssuinner64
expand.exe -f:* "%_MSUssu%" "_tSSU" %_Null% || goto :ssuinner64
goto :ssuouter64
:ssuinner64
popd
for /f %%# in ('wimlib-imagex.exe dir %_file% 1 --path=Windows\WinSxS\Manifests ^| find /i "_microsoft-windows-servicingstack_"') do (
wimlib-imagex.exe extract %_file% 1 Windows\WinSxS\%%~n# --dest-dir="!_UUP!\_tSSU" --no-acls --no-attributes %_Nul3%
)
pushd "!_UUP!"
:ssuouter64
set btx=%arch%
if /i %arch%==x64 set btx=amd64
for /f %%# in ('dir /b /ad "_tSSU\%btx%_microsoft-windows-servicingstack_*"') do set "src=%%#"
for %%# in (%_MSUdll%) do if exist "_tSSU\%src%\%%#" (move /y "_tSSU\%src%\%%#" "_tSSU\000\%%#" %_Nul1%)
call :crDDF %_MSUddc%
call :apDDF _tSSU\000
%_Null% makecab.exe /F zzz.ddf /D Compress=ON /D CompressionType=MSZIP
if %ERRORLEVEL% neq 0 (
call :dk_color1 %Red% "makecab.exe %_MSUddc% failed, skip operation." 4
(echo.&echo makecab.exe %_MSUddc% failed)>>"!logerr!"
set _mcfail=1
exit /b
)
mkdir "_tSSU\111"
if /i not %arch%==x86 if not exist "DesktopDeployment_x86.cab" goto :DDCdual
rmdir /s /q "_tSSU\" %_Nul3%
exit /b

:DDC86
echo.
echo Extracting required files...
if exist "_tSSU\" rmdir /s /q "_tSSU\" %_Nul3%
mkdir "_tSSU\111"
if not defined _MSUssu goto :ssuinner86
expand.exe -f:* "%_MSUssu%" "_tSSU" %_Null% || goto :ssuinner86
goto :ssuouter86
:ssuinner86
popd
for /f %%# in ('wimlib-imagex.exe dir %_file% 1 --path=Windows\WinSxS\Manifests ^| find /i "x86_microsoft-windows-servicingstack_"') do (
wimlib-imagex.exe extract %_file% 1 Windows\WinSxS\%%~n# --dest-dir="!_UUP!\_tSSU" --no-acls --no-attributes %_Nul3%
)
pushd "!_UUP!"
:ssuouter86
:DDCdual
for /f %%# in ('dir /b /ad "_tSSU\x86_microsoft-windows-servicingstack_*"') do set "src=%%#"
for %%# in (%_MSUdll%) do if exist "_tSSU\%src%\%%#" (move /y "_tSSU\%src%\%%#" "_tSSU\111\%%#" %_Nul1%)
call :crDDF %_MSUddd%
call :apDDF _tSSU\111
%_Null% makecab.exe /F zzz.ddf /D Compress=ON /D CompressionType=MSZIP
if %ERRORLEVEL% neq 0 (
call :dk_color1 %Red% "makecab.exe %_MSUddd% failed, skip operation." 4
(echo.&echo makecab.exe %_MSUddd% failed)>>"!logerr!"
set _mcfail=1
exit /b
)
rmdir /s /q "_tSSU\" %_Nul3%
exit /b

:crDDF
echo.
echo Creating: %~nx1
(echo .Set DiskDirectoryTemplate="."
echo .Set CabinetNameTemplate="%1"
echo .Set MaxCabinetSize=0
echo .Set MaxDiskSize=0
echo .Set FolderSizeThreshold=0
echo .Set RptFileName=nul
echo .Set InfFileName=nul
echo .Set Cabinet=ON
)>zzz.ddf
exit /b

:apDDF
(echo .Set SourceDir="%1"
echo "dpx.dll"
echo "ReserveManager.dll"
echo "TurboStack.dll"
echo "UpdateAgent.dll"
echo "wcp.dll"
if exist "%1\UpdateCompression.dll" echo "UpdateCompression.dll"
)>>zzz.ddf
exit /b

:uups_backup
if not exist "!_work!\temp\*.ESD" exit /b
call :dk_color1 %Blue% "=== Backing up Reference ESDs . . ." 4
if %EXPRESS% equ 1 (
mkdir "!_work!\CanonicalUUP" %_Nul3%
move /y "!_work!\temp\*.ESD" "!_work!\CanonicalUUP\" %_Nul3%
for /L %%# in (1,1,%uups_esd_num%) do copy /y "!_UUP!\!uups_esd%%#!" "!_work!\CanonicalUUP\" %_Nul3%
for /f %%# in ('dir /b /a:-d "!_UUP!\*Package*.ESD" %_Nul6%') do if not exist "!_work!\CanonicalUUP\%%#" (copy /y "!_UUP!\%%#" "!_work!\CanonicalUUP\" %_Nul3%)
exit /b
)
mkdir "!_UUP!\Original" %_Nul3%
move /y "!_work!\temp\*.ESD" "!_UUP!\" %_Nul3%
for /f %%# in ('dir /b /a:-d "!_UUP!\*.CAB"') do (
echo %%#| findstr /i /r "Windows.*-KB SSU-.* DesktopDeployment AggregatedMetadata" %_Nul1% || move /y "!_UUP!\%%#" "!_UUP!\Original\" %_Nul3%
)
exit /b

:uups_du
set isoupdate=
for /f "tokens=* delims=" %%# in ('dir /b /a:-d "!_UUP!\*Windows1*-KB*.cab"') do (
	del /f /q temp\update.mum %_Null%
	expand.exe -f:update.mum "!_UUP!\%%#" .\temp %_Null%
	if not exist "temp\update.mum" set isoupdate=!isoupdate! "%%#"
)
if not defined isoupdate goto :undu
call :addDU

:undu
copy /y ISOFOLDER\sources\UpdateAgent.dll %SystemRoot%\temp\ %_Nul1%
copy /y ISOFOLDER\sources\Facilitator.dll %SystemRoot%\temp\ %_Nul1%
set chkmin=%uupmin%
call :setuphostprep
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" .\bin\version.txt" %_Nul6%') do (set xduver=%%i.%%j&set xdumaj=%%i&set xdumin=%%j&set xdubranch=%%k&set xdudate=%%l)
del /f /q .\bin\version.txt %_Nul3%
if %uupmin% neq %xdumin% exit /b
if /i "%xdubranch%"=="WinBuild" exit /b
if /i "%xdubranch%"=="GitEnlistment" exit /b
if /i "%xdudate%"=="winpbld" exit /b
set tmpval=tmpval
call :fixVerBrn %uupmaj% xdubranch xduver tmpval
set _label=%xduver%.%xdudate%.%xdubranch%
call :setlabel
exit /b

:uups_external
call :dk_color1 %Blue% "=== Adding updates files to ISO distribution . . ." 4 5
if not exist "!_cabdir!\" mkdir "!_cabdir!"
set "_dest=ISOFOLDER\sources\$OEM$\$1\UUP"
if not exist "!_dest!\" mkdir "!_dest!"
copy /y bin\Updates.bat "!_dest!\" %_Nul3%
if %_build% geq 18362 for /f "tokens=* delims=" %%# in ('dir /b /os "!_UUP!\*Windows1*-KB*.cab"') do (
expand.exe -f:microsoft-windows-*enablement-package~*.mum "!_UUP!\%%#" "!_cabdir!" %_Nul3%
call :EKB1 "!_cabdir!" _actEP 1
)
call :EKB2 "!_cabdir!"
set tmpcmp=
set _rcu=
if %_build% geq 21382 if exist "!_UUP!\*Windows1*-KB*.msu" for /f "tokens=* delims=" %%# in ('dir /b /os "!_UUP!\*Windows1*-KB*.msu"') do (set "packn=%%~n#"&set "packf=%%#"&call :external_msu)
if exist "!_UUP!\SSU-*-*.cab" for /f "tokens=* delims=" %%# in ('dir /b /os "!_UUP!\SSU-*-*.cab"') do (set "packn=%%~n#"&set "packf=%%#"&call :external_cab)
if exist "!_UUP!\*Windows1*-KB*.cab" for /f "tokens=* delims=" %%# in ('dir /b /os "!_UUP!\*Windows1*-KB*.cab"') do (set "packn=%%~n#"&set "packf=%%#"&call :external_cab)
if defined tmpcmp if exist "!_UUP!\Windows1?.?-*%arch%_inout.cab" for /f "tokens=* delims=" %%# in ('dir /b /os "!_UUP!\Windows1?.?-*%arch%_inout.cab"') do (set "packn=%%~n#"&set "packf=%%#"&call :external_cab)
if not exist "!_dest!\*Windows1*-KB*.msu" if not exist "!_dest!\*Windows1*-KB*.cab" if not exist "!_dest!\*SSU-*-*.cab" (
rmdir /s /q "ISOFOLDER\sources\$OEM$\"
exit /b
)
if defined s_pkg if exist "!_dest!\1*.cab" (
del /f /q "!_dest!\1*.cab" %_Nul3%
copy /y "!_UUP!\%s_pkg%" "!_dest!\1%s_pkg%" %_Nul3%
)
if defined c_pkg if exist "!_dest!\3*.msu" if %_build% geq 26052 (
for /f "tokens=* delims=" %%# in ('dir /b /on "!_dest!\3*.msu"') do if /i not "%%#"=="3%c_pkg%" (
  set _tmp=%%#
  ren "!_dest!\%%#" "2!_tmp:~1!" %_Nul3%
  )
)
if %NetFx3% equ 1 if exist "ISOFOLDER\sources\sxs\*NetFx3*.cab" call :external_netfx
call :dk_color1 %Blue% "=== Updating %WIMFILE% registry . . ." 4
for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info ISOFOLDER\sources\%WIMFILE% ^| findstr /c:"Image Count"') do set imgcount=%%#
for /L %%# in (1,1,%imgcount%) do (
wimlib-imagex.exe extract ISOFOLDER\sources\%WIMFILE% %%# Windows\System32\config\SYSTEM --dest-dir=.\bin\temp --no-acls --no-attributes %_Null%
%_Nul3% offlinereg.exe .\bin\temp\SYSTEM Setup createkey FirstBoot
%_Nul3% offlinereg.exe .\bin\temp\SYSTEM.new Setup\FirstBoot createkey PostSysprep
%_Nul3% offlinereg.exe .\bin\temp\SYSTEM.new Setup\FirstBoot\PostSysprep setvalue uup "cmd.exe /c %%systemdrive%%\$WINDOWS.~BT\Sources\SetupPlatform.exe /postsysprep 2>nul&%%systemdrive%%\UUP\Updates.bat &reg delete HKLM\SYSTEM\Setup\FirstBoot\PostSysprep /v 0 /f 2>nul&reg delete HKLM\SYSTEM\Setup\FirstBoot\PostSysprep /v uup /f &exit /b 0 "
del /f /q .\bin\temp\SYSTEM
ren .\bin\temp\SYSTEM.new SYSTEM
type nul>bin\install-wim.txt
>>bin\install-wim.txt echo add 'bin^\temp^\SYSTEM' '^\Windows^\System32^\config^\SYSTEM'
wimlib-imagex.exe update ISOFOLDER\sources\%WIMFILE% %%# < bin\install-wim.txt %_Null%
del /f /q bin\install-wim.txt
rmdir /s /q bin\temp\
)
if %imgcount% gtr 1 if %WIMFILE%==install.wim (
call :dk_color1 %Blue% "=== Rebuilding %WIMFILE% . . ." 4 5
%_wrb% wimlib-imagex.exe optimize ISOFOLDER\sources\%WIMFILE% %_Supp%
)
exit /b

:external_cab
for /f "tokens=2 delims=-" %%V in ('echo %packn%') do set packid=%%V
set "uupmsu="
if %_build% geq 21382 if exist "!_UUP!\*Windows1*%packid%*%arch%*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*Windows1*%packid%*%arch%*.msu"') do (
set "uupmsu=%%#"
)
if defined uupmsu (
expand.exe -d -f:*Windows*.psf "!_UUP!\%uupmsu%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% && goto :eof
wimlib-imagex.exe dir "!_UUP!\%uupmsu%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% && goto :eof
)
if defined bac_%packn% goto :eof
del /f /q "!_cabdir!\*.manifest" "!_cabdir!\*.mum" "!_cabdir!\*.xml" %_Nul3%
:: expand.exe -f:update.mum "!_UUP!\%packf%" "!_cabdir!" %_Null%
7z.exe e "!_UUP!\%packf%" -o"!_cabdir!" update.mum -aoa %_Null%
if not exist "!_cabdir!\update.mum" exit /b
expand.exe -f:*.psf.cix.xml "!_UUP!\%packf%" "!_cabdir!" %_Null%
if exist "!_cabdir!\*.psf.cix.xml" (
if not exist "!_UUP!\%packn%.psf" if not exist "!_UUP!\*%packid%*%arch%*.psf" (
  call :dk_color1 %Red% "PSFX: %packf% / PSF file is missing"
  (echo.&echo %packf% / PSF file is missing)>>"!logerr!"
  exit /b
  )
if %psfnet% equ 0 (
  call :dk_color1 %Red% "PSFX: %packf% / PSFExtractor is not available"
  (echo.&echo %packf% / PSFExtractor is not available)>>"!logerr!"
  exit /b
  )
set psf_%packn%=1
)
findstr /i /m "Package_for_OasisAsset" "!_cabdir!\update.mum" %_Nul3% && (
wimlib-imagex.exe extract ISOFOLDER\sources\%WIMFILE% 1 Windows\Servicing\Packages\*OasisAssets-Package*.mum --dest-dir="!_cabdir!" --no-acls --no-attributes %_Null%
if not exist "!_cabdir!\*OasisAssets-Package*.mum" exit /b
)
expand.exe -f:toc.xml "!_UUP!\%packf%" "!_cabdir!" %_Null%
if exist "!_cabdir!\toc.xml" (
echo LCU: %packf% [Combined]
mkdir "!_cabdir!\lcu" %_Nul3%
expand.exe -f:* "!_UUP!\%packf%" "!_cabdir!\lcu" %_Null%
if exist "!_cabdir!\lcu\SSU-*%arch%*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\SSU-*%arch%*.cab"') do (set "compkg=%%#"&call :inrenssu)
if exist "!_cabdir!\lcu\*Windows1*-KB*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\*Windows1*-KB*.cab"') do (set "compkg=%%#"&call :inrenupd)
rmdir /s /q "!_cabdir!\lcu\" %_Nul3%
exit /b
)
if %_build% geq 17763 findstr /i /m "WinPE" "!_cabdir!\update.mum" %_Nul3% && (
%_Nul3% findstr /i /m "Edition\"" "!_cabdir!\update.mum"
if errorlevel 1 exit /b
)
expand.exe -f:*_microsoft-windows-servicingstack_*.manifest "!_UUP!\%packf%" "!_cabdir!" %_Null%
if exist "!_cabdir!\*_microsoft-windows-servicingstack_*.manifest" (
call :chkssu "!_cabdir!" "%packf%"
echo SSU: %packf%
copy /y "!_UUP!\%packf%" "!_dest!\1%packf%" %_Nul3%
set bac_%packn%=1
exit /b
)
set lculabel=1
findstr /i /m "Package_for_RollupFix" "!_cabdir!\update.mum" %_Nul3% && (
if defined psf_%packn% (
  echo LCU: %packf% / Repacking PSF update
  call :external_psf
  ) else (
  echo LCU: %packf%
  copy /y "!_UUP!\%packf%" "!_dest!\3%packf%" %_Nul3%
  )
if !lculabel! equ 1 call :external_label
set bac_%packn%=1
exit /b
)
echo UPD: %packf%
copy /y "!_UUP!\%packf%" "!_dest!\2%packf%" %_Nul3%
set bac_%packn%=1
exit /b

:external_msu
del /f /q "!_cabdir!\*.manifest" "!_cabdir!\*.mum" "!_cabdir!\*.xml" %_Nul3%
set msuwim=0
expand.exe -d -f:*Windows*.psf "!_UUP!\%packf%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% || (
wimlib-imagex.exe dir "!_UUP!\%packf%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% && (set msuwim=1) || (goto :eof)
)
mkdir "!_cabdir!\lcu" %_Nul3%
:: if %msuwim% equ 1 (
:: wimlib-imagex.exe extract "!_UUP!\%packf%" 1 *.AggregatedMetadata*.cab --dest-dir="!_cabdir!\lcu" %_Nul3%
:: for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\*.AggregatedMetadata*.cab" %_Nul6%') do (expand.exe -f:HotpatchCompDB*.cab "!_cabdir!\lcu\%%#" "!_cabdir!\lcu" %_Null%)
:: )
:: if exist "!_cabdir!\lcu\HotpatchCompDB*.cab" (
:: echo Not Supported: %packf% [HotPatchUpdate]
:: rmdir /s /q "!_cabdir!\lcu\" %_Nul3%
:: goto :eof
:: )
echo LCU: %packf% [Combined UUP]
copy /y "!_UUP!\%packf%" "!_dest!\3%packf%" %_Nul3%
if %msuwim% equ 0 (
expand.exe -f:*Windows*.cab "!_UUP!\%packf%" "!_cabdir!\lcu" %_Null%
expand.exe -f:SSU-*%arch%*.cab "!_UUP!\%packf%" "!_cabdir!\lcu" %_Null%
) else (
wimlib-imagex.exe extract "!_UUP!\%packf%" 1 *Windows*.wim --dest-dir="!_cabdir!\lcu" %_Null%
wimlib-imagex.exe extract "!_UUP!\%packf%" 1 SSU-*%arch%*.cab --dest-dir="!_cabdir!\lcu" %_Null%
if %_build% geq 26100 wimlib-imagex.exe extract "!_UUP!\%packf%" 1 RCU-*%arch%*.cab --dest-dir="!_cabdir!\lcu" %_Null%
)
for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\*Windows1*-KB*.*"') do set "compkg=%%#"
7z.exe e "!_cabdir!\lcu\%compkg%" -o"!_cabdir!" update.mum -aoa %_Null%
7z.exe e "!_cabdir!\lcu\%compkg%" -o"!_cabdir!" %_ss%_microsoft-windows-coreos-revision*.manifest -aoa %_Null%
7z.exe e "!_cabdir!\lcu\%compkg%" -o"!_cabdir!" %_ss%_microsoft-updatetargeting-*os_*.manifest -aoa %_Null%
if exist "!_cabdir!\lcu\SSU-*%arch%*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\SSU-*%arch%*.cab"') do (set "compkg=%%#"&call :inrenssu)
if exist "!_cabdir!\lcu\RCU-*baseless*.*" del /f /q "!_cabdir!\lcu\RCU-*baseless*.*" %_Nul3%
if exist "!_cabdir!\lcu\RCU-*%arch%*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\RCU-*%arch%*.cab"') do (
7z.exe e "!_cabdir!\lcu\%%#" -o"!_cabdir!" update.mum -aoa %_Null%
7z.exe e "!_cabdir!\lcu\%%#" -o"!_cabdir!" %_ss%_microsoft-windows-coreos-revision*.manifest -aoa %_Null%
7z.exe e "!_cabdir!\lcu\%%#" -o"!_cabdir!" %_ss%_microsoft-updatetargeting-*os_*.manifest -aoa %_Null%
set _rcu=1
)
rmdir /s /q "!_cabdir!\lcu\" %_Nul3%
call :external_label
exit /b

:external_netfx
for /f %%# in ('dir /b /os "ISOFOLDER\sources\sxs\*NetFx3*.cab"') do set "ndp=%%#"
echo DNF: %ndp%
copy /y "ISOFOLDER\sources\sxs\%ndp%" "!_dest!\" %_Nul3%
exit /b

:external_label
set kbvr=0
for /f "tokens=5-8 delims==. " %%H in ('findstr /i Package_for_RollupFix "!_cabdir!\update.mum"') do set "kbvr=%%I"
if defined _rcu for /f "tokens=5-8 delims==. " %%H in ('findstr /i Package_for_RevisedFix "!_cabdir!\update.mum"') do set "kbvr=%%I"
if %kbvr% geq %c_ver% (
set "c_ver=%kbvr%"
set "c_pkg=%packf%"
) else (
exit /b
)
copy /y "!_cabdir!\update.mum" %SystemRoot%\temp\ %_Nul1%
call :datemum isodate isotime
if exist "!_cabdir!\*cablist.ini" del /f /q "!_cabdir!\*cablist.ini" %_Nul3%
expand.exe -f:*cablist.ini "!_UUP!\%packf%" "!_cabdir!" %_Null%
if not exist "!_cabdir!\*_microsoft-windows-coreos-revision*.manifest" if exist "!_cabdir!\*cablist.ini" (
expand.exe -f:*.cab "!_UUP!\%packf%" "!_cabdir!" %_Null%
expand.exe -f:%_ss%_microsoft-windows-coreos-revision*.manifest "!_cabdir!\Cab*.cab" "!_cabdir!" %_Null%
)
if not exist "!_cabdir!\*_microsoft-windows-coreos-revision*.manifest" if not exist "!_cabdir!\*cablist.ini" (
expand.exe -f:%_ss%_microsoft-windows-coreos-revision*.manifest "!_UUP!\%packf%" "!_cabdir!" %_Null%
)
if exist "!_cabdir!\*_microsoft-windows-coreos-revision*.manifest" for /f "tokens=%tok% delims=_." %%i in ('dir /b /a:-d /od "!_cabdir!\*_microsoft-windows-coreos-revision*.manifest"') do (set uupver=%%i.%%j&set uupmaj=%%i&set uupmin=%%j)
if exist "!_cabdir!\Cab*.cab" del /f /q "!_cabdir!\Cab*.cab" %_Nul3%

if not exist "!_cabdir!\*_microsoft-updatetargeting-*os_*.manifest" (
expand.exe -f:%_ss%_microsoft-updatetargeting-*os_*.manifest "!_UUP!\%packf%" "!_cabdir!" %_Null%
)
if %_build% geq 21382 if exist "!_cabdir!\*_microsoft-updatetargeting-*os_*.manifest" (
mkdir bin\sxs
for /f %%a in ('dir /b /a:-d "!_cabdir!\*_microsoft-updatetargeting-*os_*.manifest"') do SxSExpand.exe "!_cabdir!\%%a" "bin\sxs\%%a" %_Nul3%
if exist "bin\sxs\*.manifest" move /y "bin\sxs\*" "!_cabdir!\" %_Nul1%
rmdir /s /q bin\sxs\
)
if exist "!_cabdir!\*_microsoft-updatetargeting-*os_*.manifest" for /f "tokens=8 delims== " %%# in ('findstr /i Branch "!_cabdir!\*_microsoft-updatetargeting-*os_*.manifest"') do if not defined regbranch set regbranch=%%~#
if defined regbranch set branch=%regbranch%
set "wnt=%_Pkt%_10"
if exist "!_cabdir!\*_microsoft-updatetargeting-*os_%_Pkt%_11.*.manifest" set "wnt=%_Pkt%_11"
if exist "!_cabdir!\*_microsoft-updatetargeting-*os_%_Pkt%_12.*.manifest" set "wnt=%_Pkt%_12"
if %_actEP% equ 1 if exist "!_cabdir!\*_microsoft-updatetargeting-*os_%wnt%.%_fixEP%*.manifest" (
for /f "tokens=8 delims== " %%# in ('findstr /i Branch "!_cabdir!\*_microsoft-updatetargeting-*os_%wnt%.%_fixEP%*.manifest"') do set branch=%%~#
for /f "tokens=%toe% delims=_." %%I in ('dir /b /a:-d /on "!_cabdir!\*_microsoft-updatetargeting-*os_%wnt%.%_fixEP%*.manifest"') do if %%I gtr !uupmaj! (
  set uupver=%%I.%%K
  set uupmaj=%%I
  set uupmin=%%K
  set "_fixSV=!uupmaj!"&set "_fixEP=!uupmaj!"
  )
)
call :fixBranch %uupmaj%
set _label=%uupver%.%isodate%.%branch%
call :setlabel
exit /b

:external_psf
set "lcuext=!_cabdir!\%packn%"
if not exist "!lcuext!\" mkdir "!lcuext!"
expand.exe -f:* "!_UUP!\%packf%" "!lcuext!" %_Null%
7z.exe e "!_UUP!\%packf%" -o"!lcuext!" update.mum -aoa %_Null%
if exist "!lcuext!\*cablist.ini" (
  expand.exe -f:* "!lcuext!\*.cab" "!lcuext!" %_Null%
  del /f /q "!lcuext!\*cablist.ini" %_Nul3%
  del /f /q "!lcuext!\*.cab" %_Nul3%
)
if not exist "!lcuext!\express.psf.cix.xml" for /f %%# in ('dir /b /a:-d "!lcuext!\*.psf.cix.xml"') do rename "!lcuext!\%%#" express.psf.cix.xml %_Nul3%
set _sbst=0
subst %_sdr% "!_cabdir!" %_Nul3% && set _sbst=1
if !_sbst! equ 1 pushd %_sdr%
if not exist "%packf%" (
copy /y "!_UUP!\%packn%.*" . %_Nul3%
if not exist "%packn%.psf" for /f %%# in ('dir /b /a:-d "!_UUP!\*%packid%*%arch%*.psf"') do copy /y "!_UUP!\%%#" %packn%.psf %_Nul3%
)
if not exist "PSFExtractor.exe" copy /y "!_work!\bin\PSFExtractor.*" . %_Nul3%
if not exist "cabarc.exe" copy /y "!_work!\bin\cabarc.exe" . %_Nul3%
PSFExtractor.exe %packf% %_Null%
if %errorlevel% neq 0 (
  set lculabel=0
  call :dk_color1 %Red% "Error: failed to extract %packn%.psf"
  (echo.&echo failed to extract %packn%.psf)>>"!logerr!"
  rmdir /s /q %packn% %_Nul3%
  if !_sbst! equ 1 popd
  if !_sbst! equ 1 subst %_sdr% /d %_Nul3%
  exit /b
  )
cd %packn%
del /f /q *.psf.cix.xml %_Nul3%
..\cabarc.exe -m LZX:21 -r -p N ..\3psf.cab *.* %_Null%
if %errorlevel% neq 0 (
  set lculabel=0
  call :dk_color1 %Red% "Error: failed to create %packf%"
  (echo.&echo failed to create %packf%)>>"!logerr!"
  cd..
  rmdir /s /q %packn% %_Nul3%
  if !_sbst! equ 1 popd
  if !_sbst! equ 1 subst %_sdr% /d %_Nul3%
  exit /b
  )
cd..
rmdir /s /q %packn% %_Nul3%
if !_sbst! equ 1 popd
if !_sbst! equ 1 subst %_sdr% /d %_Nul3%
move /y "!_cabdir!\3psf.cab" "!_dest!\3%packf%" %_Nul3%
exit /b

:uups_update
if %W10UI% equ 0 exit /b
set wim=0
set dvd=0
set _tgt=%1
set _upx=
set _upx=%2
if /i "%_tgt:~-4%"==".wim" (
set wim=1
set _target=%1
set _imgchk=%1
set _wimtrg=%~nx1
) else (
set dvd=1
set _target=ISOFOLDER
set _imgchk=ISOFOLDER\sources\%WIMFILE%
set _wimtrg=install.wim
)
for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info %_imgchk% ^| findstr /c:"Image Count"') do set imgcount=%%#
call :dk_color1 %Blue% "=== Updating %_wimtrg% / %imgcount% image{s} . . ." 4
if not defined _upx goto :noappx

::appx_update
if %wim% equ 1 call :updt_mount "%_target%" appx
if %dvd% equ 1 call :updt_mount "%_target%\sources\install.wim" appx
if exist "%_mount%\" rmdir /s /q "%_mount%\"
if %wim2esd% equ 1 exit /b
goto :rbldwim

:noappx
set directcab=0
if %_runDRV% equ 0 call :extract
if %wim% equ 0 goto :dvdup
call :updt_mount "%_target%"

:dvdup
if %dvd% equ 0 goto :nodvd
if exist "%SystemRoot%\temp\UpdateAgent.dll" del /f /q "%SystemRoot%\temp\UpdateAgent.dll" %_Nul3%
if exist "%SystemRoot%\temp\Facilitator.dll" del /f /q "%SystemRoot%\temp\Facilitator.dll" %_Nul3%
if exist "%SystemRoot%\temp\ServicingCommon.dll" del /f /q "%SystemRoot%\temp\ServicingCommon.dll" %_Nul3%
call :updt_mount "%_target%\sources\install.wim"

:nodvd
if exist "%_mount%\" rmdir /s /q "%_mount%\"
if %_build% geq 19041 if %winbuild% lss 17133 if exist "%SysPath%\ext-ms-win-security-slc-l1-1-0.dll" (
del /f /q %SysPath%\ext-ms-win-security-slc-l1-1-0.dll %_Nul3%
if /i not %xOS%==x86 del /f /q %SystemRoot%\SysWOW64\ext-ms-win-security-slc-l1-1-0.dll %_Nul3%
)

:rbldwim
set _wimopt=0
if %wim% equ 1 (
if /i %_target%==install.wim (if %wim2esd% equ 0 set _wimopt=1) else (if not defined _upx if %relite% equ 0 set _wimopt=1)
)
if %dvd% equ 1 if %wim2esd% equ 0 (
set _wimopt=1
if %AddUpdates% equ 2 if %_updexist% equ 1 for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info %_imgchk% ^| findstr /c:"Image Count"') do if %%# gtr 1 set _wimopt=0
)
if %_wimopt% equ 1 (
call :dk_color1 %Blue% "=== Rebuilding %_wimtrg% . . ." 4 5
)
if %wim% equ 1 (
%_wrb% if %_wimopt% equ 1 wimlib-imagex.exe optimize "%_target%" %_Supp%
exit /b
)
%_wrb% if %_wimopt% equ 1 wimlib-imagex.exe optimize "%_target%\sources\install.wim" %_Supp%
if defined _upx exit /b
if %_runDRV% equ 1 exit /b

for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info "%_target%\sources\install.wim" ^| findstr /c:"Image Count"') do set imgcount=%%#
for /L %%# in (1,1,%imgcount%) do (
  for /f "tokens=3 delims=<>" %%A in ('imagex /info "%_target%\sources\install.wim" %%# ^| find /i "<HIGHPART>"') do call set "HIGHPART=%%A"
  for /f "tokens=3 delims=<>" %%A in ('imagex /info "%_target%\sources\install.wim" %%# ^| find /i "<LOWPART>"') do call set "LOWPART=%%A"
  wimlib-imagex.exe info "%_target%\sources\install.wim" %%# --image-property CREATIONTIME/HIGHPART=!HIGHPART! --image-property CREATIONTIME/LOWPART=!LOWPART! %_Nul1%
)
if not defined isoupdate goto :nodu
call :addDU

:nodu
if not defined isover exit /b
set chkmin=%isomin%
call :setuphostprep
for /f "tokens=4-7 delims=.() " %%i in ('"findstr /i /b "FileVersion" .\bin\version.txt" %_Nul6%') do (set iduver=%%i.%%j&set idumaj=%%i&set idumin=%%j&set branch=%%k&set idudate=%%l)
del /f /q .\bin\version.txt %_Nul3%
if not defined isobranch set "isobranch=%branch%"
call :fixVerBrn %isomaj% isobranch iduver branch
set _label=%isover%.%isodate%.%isobranch%
if /i not "%branch%"=="WinBuild" if /i not "%branch%"=="GitEnlistment" if /i not "%idudate%"=="winpbld" (set _label=%iduver%.%idudate%.%branch%)
if %isomin% neq %idumin% (set _label=%isover%.%isodate%.%isobranch%)
call :setlabel
exit /b

:addDU
call :dk_color1 %Blue% "=== Adding setup dynamic update{s} . . ." 4 5
mkdir "%_cabdir%\du" %_Nul3%
for %%# in (!isoupdate!) do (
echo %%~#
expand.exe -r -f:* "!_UUP!\%%~#" "%_cabdir%\du" %_Nul1%
)
if %_build% geq 26100 (
if exist "%SystemRoot%\temp\ServicingCommon.dll" if not exist "%_cabdir%\du\ServicingCommon.dll" copy /y "%SystemRoot%\temp\ServicingCommon.dll" "%_cabdir%\du\" %_Nul3%
)
xcopy /CDRUY "%_cabdir%\du" "ISOFOLDER\sources\" %_Nul3%
if exist "%_cabdir%\du\*.ini" xcopy /CDRY "%_cabdir%\du\*.ini" "ISOFOLDER\sources\" %_Nul3%
for /f %%# in ('dir /b /ad "%_cabdir%\du\*-*" %_Nul6%') do if exist "ISOFOLDER\sources\%%#\*.mui" copy /y "%_cabdir%\du\%%#\*" "ISOFOLDER\sources\%%#\" %_Nul3%
if exist "%_cabdir%\du\replacementmanifests\" xcopy /CERY "%_cabdir%\du\replacementmanifests" "ISOFOLDER\sources\replacementmanifests\" %_Nul3%
rmdir /s /q "%_cabdir%\du\" %_Nul3%
exit /b

:extract
if not exist "!_cabdir!\" mkdir "!_cabdir!"
if not exist "!_cabdir!\LCUmum\" mkdir "!_cabdir!\LCUmum"
if not exist "!_cabdir!\LCUall\" mkdir "!_cabdir!\LCUall"
if exist "!_UUP!\*Windows1*-KB*.msu" if %LCUmsuExpand% neq 0 if %_build% geq 22621 if %winbuild% geq 9600 (
if exist "%SysPath%\UpdateCompression.dll" (set psfwim=1) else (if %_build% geq 26052 call :uups_dll UpdateCompression)
if %_build% lss 26052 set psfwim=1
)
if exist "!_cabdir!\UpdateCompression.dll" if %LCUmsuExpand% neq 0 (
set "_delta=!_cabdir!\UpdateCompression.dll"
set psfwim=1
)
if %psfnet% equ 0 set psfwim=0
set _cab=0
if %_build% geq 21382 if exist "!_UUP!\*Windows1*-KB*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*Windows1*-KB*.msu"') do (set "package=%%#"&call :sum2msu)
if exist "!_UUP!\*defender-dism*%_bit%*.cab" for /f "tokens=* delims=" %%# in ('dir /b "!_UUP!\*defender-dism*%_bit%*.cab"') do (call set /a _cab+=1)
if exist "!_UUP!\SSU-*-*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\SSU-*-*.cab"') do (call set /a _cab+=1)
if exist "!_UUP!\*Windows1*-KB*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*Windows1*-KB*.cab"') do (set "pkgn=%%~n#"&call :sum2cab)
:: if %_cab% gtr 0 call :dk_color1 %Gray% "=== Extracting updates files . . ." 4 5
set count=0&set isoupdate=&set tmpcmp=&set _rcu=
if %_build% geq 21382 if exist "!_UUP!\*Windows1*-KB*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*Windows1*-KB*.msu"') do (set "pkgn=%%~n#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :msu2)
if exist "!_UUP!\*defender-dism*%_bit%*.cab" for /f "tokens=* delims=" %%# in ('dir /b "!_UUP!\*defender-dism*%_bit%*.cab"') do (set "pkgn=%%~n#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :cab2)
if exist "!_UUP!\SSU-*-*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\SSU-*-*.cab"') do (set "pkgn=%%~n#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :cab2)
if exist "!_UUP!\*Windows1*-KB*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*Windows1*-KB*.cab"') do (set "pkgn=%%~n#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :cab2)
if defined tmpcmp if exist "!_UUP!\Windows1?.?-*%arch%_inout.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\Windows1?.?-*%arch%_inout.cab"') do (set "pkgn=%%~n#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :cab2)
if %psfwim% equ 1 if exist "!_cabdir!\*Windows1*-KB*.wim" for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\*Windows1*-KB*.wim"') do (set "pkgn=%%~n#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :psfx2)
if %psfwim% equ 1 if exist "!_UUP!\RCU-*-*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\RCU-*-*.cab"') do (set "pkgn=%%~n#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :cab3)
goto :eof

:sum2msu
expand.exe -d -f:*Windows*.psf "!_UUP!\%package%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% || (
wimlib-imagex.exe dir "!_UUP!\%package%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% || goto :eof
)
call set /a _cab+=1
goto :eof

:sum2cab
for /f "tokens=2 delims=-" %%V in ('echo %pkgn%') do set pkgid=%%V
set "uupmsu="
if %_build% geq 21382 if exist "!_UUP!\*Windows1*%pkgid%*%arch%*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*Windows1*%pkgid%*%arch%*.msu"') do (
set "uupmsu=%%#"
)
if defined uupmsu (
expand.exe -d -f:*Windows*.psf "!_UUP!\%uupmsu%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% && goto :eof
wimlib-imagex.exe dir "!_UUP!\%uupmsu%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% && goto :eof
)
call set /a _cab+=1
goto :eof

:cab2
for /f "tokens=2 delims=-" %%V in ('echo %pkgn%') do set pkgid=%%V
set "uupmsu="
if %_build% geq 21382 if exist "!_UUP!\*Windows1*%pkgid%*%arch%*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*Windows1*%pkgid%*%arch%*.msu"') do (
set "uupmsu=%%#"
)
if defined uupmsu (
expand.exe -d -f:*Windows*.psf "!_UUP!\%uupmsu%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% && goto :eof
wimlib-imagex.exe dir "!_UUP!\%uupmsu%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% && goto :eof
)
if defined cab_%pkgn% goto :eof
if exist "!dest!\" rmdir /s /q "!dest!\"
mkdir "!dest!"
set /a count+=1
if %count% equ 1 echo.
:: expand.exe -f:update.mum "!_UUP!\%package%" "!dest!" %_Null%
7z.exe e "!_UUP!\%package%" -o"!dest!" update.mum -aoa %_Null%
if not exist "!dest!\update.mum" (
expand.exe -f:*defender*.xml "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*defender*.xml" (
  if /i not "%_target%"=="temp\winre.wim" echo %count%/%_cab%: %package%
  if /i not "%_target%"=="temp\winre.wim" expand.exe -f:* "!_UUP!\%package%" "!dest!" %_Null%
  if /i "%_target%"=="temp\winre.wim" rmdir /s /q "!dest!\" %_Nul3%
) else (
  if not defined cab_%pkgn% echo %count%/%_cab%: %package% [Setup DU]
  set isoupdate=!isoupdate! "%package%"
  set cab_%pkgn%=1
  rmdir /s /q "!dest!\" %_Nul3%
  )
goto :eof
)
expand.exe -f:*.psf.cix.xml "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*.psf.cix.xml" (
if not exist "!_UUP!\%pkgn%.psf" if not exist "!_UUP!\*%pkgid%*%arch%*.psf" (
  call :dk_color1 %Red% "%count%/%_cab%: %package% / PSF file is missing"
  (echo.&echo %package% / PSF file is missing)>>"!logerr!"
  goto :eof
  )
if %psfnet% equ 0 (
  call :dk_color1 %Red% "%count%/%_cab%: %package% / PSFExtractor is not available"
  (echo.&echo %package% / PSFExtractor is not available)>>"!logerr!"
  goto :eof
  )
set psf_%pkgn%=1
)
findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% && (
call :chklcu "!dest!" Package_for_RollupFix
)
expand.exe -f:toc.xml "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\toc.xml" (
echo %count%/%_cab%: %package% [Combined]
mkdir "!_cabdir!\lcu" %_Nul3%
expand.exe -f:* "!_UUP!\%package%" "!_cabdir!\lcu" %_Null%
if exist "!_cabdir!\lcu\SSU-*%arch%*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\SSU-*%arch%*.cab"') do (set "compkg=%%#"&call :inrenssu)
if exist "!_cabdir!\lcu\*Windows1*-KB*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\*Windows1*-KB*.cab"') do (set "compkg=%%#"&call :inrenupd)
rmdir /s /q "!_cabdir!\lcu\" %_Nul3%
rmdir /s /q "!dest!\" %_Nul3%
goto :eof
)
set _extsafe=0
set "_type="
findstr /i /m "Package_for_SafeOSDU" "!dest!\update.mum" %_Nul3% && (set "_type=[SafeOS DU]"&set uwinpe=1)
if not defined _type if %_build% geq 17763 findstr /i /m "WinPE" "!dest!\update.mum" %_Nul3% && (
%_Nul3% findstr /i /m "Edition\"" "!dest!\update.mum"
if errorlevel 1 (set "_type=[WinPE]"&set _extsafe=1&set uwinpe=1)
)
if not defined _type set _extsafe=1
if %_extsafe% equ 1 if not defined _type (
expand.exe -f:*_microsoft-windows-sysreset_*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_microsoft-windows-sysreset_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (set "_type=[SafeOS DU]"&set uwinpe=1)
)
if %_extsafe% equ 1 if not defined _type (
expand.exe -f:*_microsoft-windows-winpe_tools_*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_microsoft-windows-winpe_tools_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (set "_type=[SafeOS DU]"&set uwinpe=1)
)
if %_extsafe% equ 1 if not defined _type (
expand.exe -f:*_microsoft-windows-winre-tools_*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_microsoft-windows-winre-tools_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (set "_type=[SafeOS DU]"&set uwinpe=1)
)
if %_extsafe% equ 1 if not defined _type (
expand.exe -f:*_microsoft-windows-i..dsetup-rejuvenation_*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_microsoft-windows-i..dsetup-rejuvenation_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (set "_type=[SafeOS DU]"&set uwinpe=1)
)
if not defined _type (
findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% && (set "_type=[LCU]"&set uwinpe=1)
)
if not defined _type (
findstr /i /m "Package_for_WindowsExperienceFeaturePack" "!dest!\update.mum" %_Nul3% && set "_type=[UX FeaturePack]"
)
if not defined _type (
expand.exe -f:*_microsoft-windows-servicingstack_*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_microsoft-windows-servicingstack_*.manifest" (
  set "_type=[SSU]"&set uwinpe=1
  call :chkssu "!dest!" "%package%"
  findstr /i /m /c:"Microsoft-Windows-CoreEdition" "!dest!\update.mum" %_Nul3% || set _eosC=1
  findstr /i /m /c:"Microsoft-Windows-ProfessionalEdition" "!dest!\update.mum" %_Nul3% || set _eosP=1
  findstr /i /m /c:"Microsoft-Windows-PPIProEdition" "!dest!\update.mum" %_Nul3% || set _eosT=1
  )
)
if not defined _type (
expand.exe -f:*_netfx4*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_netfx4*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || set "_type=[NetFx]"
)
if not defined _type (
expand.exe -f:*_microsoft-windows-s..boot-firmwareupdate_*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_microsoft-windows-s..boot-firmwareupdate_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || set "_type=[SecureBoot]"
)
if not defined _type if %_build% geq 18362 (
expand.exe -f:microsoft-windows-*enablement-package~*.mum "!_UUP!\%package%" "!dest!" %_Null%
call :EKB1 "!dest!" _type [Enablement]
)
call :EKB2 "!dest!"
if %_build% geq 18362 if exist "!dest!\*enablement-package*.mum" (
expand.exe -f:*_microsoft-windows-e..-firsttimeinstaller_*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_microsoft-windows-e..-firsttimeinstaller_*.manifest" set "_type=[Enablement / EdgeChromium]"
)
if not defined _type (
expand.exe -f:*_microsoft-windows-e..-firsttimeinstaller_*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_microsoft-windows-e..-firsttimeinstaller_*.manifest" set "_type=[EdgeChromium]"
)
if not defined _type (
expand.exe -f:*_adobe-flash-for-windows_*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_adobe-flash-for-windows_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || set "_type=[Flash]"
)
if not defined _type (
expand.exe -f:*_microsoft-windows-m..update-genuineintel_*.manifest "!_UUP!\%package%" "!dest!" %_Null%
expand.exe -f:*_microsoft-windows-m..update-authenticamd_*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_microsoft-windows-m..update-*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || set "_type=[Microcode]"
)
if not defined _type (
expand.exe -f:*_microsoft-onecore-c..dexperiencehost-api_*.manifest "!_UUP!\%package%" "!dest!" %_Null%
expand.exe -f:*_microsoft-updatetargeting-windowsoobe_*.manifest "!_UUP!\%package%" "!dest!" %_Null%
expand.exe -f:*_microsoft-windows-oobe-*.manifest "!_UUP!\%package%" "!dest!" %_Null%
if exist "!dest!\*_microsoft-*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || set "_type=[OOBE]"
)
echo %count%/%_cab%: %package% %_type%
set cab_%pkgn%=1
expand.exe -f:* "!_UUP!\%package%" "!dest!" %_Null% || (
  rmdir /s /q "!dest!\" %_Nul3%
  set directcab=!directcab! %package%
  goto :eof
)
7z.exe e "!_UUP!\%package%" -o"!dest!" update.mum -aoa %_Null%
if exist "!dest!\*cablist.ini" expand.exe -f:* "!dest!\*.cab" "!dest!" %_Null% || (
  rmdir /s /q "!dest!\" %_Nul3%
  set directcab=!directcab! %package%
  goto :eof
)
if exist "!dest!\*cablist.ini" (
  del /f /q "!dest!\*cablist.ini" %_Nul3%
  del /f /q "!dest!\*.cab" %_Nul3%
)
set _sbst=0
if defined psf_%pkgn% (
if not exist "!dest!\express.psf.cix.xml" for /f %%# in ('dir /b /a:-d "!dest!\*.psf.cix.xml"') do rename "!dest!\%%#" express.psf.cix.xml %_Nul3%
subst %_sdr% "!_cabdir!" %_Nul3% && set _sbst=1
if !_sbst! equ 1 pushd %_sdr%
if not exist "%package%" (
copy /y "!_UUP!\%pkgn%.*" . %_Nul3%
if not exist "%pkgn%.psf" for /f %%# in ('dir /b /a:-d "!_UUP!\*%pkgid%*%arch%*.psf"') do copy /y "!_UUP!\%%#" %pkgn%.psf %_Nul3%
)
if not exist "PSFExtractor.exe" copy /y "!_work!\bin\PSFExtractor.*" . %_Nul3%
PSFExtractor.exe %package% %_Null%
if !errorlevel! neq 0 (
  call :dk_color1 %Red% "Error: failed to extract %pkgn%.psf"
  (echo.&echo failed to extract %pkgn%.psf)>>"!logerr!"
  rmdir /s /q "%pkgn%\" %_Nul3%
  set psf_%pkgn%=
  )
if !_sbst! equ 1 popd
if !_sbst! equ 1 subst %_sdr% /d %_Nul3%
)
goto :eof

:msu2
if defined msu_%pkgn% goto :eof
for /f "tokens=2 delims=-" %%V in ('echo %pkgn%') do set pkgid=%%V
if %psfwim% equ 1 if exist "!_cabdir!\*Windows1*%pkgid%*.wim" for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\*Windows1*%pkgid%*.wim"') do (set "pkgw=%%~n#")
if defined psfx_%pkgw% goto :eof
if exist "!dest!\" rmdir /s /q "!dest!\"
mkdir "!dest!"
set msuwim=0
expand.exe -d -f:*Windows*.psf "!_UUP!\%package%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% || (
wimlib-imagex.exe dir "!_UUP!\%package%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% && (set msuwim=1) || (goto :eof)
)
mkdir "!_cabdir!\lcu" %_Nul3%
if %msuwim% equ 1 if %_build% geq 26052 (
wimlib-imagex.exe extract "!_UUP!\%package%" 1 *.AggregatedMetadata*.cab --dest-dir="!_cabdir!\lcu" %_Nul3%
for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\*.AggregatedMetadata*.cab" %_Nul6%') do (expand.exe -f:HotpatchCompDB*.cab "!_cabdir!\lcu\%%#" "!_cabdir!\lcu" %_Null%)
)
if exist "!_cabdir!\lcu\HotpatchCompDB*.cab" (
if %count% equ 0 echo.
echo Not Supported: %package% [HotPatchUpdate]
rmdir /s /q "!_cabdir!\lcu\" %_Nul3%
goto :eof
)
set /a count+=1
if %count% equ 1 echo.
echo %count%/%_cab%: %package% [Combined UUP]
if %msuwim% equ 0 (
expand.exe -f:*Windows*.cab "!_UUP!\%package%" "!_cabdir!\lcu" %_Null%
expand.exe -f:SSU-*%arch%*.cab "!_UUP!\%package%" "!_cabdir!\lcu" %_Null%
) else (
wimlib-imagex.exe extract "!_UUP!\%package%" 1 *Windows*.wim --dest-dir="!_cabdir!\lcu" %_Null%
wimlib-imagex.exe extract "!_UUP!\%package%" 1 SSU-*%arch%*.cab --dest-dir="!_cabdir!\lcu" %_Null%
if %_build% geq 26100 wimlib-imagex.exe extract "!_UUP!\%package%" 1 RCU-*%arch%*.cab --dest-dir="!_cabdir!\lcu" %_Null%
if %psfwim% equ 1 wimlib-imagex.exe extract "!_UUP!\%package%" 1 *Windows*.psf --dest-dir="!_cabdir!" %_Null%
)
for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\*Windows1*-KB*.*"') do set "compkg=%%#"
7z.exe e "!_cabdir!\lcu\%compkg%" -o"!dest!" update.mum -aoa %_Null%
if exist "!_cabdir!\lcu\RCU-*baseless*.*" del /f /q "!_cabdir!\lcu\RCU-*baseless*.*" %_Nul3%
if exist "!_cabdir!\lcu\RCU-*%arch%*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\RCU-*%arch%*.cab"') do (
set _rcu=%pkgid%
7z.exe e "!_cabdir!\lcu\%%#" -o"!_cabdir!\lcu" update.mum -aoa %_Null%
7z.exe e "!_cabdir!\lcu\%%#" -o"!dest!" %_ss%_microsoft-updatetargeting-*os_*.manifest -aoa %_Null%
call :chklcu "!_cabdir!\lcu" Package_for_RevisedFix
if %psfwim% equ 1 set "compkg=%%#"&call :inrenrcu
)
if exist "!_cabdir!\lcu\SSU-*%arch%*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\lcu\SSU-*%arch%*.cab"') do (set "compkg=%%#"&call :inrenssu)
if %msuwim% equ 1 if %psfwim% equ 1 (
move /y "!_cabdir!\lcu\*.wim" "!_cabdir!\" %_Nul3%
)
rmdir /s /q "!_cabdir!\lcu\" %_Nul3%
set msu_%pkgn%=1
findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% && (
call :chklcu "!dest!" Package_for_RollupFix
)
goto :eof

:psfx2
if defined psfx_%pkgn% goto :eof
for /f "tokens=2 delims=-" %%V in ('echo %pkgn%') do set pkgid=%%V
if exist "!dest!\" rmdir /s /q "!dest!\"
mkdir "!dest!"
set "pkgm=nein"
if exist "!_UUP!\*%pkgid%*.msu" (
for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*%pkgid%*.msu"') do set "pkgm=%%~n#"
) else if defined _rcu (
if exist "!_UUP!\*%_rcu%*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*%_rcu%*.msu"') do set "pkgm=%%~n#"
)
set msu_%pkgm%=
set psfx_%pkgn%=1
set /a count+=1
call set /a _cab+=1
echo %count%/%_cab%: %package% [LCU]
wimlib-imagex.exe apply "!_cabdir!\%package%" 1 "!dest!" --no-acls --no-attributes %_Null%
if not exist "!dest!\express.psf.cix.xml" for /f %%# in ('dir /b /a:-d "!dest!\*.psf.cix.xml"') do rename "!dest!\%%#" express.psf.cix.xml %_Nul3%
set _sbst=0
subst %_sdr% "!_cabdir!" %_Nul3% && set _sbst=1
if !_sbst! equ 1 pushd %_sdr%
if not exist "psfx.txt" copy /y "!_work!\bin\psfx.txt" . %_Nul3%
%_Nul3% %_pspsfx% "Set-Location -LiteralPath '!_cabdir!'; $f=[IO.File]::ReadAllText('.\psfx.txt') -split ':cabpsf\:.*';iex ($f[1]);P '!_cabdir!\%package%' '%_delta%'"
dir /b /ad "!dest!\*_microsoft*" %_Null% || (
  call :dk_color1 %Red% "Error: failed to extract %pkgn%.psf"
  (echo.&echo failed to extract %pkgn%.psf)>>"!logerr!"
  copy /y "!dest!\update.mum" . %_Nul3%
  copy /y "!dest!\%_ss%_microsoft-updatetargeting-*os_*.manifest" . %_Nul3%
  rmdir /s /q "!dest!\" %_Nul3%
  mkdir "!dest!" %_Nul3%
  move /y "update.mum" "!dest!\" %_Nul3%
  move /y "%_ss%_microsoft-updatetargeting-*os_*.manifest" "!dest!\" %_Nul3%
  set psfx_%pkgn%=
  set msu_%pkgm%=1
  )
if !_sbst! equ 1 popd
if !_sbst! equ 1 subst %_sdr% /d %_Nul3%
for /f "tokens=5-8 delims==. " %%H in ('findstr /i Package_for_RollupFix "!dest!\update.mum"') do set "cver=%%~H.%%I.%%J.%%K
findstr /i Baseline "!dest!\update.mum" %_Nul1% && (
set "basekbn=!basekbn! %pkgid%"
set "basepkg=!basepkg! Package_for_RollupFix~%_Pkt%~%_ss%~~%cver%"
)
:: if exist "!_cabdir!\LCUall\*%pkgm%*.msu" del /f /q "!_cabdir!\LCUall\*%pkgm%*.msu" %_Nul3%
goto :eof

:cab3
if defined cab_%pkgn% goto :eof
if exist "!dest!\" rmdir /s /q "!dest!\"
mkdir "!dest!"
set /a count+=1
:: 7z.exe e "!_UUP!\%package%" -o"!dest!" update.mum -aoa %_Null%
:: call :chklcu "!dest!" Package_for_RevisedFix
set "_type=[RCU]"&set uwinpe=1
echo %count%/%_cab%: %package% %_type%
set cab_%pkgn%=1
expand.exe -f:* "!_UUP!\%package%" "!dest!" %_Null% || (
  rmdir /s /q "!dest!\" %_Nul3%
  set directcab=!directcab! %package%
  goto :eof
)
7z.exe e "!_UUP!\%package%" -o"!dest!" update.mum -aoa %_Null%
goto :eof

:vrpad
set cuvr=%1
       if %cuvr% lss 10 (set cuvr=0000%cuvr%
) else if %cuvr% lss 100 (set cuvr=000%cuvr%
) else if %cuvr% lss 1000 (set cuvr=00%cuvr%
) else if %cuvr% lss 10000 (set cuvr=0%cuvr%
)
goto :eof

:chklcu
findstr /i /m /c:"Microsoft-Windows-CoreEdition" "%~1\update.mum" %_Nul3% || set _eosC=1
findstr /i /m /c:"Microsoft-Windows-ProfessionalEdition" "%~1\update.mum" %_Nul3% || set _eosP=1
findstr /i /m /c:"Microsoft-Windows-PPIProEdition" "%~1\update.mum" %_Nul3% || set _eosT=1
set /a c_num+=1
set kbvr=0
set kbnm=%2
for /f "tokens=5-8 delims==. " %%H in ('findstr /i %kbnm% "%~1\update.mum"') do set "kbvr=%%I"&set "cver=%%~H.%%I.%%J.%%K
if %_build% geq 22621 (
if not exist "!_cabdir!\LCUmum\%kbnm%~%_Pkt%~%_ss%~~%cver%.mum" copy /y "%~1\update.mum" "!_cabdir!\LCUmum\%kbnm%~%_Pkt%~%_ss%~~%cver%.mum" %_Nul1%
)
call :vrpad %kbvr%
if %_build% geq 26052 (
if not exist "!_cabdir!\LCUall\*Windows*%pkgid%*.msu" if not exist "!_cabdir!\LCUall\%cuvr%-%package%" (
  copy /y "!_UUP!\%package%" "!_cabdir!\LCUall\%cuvr%-%package%" %_Nul1%
)
echo %package% |findstr /i "KB5043080" %_Nul1% && if not exist "!_cabdir!\LCUbase\%cuvr%-%package%" (
  mkdir "!_cabdir!\LCUbase" %_Nul3%
  copy /y "!_UUP!\%package%" "!_cabdir!\LCUbase\%cuvr%-%package%" %_Nul1%
  )
)
if %kbvr% geq %c_ver% (
set "c_ver=%kbvr%"
set "c_pkg=%package%"
) else (
goto :eof
)
copy /y "!dest!\update.mum" %SystemRoot%\temp\ %_Nul1%
call :datemum isodate isotime
goto :eof

:chkssu
if %_build% leq 10586 exit /b
set latest=0
set chvr_aa=0
set chvr_bl=0
set chvr_mj=0
set chvr_mn=0
for /f "tokens=5-8 delims==. " %%H in ('findstr /i Package_for_ "%~1\update.mum"') do set "chvr_aa=%%~H"&set "chvr_bl=%%I"&set "chvr_mj=%%J"&set "chvr_mn=%%K
if %chvr_aa% gtr %ssvr_aa% set latest=1
if %chvr_aa% equ %ssvr_aa% if %chvr_bl% gtr %ssvr_bl% set latest=1
if %chvr_aa% equ %ssvr_aa% if %chvr_bl% equ %ssvr_bl% if %chvr_mj% gtr %ssvr_mj% set latest=1
if %chvr_aa% equ %ssvr_aa% if %chvr_bl% equ %ssvr_bl% if %chvr_mj% equ %ssvr_mj% if %chvr_mn% gtr %ssvr_mn% set latest=1
if %latest% equ 1 (
set "s_pkg=%~2"
set ssvr_aa=%chvr_aa%
set ssvr_bl=%chvr_bl%
set ssvr_mj=%chvr_mj%
set ssvr_mn=%chvr_mn%
)
goto :eof

:EKB1
if not exist "%~1\microsoft-windows-*enablement-package~*.mum" goto :eof
set "%2=%3"
if exist "%~1\Microsoft-Windows-1909Enablement-Package~*.mum" set "_fixEP=18363"
if exist "%~1\Microsoft-Windows-20H2Enablement-Package~*.mum" set "_fixEP=19042"
if exist "%~1\Microsoft-Windows-21H1Enablement-Package~*.mum" set "_fixEP=19043"
if exist "%~1\Microsoft-Windows-21H2Enablement-Package~*.mum" set "_fixEP=19044"
if exist "%~1\Microsoft-Windows-22H2Enablement-Package~*.mum" set "_fixEP=19045"
if exist "%~1\Microsoft-Windows-ASOSFe22H2Enablement-Package~*.mum" set "_fixEP=20349"
if exist "%~1\Microsoft-Windows-SV*Enablement-Package~*.mum" set "_fixEP=%_fixSV%"
if exist "%~1\Microsoft-Windows-SV2Moment*Enablement-Package~*.mum" for /f "tokens=3 delims=-" %%a in ('dir /b /a:-d /od "%~1\Microsoft-Windows-SV2Moment*Enablement-Package~*.mum"') do (
  for /f "tokens=3 delims=eEtT" %%i in ('echo %%a') do (
    set /a _fixSV=%_build%+%%i
    set /a _fixEP=%_build%+%%i
  )
)
goto :eof

:EKB2
if not exist "%~1\microsoft-windows-*enablement-package~*.mum" goto :eof
if exist "%~1\Microsoft-Windows-SV2Moment4Enablement-Package~*.mum" set "_fixSV=22631"&set "_fixEP=22631"
if exist "%~1\Microsoft-Windows-23H2Enablement-Package~*.mum" set "_fixSV=22631"&set "_fixEP=22631"
if exist "%~1\Microsoft-Windows-SV2BetaEnablement-Package~*.mum" set "_fixSV=22635"&set "_fixEP=22635"
if exist "%~1\Microsoft-Windows-Ge-Client-Server-Beta-Version-Enablement-Package~*.mum" set "_fixSV=26120"&set "_fixEP=26120"
if exist "%~1\Microsoft-Windows-Ge-Client-Server-26200-Version-Enablement-Package~*.mum" set "_fixSV=26200"&set "_fixEP=26200"
if exist "%~1\Microsoft-Windows-Ge-Client-Server-26220-Version-Enablement-Package~*.mum" set "_fixSV=26220"&set "_fixEP=26220"
if exist "%~1\Microsoft-Windows-Ge-Client-Server-26300-Version-Enablement-Package~*.mum" set "_fixSV=26300"&set "_fixEP=26300"
if exist "%~1\Microsoft-Windows-Client-Br-28020-Version-Enablement-Package~*.mum" set "_fixSV=28020"&set "_fixEP=28020"
if exist "%~1\Microsoft-Windows-Client-Br-28100-Version-Enablement-Package~*.mum" set "_fixSV=28100"&set "_fixEP=28100"
if exist "%~1\Microsoft-Windows-Client-Br-28120-Version-Enablement-Package~*.mum" set "_fixSV=28120"&set "_fixEP=28120"
goto :eof

:inrenrcu
if exist "!_UUP!\%compkg:~0,-4%*.cab" goto :eof
set kbupd=
expand.exe -f:update.mum "!_cabdir!\lcu\%compkg%" "!_cabdir!\lcu" %_Null%
if not exist "!_cabdir!\lcu\update.mum" goto :eof
for /f "tokens=3 delims== " %%# in ('findstr /i releaseType "!_cabdir!\lcu\update.mum"') do set kbupd=%%~#
if "%kbupd%"=="" goto :eof
set _ufn=%compkg:~0,-4%-%kbupd%.cab
if exist "!_UUP!\%_ufn%" goto :eof
call set /a _cab+=1
set "tmpcmp=!tmpcmp! %_ufn%"
move /y "!_cabdir!\lcu\%compkg%" "!_UUP!\%_ufn%" %_Nul3%
goto :eof

:inrenssu
if exist "!_UUP!\%compkg:~0,-4%*.cab" goto :eof
set kbupd=
expand.exe -f:update.mum "!_cabdir!\lcu\%compkg%" "!_cabdir!\lcu" %_Null%
if not exist "!_cabdir!\lcu\update.mum" goto :eof
for /f "tokens=3 delims== " %%# in ('findstr /i releaseType "!_cabdir!\lcu\update.mum"') do set kbupd=%%~#
if "%kbupd%"=="" goto :eof
set _ufn=Windows10.0-%kbupd%-%arch%_inout.cab
dir /b /on "!_cabdir!\lcu\*Windows1*-KB*.*" %_Nul2% | findstr /i "Windows11\." %_Nul1% && set _ufn=Windows11.0-%kbupd%-%arch%_inout.cab
dir /b /on "!_cabdir!\lcu\*Windows1*-KB*.*" %_Nul2% | findstr /i "Windows12\." %_Nul1% && set _ufn=Windows12.0-%kbupd%-%arch%_inout.cab
if exist "!_UUP!\%_ufn%" goto :eof
call set /a _cab+=1
set "tmpcmp=!tmpcmp! %_ufn%"
move /y "!_cabdir!\lcu\%compkg%" "!_UUP!\%_ufn%" %_Nul3%
goto :eof

:inrenupd
for /f "tokens=2 delims=-" %%V in ('echo %compkg%') do set kbupd=%%V
set _ufn=Windows10.0-%kbupd%-%arch%_inout.cab
echo %compkg%| findstr /i "Windows11\." %_Nul1% && set _ufn=Windows11.0-%kbupd%-%arch%_inout.cab
echo %compkg%| findstr /i "Windows12\." %_Nul1% && set _ufn=Windows12.0-%kbupd%-%arch%_inout.cab
if exist "!_UUP!\%_ufn%" goto :eof
call set /a _cab+=1
set "tmpcmp=!tmpcmp! %_ufn%"
move /y "!_cabdir!\lcu\%compkg%" "!_UUP!\%_ufn%" %_Nul3%
goto :eof

:updatewim
set mumtarget=%_mount%
set dismtarget=/Image:"%_mount%"
set "_Wnn=HKLM\%SOFTWARE%\Microsoft\Windows\CurrentVersion\SideBySide\Winners"
set "_Cmp=HKLM\%COMPONENTS%\DerivedData\Components"
if exist "%mumtarget%\Windows\Servicing\Packages\*~arm64~~*.mum" (
set "xBT=arm64"
set "_EsuCom=arm64_%_EsuCmp%_%_Pkt%_%_OurVer%_none_eeb9e0b00f513fbe"
set "_SupCom=arm64_%_SupCmp%_%_Pkt%_%_OurVer%_none_8b15303df56a09af"
set "_CedCom=arm64_%_CedCmp%_%_Pkt%_%_OurVer%_none_7cb088037a42a80b"
set "_EsuKey=%_Wnn%\arm64_%_EsuCmp%_%_Pkt%_none_0e1ac5e1d0e42392"
set "_SupKey=%_Wnn%\arm64_%_SupCmp%_%_Pkt%_none_0a035f900ca87ee9"
set "_EdgKey=%_Wnn%\arm64_%_EdgCmp%_%_Pkt%_none_1e5e2b2c8adcf701"
set "_CedKey=%_Wnn%\arm64_%_CedCmp%_%_Pkt%_none_df3eefecc502346d"
) else if exist "%mumtarget%\Windows\Servicing\Packages\*~amd64~~*.mum" (
set "xBT=amd64"
set "_EsuCom=amd64_%_EsuCmp%_%_Pkt%_%_OurVer%_none_eeb9d8760f514b22"
set "_SupCom=amd64_%_SupCmp%_%_Pkt%_%_OurVer%_none_8b152803f56a1513"
set "_CedCom=amd64_%_CedCmp%_%_Pkt%_%_OurVer%_none_7cb07fc97a42b36f"
set "_EsuKey=%_Wnn%\amd64_%_EsuCmp%_%_Pkt%_none_0e1abda7d0e42ef6"
set "_SupKey=%_Wnn%\amd64_%_SupCmp%_%_Pkt%_none_0a0357560ca88a4d"
set "_EdgKey=%_Wnn%\amd64_%_EdgCmp%_%_Pkt%_none_1e5e22f28add0265"
set "_CedKey=%_Wnn%\amd64_%_CedCmp%_%_Pkt%_none_df3ee7b2c5023fd1"
) else (
set "xBT=x86"
set "_EsuCom=x86_%_EsuCmp%_%_Pkt%_%_OurVer%_none_929b3cf256f3d9ec"
set "_SupCom=x86_%_SupCmp%_%_Pkt%_%_OurVer%_none_2ef68c803d0ca3dd"
set "_CedCom=x86_%_CedCmp%_%_Pkt%_%_OurVer%_none_2091e445c1e54239"
set "_EsuKey=%_Wnn%\x86_%_EsuCmp%_%_Pkt%_none_b1fc22241886bdc0"
set "_SupKey=%_Wnn%\x86_%_SupCmp%_%_Pkt%_none_ade4bbd2544b1917"
set "_EdgKey=%_Wnn%\x86_%_EdgCmp%_%_Pkt%_none_c23f876ed27f912f"
set "_CedKey=%_Wnn%\x86_%_CedCmp%_%_Pkt%_none_83204c2f0ca4ce9b"
)
for /f "tokens=4,5,6 delims=_" %%H in ('dir /b "%mumtarget%\Windows\WinSxS\Manifests\%xBT%_microsoft-windows-foundation_*.manifest"') do set "_Fnd=microsoft-w..-foundation_%_Pkt%_%%H_%%~nJ"
if %_build% geq 14393 if %_build% lss 19041 if not exist "%mumtarget%\Windows\WinSxS\Manifests\%_SupCom%.manifest" call :Latent _Sup %_Nul3%
if %_build% geq 14393 if %_build% lss 19046 if not exist "%mumtarget%\Windows\WinSxS\Manifests\%_EsuCom%.manifest" call :Latent _Esu %_Nul3%
if %_build% geq 17134 if %_build% lss 20348 if not exist "%mumtarget%\Windows\WinSxS\Manifests\%_CedCom%.manifest" if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" if not exist "%mumtarget%\Windows\WinSxS\Manifests\%xBT%_%_CedCmp%_*.manifest" if %SkipEdge% equ 1 call :Latent _Ced %_Nul3%
set lcuall=
set lcumsu=
set mpamfe=
set servicingstack=
set cumulative=
set ekbpack=
set netupdt=
set netpack=
set netroll=
set netlcu=
set netmsu=
set secureboot=
set edge=
set safeos=
set callclean=
set fupdt=
set supdt=
set cupdt=
set dupdt=
set overall=
set lcupkg=
set ldr=
set mounterr=
set idpkg=
set _clnwinpe=0
set LTSC=0
if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
if %_build% neq 14393 if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-PPIProEdition~*.mum" set LTSC=1
if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-EnterpriseS*Edition~*.mum" set LTSC=1
if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-IoTEnterpriseS*Edition~*.mum" set LTSC=1
if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-Server*Edition~*.mum" set LTSC=1
if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-Server*ACorEdition~*.mum" set LTSC=0
if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-Server*NanoEdition~*.mum" set LTSC=0
if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-ServerAzureStackHCI*Edition~*.mum" set LTSC=0
)
if exist "!_UUP!\SSU-*-*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\SSU-*-*.cab"') do (set "pckn=%%~n#"&set "packx=%%~x#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :procmum)
if exist "!_UUP!\*Windows1*-KB*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*Windows1*-KB*.cab"') do (set "pckn=%%~n#"&set "packx=%%~x#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :procmum)
if %_build% geq 21382 if exist "!_UUP!\*Windows1*-KB*.msu" (for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*Windows1*-KB*.msu"') do if defined msu_%%~n# (set "pckn=%%~n#"&set "packx=%%~x#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :procmum))
if %psfwim% equ 1 if exist "!_cabdir!\*Windows1*-KB*.wim" (for /f "tokens=* delims=" %%# in ('dir /b /on "!_cabdir!\*Windows1*-KB*.wim"') do if defined psfx_%%~n# (set "pckn=%%~n#"&set "packx=%%~x#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :procmum))
if %psfwim% equ 1 if exist "!_UUP!\RCU-*-*.cab" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\RCU-*-*.cab"') do (set "pckn=%%~n#"&set "packx=%%~x#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :procrcu)
if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" if exist "!_UUP!\*defender-dism*%_bit%*.cab" (for /f "tokens=* delims=" %%# in ('dir /b "!_UUP!\*defender-dism*%_bit%*.cab"') do (set "pckn=%%~n#"&set "packx=%%~x#"&set "package=%%#"&set "dest=!_cabdir!\%%~n#"&call :procmum))
call :wds_add
if %_build% geq 22621 if %winbuild% lss 10240 reg.exe query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentMajorVersionNumber %_Nul3% || (
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentMajorVersionNumber /t REG_DWORD /d 10 /f %_Nul3%
reg.exe add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentMinorVersionNumber /t REG_DWORD /d 0 /f %_Nul3%
)
if %_build% geq 19041 if %winbuild% lss 17133 if not exist "%SysPath%\ext-ms-win-security-slc-l1-1-0.dll" (
copy /y %SysPath%\slc.dll %SysPath%\ext-ms-win-security-slc-l1-1-0.dll %_Nul1%
if /i not %xOS%==x86 copy /y %SystemRoot%\SysWOW64\slc.dll %SystemRoot%\SysWOW64\ext-ms-win-security-slc-l1-1-0.dll %_Nul1%
)
if %winbuild% lss 15063 if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
call :hiveON
if /i %arch%==arm64 reg.exe add HKLM\%SOFTWARE%\Microsoft\Windows\CurrentVersion\SideBySide /v AllowImproperDeploymentProcessorArchitecture /t REG_DWORD /d 1 /f %_Nul3%
if %winbuild% lss 9600 reg.exe add HKLM\%SOFTWARE%\Microsoft\Windows\CurrentVersion\SideBySide /v AllowImproperDeploymentProcessorArchitecture /t REG_DWORD /d 1 /f %_Nul3%
call :hiveOFF
)
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
call :sbsconfig 9 9 1
)
if defined netpack set "ldr=!netpack! !ldr!"
if defined ekbpack set "ldr=!ekbpack! !ldr!"
for %%# in (dupdt,cupdt,supdt,fupdt,secureboot,edge,ldr,cumulative,lcumsu) do if defined %%# set overall=1
if not defined safeos if not defined overall if not defined mpamfe if not defined servicingstack goto :eof
if defined servicingstack (
set idpkg=ServicingStack
set callclean=1
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismSSU.log" /Add-Package %servicingstack%
call :chkEC !errorlevel!
if !_ec!==1 goto :errmount
if not defined safeos if not defined overall call :cleanup
)
if not defined safeos if not defined overall if not defined mpamfe goto :eof
set noLCU=0
if not defined cumulative if not defined lcumsu set noLCU=1
set mntRE=0
set sduRE=0
set cmtRE=0
if defined safeos if %SkipWinRE% equ 0 if %LCUwinre% equ 0 (
set sduRE=1
if defined overall set mntRE=1
)
if %sduRE% equ 1 if %mntRE% equ 1 (
set cmtRE=1
)
if %cmtRE% equ 1 (
if defined DrvSrcALL %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DrvWinPE.log" /Add-Driver /Driver:"!DrvSrcALL!" /Recurse
if defined DrvSrcPE %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DrvWinPE.log" /Add-Driver /Driver:"!DrvSrcPE!" /Recurse
%_dism2%:"!_cabdir!" /Commit-Wim /MountDir:"%_mount%" %_Supp%
)
if defined safeos if %SkipWinRE% equ 0 (
set idpkg=SafeOS
set callclean=1
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismWinPE.log" /Add-Package %safeos%
call :chkEC !errorlevel!
if !_ec!==1 goto :errmount
)
if %sduRE% equ 1 (
set relite=1
if not defined lcumsu if %_build% lss 26052 call :cleanup
%_wrb% if not defined lcumsu if %ResetBase% equ 0 %_dism2%:"!_cabdir!" %dismtarget% /Cleanup-Image /StartComponentCleanup /ResetBase %_Null%
call :wds_rem
%_dism2%:"!_cabdir!" /Commit-Image /MountDir:"%_mount%" /Append %_Supp%
call :wds_add
)
if %noLCU% equ 0 if not defined safeos if %SkipWinRE% equ 0 if %_build% geq 26052 if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
set relite=1
call :wds_rem
%_dism2%:"!_cabdir!" /Commit-Image /MountDir:"%_mount%" /Append %_Supp%
call :wds_add
)
if %mntRE% equ 1 (
call :dk_color1 %Gray% "=== Remounting image . . ." 4
%_dism2%:"!_cabdir!" /Unmount-Wim /MountDir:"%_mount%" /Discard
%_dism2%:"!_cabdir!" /Mount-Wim /Wimfile:"%_www%" /Index:%_inx% /MountDir:"%_mount%"
if !errorlevel! neq 0 (call :dismount 1 &goto :eof)
)
if %noLCU% equ 1 goto :scbt
set _gobk=scbt
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :updtlcu
:scbt
if defined secureboot (
set idpkg=SecureBoot
set callclean=1
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismSecureBoot.log" /Add-Package %secureboot%
call :chkEC !errorlevel!
if !_ec!==1 goto :errmount
)
if defined ldr (
set idpkg=General
set callclean=1
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismUpdt.log" /Add-Package %ldr%
call :chkEC !errorlevel!
if !_ec!==1 if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :errmount
)
if defined fupdt (
set "_SxsKey=%_EdgKey%"
set "_SxsCmp=%_EdgCmp%"
set "_SxsIdn=%_EdgIdn%"
set "_SxsCF=256"
set "_DsmLog=DismEdge.log"
for %%# in (%fupdt%) do (set "cbsn=%%~n#"&set "dest=!_cabdir!\%%~n#"&call :pXML)
)
if defined supdt (
set "_SxsKey=%_SupKey%"
set "_SxsCmp=%_SupCmp%"
set "_SxsIdn=%_SupIdn%"
set "_SxsCF=64"
set "_DsmLog=DismSupSvc.log"
for %%# in (%supdt%) do (set "cbsn=%%~n#"&set "dest=!_cabdir!\%%~n#"&call :pXML)
)
if defined cupdt (
set "_SxsKey=%_CedKey%"
set "_SxsCmp=%_CedCmp%"
set "_SxsIdn=%_CedIdn%"
set "_SxsCF=256"
set "_DsmLog=DismLCUs.log"
for %%# in (%cupdt%) do (set "cbsn=%%~n#"&set "dest=!_cabdir!\%%~n#"&call :pXML)
)
set _dualSxS=
if defined dupdt (
set _dualSxS=1
set "_SxsKey=%_SupKey%"
set "_SxsCmp=%_SupCmp%"
set "_SxsIdn=%_SupIdn%"
set "_SxsCF=64"
set "_DsmLog=DismLCUs.log"
for %%# in (%dupdt%) do (set "cbsn=%%~n#"&set "dest=!_cabdir!\%%~n#"&call :pXML)
)
if %noLCU% equ 1 goto :cuwd
set _gobk=cuwd
if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :updtlcu
:cuwd
if defined basekbn call :regBase
if defined lcupkg call :ReLCU
if defined callclean if %_clnwinpe% equ 0 call :cleanup
if defined mpamfe (
call :dk_color1 %Gray% "=== Adding Defender update . . ." 4
call :defender_update
)
if not defined edge goto :eof
if defined edge (
set idpkg=Edge
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismEdge.log" /Add-Package %edge%
call :chkEC !errorlevel!
if !_ec!==1 goto :errmount
)
goto :eof

:updtlcu
set "_wpeLCU=boot.wim"
if %SkipWinRE% equ 0 if %LCUwinre% equ 1 set "_wpeLCU=winre.wim/boot.wim"
set "_DsmLog=DismLCU.log"
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
set "_DsmLog=DismLCU_winpe.log"
call :dk_color1 %Gray% "=== Adding LCU for %_wpeLCU% . . ." 4
if defined lcumsu if %_build% geq 26052 if exist "%mumtarget%\Windows\Servicing\Packages\WinPE-Rejuv-Package~*.mum" for /f "delims=" %%# in ('dir /b /a:-d "%mumtarget%\Windows\Servicing\Packages\WinPE-Rejuv-Package~*.mum"') do (
  %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNUL.log" /Remove-Package /PackageName:%%~n# %_Nul3%
  )
)
set idpkg=LCU
set callclean=1
set _c_=0
set _e_=0
if defined cumulative for %%# in (%cumulative%) do (
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\%_DsmLog%" /Add-Package /PackagePath:%%#
call set _e_=!errorlevel!
call set /a _c_+=1
if not exist "%mumtarget%\Windows\WinSxS\pending.xml" if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" if %ResetBase% equ 2 if %_build% geq 26052 if !_c_! lss %c_num% call :rebase
)
if defined lcumsu for %%# in (%lcumsu%) do (
call :dk_color1 %_Yellow% "=== Adding LCU %%~nx#" 4
set ppath=%%#
if exist "!_cabdir!\LCUbase\%%~nx#" set ppath="!_cabdir!\LCUbase\%%~nx#"
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\%_DsmLog%" /Add-Package /PackagePath:!ppath!
call set _e_=!errorlevel!
call set /a _c_+=1
if not exist "%mumtarget%\Windows\WinSxS\pending.xml" if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" if %ResetBase% equ 2 if %_build% geq 26052 if !_c_! lss %c_num% call :rebase
)
call :chkEC %_e_%
if !_ec!==1 if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :errmount
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" if %SkipWinRE% equ 0 if %LCUwinre% equ 1 (
set _clnwinpe=1
set relite=1
call :cleanup
call :wds_rem
%_dism2%:"!_cabdir!" /Commit-Image /MountDir:"%_mount%" /Append %_Supp%
call :wds_add
)
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :%_gobk%
if not exist "%mumtarget%\Windows\Servicing\Packages\Package_for_RollupFix*.mum" goto :%_gobk%
if not defined lcumsu goto :%_gobk%
:: if %_build% geq 26052 goto :%_gobk%
if not exist "!_cabdir!\LCUmum\*.mum" goto :%_gobk%
for /f %%# in ('dir /b /a:-d /od "%mumtarget%\Windows\Servicing\Packages\Package_for_RollupFix*.mum" %_Nul6%') do if exist "!_cabdir!\LCUmum\%%#" (
call :svcpkg "%%#"
)
for /f %%# in ('dir /b /a:-d /od "%mumtarget%\Windows\Servicing\Packages\Package_for_RevisedFix*.mum" %_Nul6%') do if exist "!_cabdir!\LCUmum\%%#" (
call :svcpkg "%%#"
)
goto :%_gobk%

:svcpkg
set "kbnm=%~1"
%_Nul3% icacls "%mumtarget%\Windows\Servicing\Packages\%kbnm%" /save "!_cabdir!\acl.txt"
%_Nul3% takeown /f "%mumtarget%\Windows\Servicing\Packages\%kbnm%" /A
%_Nul3% icacls "%mumtarget%\Windows\Servicing\Packages\%kbnm%" /grant *S-1-5-32-544:F
%_Nul3% copy /y "!_cabdir!\LCUmum\%kbnm%" "%mumtarget%\Windows\Servicing\Packages\%kbnm%"
%_Nul3% icacls "%mumtarget%\Windows\Servicing\Packages\%kbnm%" /setowner *S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464
%_Nul3% icacls "%mumtarget%\Windows\Servicing\Packages" /restore "!_cabdir!\acl.txt"
%_Nul3% del /f /q "!_cabdir!\acl.txt"
goto :eof

:chkEC
set _ec=0
cmd /c exit /b %1
set "_ic=%=ExitCode%"
if /i not "!_ic!"=="00000000" if /i not "!_ic!"=="800f081e" if /i not "!_ic!"=="800706be" if /i not "!_ic!"=="800706ba" if /i not "!_ic!"=="000006be" if /i not "!_ic!"=="000006ba" set _ec=1
if /i not "!_ic!"=="00000000" if /i not "!_ic!"=="800f081e" if !_ec!==0 %_dism1% %dismtarget% /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Null%
goto :eof

:errmount
set mounterr=1
set "msgerr=Dism.exe operation failed"
call :dk_color1 %Red% "%msgerr%. Discarding . . ." 4
if defined idpkg set "msgerr=Dism.exe failed adding %idpkg% update{s}"
(echo.&echo %msgerr%)>>"!logerr!"
call :dismount 1
goto :eof
rmdir /s /q "%_mount%\" %_Nul3%
set AddUpdates=0
set FullExit=exit
goto :%_rtrn%

:regBase
if not exist "%mumtarget%\Windows\Servicing\Packages\Package_for_RollupFix*.mum" goto :eof
if exist "!_cabdir!\W10UI*.*" del /f /q "!_cabdir!\W10UI*.*" %_Nul3%
call :hiveON
set "_k_=HKEY_LOCAL_MACHINE\%SOFTWARE%\%_CBS%"
set "_p_=HKLM:\%SOFTWARE%\%_CBS%"

reg.exe query "%_k_%" /s /v Baseline | findstr /i HKEY_LOCAL_MACHINE | findstr /i /v Package_for_RollupFix >>"!_cabdir!\W10UIbaseline.txt"
type nul>"!_cabdir!\W10UIsimilar.txt"
if exist "!_cabdir!\W10UIbaseline.txt" for /f "usebackq tokens=8 delims=\." %%G in ("!_cabdir!\W10UIbaseline.txt") do (
findstr /i "%%G" "!_cabdir!\W10UIsimilar.txt" %_Null% || reg.exe query "%_k_%" /k /f "%%G" %_Nul2% | findstr /i HKEY_LOCAL_MACHINE >>"!_cabdir!\W10UIsimilar.txt"
)
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" for %%G in (Microsoft-Windows-WinPE-LanguagePack-Package~ Microsoft-Windows-WinPE-Package~) do (
findstr /i "%%G" "!_cabdir!\W10UIsimilar.txt" %_Null% || reg.exe query "%_k_%" /k /f "%%G" %_Nul2% | findstr /i HKEY_LOCAL_MACHINE >>"!_cabdir!\W10UIsimilar.txt"
)
findstr /i HKEY_LOCAL_MACHINE "!_cabdir!\W10UIsimilar.txt" %_Null% && for %%# in (%basekbn%) do (
for /f "usebackq tokens=8 delims=\" %%G in ("!_cabdir!\W10UIsimilar.txt") do reg.exe query "%_k_%\%%G" /v InstallLocation %_Nul2% | findstr /i %%# %_Nul1% && echo %%G >>"!_cabdir!\W10UImatched.txt"
)
if exist "!_cabdir!\W10UImatched.txt" for /f "usebackq tokens=1 delims= " %%G in ("!_cabdir!\W10UImatched.txt") do (
(echo New-ItemProperty '%_p_%\%%G' Baseline -Value 1 -Force -EA 0)>>"!_cabdir!\W10UIreg.txt"
)
for %%# in (%basepkg%) do (
(echo New-ItemProperty '%_p_%\%%#' Baseline -Value 1 -Force -EA 0)>>"!_cabdir!\W10UIreg.txt"
)
pushd "!_cabdir!"
if not exist "tiTkn.txt" copy /y "!_work!\bin\tiTkn.txt" . %_Nul3%
%_Nul3% %_psc% "Set-Location -LiteralPath '!_cabdir!'; $r='!_cabdir!\W10UIreg.txt'; $f=[IO.File]::ReadAllText('.\tiTkn.txt') -split ':cbsreg\:.*';iex ($f[1])"
popd

call :hiveOFF
goto :eof

:sbsconfig
if exist "!_cabdir!\W10UI*.*" del /f /q "!_cabdir!\W10UI*.*" %_Nul3%
call :hiveON
set "_p_=HKLM:\%SOFTWARE%\%_SxsCfg%"
if %1 neq 9 if %_build% geq 26052 (echo Remove-ItemProperty 'HKLM:\%SOFTWARE%\Microsoft\Windows\CurrentVersion\SideBySide' 'DecompressOverride' -Force -EA 0)>>"!_cabdir!\W10UIreg.txt"
if %1 neq 9 (echo New-ItemProperty '%_p_%' SupersededActions -Value %1 -Force -EA 0)>>"!_cabdir!\W10UIreg.txt"
if %2 neq 9 (echo New-ItemProperty '%_p_%' DisableResetbase -Value %2 -Force -EA 0)>>"!_cabdir!\W10UIreg.txt"
if %3 neq 9 (echo New-ItemProperty '%_p_%' DisableComponentBackups -Value %3 -Force -EA 0)>>"!_cabdir!\W10UIreg.txt"
pushd "!_cabdir!"
if not exist "tiTkn.txt" copy /y "!_work!\bin\tiTkn.txt" . %_Nul3%
%_Nul3% %_psc% "Set-Location -LiteralPath '!_cabdir!'; $r='!_cabdir!\W10UIreg.txt'; $f=[IO.File]::ReadAllText('.\tiTkn.txt') -split ':cbsreg\:.*';iex ($f[1])"
popd
call :hiveOFF
goto :eof

:hiveON
reg.exe load HKLM\%SOFTWARE% "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
goto :eof

:hiveOFF
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
reg.exe unload HKLM\%SOFTWARE% %_Nul1%
goto :eof
)
if /i %xOS%==x86 if /i not %arch%==x86 reg.exe save HKLM\%SOFTWARE% "%mumtarget%\Windows\System32\Config\SOFTWARE2" /y %_Nul1%
reg.exe unload HKLM\%SOFTWARE% %_Nul1%
if /i %xOS%==x86 if /i not %arch%==x86 move /y "%mumtarget%\Windows\System32\Config\SOFTWARE2" "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
goto :eof

:wds_add
if %_build% geq 29550 if %winbuild% lss 20348 if /i not %xOS%==x86 (
if /i %arch%==%xOS% copy /y %SysPath%\wdscore.dll "%_mount%\Windows\System32\downlevel\" %_Nul1%
if /i %arch%==x64 if /i %xOS%==amd64 copy /y %SysPath%\wdscore.dll "%_mount%\Windows\System32\downlevel\" %_Nul1%
if exist "%SystemRoot%\SysWOW64\wdscore.dll" if exist "%_mount%\Windows\SysWOW64\downlevel\*.dll" copy /y %SystemRoot%\SysWOW64\wdscore.dll "%_mount%\Windows\SysWOW64\downlevel\" %_Nul1%
)
exit /b

:wds_rem
if exist "%_mount%\Windows\System32\downlevel\wdscore.dll" del /f /q "%_mount%\Windows\System32\downlevel\wdscore.dll" %_Nul3%
if exist "%_mount%\Windows\SysWOW64\downlevel\wdscore.dll" del /f /q "%_mount%\Windows\SysWOW64\downlevel\wdscore.dll" %_Nul3%
exit /b

:ReLCU
if exist "!lcudir!\update.mum" if exist "!lcudir!\*.manifest" goto :eof
if not exist "!lcudir!\" mkdir "!lcudir!"
expand.exe -f:* "!_UUP!\%lcupkg%" "!lcudir!" %_Null%
7z.exe e "!_UUP!\%lcupkg%" -o"!lcudir!" update.mum -aoa %_Null%
if exist "!lcudir!\*cablist.ini" (
  expand.exe -f:* "!lcudir!\*.cab" "!lcudir!" %_Null%
  del /f /q "!lcudir!\*cablist.ini" %_Nul3%
  del /f /q "!lcudir!\*.cab" %_Nul3%
)
set _sbst=0
for /f "tokens=2 delims=-" %%V in ('echo %lcupkg%') do set lcuid=%%V
if exist "!lcudir!\*.psf.cix.xml" (
if not exist "!lcudir!\express.psf.cix.xml" for /f %%# in ('dir /b /a:-d "!lcudir!\*.psf.cix.xml"') do rename "!lcudir!\%%#" express.psf.cix.xml %_Nul3%
subst %_sdr% "!_cabdir!" %_Nul3% && set _sbst=1
if !_sbst! equ 1 pushd %_sdr%
if not exist "%lcupkg%" (
copy /y "!_UUP!\%lcupkg:~0,-4%.*" . %_Nul3%
if not exist "%lcupkg:~0,-4%.psf" for /f %%# in ('dir /b /a:-d "!_UUP!\*%lcuid%*%arch%*.psf"') do copy /y "!_UUP!\%%#" %lcupkg:~0,-4%.psf %_Nul3%
)
if not exist "PSFExtractor.exe" copy /y "!_work!\bin\PSFExtractor.*" . %_Nul3%
PSFExtractor.exe %lcupkg% %_Null%
if !_sbst! equ 1 popd
if !_sbst! equ 1 subst %_sdr% /d %_Nul3%
)
goto :eof

:procmum
if exist "!dest!\*.psf.cix.xml" if not defined psf_%pckn% if not defined psfx_%pckn% goto :eof
if exist "!dest!\*defender*.xml" (
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
call :defender_check
goto :eof
)
if not exist "!dest!\update.mum" (
if /i "!lcupkg!"=="%package%" call :ReLCU
)
set _dcu=0
if not exist "!dest!\update.mum" (
for %%# in (%directcab%) do if /i "%package%"=="%%~#" set _dcu=1
if "!_dcu!"=="0" goto :eof
)
set xmsu=0
set xwim=0
if /i "%packx%"==".msu" set xmsu=1
if /i "%packx%"==".wim" if %psfwim% equ 1 set xwim=1
for /f "tokens=2 delims=-" %%V in ('echo %pckn%') do set pckid=%%V
set "uupmsu="
if %xmsu% equ 0 if %xwim% equ 0 if %_build% geq 21382 if exist "!_UUP!\*Windows1*%pckid%*%arch%*.msu" for /f "tokens=* delims=" %%# in ('dir /b /on "!_UUP!\*Windows1*%pckid%*%arch%*.msu"') do (
set "uupmsu=%%#"
)
if defined uupmsu (
expand.exe -d -f:*Windows*.psf "!_UUP!\%uupmsu%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% && goto :eof
wimlib-imagex.exe dir "!_UUP!\%uupmsu%" %_Nul2% | findstr /i %arch%\.psf %_Nul3% && goto :eof
)
if %_build% geq 20348 if exist "!dest!\update.mum" if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (findstr /i /m "Microsoft-Windows-NetFx" "!dest!\package_1_for*.mum" %_Nul3% && (
  if exist "!dest!\*_microsoft-windows-n..35wpfcomp.resources*.manifest" (set "netupdt=!netupdt! /PackagePath:!dest!\update.mum"&goto :eof)
  ))
)
if %_build% geq 17763 if exist "!dest!\update.mum" if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (findstr /i /m "Microsoft-Windows-NetFx" "!dest!\*.mum" %_Nul3% && call :rollnet)
findstr /i /m "Package_for_OasisAsset" "!dest!\update.mum" %_Nul3% && (if not exist "%mumtarget%\Windows\Servicing\packages\*OasisAssets-Package*.mum" goto :eof)
findstr /i /m "WinPE" "!dest!\update.mum" %_Nul3% && (
  %_Nul3% findstr /i /m "Edition\"" "!dest!\update.mum"
  if errorlevel 1 goto :eof
  )
)
if %_build% geq 19041 if exist "!dest!\update.mum" if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
findstr /i /m "Package_for_WindowsExperienceFeaturePack" "!dest!\update.mum" %_Nul3% && (
  if not exist "%mumtarget%\Windows\Servicing\packages\Microsoft-Windows-UserExperience-Desktop*.mum" goto :eof
  set fxupd=0
  for /f "tokens=3 delims== " %%# in ('findstr /i "Edition" "!dest!\update.mum" %_Nul6%') do if exist "%mumtarget%\Windows\Servicing\packages\%%~#*.mum" set fxupd=1
  if "!fxupd!"=="0" goto :eof
  )
)
if exist "!dest!\*_microsoft-windows-servicingstack_*.manifest" (
if /i "%package%"=="%s_pkg%" set "servicingstack=/PackagePath:!dest!\update.mum"
if not defined s_pkg set "servicingstack=!servicingstack! /PackagePath:!dest!\update.mum"
goto :eof
)
if exist "!dest!\*_netfx4-netfx_detectionkeys_extended*.manifest" findstr /i /m "Package_for_DotNetRollup" "!dest!\update.mum" %_Nul3% || (
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
set "netpack=!netpack! /PackagePath:!dest!\update.mum"
goto :eof
)
if exist "!dest!\*_%_EdgCmp%_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
if exist "!dest!\*enablement-package*.mum" if %SkipEdge% neq 1 (
  for /f %%# in ('dir /b /a:-d "!dest!\*enablement-package~*.mum"') do set "ldr=!ldr! /PackagePath:!dest!\%%#"
  set "edge=!edge! /PackagePath:!dest!\update.mum"
  )
if exist "!dest!\*enablement-package*.mum" if %SkipEdge% equ 1 (set "fupdt=!fupdt! %package%")
if not exist "!dest!\*enablement-package*.mum" set "edge=!edge! /PackagePath:!dest!\update.mum"
goto :eof
)
if exist "!dest!\update.mum" findstr /i /m "Package_for_SafeOSDU" "!dest!\update.mum" %_Nul3% && (
if not exist "%mumtarget%\Windows\Servicing\Packages\WinPE-Rejuv-Package~*.mum" goto :eof
set "safeos=!safeos! /PackagePath:!dest!\update.mum"
goto :eof
)
if exist "!dest!\*_microsoft-windows-sysreset_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (
if not exist "%mumtarget%\Windows\Servicing\Packages\WinPE-SRT-Package~*.mum" goto :eof
set "safeos=!safeos! /PackagePath:!dest!\update.mum"
goto :eof
)
if exist "!dest!\*_microsoft-windows-winpe_tools_*.manifest" if not exist "!dest!\*_microsoft-windows-sysreset_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (
if not exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
set "safeos=!safeos! /PackagePath:!dest!\update.mum"
goto :eof
)
if exist "!dest!\*_microsoft-windows-winre-tools_*.manifest" if not exist "!dest!\*_microsoft-windows-sysreset_*.manifest" if not exist "!dest!\*_microsoft-windows-winpe_tools_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (
if not exist "%mumtarget%\Windows\Servicing\Packages\WinPE-SRT-Package~*.mum" goto :eof
set "safeos=!safeos! /PackagePath:!dest!\update.mum"
goto :eof
)
if exist "!dest!\*_microsoft-windows-i..dsetup-rejuvenation_*.manifest" if not exist "!dest!\*_microsoft-windows-sysreset_*.manifest" if not exist "!dest!\*_microsoft-windows-winpe_tools_*.manifest" if not exist "!dest!\*_microsoft-windows-winre-tools_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (
if not exist "%mumtarget%\Windows\Servicing\Packages\WinPE-Rejuv-Package~*.mum" goto :eof
set "safeos=!safeos! /PackagePath:!dest!\update.mum"
goto :eof
)
if exist "!dest!\*_microsoft-windows-s..boot-firmwareupdate_*.manifest" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
if %winbuild% lss 9600 goto :eof
set "secureboot=!secureboot! /PackagePath:"!_UUP!\%package%""
goto :eof
)
if exist "!dest!\update.mum" if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
findstr /i /m "WinPE" "!dest!\update.mum" %_Nul3% || (findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (goto :eof))
findstr /i /m "WinPE-NetFx-Package" "!dest!\update.mum" %_Nul3% && (findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (goto :eof))
)
if exist "!dest!\*_adobe-flash-for-windows_*.manifest" if not exist "!dest!\*enablement-package*.mum" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% || (
if not exist "%mumtarget%\Windows\Servicing\packages\Adobe-Flash-For-Windows-Package*.mum" if not exist "%mumtarget%\Windows\Servicing\packages\Microsoft-Windows-Client-Desktop-Required-Package*.mum" goto :eof
if %_build% geq 16299 (
  set flash=0
  for /f "tokens=3 delims== " %%# in ('findstr /i "Edition" "!dest!\update.mum" %_Nul6%') do if exist "%mumtarget%\Windows\Servicing\packages\%%~#*.mum" set flash=1
  if "!flash!"=="0" goto :eof
  )
)
if exist "!dest!\*enablement-package*.mum" (
set epkb=0
for /f "tokens=3 delims== " %%# in ('findstr /i "Edition" "!dest!\update.mum" %_Nul6%') do if exist "%mumtarget%\Windows\Servicing\packages\%%~#*.mum" set epkb=1
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" findstr /i /m "WinPE" "!dest!\update.mum" %_Nul3% && set epkb=1
if "!epkb!"=="0" goto :eof
set "ekbpack=!ekbpack! /PackagePath:!dest!\update.mum"
goto :eof
)
for %%# in (%directcab%) do (
if /i "%package%"=="%%~#" (
  set "cumulative=!cumulative! "!_UUP!\%package%""
  goto :eof
  )
)
if exist "!dest!\update.mum" findstr /i /m "Package_for_RollupFix" "!dest!\update.mum" %_Nul3% && (
goto :proclcu
)
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
set "ldr=!ldr! /PackagePath:!dest!\update.mum"
goto :eof
)
if exist "!dest!\*_%_CedCmp%_*.manifest" if %SkipEdge% equ 1 if not exist "%mumtarget%\Windows\WinSxS\Manifests\%_CedCom%.manifest" (set "cupdt=!cupdt! %package%"&goto :eof)
if exist "!dest!\*_%_CedCmp%_*.manifest" if %SkipEdge% equ 2 call :deEdge
set "ldr=!ldr! /PackagePath:!dest!\update.mum"
goto :eof

:rollnet
set rollnet=0
findstr /i /m "Package_for_DotNetRollup" "!dest!\update.mum" %_Nul3% && set rollnet=1
if not exist "!dest!\*_microsoft-windows-servicingstack_*.manifest" if not exist "!dest!\*_netfx4clientcorecomp.resources*.manifest" if not exist "!dest!\*_netfx4-netfx_detectionkeys_extended*.manifest" if not exist "!dest!\*_microsoft-windows-n..35wpfcomp.resources*.manifest" (
if exist "!dest!\*_*10.0.*.manifest" set rollnet=1
if exist "!dest!\*_*11.0.*.manifest" set rollnet=1
)
if %rollnet% equ 1 set "netroll=!netroll! /PackagePath:!dest!\update.mum"
goto :eof

:proclcu
if %_build% geq 20231 if %_build% lss 26052 if %xmsu% equ 0 (
  set "lcudir=!dest!"
  set "lcupkg=%package%"
)
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
if %xmsu% equ 1 (
  call :setlcu
  goto :eof
  )
set "cumulative=!cumulative! !dest!\update.mum"
goto :eof
)
if %xmsu% equ 1 (
  call :setlcu
  goto :eof
)
set "netlcu=!netlcu! /PackagePath:!dest!\update.mum"
if exist "!dest!\*_%_CedCmp%_*.manifest" if %SkipEdge% equ 1 if not exist "%mumtarget%\Windows\WinSxS\Manifests\%_CedCom%.manifest" (set "cupdt=!cupdt! %package%"&goto :eof)
if exist "!dest!\*_%_CedCmp%_*.manifest" if %SkipEdge% equ 2 call :deEdge
set "cumulative=!cumulative! !dest!\update.mum"
goto :eof

:setlcu
if exist "!_cabdir!\LCUall\*.msu" (
if defined lcuall goto :eof
for /f "tokens=* delims=" %%# in ('dir /b /a:-d "!_cabdir!\LCUall\*.msu"') do set "lcumsu=!lcumsu! "!_cabdir!\LCUall\%%#""
set lcuall=1
) else (
set "lcumsu=!lcumsu! "!_UUP!\%package%""
)
set "netmsu=!lcumsu!"
goto :eof

:procrcu
for %%# in (%directcab%) do (
if /i "%package%"=="%%~#" (
  set "cumulative=!cumulative! "!_UUP!\%package%""
  goto :eof
  )
)
set "netlcu=!netlcu! /PackagePath:!dest!\update.mum"
set "cumulative=!cumulative! !dest!\update.mum"
goto :eof

:deEdge
  mkdir "%mumtarget%\Program Files\Microsoft\Edge\Application" %_Nul3%
  mkdir "%mumtarget%\Program Files\Microsoft\EdgeUpdate" %_Nul3%
  type nul>"%mumtarget%\Program Files\Microsoft\Edge\Edge.dat" 2>&1
  type nul>"%mumtarget%\Program Files\Microsoft\Edge\Edge.LCU.dat" 2>&1
  type nul>"%mumtarget%\Program Files\Microsoft\EdgeUpdate\EdgeUpdate.dat" 2>&1
  if exist "%mumtarget%\Windows\SysWOW64\*.dll" (
    mkdir "%mumtarget%\Program Files (x86)\Microsoft\Edge\Application" %_Nul3%
    mkdir "%mumtarget%\Program Files (x86)\Microsoft\EdgeUpdate" %_Nul3%
    type nul>"%mumtarget%\Program Files (x86)\Microsoft\Edge\Edge.dat" 2>&1
    type nul>"%mumtarget%\Program Files (x86)\Microsoft\Edge\Edge.LCU.dat" 2>&1
    type nul>"%mumtarget%\Program Files (x86)\Microsoft\EdgeUpdate\EdgeUpdate.dat" 2>&1
    )
goto :eof

:defender_check
goto :eof

:defender_update
echo.
goto :eof

:pXML
if %_build% neq 18362 (
call :cXML stage
echo.
echo Processing 1 of 1 - Staging %cbsn%
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\%_DsmLog%" /Apply-Unattend:"!_cabdir!\stage.xml"
if !errorlevel! neq 0 if !errorlevel! neq 3010 (
  (echo.&echo Failed staging %cbsn%)>>"!logerr!"
  goto :eof
  )
)
if %_build% neq 18362 (call :Winner) else (call :Suppress)
if defined _dualSxS (
set "_SxsKey=%_CedKey%"
set "_SxsCmp=%_CedCmp%"
set "_SxsIdn=%_CedIdn%"
set "_SxsCF=256"
if %_build% neq 18362 (call :Winner) else (call :Suppress)
)
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\%_DsmLog%" /Add-Package /PackagePath:"!dest!\update.mum"
if !errorlevel! neq 0 (
  (echo.&echo Failed installing %cbsn%)>>"!logerr!"
  )
if %_build% neq 18362 (del /f /q "!_cabdir!\stage.xml" %_Nul3%)
goto :eof

:cXML
(
echo.^<?xml version="1.0" encoding="utf-8"?^>
echo.^<unattend xmlns="urn:schemas-microsoft-com:unattend"^>
echo.    ^<servicing^>
echo.        ^<package action="%1"^>
)>"!_cabdir!\%1.xml"
findstr /i Package_for_RollupFix "!dest!\update.mum" %_Nul3% && (
findstr /i Package_for_RollupFix "!dest!\update.mum" >>"!_cabdir!\%1.xml"
)
findstr /i Package_for_RollupFix "!dest!\update.mum" %_Nul3% || (
findstr /i Package_for_KB "!dest!\update.mum" | findstr /i /v _RTM >>"!_cabdir!\%1.xml"
)
(
echo.            ^<source location="!dest!\update.mum" /^>
echo.        ^</package^>
echo.     ^</servicing^>
echo.^</unattend^>
)>>"!_cabdir!\%1.xml"
goto :eof

:Latent
set "_InCom=!%1Com!"
set "_InKey=!%1Key!"
set "_InIdn=!%1Idn!"
if not exist "!_CabDir!\" mkdir "!_CabDir!"
if not exist "!_CabDir!\%_InCom%.manifest" (
(echo ^<?xml version="1.0" encoding="UTF-8" standalone="yes"?^>
echo ^<assembly xmlns="urn:schemas-microsoft-com:asm.v3" manifestVersion="1.0" copyright="Copyright (c) Microsoft Corporation. All Rights Reserved."^>
echo   ^<assemblyIdentity name="%_InIdn%" version="%_OurVer%" processorArchitecture="%xBT%" language="neutral" buildType="release" publicKeyToken="%_Pkt%" versionScope="nonSxS" /^>
echo ^</assembly^>)>"!_CabDir!\%_InCom%.manifest"
)
set "_InIdt="
set "_psin=%_InIdn%, Culture=neutral, Version=%_OurVer%, PublicKeyToken=%_Pkt%, ProcessorArchitecture=%xBT%, versionScope=NonSxS"
for /f "tokens=* delims=" %%# in ('%_psc% "[BitConverter]::ToString([Text.Encoding]::ASCII.GetBytes($env:_psin)) -replace '-'"') do set "_InIdt=%%#"
if not defined _InIdt exit /b
set "_InHsh="
for /f "tokens=* delims=" %%# in ('%_psc% "[BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash(([IO.StreamReader]'!_CabDir!\%_InCom%.manifest').BaseStream)) -replace '-'"') do set "_InHsh=%%#"
if not defined _InHsh exit /b
icacls "%mumtarget%\Windows\WinSxS\Manifests" /save "!_CabDir!\acl.txt"
takeown /f "%mumtarget%\Windows\WinSxS\Manifests" /A
icacls "%mumtarget%\Windows\WinSxS\Manifests" /grant:r "*S-1-5-32-544:(OI)(CI)(F)"
copy /y "!_CabDir!\%_InCom%.manifest" "%mumtarget%\Windows\WinSxS\Manifests\"
icacls "%mumtarget%\Windows\WinSxS\Manifests" /setowner *S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464
icacls "%mumtarget%\Windows\WinSxS" /restore "!_CabDir!\acl.txt"
del /f /q "!_CabDir!\acl.txt"
reg.exe load HKLM\%SOFTWARE% "%mumtarget%\Windows\System32\Config\SOFTWARE"
reg.exe query HKLM\%COMPONENTS% %_Null% || reg.exe load HKLM\%COMPONENTS% "%mumtarget%\Windows\System32\Config\COMPONENTS"
reg.exe delete "%_Cmp%\%_InCom%" /f %_Null%
reg.exe add "%_Cmp%\%_InCom%" /f /v "c^!%_Fnd%" /t REG_BINARY /d ""
reg.exe add "%_Cmp%\%_InCom%" /f /v identity /t REG_BINARY /d "%_InIdt%"
reg.exe add "%_Cmp%\%_InCom%" /f /v S256H /t REG_BINARY /d "%_InHsh%"
reg.exe add "%_Cmp%\%_InCom%" /f /v CF /t REG_DWORD /d "64"
reg.exe add "%_InKey%" /f /ve /d %_OurVer:~0,5%
reg.exe add "%_InKey%\%_OurVer:~0,5%" /f /ve /d %_OurVer%
reg.exe add "%_InKey%\%_OurVer:~0,5%" /f /v %_OurVer% /t REG_BINARY /d 01
for /f "tokens=* delims=" %%# in ('reg.exe query HKLM\%COMPONENTS%\DerivedData\VersionedIndex %_Nul6% ^| findstr /i VersionedIndex') do reg.exe delete "%%#" /f
goto :EndChk

:Suppress
for /f %%# in ('dir /b /a:-d "!dest!\%xBT%_%_SxsCmp%_*.manifest"') do set "_SxsCom=%%~n#"
for /f "tokens=4 delims=_" %%# in ('echo %_SxsCom%') do set "_SxsVer=%%#"
if not exist "%mumtarget%\Windows\WinSxS\Manifests\%_SxsCom%.manifest" (
%_Nul3% icacls "%mumtarget%\Windows\WinSxS\Manifests" /save "!_cabdir!\acl.txt"
%_Nul3% takeown /f "%mumtarget%\Windows\WinSxS\Manifests" /A
%_Nul3% icacls "%mumtarget%\Windows\WinSxS\Manifests" /grant:r "*S-1-5-32-544:(OI)(CI)(F)"
%_Nul3% copy /y "!dest!\%_SxsCom%.manifest" "%mumtarget%\Windows\WinSxS\Manifests\"
%_Nul3% icacls "%mumtarget%\Windows\WinSxS\Manifests" /setowner *S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464
%_Nul3% icacls "%mumtarget%\Windows\WinSxS" /restore "!_cabdir!\acl.txt"
%_Nul3% del /f /q "!_cabdir!\acl.txt"
)
reg.exe query HKLM\%COMPONENTS% %_Null% || reg.exe load HKLM\%COMPONENTS% "%mumtarget%\Windows\System32\Config\COMPONENTS" %_Nul3%
reg.exe query "%_Cmp%\%_SxsCom%" %_Nul3% && goto :Winner
for /f "skip=1 tokens=* delims=" %%# in ('certutil -hashfile "!dest!\%_SxsCom%.manifest" SHA256^|findstr /i /v CertUtil') do set "_SxsSha=%%#"
set "_SxsSha=%_SxsSha: =%"
set "_psin=%_SxsIdn%, Culture=neutral, Version=%_SxsVer%, PublicKeyToken=%_Pkt%, ProcessorArchitecture=%xBT%, versionScope=NonSxS"
for /f "tokens=* delims=" %%# in ('%_psc% "$str = '%_psin%'; [BitConverter]::ToString([Text.Encoding]::ASCII.GetBytes($str)) -replace '-'" %_Nul6%') do set "_SxsHsh=%%#"
%_Nul3% reg.exe add "%_Cmp%\%_SxsCom%" /f /v "c^!%_Fnd%" /t REG_BINARY /d ""
%_Nul3% reg.exe add "%_Cmp%\%_SxsCom%" /f /v identity /t REG_BINARY /d "%_SxsHsh%"
%_Nul3% reg.exe add "%_Cmp%\%_SxsCom%" /f /v S256H /t REG_BINARY /d "%_SxsSha%"
%_Nul3% reg.exe add "%_Cmp%\%_SxsCom%" /f /v CF /t REG_DWORD /d "%_SxsCF%"
for /f "tokens=* delims=" %%# in ('reg.exe query HKLM\%COMPONENTS%\DerivedData\VersionedIndex %_Nul6% ^| findstr /i VersionedIndex') do reg.exe delete "%%#" /f %_Nul3%

:Winner
for /f "tokens=4 delims=_" %%# in ('dir /b /a:-d "!dest!\%xBT%_%_SxsCmp%_*.manifest"') do (
set "pv_al=%%#"
)
for /f "tokens=1-4 delims=." %%G in ('echo %pv_al%') do (
set "pv_os=%%G.%%H"
set "pv_mj=%%G"&set "pv_mn=%%H"&set "pv_bl=%%I"&set "pv_dl=%%J"
)
set kv_al=
reg.exe load HKLM\%SOFTWARE% "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul3%
if not exist "%mumtarget%\Windows\WinSxS\Manifests\%xBT%_%_SxsCmp%_*.manifest" goto :SkipChk
reg.exe query "%_SxsKey%" %_Nul3% || goto :SkipChk
reg.exe query HKLM\%COMPONENTS% %_Null% || reg.exe load HKLM\%COMPONENTS% "%mumtarget%\Windows\System32\Config\COMPONENTS" %_Nul3%
reg.exe query "%_Cmp%" /f "%xBT%_%_SxsCmp%_*" /k %_Nul2% | find /i "HKEY_LOCAL_MACHINE" %_Nul1% || goto :SkipChk
call :ChkESUver %_Nul3%
set "wv_bl=0"&set "wv_dl=0"
reg.exe query "%_SxsKey%\%pv_os%" /ve %_Nul2% | findstr \( | findstr \. %_Nul1% || goto :SkipChk
for /f "tokens=2*" %%a in ('reg.exe query "%_SxsKey%\%pv_os%" /ve ^| findstr \(') do set "wv_al=%%b"
for /f "tokens=1-4 delims=." %%G in ('echo %wv_al%') do (
set "wv_mj=%%G"&set "wv_mn=%%H"&set "wv_bl=%%I"&set "wv_dl=%%J"
)

:SkipChk
reg.exe add "%_SxsKey%\%pv_os%" /f /v %pv_al% /t REG_BINARY /d 01 %_Nul3%
set skip_pv=0
if "%kv_al%"=="" (
reg.exe add "%_SxsKey%\%pv_os%" /f /ve /d %pv_al% %_Nul3%
reg.exe add "%_SxsKey%" /f /ve /d %pv_os% %_Nul3%
goto :EndChk
)
if %pv_mj% lss %kv_mj% (
set skip_pv=1
if %pv_bl% geq %wv_bl% if %pv_dl% geq %wv_dl% reg.exe add "%_SxsKey%\%pv_os%" /f /ve /d %pv_al% %_Nul3%
)
if %pv_mj% equ %kv_mj% if %pv_mn% lss %kv_mn% (
set skip_pv=1
if %pv_bl% geq %wv_bl% if %pv_dl% geq %wv_dl% reg.exe add "%_SxsKey%\%pv_os%" /f /ve /d %pv_al% %_Nul3%
)
if %pv_mj% equ %kv_mj% if %pv_mn% equ %kv_mn% if %pv_bl% lss %kv_bl% (
set skip_pv=1
)
if %pv_mj% equ %kv_mj% if %pv_mn% equ %kv_mn% if %pv_bl% equ %kv_bl% if %pv_dl% lss %kv_dl% (
set skip_pv=1
)
if %skip_pv% equ 0 (
reg.exe add "%_SxsKey%\%pv_os%" /f /ve /d %pv_al% %_Nul3%
reg.exe add "%_SxsKey%" /f /ve /d %pv_os% %_Nul3%
)

:EndChk
if /i %xOS%==x86 if /i not %arch%==x86 (
  reg.exe save HKLM\%SOFTWARE% "%mumtarget%\Windows\System32\Config\SOFTWARE2" %_Nul1%
  reg.exe query HKLM\%COMPONENTS% %_Null% && reg.exe save HKLM\%COMPONENTS% "%mumtarget%\Windows\System32\Config\COMPONENTS2" %_Nul1%
)
reg.exe unload HKLM\%SOFTWARE% %_Nul3%
reg.exe unload HKLM\%COMPONENTS% %_Nul3%
if /i %xOS%==x86 if /i not %arch%==x86 (
  move /y "%mumtarget%\Windows\System32\Config\SOFTWARE2" "%mumtarget%\Windows\System32\Config\SOFTWARE" %_Nul1%
  if exist "%mumtarget%\Windows\System32\Config\COMPONENTS2" move /y "%mumtarget%\Windows\System32\Config\COMPONENTS2" "%mumtarget%\Windows\System32\Config\COMPONENTS" %_Nul1%
)
goto :eof

:ChkESUver
set kv_os=
reg.exe query "%_SxsKey%" /ve | findstr \( | findstr \. || goto :eof
for /f "tokens=2*" %%a in ('reg.exe query "%_SxsKey%" /ve ^| findstr \(') do set "kv_os=%%b"
if "%kv_os%"=="" goto :eof
set kv_al=
reg.exe query "%_SxsKey%\%kv_os%" /ve | findstr \( | findstr \. || goto :eof
for /f "tokens=2*" %%a in ('reg.exe query "%_SxsKey%\%kv_os%" /ve ^| findstr \(') do set "kv_al=%%b"
if "%kv_al%"=="" goto :eof
reg.exe query "%_Cmp%" /f "%xBT%_%_SxsCmp%_%_Pkt%_%kv_al%_*" /k %_Nul2% | find /i "%kv_al%" %_Nul1% || (
set kv_al=
goto :eof
)
for /f "tokens=1-4 delims=." %%G in ('echo %kv_al%') do (
set "kv_mj=%%G"&set "kv_mn=%%H"&set "kv_bl=%%I"&set "kv_dl=%%J"
)
goto :eof

:updt_mount
if not exist "!_cabdir!\" mkdir "!_cabdir!"
if exist "%_mount%\" rmdir /s /q "%_mount%\"
if not exist "%_mount%\" mkdir "%_mount%"
set _www=%~1
set _nnn=%~nx1
set isappx=
set isappx=%2
if defined isappx (
set _eosC=0
set _eosP=0
set _eosT=0
)
for %%# in (uProf,uProN,uSDC,uSDD,_upgr,handle1,handle2,WimRE) do set %%#=0
for %%# in (iCore,iCorN,iCorS,iCorC,iTeam,iEntr,iEntN,iSRSC,iSRSD,iHome,iHomN,iProf,iProN,iSSC,iSSD,iSDC,iSDD) do set "%%#="
if /i %_nnn%==winre.wim set WimRE=1
if %WimRE% equ 0 if %_build% geq 17063 if %imgcount% gtr 1 if %DisableUpdatingUpgrade% equ 0 set _upgr=1
for /L %%# in (1,1,%imgcount%) do imagex /info "%_www%" %%# >bin\info%%#.txt 2>&1
if %WimRE% equ 0 for /L %%# in (1,1,%imgcount%) do (
if not defined iHome if %_eosC% equ 0 (find /i "Core</EDITIONID>" bin\info%%#.txt %_Nul3% && set iHome=%%#)
if not defined iHomN if %_eosC% equ 0 (find /i "CoreN</EDITIONID>" bin\info%%#.txt %_Nul3% && set iHomN=%%#)
if not defined iProf if %_eosP% equ 0 (find /i "Professional</EDITIONID>" bin\info%%#.txt %_Nul3% && set iProf=%%#)
if not defined iProN if %_eosP% equ 0 (find /i "ProfessionalN</EDITIONID>" bin\info%%#.txt %_Nul3% && set iProN=%%#)
if not defined iSSC (find /i "ServerStandard</EDITIONID>" bin\info%%#.txt %_Nul3% && (findstr /i /c:"Server Core" bin\info%%#.txt %_Nul3% && set iSSC=%%#))
if not defined iSSD (find /i "ServerStandard</EDITIONID>" bin\info%%#.txt %_Nul3% && (findstr /i /c:"Server Core" bin\info%%#.txt %_Nul3% || set iSSD=%%#))
if not defined iSDC (find /i "ServerDatacenter</EDITIONID>" bin\info%%#.txt %_Nul3% && (findstr /i /c:"Server Core" bin\info%%#.txt %_Nul3% && set iSDC=%%#))
if not defined iSDD (find /i "ServerDatacenter</EDITIONID>" bin\info%%#.txt %_Nul3% && (findstr /i /c:"Server Core" bin\info%%#.txt %_Nul3% || set iSDD=%%#))
)
if %_upgr% equ 1 (
if defined iHome if defined iProf set uProf=1
if defined iHomN if defined iProN set uProN=1
if defined iSSC if defined iSDC set uSDC=1
if defined iSSD if defined iSDD set uSDD=1
)
del /f /q bin\info*.txt
rem editions deleted in reverse order
if %uSDD% equ 1 (
set /a imgcount-=1
wimlib-imagex.exe delete "%_www%" %iSDD% --soft %_Nul3%
)
if %uSDC% equ 1 (
set /a imgcount-=1
wimlib-imagex.exe delete "%_www%" %iSDC% --soft %_Nul3%
)
if %uProN% equ 1 (
if %_pmcppc% equ 1 if %_build% geq 19041 call :pmcppcpro %iProN%
set /a imgcount-=1
wimlib-imagex.exe delete "%_www%" %iProN% --soft %_Nul3%
)
if %uProf% equ 1 (
if %_pmcppc% equ 1 if %_build% geq 19041 call :pmcppcpro %iProf%
set /a imgcount-=1
wimlib-imagex.exe delete "%_www%" %iProf% --soft %_Nul3%
)
set _imgi=%imgcount%
for /L %%# in (1,1,%imgcount%) do imagex /info "%_www%" %%# >bin\info%%#.txt 2>&1
if %WimRE% equ 0 for /L %%# in (1,1,%imgcount%) do (
if not defined iCore (find /i "Core</EDITIONID>" bin\info%%#.txt %_Nul3% && set iCore=%%#)
if not defined iCorN (find /i "CoreN</EDITIONID>" bin\info%%#.txt %_Nul3% && set iCorN=%%#)
if not defined iCorS (find /i "CoreSingleLanguage</EDITIONID>" bin\info%%#.txt %_Nul3% && set iCorS=%%#)
if not defined iCorC (find /i "CoreCountrySpecific</EDITIONID>" bin\info%%#.txt %_Nul3% && set iCorC=%%#)
if not defined iEntr (find /i "Professional</EDITIONID>" bin\info%%#.txt %_Nul3% && set iEntr=%%#)
if not defined iEntN (find /i "ProfessionalN</EDITIONID>" bin\info%%#.txt %_Nul3% && set iEntN=%%#)
if not defined iTeam (find /i "PPIPro</EDITIONID>" bin\info%%#.txt %_Nul3% && set iTeam=%%#)
if not defined iSRSC (find /i "ServerStandard</EDITIONID>" bin\info%%#.txt %_Nul3% && (findstr /i /c:"Server Core" bin\info%%#.txt %_Nul3% && set iSRSC=%%#))
if not defined iSRSD (find /i "ServerStandard</EDITIONID>" bin\info%%#.txt %_Nul3% && (findstr /i /c:"Server Core" bin\info%%#.txt %_Nul3% || set iSRSD=%%#))
)
for %%# in (iCore,iCorN,iCorS,iCorC,iTeam,iEntr,iEntN,iSRSC,iSRSD,iHome,iHomN) do (
if not defined %%# set %%#=0
)
set "_wtx=Windows 10"
if %iCore% neq 0 (
find /i "<NAME>" bin\info%iCore%.txt %_Nul2% | find /i "Windows 11" %_Nul1% && (set "_wtx=Windows 11")
find /i "<NAME>" bin\info%iCore%.txt %_Nul2% | find /i "Windows 12" %_Nul1% && (set "_wtx=Windows 12")
)
if %iCorN% neq 0 (
find /i "<NAME>" bin\info%iCorN%.txt %_Nul2% | find /i "Windows 11" %_Nul1% && (set "_wtx=Windows 11")
find /i "<NAME>" bin\info%iCorN%.txt %_Nul2% | find /i "Windows 12" %_Nul1% && (set "_wtx=Windows 12")
)
set "_wsr=Windows Server 2022"
if %iSRSC% neq 0 (
find /i "<NAME>" bin\info%iSRSC%.txt %_Nul2% | find /i " 2025" %_Nul1% && (set "_wsr=Windows Server 2025")
if %_build% geq 26010 (set "_wsr=Windows Server 2025")
)
if %iSRSD% neq 0 (
find /i "<NAME>" bin\info%iSRSD%.txt %_Nul2% | find /i " 2025" %_Nul1% && (set "_wsr=Windows Server 2025")
if %_build% geq 26010 (set "_wsr=Windows Server 2025")
)
del /f /q bin\info*.txt
if %WimRE% equ 1 (
set "_inx=1"&call :dowork
goto :eof
)
set "indices="
set "indexes="
if defined isappx (
for /L %%# in (1,1,%imgcount%) do (
if defined indexes (set "indexes=!indexes!,%%#") else (set "indexes=%%#")
)
goto :appxdo
)
for /L %%# in (1,1,%imgcount%) do (
set _oa%%#=0
if %_eosT% equ 0 if %_eosP% equ 0 if %_eosC% equ 0 (if defined indices (set "indices=!indices!,%%#") else (set "indices=%%#"))
if %_eosT% equ 0 if %_eosP% equ 0 if %_eosC% equ 1 if %%# neq %iCore% if %%# neq %iCorN% if %%# neq %iCorS% if %%# neq %iCorC% (if defined indices (set "indices=!indices!,%%#") else (set "indices=%%#"))
if %_eosT% equ 0 if %_eosP% equ 1 if %_eosC% equ 1 if %%# neq %iEntr% if %%# neq %iEntN% if %%# neq %iCore% if %%# neq %iCorN% if %%# neq %iCorS% if %%# neq %iCorC% (if defined indices (set "indices=!indices!,%%#") else (set "indices=%%#"))
if %_eosT% equ 0 if %_eosP% equ 1 if %_eosC% equ 0 if %%# neq %iEntr% if %%# neq %iEntN% (if defined indices (set "indices=!indices!,%%#") else (set "indices=%%#"))
if %_eosT% equ 1 if %_eosP% equ 0 if %_eosC% equ 0 if %%# neq %iTeam% (if defined indices (set "indices=!indices!,%%#") else (set "indices=%%#"))
if %_eosT% equ 1 if %_eosP% equ 0 if %_eosC% equ 1 if %%# neq %iTeam% if %%# neq %iCore% if %%# neq %iCorN% if %%# neq %iCorS% if %%# neq %iCorC% (if defined indices (set "indices=!indices!,%%#") else (set "indices=%%#"))
if %_eosT% equ 1 if %_eosP% equ 1 if %_eosC% equ 0 if %%# neq %iTeam% if %%# neq %iEntr% if %%# neq %iEntN% (if defined indices (set "indices=!indices!,%%#") else (set "indices=%%#"))
if %_eosT% equ 1 if %_eosP% equ 1 if %_eosC% equ 1 if %%# neq %iTeam% if %%# neq %iEntr% if %%# neq %iEntN% if %%# neq %iCore% if %%# neq %iCorN% if %%# neq %iCorS% if %%# neq %iCorC% (if defined indices (set "indices=!indices!,%%#") else (set "indices=%%#"))
)
if %_runIPA% equ 1 for /L %%# in (1,1,%imgcount%) do (
if %_eosC% equ 1 if %%# equ %iCore% set _oa%%#=1
if %_eosC% equ 1 if %%# equ %iCorN% set _oa%%#=1
if %_eosC% equ 1 if %%# equ %iCorS% set _oa%%#=1
if %_eosC% equ 1 if %%# equ %iCorC% set _oa%%#=1
if %_eosP% equ 1 if %%# equ %iEntr% set _oa%%#=1
if %_eosP% equ 1 if %%# equ %iEntN% set _oa%%#=1
if %_eosT% equ 1 if %%# equ %iTeam% set _oa%%#=1
)
if %_runIPA% equ 1 if defined indices for %%# in (%indices%) do (
set _oa%%#=0
)
if %_runIPA% equ 1 for /L %%# in (1,1,%imgcount%) do (
if !_oa%%#! equ 1 (if defined indexes (set "indexes=!indexes!,%%#") else (set "indexes=%%#"))
)
set _inCmpt=0
if %_runIPA% equ 0 if not defined indices set _inCmpt=1
if %_runIPA% equ 1 if not defined indices if not defined indexes set _inCmpt=1
if %_inCmpt% equ 1 (
call :dk_color1 %_Yellow% "No compatible editions found with applicable updates." 4
goto :eof
)
if defined indices for %%# in (%indices%) do (set "_inx=%%#"&call :dowork)
:appxdo
set isappx=1
if defined indexes for %%# in (%indexes%) do (set "_inx=%%#"&call :dowork)
if %_extVirt% equ 0 goto :eof
if %DeleteSource% neq 1 goto :eof
call :dk_color1 %Blue% "=== Deleting Source Edition{s} . . ." 4 5
if %_didProf% equ 1 call :dDelete Professional
if %_didProN% equ 1 call :dDelete ProfessionalN
if %_didHome% equ 1 call :dDelete Core
for /f "tokens=3 delims=: " %%# in ('imagex /info "%_www%" ^|findstr /i /b /c:"Image Count"') do set finalimages=%%#
if %finalimages% gtr 1 goto :eof
for /f "tokens=3 delims=<>" %%# in ('imagex /info "%_www%" 1 ^| find /i "<EDITIONID>"') do set editionid=%%#
set AIO=0&set _count=0
call :virtlabel
goto :eof

:dowork
if %WimRE% equ 0 call :dk_color1 %Gray% "=== Servicing Index: %_inx%" 4
%_dism2%:"!_cabdir!" /Mount-Wim /Wimfile:"%_www%" /Index:%_inx% /MountDir:"%_mount%"
if !errorlevel! neq 0 (
call :dismount 1
goto :eof
)
call :wds_add
set _noApps=1
set _noSave=1
if %WimRE% equ 0 if %_wimEdge% equ 1 if %SkipEdge% equ 0 (
set _noSave=0
call :dk_color1 %Gray% "=== Adding Microsoft Edge . . ." 4
%_dism2%:"!_cabdir!" /Image:"%_mount%" /LogPath:"%_dLog%\DismEdgeWim.log" /Add-Edge /SupportPath:"!_UUP!"
if !errorlevel! neq 0 (
  (echo.&echo Failed adding Edge.wim)>>"!logerr!"
  )
)
if %WimRE% equ 0 if %_build% geq 19041 if %_upgr% equ 1 if %_pmcppc% equ 1 if not exist "%_mount%\Windows\Servicing\Packages\Microsoft-Windows-Printing-PMCPPC-FoD-Package*.mum" call :pmcppcwim
if defined isappx goto :doappx

if %_runDRV% equ 1 (
set mumtarget=%_mount%
set dismtarget=/Image:"%_mount%"
goto :doDrivers
)
if %WimRE% equ 1 goto :doupdt

:: === INCEPUT MODIFICARI AGRESIVE INSTALL.WIM ===
call :dk_color1 %Gray% "=== Eliminare HelpPane, OneDrive si Tweaks Registry OOBE/Defend . . ." 4

if exist "%_mount%\PerfLogs" (
    :: Preluarea proprietatii recursive
    takeown /f "%_mount%\PerfLogs" /r /d y %_Nul3%
    :: Acordarea permisiunilor depline (Full Control) grupului de administratori
    icacls "%_mount%\PerfLogs" /grant administrators:F /t %_Nul3%
    :: Stergerea fizica a directorului si a continutului
    rmdir /s /q "%_mount%\PerfLogs" %_Nul3%
)

if exist "%_mount%\Program Files\Windows Defender" (
    :: Preluarea proprietatii recursive
    takeown /f "%_mount%\Program Files\Windows Defender" /r /d y %_Nul3%
    :: Acordarea permisiunilor depline (Full Control) grupului de administratori
    icacls "%_mount%\Program Files\Windows Defender" /grant administrators:F /t %_Nul3%
    :: Stergerea fizica a directorului si a continutului
    rmdir /s /q "%_mount%\Program Files\Windows Defender" %_Nul3%
    
    :: Recreem imediat un folder Backup complet gol
    mkdir "%_mount%\Program Files\Windows Defender" %_Nul3%
)

if exist "%_mount%\Program Files\Windows Defender Advanced Threat Protection" (
    :: Preluarea proprietatii recursive
    takeown /f "%_mount%\Program Files\Windows Defender Advanced Threat Protection" /r /d y %_Nul3%
    :: Acordarea permisiunilor depline (Full Control) grupului de administratori
    icacls "%_mount%\Program Files\Windows Defender Advanced Threat Protection" /grant administrators:F /t %_Nul3%
    :: Stergerea fizica a directorului si a continutului
    rmdir /s /q "%_mount%\Program Files\Windows Defender Advanced Threat Protection" %_Nul3%
    
    :: Recreem imediat un folder Backup complet gol
    mkdir "%_mount%\Program Files\Windows Defender Advanced Threat Protection" %_Nul3%
)

:: 3. Modificari in structura de Registry a imaginii offline (SOFTWARE)
reg load HKLM\OfflineSOFTWARE "%_mount%\Windows\System32\config\SOFTWARE" %_Nul3%
if errorlevel 1 (
    call :dk_color1 %_Yellow% "[EROARE] Nu s-a putut incarca stupul SOFTWARE!"
) else (
    :: Tweak pentru BypassNRO (Bypass Network Requirement)
    reg add HKLM\OfflineSOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f %_Nul3%
    
    :: Configurare TargetReleaseVersion si Editiile TargetInfo
    reg add HKLM\OfflineSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v TargetReleaseVersion /t REG_DWORD /d 1 /f %_Nul3%
    reg add HKLM\OfflineSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate /v TargetReleaseVersionInfo /t REG_SZ /d 25H1 /f %_Nul3%

    :: Dezactivare ecrane de confidentialitate OOBE (Privacy Settings)
    reg add HKLM\OfflineSOFTWARE\Policies\Microsoft\Windows\OOBE /v DisablePrivacyExperience /t REG_DWORD /d 1 /f %_Nul3%
    reg add HKLM\OfflineSOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v ProtectYourPC /t REG_DWORD /d 3 /f %_Nul3%
    
    reg unload HKLM\OfflineSOFTWARE %_Nul3%
)

:: 3.5 Modificari in structura de Registry pentru utilizatorul implicit (NTUSER.DAT)
reg load HKLM\OfflineDEFAULT "%_mount%\Users\Default\NTUSER.DAT" %_Nul3%
if errorlevel 1 (
    call :dk_color1 %_Yellow% "[EROARE] Nu s-a putut incarca stupul NTUSER.DAT implicit!"
) else (
    :: Eliminare notificari hardware neacceptat (UnsupportedHardwareNotificationCache)
    reg add "HKLM\OfflineDEFAULT\Control Panel\UnsupportedHardwareNotificationCache" /v SV1 /t REG_DWORD /d 0 /f %_Nul3%
    reg add "HKLM\OfflineDEFAULT\Control Panel\UnsupportedHardwareNotificationCache" /v SV2 /t REG_DWORD /d 0 /f %_Nul3%
    
    reg unload HKLM\OfflineDEFAULT %_Nul3%
)

:: 4. Modificari in structura de Registry a imaginii offline (SYSTEM) pentru eliminarea WinDefend
reg load HKLM\OfflineSYSTEM "%_mount%\Windows\System32\config\SYSTEM" %_Nul3%
if errorlevel 1 (
    call :dk_color1 %_Yellow% "[EROARE] Nu s-a putut incarca stupul SYSTEM!"
) else (
    :: Eliminarea fizica a serviciului Windows Defender din configuratia de boot ControlSet001
    reg delete HKLM\OfflineSYSTEM\ControlSet001\Services\WinDefend /f %_Nul3%
    reg delete HKLM\OfflineSYSTEM\ControlSet001\Services\whesvc /f %_Nul3%
    reg delete HKLM\OfflineSYSTEM\ControlSet001\Services\SecurityHealthService /f %_Nul3%
    reg delete HKLM\OfflineSYSTEM\ControlSet001\Services\wscsvc /f %_Nul3%
    reg delete HKLM\OfflineSYSTEM\ControlSet001\Services\MDCoreSvc /f %_Nul3%
    reg delete HKLM\OfflineSYSTEM\ControlSet001\Services\webthreatdefsvc /f %_Nul3%
    reg delete HKLM\OfflineSYSTEM\ControlSet001\Services\webthreatdefusersvc /f %_Nul3%
    reg delete HKLM\OfflineSYSTEM\ControlSet001\Services\WdFilter /f %_Nul3%
    reg delete HKLM\OfflineSYSTEM\ControlSet001\Services\WdNisDrv /f %_Nul3%
    reg delete HKLM\OfflineSYSTEM\ControlSet001\Services\WdNisSvc /f %_Nul3%
    reg delete HKLM\OfflineSYSTEM\ControlSet001\Services\Sense /f %_Nul3%
    reg unload HKLM\OfflineSYSTEM %_Nul3%
)
:: === SFARSIT MODIFICARI AGRESIVE INSTALL.WIM ===


if %_runIPA% equ 0 goto :doupdt
call :dk_color1 %Gray% "=== Adding Apps . . ." 4 5
call :appx_wim
if %_noApps% equ 0 (
%_dism2%:"!_cabdir!" /Commit-Wim /MountDir:"%_mount%"
)
call :dk_color1 %Gray% "=== Adding Updates . . ." 4

:doupdt
call :updatewim
if defined mounterr goto :eof
if %dvd% equ 0 goto :noextra
if %NetFx3% equ 1 call :enablenet35
if /i %arch%==x86 (set efifile=bootia32.efi) else if /i %arch%==x64 (set efifile=bootx64.efi) else (set efifile=bootaa64.efi)
if !handle1! equ 1 goto :skiphand1
set handle1=1
if %UpdtBootFiles% neq 1 goto :nonewboot
if exist "%_mount%\Windows\Boot\EFI\winsipolicy.p7b" if exist "%_target%\efi\microsoft\boot\winsipolicy.p7b" xcopy /CIDRY "%_mount%\Windows\Boot\EFI\winsipolicy.p7b" "%_target%\efi\microsoft\boot\" %_Nul3%
if exist "%_mount%\Windows\Boot\EFI\CIPolicies\" if exist "%_target%\efi\microsoft\boot\cipolicies\" xcopy /CEDRY "%_mount%\Windows\Boot\EFI\CIPolicies" "%_target%\efi\microsoft\boot\cipolicies\" %_Nul3%
xcopy /CIDRY "%_mount%\Windows\Boot\DVD\EFI\en-US\efisys.bin" "%_target%\efi\microsoft\boot\" %_Nul3%
xcopy /CIDRY "%_mount%\Windows\Boot\DVD\EFI\en-US\efisys_noprompt.bin" "%_target%\efi\microsoft\boot\" %_Nul3%
xcopy /CIDRY "%_mount%\Windows\Boot\EFI\boot.stl" "%_target%\efi\microsoft\boot\" %_Nul3%
if /i not %arch%==arm64 (
xcopy /CIDRY "%_mount%\Windows\Boot\PCAT\bootmgr" "%_target%\" %_Nul3%
xcopy /CIDRY "%_mount%\Windows\Boot\PCAT\memtest.exe" "%_target%\boot\" %_Nul3%
xcopy /CIDRY "%_mount%\Windows\Boot\EFI\memtest.efi" "%_target%\efi\microsoft\boot\" %_Nul3%
)
if not exist "%_mount%\Windows\Boot\EFI_EX\*_EX.efi" goto :nonewboot
if exist "%_target%\efi\boot\bootmgfw.efi" xcopy /CIDRY "%_mount%\Windows\Boot\EFI_EX\bootmgfw_EX.efi" "%_target%\efi\boot\bootmgfw.efi" %_Nul3%
xcopy /CIDRY "%_mount%\Windows\Boot\EFI_EX\bootmgfw_EX.efi" "%_target%\efi\boot\!efifile!" %_Nul3%
if exist "%_mount%\Windows\Boot\EFI_EX\bootmgr_EX.efi" (xcopy /CIDRY "%_mount%\Windows\Boot\EFI_EX\bootmgr_EX.efi" "%_target%\bootmgr.efi" %_Nul3%) else (xcopy /CIDRY "%_mount%\Windows\Boot\EFI\bootmgr.efi" "%_target%\" %_Nul3%)
xcopy /CIDRY "%_mount%\Windows\Boot\DVD_EX\EFI\en-US\efisys_EX.bin" "%_target%\efi\microsoft\boot\efisys.bin" %_Nul3%
xcopy /CIDRY "%_mount%\Windows\Boot\DVD_EX\EFI\en-US\efisys_noprompt_EX.bin" "%_target%\efi\microsoft\boot\efisys_noprompt.bin" %_Nul3%
xcopy /CIDRY "%_mount%\Windows\Boot\FONTS_EX\*" "%_target%\efi\microsoft\boot\fonts\" %_Nul3%
for /f "tokens=1-3 delims=_." %%i in ('dir /b "%_target%\efi\microsoft\boot\fonts\*_EX.ttf" %_Nul6%') do move /y "%_target%\efi\microsoft\boot\fonts\%%i_%%j_%%k.ttf" "%_target%\efi\microsoft\boot\fonts\%%i_%%j.ttf" %_Nul3%
goto :skiphand1
:nonewboot
if exist "%_target%\efi\boot\bootmgfw.efi" xcopy /CIDRY "%_mount%\Windows\Boot\EFI\bootmgfw.efi" "%_target%\efi\boot\bootmgfw.efi" %_Nul3%
xcopy /CIDRY "%_mount%\Windows\Boot\EFI\bootmgfw.efi" "%_target%\efi\boot\!efifile!" %_Nul3%
xcopy /CIDRY "%_mount%\Windows\Boot\EFI\bootmgr.efi" "%_target%\" %_Nul3%
xcopy /CIDRY "%_mount%\Windows\Boot\EFI\boot.stl" "%_target%\efi\microsoft\boot\" %_Nul3%
:skiphand1
if !handle2! equ 0 if not exist "%_mount%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" if exist "%_mount%\Windows\Servicing\Packages\Package_for_RollupFix*.mum" (
set handle2=1
set isomin=0
for /f "tokens=%tok% delims=_." %%i in ('dir /b /a:-d /od "%_mount%\Windows\WinSxS\Manifests\%_ss%_microsoft-windows-coreos-revision*.manifest"') do (set isover=%%i.%%j&set isomaj=%%i&set isomin=%%j)
set "isokey=Microsoft\Windows NT\CurrentVersion\Update\TargetingInfo\Installed"
for /f %%i in ('"offlinereg.exe "%_mount%\Windows\system32\config\SOFTWARE" "!isokey!" enumkeys %_Nul6% ^| findstr /i /r "Client\.OS Server\.OS WNC\.OS WCOSDevice""') do if not errorlevel 1 (
  for /f "tokens=3 delims==:" %%A in ('"offlinereg.exe "%_mount%\Windows\system32\config\SOFTWARE" "!isokey!\%%i" getvalue Branch %_Nul6%"') do set "isobranch=%%~A"
  for /f "tokens=5,6 delims==:." %%A in ('"offlinereg.exe "%_mount%\Windows\system32\config\SOFTWARE" "!isokey!\%%i" getvalue Version %_Nul6%"') do if %%A gtr !isomaj! (
    set "isover=%%~A.%%B
    set isomaj=%%~A
    set "isomin=%%B
    set "_fixSV=!isomaj!"&set "_fixEP=!isomaj!"
    )
  )
)
:noextra
if exist "%_mount%\Windows\system32\UpdateAgent.dll" if not exist "%SystemRoot%\temp\UpdateAgent.dll" copy /y "%_mount%\Windows\system32\UpdateAgent.dll" %SystemRoot%\temp\ %_Nul1%
if exist "%_mount%\Windows\system32\Facilitator.dll" if not exist "%SystemRoot%\temp\Facilitator.dll" copy /y "%_mount%\Windows\system32\Facilitator.dll" %SystemRoot%\temp\ %_Nul1%
if exist "%_mount%\Windows\system32\ServicingCommon.dll" if not exist "%SystemRoot%\temp\ServicingCommon.dll" copy /y "%_mount%\Windows\system32\ServicingCommon.dll" %SystemRoot%\temp\ %_Nul1%
set _noSave=0
goto :doDrivers

:doappx
call :dk_color1 %Gray% "=== Adding Apps . . ." 4 5
call :appx_wim

:doDrivers
if not defined DrvOpt goto :doCommit
set _noSave=0
if %WimRE% equ 1 (
if %cmtRE% equ 1 goto :doCommit
if defined DrvSrcALL %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DrvWinPE.log" /Add-Driver /Driver:"!DrvSrcALL!" /Recurse
if defined DrvSrcPE %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DrvWinPE.log" /Add-Driver /Driver:"!DrvSrcPE!" /Recurse
goto :doCommit
)
if not defined OSDrv goto :doCommit
call :dk_color1 %Gray% "=== Adding Drivers . . ." 4
if defined DrvSrcALL %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DrvOS.log" /Add-Driver /Driver:"!DrvSrcALL!" /Recurse
if defined DrvSrcOS %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DrvOS.log" /Add-Driver /Driver:"!DrvSrcOS!" /Recurse

:doCommit
if %_noSave% equ 1 goto :noCommit
call :wds_rem
%_dism2%:"!_cabdir!" /Commit-Wim /MountDir:"%_mount%"
if !errorlevel! neq 0 (
call :dismount 1
)
call :wds_add
:noCommit
if %WimRE% equ 1 goto :crDsc

:crHome
if %_inx% neq %iHome% goto :crProf
if %StartVirtual% equ 0 goto :crProf
set _didHome=1&call :V_Ext Home

:crProf
if %uProf% equ 0 goto :crProN
if %_inx% neq %iHome% goto :crProN
call :dk_color1 %Gray% "=== Creating Edition: Pro" 4
%_dism2%:"!_cabdir!" /Image:"%_mount%" /LogPath:"%_dLog%\DismCore2Pro.log" /Set-Edition:Professional /Channel:Retail
call :wds_rem
%_dism2%:"!_cabdir!" /Commit-Image /MountDir:"%_mount%" /Append %_Supp%
call :wds_add
call set /a _imgi+=1
call set ddesc="%_wtx% Pro"
wimlib-imagex.exe info "%_www%" !_imgi! !ddesc! !ddesc! --image-property DISPLAYNAME=!ddesc! --image-property DISPLAYDESCRIPTION=!ddesc! --image-property FLAGS=Professional %_Nul3%
if %StartVirtual% equ 0 goto :crProN
set _didProf=1&call :V_Ext Prof

:crProN
if %uProN% equ 0 goto :crSDC
if %_inx% neq %iHomN% goto :crSDC
call :dk_color1 %Gray% "=== Creating Edition: Pro N" 4
%_dism2%:"!_cabdir!" /Image:"%_mount%" /LogPath:"%_dLog%\DismCoreN2ProN.log" /Set-Edition:ProfessionalN /Channel:Retail
call :wds_rem
%_dism2%:"!_cabdir!" /Commit-Image /MountDir:"%_mount%" /Append %_Supp%
call :wds_add
call set /a _imgi+=1
call set ddesc="%_wtx% Pro N"
wimlib-imagex.exe info "%_www%" !_imgi! !ddesc! !ddesc! --image-property DISPLAYNAME=!ddesc! --image-property DISPLAYDESCRIPTION=!ddesc! --image-property FLAGS=ProfessionalN %_Nul3%
if %StartVirtual% equ 0 goto :crSDC
set _didProN=1&call :V_Ext ProN

:crSDC
if %uSDC% equ 0 goto :crSDD
if %_inx% neq %iSSC% goto :crSDD
call :dk_color1 %Gray% "=== Creating Edition: Datacenter Core" 4
%_dism2%:"!_cabdir!" /Image:"%_mount%" /LogPath:"%_dLog%\DismSrvSc2SrvDc.log" /Set-Edition:ServerDatacenterCor /Channel:Retail
call :wds_rem
%_dism2%:"!_cabdir!" /Commit-Image /MountDir:"%_mount%" /Append %_Supp%
call :wds_add
call set /a _imgi+=1
call set cname="%_wsr% ServerDatacenterCore"
call set dname="%_wsr% Datacenter"
call set ddesc="(Recommended) This option omits most of the Windows graphical environment. Manage with a command prompt and PowerShell, or remotely with Windows Admin Center or other tools."
wimlib-imagex.exe info "%_www%" !_imgi! !cname! !cname! --image-property DISPLAYNAME=!dname! --image-property DISPLAYDESCRIPTION=!ddesc! --image-property FLAGS=ServerDatacenterCore %_Nul3%

:crSDD
if %uSDD% equ 0 goto :crEnd
if %_inx% neq %iSSD% goto :crEnd
call :dk_color1 %Gray% "=== Creating Edition: Datacenter" 4
%_dism2%:"!_cabdir!" /Image:"%_mount%" /LogPath:"%_dLog%\DismSrvSf2SrvDf.log" /Set-Edition:ServerDatacenter /Channel:Retail
call :wds_rem
%_dism2%:"!_cabdir!" /Commit-Image /MountDir:"%_mount%" /Append %_Supp%
call :wds_add
call set /a _imgi+=1
call set cname="%_wsr% ServerDatacenter"
call set dname="%_wsr% Datacenter (Desktop Experience)"
call set ddesc="This option installs the full Windows graphical environment, consuming extra drive space. It can be useful if you want to use the Windows desktop or have an app that requires it."
wimlib-imagex.exe info "%_www%" !_imgi! !cname! !cname! --image-property DISPLAYNAME=!dname! --image-property DISPLAYDESCRIPTION=!ddesc! --image-property FLAGS=ServerDatacenter %_Nul3%

:crEnd
if %_SrvESD% equ 1 goto :crDsc
if %StartVirtual% equ 0 goto :crDsc
if %uProf% equ 0 if %_inx% equ %iEntr% (set _didProf=1&call :V_Ext Prof)
if %uProN% equ 0 if %_inx% equ %iEntN% (set _didProN=1&call :V_Ext ProN)

:crDsc
%_dism2%:"!_cabdir!" /Unmount-Wim /MountDir:"%_mount%" /Discard
goto :eof

:pmcppcpro
if exist "bin\temp\pmcppc\Microsoft-Windows-Printing-PMCPPC-FoD-Package*.mum" goto :eof
mkdir bin\temp\pmcppc %_Nul3%
for /f %%# in ('dir /b /a:-d "!_UUP!\*Microsoft-Windows-Printing-PMCPPC-FoD-Package*.*"') do (
if /i "%%~x#"==".cab" (expand.exe -f:* "!_UUP!\%%#" bin\temp\pmcppc\ %_Nul3%) else (wimlib-imagex.exe apply "!_UUP!\%%#" 1 bin\temp\pmcppc\ --no-acls --no-attributes %_Nul3%)
)
7z.exe e "%_www%" -o.\bin\temp\pmcppc %1\Windows\servicing\Packages\Microsoft-Windows-Printing-PMCPPC-FoD-Package~%_Pkt%~*~%langid%~*.* %1\Windows\WinSxS\Manifests\*_microsoft-windows-p..oyment-languagepack_*.manifest %1\Windows\WinSxS\Manifests\*_microsoft-windows-p..ui-pmcppc.resources_*.manifest -aoa %_Nul3%
for /f %%# in ('dir /b /a:-d "bin\temp\pmcppc\*_microsoft-windows-p..ui-pmcppc.resources_*.manifest"') do (
7z.exe e "%_www%" -o.\bin\temp\pmcppc\%%~n# %1\Windows\WinSxS\%%~n#\* -aoa %_Nul3%
)
mkdir bin\temp\sxs %_Nul3%
for /f %%a in ('dir /b /a:-d "bin\temp\pmcppc\*.manifest"') do SxSExpand.exe "!_work!\bin\temp\pmcppc\%%a" "bin\temp\sxs\%%a" %_Nul3%
if exist "bin\temp\sxs\*.manifest" move /y "bin\temp\sxs\*" "bin\temp\pmcppc\" %_Nul1%
rmdir /s /q bin\temp\sxs\
goto :eof

:pmcppcwim
set _noSave=0
for /f %%# in ('dir /b /a:-d "bin\temp\pmcppc\Microsoft-Windows-Printing-PMCPPC-FoD-Package~%_Pkt%~*~~*.mum" %_Nul6%') do (
%_dism2%:"!_cabdir!" /Image:"%_mount%" /LogPath:"%_dLog%\PMCPPC_FoD.log" /Add-Package /PackagePath:"bin\temp\pmcppc\%%#" %_Nul3%
if !errorlevel! neq 0 (
  (echo.&echo Failed installing %%~n#)>>"!logerr!"
  )
)
for /f %%# in ('dir /b /a:-d "bin\temp\pmcppc\Microsoft-Windows-Printing-PMCPPC-FoD-Package~%_Pkt%~*~%langid%~*.mum" %_Nul6%') do (
%_dism2%:"!_cabdir!" /Image:"%_mount%" /LogPath:"%_dLog%\PMCPPC_FoD.log" /Add-Package /PackagePath:"bin\temp\pmcppc\%%#" %_Nul3%
if !errorlevel! neq 0 (
  (echo.&echo Failed installing %%~n#)>>"!logerr!"
  )
)
goto :eof

:dDelete
for /f "tokens=3 delims=: " %%# in ('imagex /info "%_www%" ^|findstr /i /b /c:"Image Count"') do set vimages=%%#
for /l %%# in (1,1,%vimages%) do imagex /info "%_www%" %%# >bin\info%%#.txt 2>&1
for /L %%# in (1,1,%vimages%) do (
find /i "<EDITIONID>%1</EDITIONID>" bin\info%%#.txt %_Nul3% && (
  echo %1
  wimlib-imagex.exe delete "%_www%" %%# --soft %_Nul3%
  )
)
del /f /q bin\info*.txt %_Nul3%
goto :eof

:doSort
set simages=%finalimages%
for /l %%# in (1,1,%simages%) do imagex /info ISOFOLDER\sources\%WimFile% %%# >bin\info%%#.txt 2>&1
set tcount=0
for %%A in (%SortEditions%) do (
for /L %%# in (1,1,%simages%) do (
  find /i "<EDITIONID>%%A</EDITIONID>" bin\info%%#.txt %_Nul3% && (
    set /a tcount+=1
    echo !tcount!. %%A
    wimlib-imagex.exe export ISOFOLDER\sources\%WimFile% %%# ISOFOLDER\sources\temp.wim %_Supp%
    )
  )
)
del /f /q bin\info*.txt %_Nul3%
if exist ISOFOLDER\sources\temp.wim (
del /f /q ISOFOLDER\sources\%WimFile%
ren ISOFOLDER\sources\temp.wim %WimFile%
set didsort=1
)
goto :eof

:dismount
set "_Nul8=1>nul 2>nul"
if /i not "%~1"=="" set "_Nul8="
%_dism1% /Image:"%_mount%" /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Null%
%_dism1% /Unmount-Wim /MountDir:"%_mount%" /Discard %_Nul8%
%_dism1% /Cleanup-Wim %_Null%
goto :eof

:cleanup
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" (
call :sbsconfig %savr% 9 1
%_wrb% %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismCleanup_pe.log" /Cleanup-Image /StartComponentCleanup
if %Cleanup% neq 0 (
if %ResetBase% neq 0 %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismCleanup_pe.log" /Cleanup-Image /StartComponentCleanup /ResetBase %_Null%
)
call :cleanmanual&goto :eof
)
if %Cleanup% equ 0 call :cleanmanual&goto :eof
if exist "%mumtarget%\Windows\WinSxS\pending.xml" call :cleanmanual&goto :eof
set "_Nul8="
if %_build% geq 25380 if %_build% lss 26000 (
set "_Nul8=1>nul 2>nul"
call :dk_color1 %Gray% "=== Running DISM Cleanup . . ." 4
)
if %ResetBase% equ 0 (
call :sbsconfig %savc% 1 9
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismCleanup.log" /Cleanup-Image /StartComponentCleanup %_Nul8%
goto :finclean
)
:rebase
call :sbsconfig %savr% %rbvr% 9
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismCleanup.log" /Cleanup-Image /StartComponentCleanup %_Nul8%
if %ResetBase% neq 0 %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismCleanup.log" /Cleanup-Image /StartComponentCleanup /ResetBase %_Null%
:finclean
call :cleanmanual
goto :eof

:cleanmanual
if exist "%mumtarget%\Windows\WinSxS\ManifestCache\*.bin" (
takeown /f "%mumtarget%\Windows\WinSxS\ManifestCache\*.bin" /A %_Nul3%
icacls "%mumtarget%\Windows\WinSxS\ManifestCache\*.bin" /grant *S-1-5-32-544:F %_Nul3%
del /f /q "%mumtarget%\Windows\WinSxS\ManifestCache\*.bin" %_Nul3%
)
if exist "%mumtarget%\Windows\WinSxS\Temp\PendingDeletes\*" (
takeown /f "%mumtarget%\Windows\WinSxS\Temp\PendingDeletes\*" /A %_Nul3%
icacls "%mumtarget%\Windows\WinSxS\Temp\PendingDeletes\*" /grant *S-1-5-32-544:F %_Nul3%
del /f /q "%mumtarget%\Windows\WinSxS\Temp\PendingDeletes\*" %_Nul3%
)
if exist "%mumtarget%\Windows\WinSxS\Temp\TransformerRollbackData\*" (
takeown /f "%mumtarget%\Windows\WinSxS\Temp\TransformerRollbackData\*" /R /A %_Nul3%
icacls "%mumtarget%\Windows\WinSxS\Temp\TransformerRollbackData\*" /grant *S-1-5-32-544:F /T %_Nul3%
del /s /f /q "%mumtarget%\Windows\WinSxS\Temp\TransformerRollbackData\*" %_Nul3%
)
if exist "%mumtarget%\Windows\inf\*.log" (
del /f /q "%mumtarget%\Windows\inf\*.log" %_Nul3%
)
for /f "tokens=* delims=" %%# in ('dir /b /ad "%mumtarget%\Windows\CbsTemp\" %_Nul6%') do rmdir /s /q "%mumtarget%\Windows\CbsTemp\%%#\" %_Nul3%
del /s /f /q "%mumtarget%\Windows\CbsTemp\*" %_Nul3%
for /f "tokens=* delims=" %%# in ('dir /b /ad "%mumtarget%\Windows\Temp\" %_Nul6%') do rmdir /s /q "%mumtarget%\Windows\Temp\%%#\" %_Nul3%
del /s /f /q "%mumtarget%\Windows\Temp\*" %_Nul3%
if exist "%mumtarget%\Windows\WinSxS\pending.xml" goto :eof
for /f "tokens=* delims=" %%# in ('dir /b /ad "%mumtarget%\Windows\WinSxS\Temp\InFlight\" %_Nul6%') do (
takeown /f "%mumtarget%\Windows\WinSxS\Temp\InFlight\%%#" /A %_Null%
icacls "%mumtarget%\Windows\WinSxS\Temp\InFlight\%%#" /grant:r "*S-1-5-32-544:(OI)(CI)(F)" %_Null%
rmdir /s /q "%mumtarget%\Windows\WinSxS\Temp\InFlight\%%#\" %_Nul3%
)
if exist "%mumtarget%\Windows\WinSxS\Temp\PendingRenames\*" (
takeown /f "%mumtarget%\Windows\WinSxS\Temp\PendingRenames\*" /A %_Nul3%
icacls "%mumtarget%\Windows\WinSxS\Temp\PendingRenames\*" /grant *S-1-5-32-544:F %_Nul3%
del /f /q "%mumtarget%\Windows\WinSxS\Temp\PendingRenames\*" %_Nul3%
)
goto :eof

:enablenet35
if exist "%mumtarget%\Windows\Servicing\Packages\*WinPE-LanguagePack*.mum" goto :eof
if exist "%mumtarget%\Windows\Microsoft.NET\Framework\v2.0.50727\ngen.exe" goto :eof
if not exist "%_target%\sources\sxs\*NetFx3*.cab" goto :eof
set "net35source=%_target%\sources\sxs"
call :dk_color1 %_Yellow% "=== Processing NetFx3 feature" 4
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNetFx3.log" /Enable-Feature /FeatureName:NetFx3 /All /LimitAccess /Source:"%net35source%"
if !errorlevel! neq 0 (
  (echo.&echo Failed enabling NetFx3 feature)>>"!logerr!"
  )
if defined netupdt (
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNetFx3.log" /Add-Package %netupdt%
if !errorlevel! neq 0 (
  (echo.&echo Failed installing NetFx3 update)>>"!logerr!"
  )
)
if not defined netroll if not defined netlcu if not defined netmsu if not defined cumulative (
call :cleanmanual
goto :eof
)
if not defined netupdt if %_build% geq 20231 dir /b /ad "%mumtarget%\Windows\Servicing\LCU\Package_for_RollupFix*" %_Nul3% && (
call :cleanmanual
goto :eof
)
set ERRTEMP=0
set netxtr=
if defined netroll set "netxtr=%netroll%"
if defined netlcu set "netxtr=%netxtr% %netlcu%"
if defined netmsu if defined netxtr (
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNetFx3.log" /Add-Package %netxtr%
)
if defined netmsu for %%# in (%netmsu%) do (
echo.&echo Reinstalling %%~nx#
set ppath=%%#
if exist "!_cabdir!\LCUbase\%%~nx#" set ppath="!_cabdir!\LCUbase\%%~nx#"
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNetFx3.log" /Add-Package /PackagePath:!ppath!
call set ERRTEMP=!ERRORLEVEL!
)
if not defined netmsu if defined netlcu (
%_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNetFx3.log" /Add-Package %netroll% %netlcu%
call set ERRTEMP=!ERRORLEVEL!
)
if not defined netmsu if not defined netlcu (
if defined netroll %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNetFx3.log" /Add-Package %netroll%
if defined cumulative for %%# in (%cumulative%) do %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismNetFx3.log" /Add-Package /PackagePath:%%#
call set ERRTEMP=!ERRORLEVEL!
)
if !ERRTEMP! neq 0 (
  (echo.&echo Failed reinstalling cumulative update{s})>>"!logerr!"
  )
if defined lcupkg call :ReLCU
call :cleanmanual
goto :eof

:setuphostprep
copy /y ISOFOLDER\sources\setuphost.exe %SystemRoot%\temp\ %_Nul1%
copy /y ISOFOLDER\sources\setupprep.exe %SystemRoot%\temp\ %_Nul1%
set _svr1=0&set _svr2=0&set _svr3=0&set _svr4=0
set "_fvr1=%SystemRoot%\temp\UpdateAgent.dll"
set "_fvr2=%SystemRoot%\temp\setuphost.exe"
set "_fvr3=%SystemRoot%\temp\setupprep.exe"
set "_fvr4=%SystemRoot%\temp\Facilitator.dll"
set "cfvr1=!_fvr1:\=\\!"
set "cfvr2=!_fvr2:\=\\!"
set "cfvr3=!_fvr3:\=\\!"
set "cfvr4=!_fvr4:\=\\!"
if %_cwmi% equ 1 (
if exist "!_fvr1!" for /f "tokens=5 delims==." %%a in ('wmic datafile where "name='!cfvr1!'" get Version /value ^| find "="') do set /a "_svr1=%%a"
if exist "!_fvr2!" for /f "tokens=5 delims==." %%a in ('wmic datafile where "name='!cfvr2!'" get Version /value ^| find "="') do set /a "_svr2=%%a"
if exist "!_fvr3!" for /f "tokens=5 delims==." %%a in ('wmic datafile where "name='!cfvr3!'" get Version /value ^| find "="') do set /a "_svr3=%%a"
if exist "!_fvr4!" for /f "tokens=5 delims==." %%a in ('wmic datafile where "name='!cfvr4!'" get Version /value ^| find "="') do set /a "_svr4=%%a"
)
if %_cwmi% equ 0 (
if exist "!_fvr1!" for /f "tokens=4 delims=." %%a in ('%_psc% "([WMI]'CIM_DataFile.Name=''!cfvr1!''').Version"') do set /a "_svr1=%%a"
if exist "!_fvr2!" for /f "tokens=4 delims=." %%a in ('%_psc% "([WMI]'CIM_DataFile.Name=''!cfvr2!''').Version"') do set /a "_svr2=%%a"
if exist "!_fvr3!" for /f "tokens=4 delims=." %%a in ('%_psc% "([WMI]'CIM_DataFile.Name=''!cfvr3!''').Version"') do set /a "_svr3=%%a"
if exist "!_fvr4!" for /f "tokens=4 delims=." %%a in ('%_psc% "([WMI]'CIM_DataFile.Name=''!cfvr4!''').Version"') do set /a "_svr4=%%a"
)
set "_chk=!_fvr1!"
if %chkmin% equ %_svr1% set "_chk=!_fvr1!"&goto :prephostsetup
if %chkmin% equ %_svr2% set "_chk=!_fvr2!"&goto :prephostsetup
if %chkmin% equ %_svr3% set "_chk=!_fvr3!"&goto :prephostsetup
if %chkmin% equ %_svr4% set "_chk=!_fvr4!"&goto :prephostsetup
if %_svr2% gtr %_svr1% (
if %_svr2% gtr %_svr3% if %_svr2% gtr %_svr4% set "_chk=!_fvr2!"
if %_svr3% gtr %_svr2% if %_svr3% gtr %_svr4% set "_chk=!_fvr3!"
if %_svr4% gtr %_svr2% if %_svr4% gtr %_svr3% set "_chk=!_fvr4!"
)
if %_svr3% gtr %_svr1% (
if %_svr2% gtr %_svr3% if %_svr2% gtr %_svr4% set "_chk=!_fvr2!"
if %_svr3% gtr %_svr2% if %_svr3% gtr %_svr4% set "_chk=!_fvr3!"
if %_svr4% gtr %_svr2% if %_svr4% gtr %_svr3% set "_chk=!_fvr4!"
)
if %_svr4% gtr %_svr1% (
if %_svr2% gtr %_svr3% if %_svr2% gtr %_svr4% set "_chk=!_fvr2!"
if %_svr3% gtr %_svr2% if %_svr3% gtr %_svr4% set "_chk=!_fvr3!"
if %_svr4% gtr %_svr2% if %_svr4% gtr %_svr3% set "_chk=!_fvr4!"
)

:prephostsetup
7z.exe l "%_chk%" >.\bin\version.txt 2>&1
del /f /q "!_fvr1!" "!_fvr2!" "!_fvr3!" "!_fvr4!" %_Nul3%
exit /b

:appx_sort
call :dk_color1 %Blue% "=== Parsing Apps CompDB . . ." 4
if %_pwsh% equ 0 (
echo.
echo Windows PowerShell is not detected, skip operation.
set _IPA=0
goto :eof
)
pushd "!_UUP!"
if exist "_tmpMD\" rmdir /s /q "_tmpMD\" %_Nul3%
mkdir "_tmpMD"
if exist "*LanguageExperiencePack*.*x*" (
echo.
for /f "delims=" %%# in ('dir /b /a:-d "*LanguageExperiencePack*.*x*"') do call :lxp_sort "%%#"
)
for /f "delims=" %%# in ('dir /b /a:-d "*.AggregatedMetadata*.cab"') do (
expand.exe -f:*TargetCompDB_* "%%#" _tmpMD %_Null%
)
expand.exe -r -f:*.xml "_tmpMD\*.cab" _tmpMD %_Null%
if not exist "_tmpMD\*TargetCompDB_App_*.xml" (
echo.
echo CompDB_App.xml file is missing, skip operation.
rmdir /s /q "_tmpMD\" %_Nul3%
popd
set _IPA=0
goto :eof
)
type nul>AppsList.xml
>>AppsList.xml echo ^<Apps^>
>>AppsList.xml echo ^<Client^>
for %%# in (Core,CoreCountrySpecific,CoreSingleLanguage,Professional,ProfessionalEducation,ProfessionalWorkstation,Education,Enterprise,EnterpriseG,EnterpriseS,ServerRdsh,IoTEnterprise,IoTEnterpriseK,IoTEnterpriseS,IoTEnterpriseSK,CloudEdition,CloudEditionL) do if exist _tmpMD\*CompDB_%%#_*.xml (
>>AppsList.xml (find /i "PreinstalledApps" _tmpMD\*CompDB_%%#_*.xml | find /v "-")
)
for /f "delims=" %%# in ('dir /b /a:-d "_tmpMD\*TargetCompDB_App_Moment_*.xml" %_Nul6%') do (
>>AppsList.xml (find /i "PreinstalledApps" _tmpMD\%%# | find /i "Optional")
)
>>AppsList.xml echo ^</Client^>
>>AppsList.xml echo ^<CoreN^>
for %%# in (CoreN,ProfessionalN,ProfessionalEducationN,ProfessionalWorkstationN,EducationN,EnterpriseN,EnterpriseGN,EnterpriseSN,CloudEditionN,CloudEditionLN) do if exist _tmpMD\*CompDB_%%#_*.xml (
>>AppsList.xml (find /i "PreinstalledApps" _tmpMD\*CompDB_%%#_*.xml | find /v "-")
)
for /f "delims=" %%# in ('dir /b /a:-d "_tmpMD\*TargetCompDB_App_Moment_*.xml" %_Nul6%') do (
>>AppsList.xml (find /i "PreinstalledApps" _tmpMD\%%# | find /i "Optional")
)
>>AppsList.xml echo ^</CoreN^>
>>AppsList.xml echo ^<Team^>
for %%# in (PPIPro,WNC) do if exist _tmpMD\*CompDB_%%#_*.xml (
>>AppsList.xml (find /i "PreinstalledApps" _tmpMD\*CompDB_%%#_*.xml | find /v "-")
)
>>AppsList.xml echo ^</Team^>
>>AppsList.xml echo ^<ServerAzure^>
for %%# in (AzureStackHCICor) do if exist _tmpMD\*CompDB_Server%%#_*.xml (
>>AppsList.xml (find /i "PreinstalledApps" _tmpMD\*CompDB_Server%%#_*.xml | find /v "-")
)
>>AppsList.xml echo ^</ServerAzure^>
>>AppsList.xml echo ^<ServerCore^>
for %%# in (Standard,Datacenter,Turbine) do if exist _tmpMD\*CompDB_Server%%#Core_*.xml (
>>AppsList.xml (find /i "PreinstalledApps" _tmpMD\*CompDB_Server%%#Core_*.xml | find /v "-")
)
>>AppsList.xml echo ^</ServerCore^>
>>AppsList.xml echo ^<ServerFull^>
for %%# in (Standard,Datacenter,Turbine) do if exist _tmpMD\*CompDB_Server%%#_*.xml (
>>AppsList.xml (find /i "PreinstalledApps" _tmpMD\*CompDB_Server%%#_*.xml | find /v "-")
)
>>AppsList.xml echo ^</ServerFull^>
>>AppsList.xml echo ^</Apps^>
copy /y "!_work!\bin\CompDB_App.txt" . %_Nul3%
type nul>_AppsFilesList.csv
>>_AppsFilesList.csv echo File_Prefix;Target_Path
for /f "delims=" %%# in ('dir /b /a:-d "_tmpMD\*TargetCompDB_App_*.xml" %_Nul6%') do (
copy /y _tmpMD\%%# .\CompDB_App.xml %_Nul1%
%_Nul3% %_psc% "Set-Location -LiteralPath '!_UUP!'; $f=[IO.File]::ReadAllText('.\CompDB_App.txt') -split ':embed\:.*'; iex ($f[1])"
)
type nul>_AppsEditions.txt
%_Nul3% %_psc% "Set-Location -LiteralPath '!_UUP!'; $f=[IO.File]::ReadAllText('.\CompDB_App.txt') -split ':embed\:.*'; iex ($f[2])"
if exist "Apps\*_8wekyb3d8bbwe" move /y _AppsEditions.txt Apps\ %_Nul1%
del /f /q AppsList.xml CompDB_App.* %_Nul3%
rmdir /s /q "_tmpMD\" %_Nul3%
popd
goto :eof

:lxp_sort
del /f /q _tmpMD\AppxManifest.xml %_Null%
"!_work!\bin\7z.exe" e "%~1" -o.\_tmpMD AppxManifest.xml -aoa %_Nul3%
if not exist "_tmpMD\AppxManifest.xml" goto :eof
for /f %%G in ('%_psc% "([xml](Get-Content '_tmpMD\AppxManifest.xml')).Package.Identity.Name"') do set "_pfm=%%G_8wekyb3d8bbwe"
if exist "Apps\%_pfm%\License.xml" if exist "Apps\%_pfm%\*.*x*" goto :eof
for /f "tokens=2 delims=._" %%G in ('echo %_pfm%') do set "_lxp=%%G"
set "_lxp=%_lxp:LanguageExperiencePack=%"
echo Extra: LXP %_lxp%
"!_work!\bin\7z.exe" e "%~1" -o"Apps\%_pfm%" License.xml -aoa %_Nul3%
move /y "%~1" "Apps\%_pfm%\" %_Nul3%
del /f /q _tmpMD\AppxManifest.xml %_Null%
goto :eof

:appx_wim
set mumtarget=%_mount%
set dismtarget=/Image:"%_mount%"
set _edtn=
for /f "tokens=3 delims==:" %%# in ('"offlinereg.exe "%mumtarget%\Windows\System32\config\SOFTWARE" "Microsoft\Windows NT\CurrentVersion" getvalue EditionID" %_Nul6%') do set "_edtn=%%~#"
if not defined _edtn (
call :hiveON
for /f "skip=2 tokens=2*" %%a in ('reg.exe query "HKLM\%SOFTWARE%\Microsoft\Windows NT\CurrentVersion" /v EditionID') do set "_edtn=%%b"
call :hiveOFF
)
if exist "CustomAppsList2.txt" (set _appsFile=CustomAppsList2.txt) else (set _appsFile=CustomAppsList.txt)
if %_appsCustom% neq 0 for /f "eol=# tokens=*" %%a in ('type %_appsFile%') do set "cal_%%a=1"
set "_appProf=%_appBase%,%_appClnt%,%_appCodec%,%_appMedia%"
set "_appProN=%_appBase%,%_appClnt%"
set "_appTeam=%_appBase%,%_appCodec%,%_appPPIP%"
set "_appSFull=%_appSrvr%"
set "_appSCore="
set "_appAzure="
pushd "!_UUP!\Apps"
if exist "_AppsEditions.txt" (
for /f "tokens=* delims=" %%# in ('type _AppsEditions.txt') do set "%%#"
type _AppsEditions.txt | find "=" %_Nul3% || set "_appSFull="
)
if %_appsCustom% equ 0 if %AppsLevel% gtr 0 (
set "_appProf=%_appMin1%"
set "_appProN=%_appMin1%"
)
if %_appsCustom% equ 0 if %AppsLevel% gtr 1 (
set "_appProf=%_appProf%,%_appMin2%"
set "_appProN=%_appProN%,%_appMin2%"
)
if %_appsCustom% equ 0 if %AppsLevel% gtr 2 (
set "_appProf=%_appProf%,%_appMin3%"
set "_appProN=%_appProN%,%_appMin3%"
)
if %_appsCustom% equ 0 if %AppsLevel% gtr 3 (
set "_appProf=%_appProf%,%_appMin4%"
)
set "_appList="
for %%# in (Core,CoreCountrySpecific,CoreSingleLanguage,Professional,ProfessionalEducation,ProfessionalWorkstation,Education,Enterprise,EnterpriseG,EnterpriseS,ServerRdsh,IoTEnterprise,IoTEnterpriseK,IoTEnterpriseS,IoTEnterpriseSK,CloudEdition,CloudEditionL) do (
if /i "%_edtn%"=="%%#" set "_appList=%_appProf%"
)
for %%# in (CoreN,ProfessionalN,ProfessionalEducationN,ProfessionalWorkstationN,EducationN,EnterpriseN,EnterpriseGN,EnterpriseSN,CloudEditionN,CloudEditionLN) do (
if /i "%_edtn%"=="%%#" set "_appList=%_appProN%"
)
if /i "%_edtn%"=="PPIPro" set "_appList=%_appTeam%"
if /i "%_edtn%"=="WNC" set "_appList=%_appTeam%"
for %%# in (AzureStackHCICor) do (
if /i "%_edtn%"=="%%#" set "_appList=%_appAzure%"
)
for %%# in (ServerStandard,ServerDatacenter,ServerTurbine) do (
if /i "%_edtn%"=="%%#" (if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-Server*CorEdition~*.mum" (set "_appList=%_appSCore%") else (set "_appList=%_appSFull%"))
)
set _appWay=0
if %winbuild% geq 19040 set _appWay=1
if %_ADK% equ 1 (
if %apiver% geq 19040 (set _appWay=1) else (set _appWay=0)
)
if not exist "%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\ngen.exe" set _appWay=0
if %winbuild% LSS 9600 if not exist "%SystemRoot%\servicing\Packages\Microsoft-Windows-PowerShell-WTR-Package~*.mum" set _appWay=0
if not exist "!_work!\bin\APAP.*" set _appWay=0
set _addApps=1
set _fndApps=0
for /f %%# in ('dir /b /ad . %_Nul6% ^| findstr /i /v MSIXFramework') do (
if exist "%%#\*.appx*" set _fndApps=1
if exist "%%#\*.msix*" set _fndApps=1
)
if exist "%mumtarget%\Windows\Servicing\Packages\Microsoft-Windows-Server*Edition~*.mum" (
if "%_appList%"=="" set _addApps=0
if %_fndApps% equ 0 set _addApps=0
)
if exist "*LanguageExperiencePack*" set _addApps=1
if %_addApps% equ 0 goto :wimappx
set _noApps=0
set _noSave=0
del /f /q AppsToAdd.txt %_Null%
if exist "MSIXFramework\*" for /f "tokens=* delims=" %%# in ('dir /b /a:-d "MSIXFramework\*.*x"') do (
  if %_appWay% equ 0 (
  echo %%~n#
  %_Nul1% %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismAppx.log" /Add-ProvisionedAppxPackage /PackagePath:"MSIXFramework\%%#" /SkipLicense
  ) else (
  >>AppsToAdd.txt echo MSIXFramework\%%#
  )
)
if exist "*LanguageExperiencePack*" for /f "tokens=* delims=" %%# in ('dir /b /ad "*LanguageExperiencePack*"') do (
set "cal_%%#=1"
call :appx_add "%%#"
)
if defined _appList for %%# in (%_appList%) do call :appx_add "%%#"
if %_appWay% equ 0 goto :wimappx
if not exist "AppsToAdd.txt" goto :wimappx
copy /y "!_work!\bin\APAP.*" . %_Nul3%
copy /y "!_work!\bin\Microsoft.Dism.dll" . %_Nul3%
:: %_psc% "cd -Lit ($env:__CD__); $f=[IO.File]::ReadAllText('.\APAP.txt') -split ':embed\:.*'; iex ($f[1]); ATA '%_mount%' '%_dLog%\DismAppx.log' '!_cabdir!' %StubAppsFull%"
APAP.exe "%_mount%" "%_dLog%\DismAppx.log" "!_cabdir!" "%StubAppsFull%"
del /f /q AppsToAdd.txt APAP.* Microsoft.Dism.dll %_Nul3%
:wimappx
popd
if %_appsCustom% neq 0 for /f "eol=# tokens=*" %%a in ('type %_appsFile%') do set "cal_%%a="
if %_addApps% equ 1 %_dism1% /Image:"%_mount%" /LogPath:"%_dLog%\DismNUL.log" /Get-Packages %_Null%
goto :eof

:appx_add
set "_pfn=%~1"
if %_appsCustom% neq 0 if not defined cal_%_pfn% goto :eof
if not exist "%_pfn%\License.xml" goto :eof
if not exist "%_pfn%\*.appx*" if not exist "%_pfn%\*.msix*" goto :eof
set "_main="
if not defined _main if exist "%_pfn%\*.msixbundle" for /f "tokens=* delims=" %%# in ('dir /b /a:-d "%_pfn%\*.msixbundle"') do set "_main=%%#"
if not defined _main if exist "%_pfn%\*.appxbundle" for /f "tokens=* delims=" %%# in ('dir /b /a:-d "%_pfn%\*.appxbundle"') do set "_main=%%#"
if not defined _main if exist "%_pfn%\*.appx" for /f "tokens=* delims=" %%# in ('dir /b /a:-d "%_pfn%\*.appx"') do set "_main=%%#"
if not defined _main if exist "%_pfn%\*.msix" for /f "tokens=* delims=" %%# in ('dir /b /a:-d "%_pfn%\*.msix"') do set "_main=%%#"
if not defined _main (
(echo.&echo %_pfn% App main installer is not found)>>"!logerr!"
goto :eof
)
if %_appWay% neq 0 (
>>AppsToAdd.txt echo %_pfn%\%_main%
goto :eof
)
set "_stub="
if exist "%_pfn%\AppxMetadata\Stub\*.*x" (
set "_stub=/StubPackageOption:InstallStub"
if %StubAppsFull% neq 0 set "_stub=/StubPackageOption:InstallFull"
)
echo %_pfn%
%_Nul1% %_dism2%:"!_cabdir!" %dismtarget% /LogPath:"%_dLog%\DismAppx.log" /Add-ProvisionedAppxPackage /PackagePath:"%_pfn%\%_main%" /LicensePath:"%_pfn%\License.xml" /Region:all %_stub%
goto :eof

:V_Ext
set _extVirt=1
call create_virtual_editions.cmd extdism %1
if /i "%_Exit%"=="rem." set _Debug=1
if %_Debug% neq 0 @echo on
for /f "tokens=3 delims=: " %%# in ('wimlib-imagex.exe info "%_www%" ^| findstr /c:"Image Count"') do set _imgi=%%#
goto :eof

:V_Auto
if %wim2esd% equ 0 (
if %wim2swm% equ 0 (set virtag=autowim) else (set virtag=autoswm)
) else (
set virtag=autoesd
)
call create_virtual_editions.cmd %virtag% %_label% %isotime%
if /i "%_Exit%"=="rem." set _Debug=1
if %_Debug% neq 0 @echo on
title UUP -^> ISO %uivr%
goto :QUIT

:V_Manu
if %wim2esd% equ 0 (
if %wim2swm% equ 0 (set virtag=manuwim) else (set virtag=manuswm)
) else (
set virtag=manuesd
)
start /i "" %SysPath%\cmd.exe /c "create_virtual_editions.cmd %virtag% %_label% %isotime%"
if exist temp\ rmdir /s /q temp\
if exist bin\expand.exe if not exist bin\dpx.dll del /f /q bin\expand.exe
popd
call :dk_color2 %Green% "Finished." %_Yellow% " You chose to start create_virtual_editions.cmd independently." 7 8
echo Press 0 or q to exit.
choice /c 0Q /n
if errorlevel 1 (exit /b) else (rem.)
exit /b

:preVars
set psfnet=0
if exist "%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\ngen.exe" set psfnet=1
if exist "%SystemRoot%\Microsoft.NET\Framework\v2.0.50727\ngen.exe" set psfnet=1
for %%# in (E F G H I J K L M N O P Q R S T U V W X Y Z) do (
set "_adr%%#=%%#"
)
if %_cwmi% equ 1 for /f "tokens=2 delims==:" %%# in ('"wmic path Win32_Volume where (DriveLetter is not NULL) get DriveLetter /value" ^| findstr ^=') do (
if defined _adr%%# set "_adr%%#="
)
if %_cwmi% equ 1 for /f "tokens=2 delims==:" %%# in ('"wmic path Win32_LogicalDisk where (DeviceID is not NULL) get DeviceID /value" ^| findstr ^=') do (
if defined _adr%%# set "_adr%%#="
)
if %_cwmi% equ 0 for /f "tokens=1 delims=:" %%# in ('%_psc% "(([WMISEARCHER]'Select * from Win32_Volume where DriveLetter is not NULL').Get()).DriveLetter; (([WMISEARCHER]'Select * from Win32_LogicalDisk where DeviceID is not NULL').Get()).DeviceID"') do (
if defined _adr%%# set "_adr%%#="
)
for %%# in (E F G H I J K L M N O P Q R S T U V W X Y Z) do (
if not defined _sdr (if defined _adr%%# set "_sdr=%%#:")
)
if not defined _sdr set psfnet=0
set "_Pkt=31bf3856ad364e35"
set "_OurVer=25.10.0.0"
set "_SupCmp=microsoft-client-li..pplementalservicing"
set "_EdgCmp=microsoft-windows-e..-firsttimeinstaller"
set "_CedCmp=microsoft-windows-edgechromium"
set "_EsuCmp=microsoft-windows-s..edsecurityupdatesai"
set "_SupIdn=Microsoft-Client-Licensing-SupplementalServicing"
set "_EdgIdn=Microsoft-Windows-EdgeChromium-FirstTimeInstaller"
set "_CedIdn=Microsoft-Windows-EdgeChromium"
set "_EsuIdn=Microsoft-Windows-Security-SPP-Component-ExtendedSecurityUpdatesAI"
set "_SxsCfg=Microsoft\Windows\CurrentVersion\SideBySide\Configuration"
set "_CBS=Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages"
set "_IFEO=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\dismhost.exe"
set _MOifeo=0
goto :eof

:postVars
set "_wsr=Windows Server 2022"
set "pub=_8wekyb3d8bbwe"
set "_appSrvr=Microsoft.SecHealthUI%pub%,Microsoft.WindowsTerminal%pub%,Microsoft.DesktopAppInstaller%pub%,Microsoft.WindowsFeedbackHub%pub%"
set "_appBase=Microsoft.WindowsStore%pub%,Microsoft.StorePurchaseApp%pub%,Microsoft.SecHealthUI%pub%,Microsoft.DesktopAppInstaller%pub%,microsoft.windowscommunicationsapps%pub%,Microsoft.OutlookForWindows%pub%,Microsoft.WindowsCalculator%pub%,Microsoft.Windows.Photos%pub%,Microsoft.WindowsMaps%pub%,Microsoft.WindowsCamera%pub%,Microsoft.WindowsFeedbackHub%pub%,Microsoft.Getstarted%pub%,Microsoft.WindowsAlarms%pub%,Microsoft.StartExperiencesApp%pub%,Microsoft.ApplicationCompatibilityEnhancements%pub%"
set "_appClnt=Microsoft.WindowsNotepad%pub%,Microsoft.WindowsTerminal%pub%,Microsoft.Paint%pub%,MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy,Microsoft.People%pub%,Microsoft.ScreenSketch%pub%,Microsoft.MicrosoftStickyNotes%pub%,Microsoft.XboxIdentityProvider%pub%,Microsoft.XboxSpeechToTextOverlay%pub%,Microsoft.XboxGameOverlay%pub%,Clipchamp.Clipchamp_yxz26nhyzhsrt,MicrosoftTeams%pub%,MSTeams%pub%,Microsoft.WidgetsPlatformRuntime%pub%"
set "_appCodec=Microsoft.WebMediaExtensions%pub%,Microsoft.RawImageExtension%pub%,Microsoft.HEIFImageExtension%pub%,Microsoft.HEVCVideoExtension%pub%,Microsoft.VP9VideoExtensions%pub%,Microsoft.WebpImageExtension%pub%,Microsoft.DolbyAudioExtension%pub%,Microsoft.AVCEncoderVideoExtension%pub%,Microsoft.MPEG2VideoExtension%pub%"
set "_appMedia=Microsoft.ZuneMusic%pub%,Microsoft.ZuneVideo%pub%,Microsoft.WindowsSoundRecorder%pub%,Microsoft.GamingApp%pub%,Microsoft.XboxGamingOverlay%pub%,Microsoft.Xbox.TCUI%pub%,Microsoft.YourPhone%pub%,Microsoft.Windows.DevHome%pub%"
set "_appPPIP=Microsoft.MicrosoftPowerBIForWindows%pub%,microsoft.microsoftskydrive%pub%,Microsoft.MicrosoftTeamsforSurfaceHub%pub%,MicrosoftCorporationII.MailforSurfaceHub%pub%,Microsoft.Whiteboard%pub%,Microsoft.SkypeApp_kzf8qxf38zg5c"
set "_appMin1=Microsoft.WindowsStore%pub%,Microsoft.StorePurchaseApp%pub%,Microsoft.SecHealthUI%pub%,Microsoft.DesktopAppInstaller%pub%,Microsoft.StartExperiencesApp%pub%,Microsoft.ApplicationCompatibilityEnhancements%pub%"
set "_appMin2=Microsoft.Windows.Photos%pub%,Microsoft.WindowsCamera%pub%,Microsoft.WindowsNotepad%pub%,Microsoft.Paint%pub%"
set "_appMin3=Microsoft.WindowsTerminal%pub%,MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy,microsoft.windowscommunicationsapps%pub%,Microsoft.OutlookForWindows%pub%,Clipchamp.Clipchamp_yxz26nhyzhsrt,Microsoft.WidgetsPlatformRuntime%pub%"
set "_appMin4=%_appCodec%,Microsoft.ZuneMusic%pub%,Microsoft.ZuneVideo%pub%,Microsoft.YourPhone%pub%"
set ksub=SOFTWIM
set SOFTWARE=uiSOFTWARE
set COMPONENTS=uiCOMPONENTS
set ERRTEMP=
set PREPARED=0
set VOL=0
set EXPRESS=0
set AIO=0
set FixDisplay=0
set uups_esd_num=0
set uwinpe=0
set _count=0
set "_fixEP="
set _actEP=0
set _skpd=0
set _skpp=0
set _eosC=0
set _eosP=0
set _eosT=0
set relite=0
set _SrvESD=0
set _Srvr=0
set _reMSU=0
set _OPA=0
set _IPA=0
set _runIPA=0
set _appsCustom=0
set _initial=0
set _wimEdge=0
set noLCU=0
set mntRE=0
set sduRE=0
set cmtRE=0
set psfwim=0
set _delta=msdelta.dll
set _pspsfx=%_psc%
set basekbn=
set basepkg=
set "_mount=%_drv%\MountUUP"
set "_ntf=NTFS"
if /i not "%_drv%"=="%SystemDrive%" if %_cwmi% equ 1 for /f "tokens=2 delims==" %%# in ('"wmic volume where DriveLetter='%_drv%' get FileSystem /value"') do set "_ntf=%%#"
if /i not "%_drv%"=="%SystemDrive%" if %_cwmi% equ 0 for /f %%# in ('%_psc% "(([WMISEARCHER]'Select * from Win32_Volume where DriveLetter=\"%_drv%\"').Get()).FileSystem"') do set "_ntf=%%#"
if /i not "%_ntf%"=="NTFS" (
set "_mount=%SystemDrive%\MountUUP"
)
set "_ln2=____________________________________________________________"
set "_ln1=________________________________________________"
set _extVirt=0
set _didProf=0
set _didProN=0
set _didHome=0
set u_msulcu=0
set u_winre=0
set u_upgrade=0
goto :eof

:checkadk
set _dism1=dism.exe /English
set _dism2=dism.exe /English /ScratchDir
set _ADK=0
set regKeyPathFound=1
set wowRegKeyPathFound=1
reg.exe query "HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 %_Nul3% || set wowRegKeyPathFound=0
reg.exe query "HKLM\Software\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 %_Nul3% || set regKeyPathFound=0
if %wowRegKeyPathFound% equ 0 (
  if %regKeyPathFound% equ 0 (
    goto :eof
  ) else (
    set regKeyPath=HKLM\Software\Microsoft\Windows Kits\Installed Roots
  )
) else (
    set regKeyPath=HKLM\Software\Wow6432Node\Microsoft\Windows Kits\Installed Roots
)
for /f "skip=2 tokens=2*" %%i in ('reg.exe query "%regKeyPath%" /v KitsRoot10') do set "KitsRoot=%%j"
set "DandIRoot=%KitsRoot%Assessment and Deployment Kit\Deployment Tools"
if exist "%DandIRoot%\%xOS%\DISM\dism.exe" (
set _ADK=1
set "Path=%xDS%;%DandIRoot%\%xOS%\DISM;%SysPath%;%SystemRoot%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
)
goto :eof

:DismHostON
if %winbuild% lss 9200 exit /b
if %_MOifeo% neq 0 exit /b
set _MOifeo=1
(
echo Windows Registry Editor Version 5.00
echo.
echo [%_IFEO%]
echo "MitigationOptions"=hex^(b^):00,00,22,00,00,00,00,00
)>bin\dismAdd.reg
reg.exe query "%_IFEO%" /v MitigationOptions %_Nul3%
if %errorlevel% equ 0 (
regedit.exe /E bin\dismOrg.reg "%_IFEO%"
)
regedit.exe /S bin\dismAdd.reg
exit /b

:DismHostOFF
if %winbuild% lss 9200 exit /b
if %_MOifeo% equ 0 exit /b
(
echo Windows Registry Editor Version 5.00
echo.
echo [-%_IFEO%]
)>bin\dismRem.reg
if exist "bin\dismOrg.reg" (
regedit.exe /S bin\dismOrg.reg
) else (
regedit.exe /S bin\dismRem.reg
)
del /f /q bin\dism*.reg %_Nul3%
exit /b

:pr_color
set _NCS=1
if %winbuild% LSS 10586 set _NCS=0
if %winbuild% GEQ 10586 reg.exe query HKCU\Console /v ForceV2 2>nul | find /i "0x0" %_Null% && (set _NCS=0)

if %_NCS% EQU 1 (
for /F %%a in ('echo prompt $E ^| cmd.exe') do set "_esc=%%a"
set     "Red="41;97m" "pad""
set    "Gray="100;97m" "pad""
set   "Green="42;97m" "pad""
set    "Blue="44;97m" "pad""
set  "_White="40;37m" "pad""
set  "_Green="40;92m" "pad""
set "_Yellow="40;93m" "pad""
) else (
set     "Red="Red" "white""
set    "Gray="DarkGray" "white""
set   "Green="DarkGreen" "white""
set    "Blue="Blue" "white""
set  "_White="Black" "Gray""
set  "_Green="Black" "Green""
set "_Yellow="Black" "Yellow""
)

set "_err=echo: &call :dk_color1 %Red% "==== ERROR ====" &echo:"
exit /b

:dk_color1
if /i "%_Exit%"=="rem." (
echo %~3
exit /b
)
if not "%4"=="" if "%4"=="4" echo:
if %_NCS% EQU 1 (
echo %_esc%[%~1%~3%_esc%[0m
) else if %_pwsh% EQU 1 (
%_psc% write-host -back '%1' -fore '%2' '%3'
) else (
echo %~3
)
if not "%5"=="" echo:
exit /b

:dk_color2
if /i "%_Exit%"=="rem." (
echo %~3 %~6
exit /b
)
if not "%7"=="" if "%7"=="7" echo:
if %_NCS% EQU 1 (
echo %_esc%[%~1%~3%_esc%[%~4%~6%_esc%[0m
) else if %_pwsh% EQU 1 (
%_psc% write-host -back '%1' -fore '%2' '%3' -NoNewline; write-host -back '%4' -fore '%5' '%6'
) else (
echo %~3 %~6
)
if not "%8"=="" echo:
exit /b

:checkQE
if not defined qerel reg.exe query HKCU\Console /v QuickEdit 2>nul | find /i "0x0" >nul || (
call :dk_color1 %Red% "### WARNING ###"
echo.
echo Console "Quick Edit Mode" is active.
echo Do not left-click with the mouse cursor inside the console window,
echo or else the operation execution will hang until a key is pressed.
echo.
)
exit /b

:E_Admin
%_err%
echo This script require administrator privileges.
echo To do so, right click on this script and select 'Run as administrator'
goto :E_Exit

:E_PWS
%_err%
echo Windows PowerShell is not detected or not working correctly.
echo It is required for this script to work.
goto :E_Exit

:E_Exit
if %AutoExit% neq 0 exit /b
if %_Debug% neq 0 exit /b
echo.
echo Press any key to exit.
pause >nul
exit /b

:E_Bin
%_err%
echo Required file %_bin% is missing.
echo.
goto :QUIT

:E_ESD
:: @color 0F
@cls
call :dk_color1 %Red% "No Edition file{s} found in the specified UUP source." 4 5
goto :QUIT

:E_Apply
:: @color 17
call :dk_color1 %Red% "Errors were reported during wim apply." 4 5
(echo.&echo Errors were reported during wim apply.)>>"!logerr!"
goto :QUIT

:E_Export
:: @color 17
call :dk_color1 %Red% "Errors were reported during wim export." 4 5
(echo.&echo Errors were reported during wim export.)>>"!logerr!"
goto :QUIT

:E_ISO
:: @color 17
ren ISOFOLDER %DVDISO%
call :dk_color1 %Red% "Errors were reported during ISO creation." 4 5
(echo.&echo Errors were reported during ISO creation.)>>"!logerr!"
goto :QUIT

:QUIT
call :DismHostOFF
if exist ISOFOLDER\ rmdir /s /q ISOFOLDER\
if exist bin\temp\ rmdir /s /q bin\temp\
if exist temp\ rmdir /s /q temp\
if exist bin\expand.exe if not exist bin\dpx.dll del /f /q bin\expand.exe
if exist bin\info*.txt del /f /q bin\info*.txt
popd
if defined tmpcmp (
  for %%# in (%tmpcmp%) do del /f /q "!_UUP!\%%~#" %_Nul3%
  set tmpcmp=
)
if exist "!_cabdir!\" (
rmdir /s /q "!_cabdir!\" %_Nul3%
)
if exist "!_cabdir!\" (
mkdir %_drv%\_del286 %_Null%
robocopy %_drv%\_del286 "!_cabdir!" /MIR /R:1 /W:1 /NFL /NDL /NP /NJH /NJS %_Null%
rmdir /s /q %_drv%\_del286\ %_Null%
rmdir /s /q "!_cabdir!\" %_Nul3%
)
if defined qmsg call :dk_color1 %Green% "%qmsg%" 4
if %AutoExit% neq 0 exit /b
if %_Debug% neq 0 exit /b
call :dk_color1 %_Yellow% "Press 0 or q to exit."
choice /c 0Q /n
if errorlevel 1 (exit /b) else (rem.)

----- Begin wsf script --->
<package>
   <job id="ELAV">
      <script language="VBScript">
         Set strArg=WScript.Arguments.Named
         Set strRdlproc = CreateObject("WScript.Shell").Exec("rundll32 kernel32,Sleep")
         With GetObject("winmgmts:\\.\root\CIMV2:Win32_Process.Handle='" & strRdlproc.ProcessId & "'")
            With GetObject("winmgmts:\\.\root\CIMV2:Win32_Process.Handle='" & .ParentProcessId & "'")
               If InStr (.CommandLine, WScript.ScriptName) <> 0 Then
                  strLine = Mid(.CommandLine, InStr(.CommandLine , "/File:") + Len(strArg("File")) + 8)
               End If
            End With
            .Terminate
         End With
         CreateObject("Shell.Application").ShellExecute "cmd.exe", "/c " & chr(34) & chr(34) & strArg("File") & chr(34) & strLine & chr(34), "", "runas", 1
      </script>
   </job>
</package>
