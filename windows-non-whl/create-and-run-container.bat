
if [%1]==[] goto usage
if [%2]==[] goto usage
if [%3]==[] goto usage
echo Deleting existing container with name: $1
echo Ignore any "No such container message" below:
docker container rm -f %1

docker container run -d ^
    --name %1 ^
    --mount type=volume,source=%2,target=/workspace ^
    --mount type=bind,source=%USERPROFILE%\.ssh,target=/home/dev/.ssh,readonly ^
    --mount type=bind,source=%USERPROFILE%\.aws,target=/home/dev/.aws ^
    dev-container-image-python:%3

if %errorlevel% neq 0 exit /b %errorlevel%
echo Created container %1
goto :eof
:usage
@echo Usage: %0 ^<NewContainerName^> ^<VolumeName^> ^<PythonVersion^>
exit /B 1