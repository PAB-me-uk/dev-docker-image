@echo off
if [%1]==[] goto usage
docker build .. -t dev-container-image-python:%1 --build-arg PYTHON_VERSION=%1
if %errorlevel% neq 0 exit /b %errorlevel%
echo Built image dev-container-image-python:%1
goto :eof
:usage
echo Usage: %0 ^<PythonVersion^>
exit /B 1