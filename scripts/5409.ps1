@echo off
  setlocal enabledelayedexpansion
    for /f "tokens=2 delims=-" %%i in (
      'arp -a ^| 2^>nul findstr /rc:"0x"'
    ) do set "itm=%%i"
    if "%itm%" equ "" echo Could not parse ARP table. & goto:eof
    for /f "tokens=2 delims=." %%i in (
      'route print ^| findstr %itm%'
    ) do set "mac=%%i"
    set "str=%mac%"
    set "len=0"
    
    :loop
    if defined str (set str=%str:~1%& set /a "len+=1" & goto:loop)
    
    set /a "len=%len%-1"
    set "mac=%mac: =-%"
    echo !mac:~0,%len%!
  endlocal
exit /b
