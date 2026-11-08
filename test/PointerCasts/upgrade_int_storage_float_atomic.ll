; RUN: clspv-opt %s -o %t.ll --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; Floating-point atomics on storage declared with a same-sized integer type
; must retype the storage, otherwise the SPIR-V atomic pointer type does not
; match its result type.

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

; CHECK-DAG: @scalar = internal addrspace(3) global float undef, align 4
; CHECK-DAG: @array = internal addrspace(3) global [4 x float] undef, align 4
; CHECK-DAG: @mixed = internal addrspace(3) global [1 x i32] undef, align 4
@scalar = internal addrspace(3) global [1 x i32] undef, align 4
@array = internal addrspace(3) global [4 x i32] undef, align 4
@mixed = internal addrspace(3) global [1 x i32] undef, align 4

; CHECK-LABEL: define spir_kernel void @fadd_scalar(
; CHECK: call float @_Z8spirv.op.6035.PU3AS3fjjf(i32 6035, ptr addrspace(3) @scalar, i32 2, i32 0, float %v)
define spir_kernel void @fadd_scalar(float %v) {
entry:
  %old = call float @_Z8spirv.op.6035.PU3AS3fjjf(i32 6035, ptr addrspace(3) @scalar, i32 2, i32 0, float %v)
  ret void
}

; CHECK-LABEL: define spir_kernel void @fadd_array(
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr float, ptr addrspace(3) @array, i32 %idx
; CHECK: call float @_Z8spirv.op.6035.PU3AS3fjjf(i32 6035, ptr addrspace(3) [[gep]], i32 2, i32 0, float %v)
define spir_kernel void @fadd_array(float %v, i32 %idx) {
entry:
  %gep = getelementptr i32, ptr addrspace(3) @array, i32 %idx
  %old = call float @_Z8spirv.op.6035.PU3AS3fjjf(i32 6035, ptr addrspace(3) %gep, i32 2, i32 0, float %v)
  ret void
}

; Storage also used by integer atomics is left as integer, so that the integer
; and floating-point retyping rules do not undo each other.
; CHECK-LABEL: define spir_kernel void @mixed_int_and_float(
; CHECK: call i32 @_Z8spirv.op.234.PU3AS3jjjj(i32 234, ptr addrspace(3) {{.*}}, i32 2, i32 0, i32 1)
define spir_kernel void @mixed_int_and_float(float %v) {
entry:
  %oldf = call float @_Z8spirv.op.6035.PU3AS3fjjf(i32 6035, ptr addrspace(3) @mixed, i32 2, i32 0, float %v)
  %oldi = call i32 @_Z8spirv.op.234.PU3AS3jjjj(i32 234, ptr addrspace(3) @mixed, i32 2, i32 0, i32 1)
  ret void
}

declare float @_Z8spirv.op.6035.PU3AS3fjjf(i32, ptr addrspace(3), i32, i32, float)
declare i32 @_Z8spirv.op.234.PU3AS3jjjj(i32, ptr addrspace(3), i32, i32, i32)
