# Clspv - C API wrapper

This folder contains the C API for shared lib version of Clspv.

## clBuildProgram Example Flow

```C++
#include <cstdio>
#include <cstdint>

#include "Clspv.h"

int main() {
    // CL source example:
    const char* clSrc = "__kernel void sample_test(__global int *dst, int count) {  \n"
                        "                                                           \n"
                        "   int  tid = get_global_id(0);                            \n"
                        "   for( int i = 0; i < count; i++ )                        \n"
                        "       dst[i] = tid + i;                                   \n"
                        "}                                                          \n";

    // Create container
    ClspvContainer container = clspvCreateContainer();
    if (container == nullptr) {
        // Handle error ...
    }

    // Compile
    size_t outputSpvSize = 0;
    char* outputSpv = nullptr;
    const char* outputBuildLog = nullptr;
    ClspvError ret = clspvCompileFromSourcesString(container,
                                                   1,
                                                   NULL,
                                                   (const char**)&clSrc,
                                                   "--output-format=spv ",
                                                   &outputSpv,
                                                   &outputSpvSize,
                                                   &outputBuildLog);
    printf("Build Log:\n%s\n", outputBuildLog);
    if (ret != CLSPV_SUCCESS) {
        // Handle error ...
    }

    // Cleanup
    clspvDestroyContainer(container);
    return 0;
}
```

## clCompileProgram and clLinkProgram Example Flow

```C++
#include <cstdio>
#include <cstdint>

#include "Clspv.h"

int main() {
    // Test/Build CL source example:
    const char* clSrc = "__kernel void sample_test(__global int *dst, int count) {  \n"
                        "                                                           \n"
                        "   int  tid = get_global_id(0);                            \n"
                        "   for( int i = 0; i < count; i++ )                        \n"
                        "       dst[i] = tid + i;                                   \n"
                        "}                                                          \n";

    const char* clSrc2 = "__kernel void sample_test2(__global float *src, __global int *dst) {  \n"
                         "    int  tid = get_global_id(0);                                      \n"
                         "    dst[tid] = (int)src[tid];                                         \n"
                         "}                                                                     \n";

    // Create containers
    ClspvContainer container  = clspvCreateContainer();
    ClspvContainer container2 = clspvCreateContainer();
    ClspvContainer container3 = clspvCreateContainer();
    if (container == nullptr) {
        // Handle error ...
    }
    if (container2 == nullptr) {
        // Handle error ...
    }
    if (container3 == nullptr) {
        // Handle error ...
    }

    // Compile first program to LLVM IR
    size_t outputBinSize = 0;
    char* outputBin = nullptr;
    const char* outputBuildLog = nullptr;
    ClspvError ret = clspvCompileFromSourcesString(container,
                                                   1,
                                                   NULL,
                                                   (const char**)&clSrc,
                                                   "--output-format=bc ",
                                                   &outputBin,
                                                   &outputBinSize,
                                                   &outputBuildLog);
    if (ret != CLSPV_SUCCESS) {
        // Handle error ...
    }

    // Compile second program to LLVM IR
    size_t outputBinSize2 = 0;
    char* outputBin2 = nullptr;
    const char* outputBuildLog2 = nullptr;
    ret = clspvCompileFromSourcesString(container2,
                                        1,
                                        NULL,
                                        (const char**)&clSrc2,
                                        "--output-format=bc ",
                                        &outputBin2,
                                        &outputBinSize2,
                                        &outputBuildLog2);
    if (ret != CLSPV_SUCCESS) {
        // Handle error ...
    }

    // Link programs
    size_t outputSpvSize = 0;
    char* outputSpv = nullptr;
    size_t outputBinSizes[2] = { outputBinSize, outputBinSize2 };
    const char* outputBinChars[2] = { outputBin, outputBin2 };
    const char* outputBuildLog3 = nullptr;
    ret = clspvCompileFromSourcesString(container3,
                                        2,
                                        outputBinSizes,
                                        outputBinChars,
                                        "-x ir ",
                                        &outputSpv,
                                        &outputSpvSize,
                                        &outputBuildLog3);
    if (ret != CLSPV_SUCCESS) {
        // Handle error ...
    }

    // Cleanup
    clspvDestroyContainer(container);
    clspvDestroyContainer(container2);
    clspvDestroyContainer(container3);
    return 0;
}
```
