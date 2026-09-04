; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t.ll
; RUN: FileCheck %s < %t.ll

; CHECK-LABEL: define dso_local spir_func ptr @test_copy(
; CHECK: [[zext_n:%[a-zA-Z0-9_.]+]] = zext i32 %num_gentypes to i64
; CHECK: [[phi_n:%[a-zA-Z0-9_.]+]] = phi i64 [
; CHECK: icmp ult i64 [[phi_n]], [[zext_n]]

; CHECK-LABEL: define dso_local spir_func ptr @test_strided_copy(
; CHECK: [[zext_stride_n:%[a-zA-Z0-9_.]+]] = zext i32 %num_gentypes to i64
; CHECK: [[zext_stride:%[a-zA-Z0-9_.]+]] = zext i32 %stride to i64
; CHECK: [[phi_s:%[a-zA-Z0-9_.]+]] = phi i64 [
; CHECK: icmp ult i64 [[phi_s]], [[zext_stride_n]]
; CHECK: mul i64 [[phi_s]], [[zext_stride]]

target datalayout = "e-p:64:64-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv64-unknown-vulkan"

define dso_local spir_func ptr @test_copy(ptr addrspace(3) %dst, ptr addrspace(1) %src, i32 %num_gentypes, ptr %event) {
entry:
  %call = call spir_func ptr @_Z21async_work_group_copyPU3AS3iPU3AS1Kij9ocl_event(ptr addrspace(3) %dst, ptr addrspace(1) %src, i32 %num_gentypes, ptr %event)
  ret ptr %call
}

define dso_local spir_func ptr @test_strided_copy(ptr addrspace(3) %dst, ptr addrspace(1) %src, i32 %num_gentypes, i32 %stride, ptr %event) {
entry:
  %call = call spir_func ptr @_Z29async_work_group_strided_copyPU3AS3iPU3AS1Kijj9ocl_event(ptr addrspace(3) %dst, ptr addrspace(1) %src, i32 %num_gentypes, i32 %stride, ptr %event)
  ret ptr %call
}

declare spir_func ptr @_Z21async_work_group_copyPU3AS3iPU3AS1Kij9ocl_event(ptr addrspace(3), ptr addrspace(1), i32, ptr)
declare spir_func ptr @_Z29async_work_group_strided_copyPU3AS3iPU3AS1Kijj9ocl_event(ptr addrspace(3), ptr addrspace(1), i32, i32, ptr)
