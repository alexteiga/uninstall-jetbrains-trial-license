
@echo off
setlocal enabledelayedexpansion

REM Close all JetBrains-related processes
taskkill /f /im jetbrains.* /t
taskkill /f /im devenv.* /t

REM Get the current user's SID
for /f "tokens=2 delims= " %%a in ('whoami /user') do set "usersid=%%a"

echo User SID: %usersid%

REM Loop through JetBrains product directories
for %%I in ("WebStorm", "IntelliJ", "CLion", "Rider", "GoLand", "PhpStorm", "ReSharper", "PyCharm") do (
    for /d %%a in ("%USERPROFILE%\%%I*") do (
        attrib -h -r -s "%%a\config\eval" /s /d
        rd /s /q "%%a\config\eval"
        del /q "%%a\config\options\other.xml"
    )
)

REM Delete JetBrains-related folders in AppData
rmdir /s /q "%APPDATA%\JetBrains"
rmdir /s /q "%LOCALAPPDATA%\JetBrains\ReSharper"
rmdir /s /q "%LOCALAPPDATA%\JetBrains\ReSharperPlatformVs17"
rmdir /s /q "%LOCALAPPDATA%\JetBrains\Shared"
rmdir /s /q "%LOCALAPPDATA%\JetBrains\Transient"

REM Delete the ReSharper uninstall files if they exist
set "installationsDir=%LOCALAPPDATA%\JetBrains\Installations"
set "uninstallFiles="

REM Check for all uninstall files without an extension recursively
for /r "%installationsDir%" %%f in (uninstall*) do (
    echo Found uninstall file: %%f
    set "uninstallFiles=!uninstallFiles! %%f"
)

if defined uninstallFiles (
    for %%u in (!uninstallFiles!) do (
        echo Processing uninstall file: %%u
       
        REM Read the uninstall file for registry keys
        set "inRegistryValues=false"
        for /f "usebackq tokens=*" %%k in ("%%u") do (
            set "line=%%k"
            REM Check for the start of the RegistryValues section
            if "!line!"=="  \"RegistryValues\":" (
                set "inRegistryValues=true"
                rem Skip the next line as it's just an opening bracket
                set "skipNext=true"
                continue
            )
            REM Check for the end of the RegistryValues section
            if "!line!"=="  ]," (
                set "inRegistryValues=false"
                continue
            )
            REM If in the RegistryValues section, extract the Key
            if "!inRegistryValues!"=="true" (
                if defined skipNext (
                    set "skipNext="
                    continue
                )
                for /f "tokens=2 delims=:" %%j in ("!line!") do (
                    set "regKey=%%j"
                    REM Remove leading and trailing spaces and quotes
                    set "regKey=!regKey:~1,-1!"
                    REM Construct the full registry path
                    set "regKey=HKEY_CURRENT_USER\!regKey!"
                   
                    echo Deleting registry key: !regKey!
                    reg delete "!regKey!" /f
                )
            )
        )
    )
) else (
    echo No uninstall files found in %installationsDir%.
)

REM Delete registry keys under the dynamically retrieved user SID
reg delete "HKEY_USERS\%usersid%\Software\JetBrains" /f

REM Delete JetBrains and related registry keys
reg delete "HKEY_CURRENT_USER\Software\JetBrains" /f
reg delete "HKEY_CURRENT_USER\Software\JavaSoft" /f

REM Optional: Check and delete other potential JetBrains folders
rmdir /s /q "%PROGRAMDATA%\JetBrains"
rmdir /s /q "%USERPROFILE%\Documents\JetBrains"

echo All JetBrains products and their data have been removed.
pause



REM If it didn't work we need to go to the folder where the file is  \AppData\Local\JetBrains\Installations\ReSharperPlatformVs17 ...
REM Check the uninstall file and delete the keys like
REM reg delete "HKEY_CURRENT_USER\Software\JetBrains\ReSharperPlatformVs17\v242_5cdabf11" /f
REM reg delete "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall\{732990ac-00cf-5015-b4ff-9d5212816ed0}" /f
