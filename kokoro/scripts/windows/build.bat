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

:: Use updated CMake
set PATH=c:\cmake-3.31.2\bin;%PATH%

:: Use updated Python
set PATH=c:\Python312;%PATH%

cd %SRC%
python utils/fetch_sources.py

:: #########################################
:: set up msvc build env
:: #########################################
if %VS_VERSION% == 2022 (
  set GENERATOR="Visual Studio 17 2022"
  echo "Using VS 2022..."
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
cmake --build . --config %BUILD_TYPE% -- /bl
cat msbuild.binlog
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
