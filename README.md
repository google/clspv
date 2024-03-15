# clspv [![Discord Shield](https://discordapp.com/api/guilds/1002628585250631681/widget.png?style=shield)](https://discord.gg/xsVdjmhFM9)

**Clspv** is a compiler for OpenCL C targeting Vulkan compute shaders.

It consists of:
* A set of LLVM Module passes to transform a dialect of LLVM IR into
  a SPIR-V module containing Vulkan compute shaders.
* A command line compiler tool called _'clspv'_ to compile a subset of
  OpenCL C into a Vulkan compute shader.

Clspv depends on external projects:
* Top-of-tree versions of [Clang][Clang], [LLVM][LLVM] and [libclc][libclc]
* [SPIRV-Tools][SPIRV-Tools]
* [SPIRV-Headers][SPIRV-Headers]

## Legal

Clspv is licensed under the terms of the [Apache 2.0 license](LICENSE).
The [AUTHORS](AUTHORS) file lists the copyright owners, while individual
credit is given in the [CONTRIBUTORS](CONTRIBUTORS) file.
To contribute, see [CONTRIBUTING.md](CONTRIBUTING.md).

Materials in projects Clspv depends on are licensed under
their own terms.

Clspv is not an official Google product.

## Status

Clspv has passed OpenCL3.0 conformance with:
- [clvk][clvk] as the runtime driver ([submission 419](https://www.khronos.org/conformance/adopters/conformant-products/opencl#submission_419))
using the following tags:
  - clvk: [khronos-submission-419](https://github.com/kpet/clvk/releases/tag/khronos-submission-419)
  - clspv: [clvk-khronos-submission-419](https://github.com/google/clspv/releases/tag/clvk-khronos-submission-419)

The input language is OpenCL C version 1.2.
Read the [OpenCL C on Vulkan Specification](docs/OpenCLCOnVulkan.md) for more
information on the support and the mapping into Vulkan compute shaders.

## Examples

Compile a set of kernels into a SPIR-V binary module:

    clspv foo.cl -o foo.spv

Emit the binary as a C initializer list, for easy embedding of a shader in
in a C or C++ program source:

    clspv --output-format=c foo.cl -o -

Predefine some preprocessor symbols:

    clspv -DWIDTH=32 -DHEIGHT=64 foo.cl -o foo.spv

Use OpenCL compiler options:

    clspv -cl-fast-relaxed-math -cl-single-precision-constant foo.cl -o foo.spv

Show help:

    clspv -help

## Compiler-explorer
> Compiler Explorer is an interactive compiler exploration website. Edit code in C, C++, C#, F#, Rust, Go, D, Haskell, Swift, Pascal, ispc, Python, Java or in any of the other 30+ supported languages, and see how that code looks after being compiled in real time. Multiple compilers are supported for each language, many different tools and visualisations are available, and the UI layout is configurable (thanks to GoldenLayout).
>
> -- https://github.com/compiler-explorer/compiler-explorer#readme

clspv is available in [compiler-explorer](https://godbolt.org/) among the `OpenCL C` compilers.

It is built daily by the compiler-explorer infrastructure.

## Build

### Tools

You will need:

* CMake
* Python3
* A C++ compiler
* git

### Getting sources for dependencies

Clspv depends on the sources for other projects, at specific commits.
Run the following command to download those dependencies, and place them
in the `third_party` directory:

    python3 utils/fetch_sources.py

### Building

Then, create a build directory:

    cd <clspv-dir>
    mkdir build
    cd build

Then configure and build the code:

    cmake <clspv-dir>
    cmake --build .

This will build the `clspv` command line compiler and place it in
location `bin/clspv` under the build directory.

### Using Ninja to build, and other build options

We recommend you use the [Ninja][Ninja] build tool if it's available.
To do so, replace the last two commands with:

    cmake -G Ninja <clspv-dir>
    ninja

Other useful configuration options (the first `cmake` command):

* `-DCMAKE_BUILD_TYPE=RelWithDebInfo` : Build in release mode, with debugging
  information. Default is a debug build.

See the [CMake][CMake] [documentation][CMake-doc] for more generic options.

## Test

To run the test suite from within the build directory:

    cmake --build . --target check-spirv

Or if you are using Ninja:

    ninja check-spirv

[Clang]: http://clang.llvm.org
[clvk]: https://github.com/kpet/clvk
[CMake-doc]: https://cmake.org/documentation
[CMake]: https://cmake.org
[libclc] https://libclc.llvm.org
[LLVM]: http://llvm.org
[Ninja]: https://ninja-build.org
[SPIRV-Headers]: https://github.com/KhronosGroup/SPIRV-Headers
[SPIRV-Tools]: https://github.com/KhronosGroup/SPIRV-Tools
