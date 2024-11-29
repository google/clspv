#!/usr/bin/env python
# Copyright 2019 The Clspv Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os.path
import re

def main():
    import argparse
    parser = argparse.ArgumentParser(description='Define clspv builtins')

    parser.add_argument('--output-file', metavar='<path>',
            type=str, required=True,
            help='output OpenCL C header')

    args = parser.parse_args()

    # Add some customs builtins.
    with open(args.output_file, "a") as output:
        output.write("\n");
        output.write("\nfloat4 __attribute((overloadable)) __clspv_vloada_half4(size_t, const __global uint2*);")
        output.write("\nfloat4 __attribute((overloadable)) __clspv_vloada_half4(size_t, const __local uint2*);")
        output.write("\nfloat4 __attribute((overloadable)) __clspv_vloada_half4(size_t, const __private uint2*);")
        output.write("\nfloat2 __attribute((overloadable)) __clspv_vloada_half2(size_t, const __global uint*);")
        output.write("\nfloat2 __attribute((overloadable)) __clspv_vloada_half2(size_t, const __local uint*);")
        output.write("\nfloat2 __attribute((overloadable)) __clspv_vloada_half2(size_t, const __private uint*);")
        output.write("\n");
        # Define the OpenCL 2.0 work_group_barrier alias.
        output.write("\n#if !defined(__OPENCL_CPP_VERSION__) && (__OPENCL_C_VERSION__ < CL_VERSION_2_0)\n")
        output.write("#define __ovld __attribute__((overloadable))\n")
        output.write("#define __conv __attribute__((convergent))\n")
        output.write("void __ovld __conv work_group_barrier(cl_mem_fence_flags flags);\n")
        output.write("#undef __ovld\n")
        output.write("#undef __conv\n")
        output.write("#endif\n");

if __name__ == '__main__':
    main()
