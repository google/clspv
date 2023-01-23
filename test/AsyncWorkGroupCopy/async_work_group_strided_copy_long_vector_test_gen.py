#!/usr/bin/env python3

# Copyright 2020 The Clspv Authors. All rights reserved.
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

from string import Template
import os

TEMPLATE=Template("""
; RUN: clspv-opt --passes=replace-opencl-builtin,long-vector-lowering %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; AUTO-GENERATED TEST FILE
; This test was generated by ${test_gen_file}.
; Please modify that file and regenate the tests to make changes.

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

${spirv_variables}

define dso_local spir_func ptr @foo(ptr addrspace(${dst_addrspace}) %dst, ptr addrspace(${src_addrspace}) %src, i32 %num_gentypes, i32 %stride, ptr %event) {
entry:
  %call = call spir_func ptr @_Z29async_work_group_strided_copy${async_mangling}jj9ocl_event(ptr addrspace(${dst_addrspace}) %dst, ptr addrspace(${src_addrspace}) %src, i32 %num_gentypes, i32 %stride, ptr %event)
  ret ptr %call
}

declare spir_func ptr @_Z29async_work_group_strided_copy${async_mangling}jj9ocl_event(ptr addrspace(${dst_addrspace}), ptr addrspace(${src_addrspace}), i32, i32, ptr)

; CHECK: [[localid0:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(5) @__spirv_LocalInvocationId, align
; CHECK: [[gep:%[^ ]+]] = getelementptr <3 x i32>, ptr addrspace(5) @__spirv_LocalInvocationId, i32 0, i32 1
; CHECK: [[localid1:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(5) [[gep]], align
; CHECK: [[gep:%[^ ]+]] = getelementptr <3 x i32>, ptr addrspace(5) @__spirv_LocalInvocationId, i32 0, i32 2
; CHECK: [[localid2:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(5) [[gep]], align
; CHECK: [[groupsizevec:%[a-zA-Z0-9_.]+]] = load <3 x i32>, ptr addrspace(8) @__spirv_WorkgroupSize, align 16
; CHECK: [[groupsize0:%[a-zA-Z0-9_.]+]] = extractelement <3 x i32> [[groupsizevec]], i32 0
; CHECK: [[groupsize1:%[a-zA-Z0-9_.]+]] = extractelement <3 x i32> [[groupsizevec]], i32 1
; CHECK: [[groupsize2:%[a-zA-Z0-9_.]+]] = extractelement <3 x i32> [[groupsizevec]], i32 2
; CHECK: [[tmp7:%[a-zA-Z0-9_.]+]] = mul i32 [[localid2]], [[groupsize1]]
; CHECK: [[tmp8:%[a-zA-Z0-9_.]+]] = add i32 [[tmp7]], [[localid1]]
; CHECK: [[tmp9:%[a-zA-Z0-9_.]+]] = mul i32 [[tmp8]], [[groupsize0]]
; CHECK: [[startid:%[a-zA-Z0-9_.]+]] = add i32 [[tmp9]], [[localid0]]
; CHECK: [[tmp11:%[a-zA-Z0-9_.]+]] = mul i32 [[groupsize0]], [[groupsize1]]
; CHECK: [[incr:%[a-zA-Z0-9_.]+]] = mul i32 [[tmp11]], [[groupsize2]]
; CHECK: br label %[[cmp:[a-zA-Z0-9_.]+]]
; CHECK: [[cmp]]:
; CHECK: [[phiiterator:%[a-zA-Z0-9_.]+]] = phi i32 [ [[startid]], %[[entry:[a-zA-Z0-9_.]+]] ], [ [[nextiterator:%[a-zA-Z0-9_.]+]], %[[loop:[a-zA-Z0-9_.]+]] ]
; CHECK: [[icmp:%[a-zA-Z0-9_.]+]] = icmp ult i32 [[phiiterator]], %num_gentypes
; CHECK: br i1 [[icmp]], label %[[loop]], label %[[exit:[a-zA-Z0-9_.]+]]
; CHECK: [[loop]]:
${stride_block}
; CHECK: [[nextiterator]] = add i32 [[phiiterator]], [[incr]]
${copy_memory}
; CHECK: br label %[[cmp]]
""")

STRIDE_DST_TEMPLATE=Template("""
; CHECK: [[dstiterator:%[a-zA-Z0-9_.]+]] = mul i32 [[phiiterator]], %stride
; CHECK: [[dsti:%[a-zA-Z0-9_.]+]] = getelementptr ${type}, ptr addrspace(${dst_addrspace}) %dst, i32 [[dstiterator]]
; CHECK: [[srci:%[a-zA-Z0-9_.]+]] = getelementptr ${type}, ptr addrspace(${src_addrspace}) %src, i32 [[phiiterator]]
""")
STRIDE_SRC_TEMPLATE=Template("""
; CHECK: [[srciterator:%[a-zA-Z0-9_.]+]] = mul i32 [[phiiterator]], %stride
; CHECK: [[dsti:%[a-zA-Z0-9_.]+]] = getelementptr ${type}, ptr addrspace(${dst_addrspace}) %dst, i32 [[phiiterator]]
; CHECK: [[srci:%[a-zA-Z0-9_.]+]] = getelementptr ${type}, ptr addrspace(${src_addrspace}) %src, i32 [[srciterator]]
""")

COPY_MEMORY=Template("""
; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load ${check_type}, ptr addrspace(${src_addrspace}) [[srci]]
; CHECK: store ${check_type} [[ld]], ptr addrspace(${dst_addrspace}) [[dsti]]
""")

SPIRV_VARIABLES="""
@__spirv_LocalInvocationId = local_unnamed_addr addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer
"""

WIDTHS=[8, 16, 32, 64]
VECTOR_SIZES=[8, 16]
GLOBAL_ADDRSPACE='global'
LOCAL_ADDRSPACE='local'
ADDRESS_SPACE={GLOBAL_ADDRSPACE: '1', LOCAL_ADDRSPACE : '3'}
TYPE_MANGLING={'unsigned': {8: 'h', 16: 't', 32: 'j', 64: 'm'}, 'signed': {8: 'c', 16: 's', 32: 'i', 64: 'l'} }

def get_scalar_type(width):
    return 'i' + str(width)

def get_type(width, vector_size):
        return '<' + str(vector_size) + ' x ' + get_scalar_type(width) + '>'

def get_check_type(width, vector_size):
    return '[' + str(vector_size) + ' x ' + str(get_scalar_type(width)) + ']'

def get_type_mangling(width, vector_size, signed):
    if vector_size > 1:
        return 'Dv' + str(vector_size) + '_' + TYPE_MANGLING[signed][width]
    else:
        return TYPE_MANGLING[signed][width]

def get_addr_mangling(addrspace):
    return 'PU3AS' + ADDRESS_SPACE[addrspace]

def get_async_mangling_suffix(width, vector_size):
    if vector_size > 1:
        return 'KS_'
    else:
        return 'K' + TYPE_MANGLING['signed'][width]

def get_async_mangling(dst, src, width, vector_size):
    return get_addr_mangling(dst) + get_type_mangling(width, vector_size, 'signed') \
        + get_addr_mangling(src) + get_async_mangling_suffix(width, vector_size)

def get_copy_memory(check_type, dst_addrspace, src_addrspace, vector_size, width):
    copy_memory = COPY_MEMORY.substitute(
            id = str(id),
            check_type = check_type,
            src_addrspace = src_addrspace,
            dst_addrspace = dst_addrspace)
    return copy_memory

def generate_one(dst, src, width, vector_size, spirv_variables):
    type_ = get_type(width, vector_size)
    check_type_ = get_check_type(width, vector_size)
    if src == GLOBAL_ADDRSPACE:
        stride_block = STRIDE_SRC_TEMPLATE.substitute(type = check_type_,
                                                      dst_addrspace = ADDRESS_SPACE[dst],
                                                      src_addrspace = ADDRESS_SPACE[src])
    else:
        stride_block = STRIDE_DST_TEMPLATE.substitute(type = check_type_,
                                                      dst_addrspace = ADDRESS_SPACE[dst],
                                                      src_addrspace = ADDRESS_SPACE[src])

    template = TEMPLATE.substitute(test_gen_file = os.path.basename(__file__),
                                   type = get_type(width, vector_size),
                                   dst_addrspace = ADDRESS_SPACE[dst],
                                   src_addrspace = ADDRESS_SPACE[src],
                                   spirv_variables = SPIRV_VARIABLES if spirv_variables else "",
                                   async_mangling = get_async_mangling(dst, src, width, vector_size),
                                   stride_block = stride_block,
                                   copy_memory = get_copy_memory(
                                       check_type_,
                                       ADDRESS_SPACE[dst],
                                       ADDRESS_SPACE[src],
                                       vector_size,
                                       width))
    filename = 'async_work_group_strided_copy' +  '_v' + str(vector_size) + get_scalar_type(width) \
        + '_' + src + '_to_' + dst \
        + ('_explicit_spirv_variables' if spirv_variables else '') + '.ll'
    with open(filename, 'w') as file:
        file.write(template)

def generate(dst, src, spirv_variables):
    for width in WIDTHS:
        for vector_size in VECTOR_SIZES:
            generate_one(dst, src, width, vector_size, spirv_variables)

generate(dst = GLOBAL_ADDRSPACE, src = LOCAL_ADDRSPACE, spirv_variables = True)
generate(dst = GLOBAL_ADDRSPACE, src = LOCAL_ADDRSPACE, spirv_variables = False)
generate(dst = LOCAL_ADDRSPACE, src = GLOBAL_ADDRSPACE, spirv_variables = True)
generate(dst = LOCAL_ADDRSPACE, src = GLOBAL_ADDRSPACE, spirv_variables = False)

