; RUN: clspv-opt %s -o %t.ll --passes=spirv-producer -producer-out-file %t.spv
; RUN: spirv-dis -o %t2.spvasm %t.spv
; RUN: FileCheck %s < %t2.spvasm
; RUN: spirv-val %t.spv

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.image1d_array_ro_t.float.sampled = type opaque

declare spir_func i32 @_Z20get_image_array_size39opencl.image1d_array_ro_t.float.sampled(%opencl.image1d_array_ro_t.float.sampled addrspace(1)*)

define spir_kernel void @foo(i32 addrspace(1)* nocapture writeonly align 4 %out, %opencl.image1d_array_ro_t.float.sampled addrspace(1)* %img) {
entry:
  %0 = call { [0 x i32] } addrspace(1)* @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i32] } zeroinitializer)
  %1 = getelementptr { [0 x i32] }, { [0 x i32] } addrspace(1)* %0, i32 0, i32 0, i32 0
  %2 = call %opencl.image1d_array_ro_t.float.sampled addrspace(1)* @_Z14clspv.resource.1(i32 0, i32 1, i32 6, i32 1, i32 1, i32 0, %opencl.image1d_array_ro_t.float.sampled zeroinitializer)
  %call = tail call spir_func i32 @_Z20get_image_array_size39opencl.image1d_array_ro_t.float.sampled(%opencl.image1d_array_ro_t.float.sampled addrspace(1)* %2)
  store i32 %call, i32 addrspace(1)* %1, align 4
  ret void
}

declare { [0 x i32] } addrspace(1)* @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i32] })

declare %opencl.image1d_array_ro_t.float.sampled addrspace(1)* @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, %opencl.image1d_array_ro_t.float.sampled)

; CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
; CHECK-DAG: [[v2uint:%[^ ]+]] = OpTypeVector [[uint]] 2
; CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
; CHECK-DAG: [[imgTy:%[^ ]+]] = OpTypeImage [[float]] 1D 0 1 0 1 Unknown
; CHECK-DAG: [[uint_0:%[^ ]+]] = OpConstant [[uint]] 0
; CHECK:     [[load:%[^ ]+]] = OpLoad [[imgTy]]
; CHECK:     [[imgQuery:%[^ ]+]] = OpImageQuerySizeLod [[v2uint]] [[load]] [[uint_0]]
; CHECK:     [[arraySize:%[^ ]+]] = OpCompositeExtract [[uint]] [[imgQuery]] 1
; CHECK:     OpStore {{.*}} [[arraySize]]
