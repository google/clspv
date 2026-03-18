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
set BUILD=%SRC%\build

:: Use updated CMake
set PATH=c:\cmake-3.31.2\bin;%PATH%

:: Use updated Python
set PATH=c:\Python312;%PATH%

:: Install LLVM
choco install -y llvm
set LLVM_BIN_PATH=c:\Program Files\LLVM\bin
set "CC=%LLVM_BIN_PATH%\clang.exe"
set "CXX=%LLVM_BIN_PATH%\clang++.exe"

:: Upgrade ninja
choco upgrade -y ninja
ninja --version

:: VcVarsAll call
SET "VSWHERE_PATH=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
IF NOT EXIST "%VSWHERE_PATH%" (
  ECHO "ERROR: vswhere.exe not found at %VSWHERE_PATH%"
  EXIT /B 1
)
FOR /F "usebackq tokens=*" %%i IN (`"%VSWHERE_PATH%" -latest -property installationPath`) DO SET VS_INSTALL_PATH=%%i
IF NOT DEFINED VS_INSTALL_PATH (
  ECHO "ERROR: vswhere.exe did not find any Visual Studio installation."
  EXIT /B 1
)
ECHO "Found Visual Studio at: %VS_INSTALL_PATH%"
SET "VCVARSALL_PATH=%VS_INSTALL_PATH%\VC\Auxiliary\Build\vcvarsall.bat"
CALL "%VCVARSALL_PATH%" x64

cd %SRC%
python utils/fetch_sources.py --ci

:: #########################################
:: Start building.
:: #########################################
echo "Starting build... %DATE% %TIME%"
if "%KOKORO_GITHUB_COMMIT%." == "." (
  set BUILD_SHA=%KOKORO_GITHUB_PULL_REQUEST_COMMIT%
) else (
  set BUILD_SHA=%KOKORO_GITHUB_COMMIT%
)

cmake -S %SRC% -B %BUILD% -G Ninja -DCMAKE_BUILD_TYPE=%BUILD_TYPE%

if %ERRORLEVEL% GEQ 1 exit /b %ERRORLEVEL%

echo "Build everything... %DATE% %TIME%"
cmake --build %BUILD% --config %BUILD_TYPE%
if %ERRORLEVEL% GEQ 1 exit /b %ERRORLEVEL%
echo "Build Completed %DATE% %TIME%"

echo "Run tests... %DATE% %TIME%"
cmake --build %BUILD% --target check-spirv --config %BUILD_TYPE%
if %ERRORLEVEL% GEQ 1 exit /b %ERRORLEVEL%
cmake --build %BUILD% --target check-spirv-64 --config %BUILD_TYPE%
if %ERRORLEVEL% GEQ 1 exit /b %ERRORLEVEL%
echo "Tests Completed %DATE% %TIME%"

:: Clean up some directories.
rm -rf %BUILD%
rm -rf %SRC%\third_party

exit /b %ERRORLEVEL%
