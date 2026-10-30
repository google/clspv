; RUN: clspv-opt %s -o %t.ll --passes=allocate-descriptors
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spirv32-unknown-vulkan"

%struct.Holder = type { i32, [2 x ptr addrspace(1)] }

; CHECK-LABEL: define spir_kernel void @test_helper_arg_container(
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x float] } zeroinitializer)

define dso_local spir_func float @read_from_container(ptr %arr, i32 %idx) {
entry:
  %slot = getelementptr [2 x ptr addrspace(1)], ptr %arr, i32 0, i32 %idx
  %ld_ptr = load ptr addrspace(1), ptr %slot, align 4
  %val = load float, ptr addrspace(1) %ld_ptr, align 4
  ret float %val
}

define spir_kernel void @test_helper_arg_container(ptr addrspace(1) %buf, ptr addrspace(1) %out, i32 %idx) !clspv.pod_args_impl !0 {
entry:
  %arr = alloca [2 x ptr addrspace(1)], align 4
  %s0 = getelementptr [2 x ptr addrspace(1)], ptr %arr, i32 0, i32 0
  store ptr addrspace(1) %buf, ptr %s0, align 4
  %val = call spir_func float @read_from_container(ptr %arr, i32 %idx)
  store float %val, ptr addrspace(1) %out, align 4
  ret void
}

; Direct store/load on a scalar pointer alloca without GEPs.
; CHECK-LABEL: define spir_kernel void @test_direct_ptr_alloca(
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.3(i32 0, i32 0, i32 0, i32 0, i32 3, i32 0, { [0 x i32] } zeroinitializer)

define spir_kernel void @test_direct_ptr_alloca(ptr addrspace(1) %in, ptr addrspace(1) %out) !clspv.pod_args_impl !0 {
entry:
  %slot = alloca ptr addrspace(1), align 4
  store ptr addrspace(1) %in, ptr %slot, align 4
  %ld = load ptr addrspace(1), ptr %slot, align 4
  %v = load i32, ptr addrspace(1) %ld, align 4
  store i32 %v, ptr addrspace(1) %out, align 4
  ret void
}

; Store via nested GEPs into a struct container that also has non-pointer loads,
; and pass the nested array across chained helper calls.
; CHECK-LABEL: define spir_kernel void @test_nested_struct_and_chained_calls(
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.5(i32 0, i32 0, i32 0, i32 0, i32 5, i32 0, { [0 x <4 x float>] } zeroinitializer)

define dso_local spir_func <4 x float> @leaf_load(ptr %sub_arr, i32 %idx) {
entry:
  %p = getelementptr ptr addrspace(1), ptr %sub_arr, i32 %idx
  %ld_ptr = load ptr addrspace(1), ptr %p, align 4
  %elt = getelementptr <4 x float>, ptr addrspace(1) %ld_ptr, i32 %idx
  %v = load <4 x float>, ptr addrspace(1) %elt, align 16
  ret <4 x float> %v
}

define dso_local spir_func <4 x float> @mid_forward(ptr %holder, i32 %idx) {
entry:
  %count_ptr = getelementptr %struct.Holder, ptr %holder, i32 0, i32 0
  %count = load i32, ptr %count_ptr, align 4
  %arr_ptr = getelementptr %struct.Holder, ptr %holder, i32 0, i32 1, i32 0
  %sum_idx = add i32 %idx, %count
  %res = call spir_func <4 x float> @leaf_load(ptr %arr_ptr, i32 %sum_idx)
  ret <4 x float> %res
}

define spir_kernel void @test_nested_struct_and_chained_calls(ptr addrspace(1) %vec_buf, ptr addrspace(1) %out, i32 %idx) !clspv.pod_args_impl !0 {
entry:
  %h = alloca %struct.Holder, align 4
  %cnt = getelementptr %struct.Holder, ptr %h, i32 0, i32 0
  store i32 0, ptr %cnt, align 4
  %arr = getelementptr %struct.Holder, ptr %h, i32 0, i32 1
  %s1 = getelementptr [2 x ptr addrspace(1)], ptr %arr, i32 0, i32 1
  store ptr addrspace(1) %vec_buf, ptr %s1, align 4
  %v = call spir_func <4 x float> @mid_forward(ptr %h, i32 %idx)
  store <4 x float> %v, ptr addrspace(1) %out, align 16
  ret void
}

!0 = !{i32 2}
