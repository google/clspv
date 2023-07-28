# Building CLSPV with GN

Note: The clspv official build is CMake. The GN build described here is
experimental and use it only if there is a dependency on GN.

GN[1] is meta-build system and generates the ninja files. It is provided here to
build clspv as part of chromium build infra which uses GN. The clspv project has
a dependency on LLVM, and as such GN build leverages some of the LLVM
experimental GN build files[2].

## Build Instructions

### Fetch the dependencies

1. Install GN
   * See "Getting a Binary" section in [1]
   * For ubuntu, a debian package `generate-ninja` is available from 20.04
     onwards -- `sudo apt install generate-ninja`

2. Fetch all the dependencies of clspv
    `python3 utils/fetch_sources.py`

### Building

For native linux build

```
cd <clspv-dir>
gn gen <build-dir>
ninja -C <build-dir>
```

For android build, setup the below in `args.gn` file

```
# See `gn help buildargs` for more on the args.gn
android-ndk-path = <path to Android NDK r21>
clang-base-path = android_ndk_path + "toolchains/llvm/prebuilt/linux-x86_64"
target_os = "android"
target_cpu = <arm or arm64>
```

Note: Only `arm/arm64` targets are supported for now. The NDK is limited to
version r21 as LLVM is restricted to it.


[1]: https://gn.googlesource.com/gn/
[2]: https://github.com/llvm/llvm-project/blob/main/llvm/utils/gn/README.rst
