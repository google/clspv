
; RUN: clspv-opt -ReplaceOpenCLBuiltin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.event_t = type opaque

define dso_local spir_kernel void @foo() {
entry:
  %e = alloca %opencl.event_t*, align 4
  store %opencl.event_t* null, %opencl.event_t** %e, align 4
  call spir_func void @_Z17wait_group_eventsiP9ocl_event(i32 1, %opencl.event_t** %e)
  ret void
}

declare spir_func void @_Z17wait_group_eventsiP9ocl_event(i32, %opencl.event_t**)

; CHECK: [[tmp1:%[a-zA-Z0-9_.]+]] = shl i32 1, 8
; CHECK: [[tmp2:%[a-zA-Z0-9_.]+]] = or i32 [[tmp1]], 8
; CHECK: call void @_Z8spirv.op.224.jjj(i32 224, i32 2, i32 2, i32 [[tmp2]])