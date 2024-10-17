:: Copyright 2018 The Clspv Authors. All rights reserved.
::
:: Licensed under the Apache License, Version 2.0 (the "License");
:: you may not use this file except in compliance with the License.
:: You may obtain a copy of the License at
::
::     http://www.apache.org/licenses/LICENSE-2.0
::
:: Unless required by applicable law or agreed to in writing, software
:: distributed under the License is distributed on an "AS IS" BASIS,
:: WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
:: See the License for the specific language governing permissions and
:: limitations under the License.

@echo on

set BUILD_ROOT=%cd%
set SRC=%cd%\github\clspv
set BUILD_TYPE=%1
set VS_VERSION=%2

:: Define the Python version and download URL
set "pythonVersion=3.8.10"
:: Download Python installer
wget "https://www.python.org/ftp/python/%pythonVersion%/python-%pythonVersion%-amd64.exe" -O "%TEMP%\python-installer.exe"
:: Install Python silently
"%TEMP%\python-installer.exe" /quiet InstallAllUsers=1 PrependPath=1

cd %SRC%
python utils/fetch_sources.py

:: #########################################
:: set up msvc build env
:: #########################################
if %VS_VERSION% == 2019 (
  set GENERATOR="Visual Studio 16 2019"
  echo "Using VS 2019..."
) else if %VS_VERSION% == 2017 (
  set GENERATOR="Visual Studio 15 2017 Win64"
  echo "Using VS 2017..."
) else if %VS_VERSION% == 2015 (
  set GENERATOR="Visual Studio 14 2015 Win64"
  echo "Using VS 2015..."
) else if %VS_VERSION% == 2013 (
  set GENERATOR="Visual Studio 12 2013 Win64"
  echo "Using VS 2013..."
)

cd %SRC%
mkdir build
cd build

:: #########################################
:: Start building.
:: #########################################
echo "Starting build... %DATE% %TIME%"
if "%KOKORO_GITHUB_COMMIT%." == "." (
  set BUILD_SHA=%KOKORO_GITHUB_PULL_REQUEST_COMMIT%
) else (
  set BUILD_SHA=%KOKORO_GITHUB_COMMIT%
)

cmake -G%GENERATOR% -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DLLVM_TARGETS_TO_BUILD="" .. -Thost=x64

if %ERRORLEVEL% GEQ 1 exit /b %ERRORLEVEL%

echo "Build everything... %DATE% %TIME%"
cmake --build . --config %BUILD_TYPE%
if %ERRORLEVEL% GEQ 1 exit /b %ERRORLEVEL%
echo "Build Completed %DATE% %TIME%"

echo "Run tests... %DATE% %TIME%"
cmake --build . --target check-spirv --config %BUILD_TYPE%
if %ERRORLEVEL% GEQ 1 exit /b %ERRORLEVEL%
cmake --build . --target check-spirv-64 --config %BUILD_TYPE%
if %ERRORLEVEL% GEQ 1 exit /b %ERRORLEVEL%
echo "Tests Completed %DATE% %TIME%"

:: Clean up some directories.
rm -rf %SRC%\build
rm -rf %SRC%\third_party

exit /b %ERRORLEVEL%
