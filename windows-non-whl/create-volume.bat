@echo off
if [%1]==[] goto usage
docker volume create --name %1
if %errorlevel% neq 0 exit /b %errorlevel%
echo Created volume %1
goto :eof
:usage
@echo Usage: %0 ^<NewVolumeName^>
exit /B 1