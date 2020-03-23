; RUN: clspv-opt -AddFunctionAttributes %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; CHECK: declare %opencl.sampler_t addrspace(2)* @__translate_sampler_initializer(i32) [[ATTR:#[0-9]+]]
; CHECK: attributes [[ATTR]] = { readnone speculatable }

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.sampler_t = type opaque

declare %opencl.sampler_t addrspace(2)* @__translate_sampler_initializer(i32)

