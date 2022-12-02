# clspv [![Discord Shield](https://discordapp.com/api/guilds/1002628585250631681/widget.png?style=shield)](https://discord.gg/xsVdjmhFM9)

**Clspv** is a prototype compiler for a subset of OpenCL C to Vulkan
compute shaders.

It consists of:
* A set of LLVM Module passes to transform a dialect of LLVM IR into
  a SPIR-V module containing Vulkan compute shaders.
* A command line compiler tool called _'clspv'_ to compile a subset of
  OpenCL C into a Vulkan compute shader.

Clspv depends on external projects:
* Top-of-tree versions of [Clang][Clang] and [LLVM][LLVM]
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

The compiler is an incomplete prototype, with many rough edges.

The input language is a subset of OpenCL C version 1.2.
The [OpenCL C on Vulkan Specification](docs/OpenCLCOnVulkan.md)
describes the specific subset, and also the mapping into Vulkan compute
shaders.

## Examples

Compile a set of kernels into a SPIR-V binary module:

    clspv foo.cl -o foo.spv

Emit the binary as a C initializer list, for easy embedding of a shader in
in a C or C++ program source:

    clspv -mfmt=c foo.cl -o -

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
[CMake-doc]: https://cmake.org/documentation
[CMake]: https://cmake.org
[LLVM]: http://llvm.org
[Ninja]: https://ninja-build.org
[SPIRV-Headers]: https://github.com/KhronosGroup/SPIRV-Headers
[SPIRV-Tools]: https://github.com/KhronosGroup/SPIRV-Tools

## Builtin Libraries

Clspv includes two LLVM IR libraries (cmake/clspv--.bc, cmake/clspv64--.bc)
containing implementations of some OpenCL builtin functions, for the spir and
spir64 targets respectively. These files are distributed under the LLVM license
(included in LICENSE) as they are generated from the LLVM sub-project
[libclc](https://libclc.llvm.org). Refer to the source for the relevant
copyrights.

### Rebuilding the Library

#### Required Tools

You will need a pre-built version of [LLVM](github.com/llvm/llvm-project) for
your system, CMake, and (optionally) Ninja.

#### Build

To rebuild the library run the following commands:

    cmake -GNinja <libclc dir> -DLIBCLC_TARGETS_TO_BUILD="clspv--;clspv64--" -DLLVM_CMAKE_DIR=</path/to/llvm_installation/lib/cmake/>
    ninja

Copy the resulting `clspv--.bc` and `clspv64--.bc` files into the cmake/
directory and rebuild clspv.
