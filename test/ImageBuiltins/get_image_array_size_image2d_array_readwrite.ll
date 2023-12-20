; RUN: clspv-opt %s -o %t.ll --passes=spirv-producer -producer-out-file %t.spv
; RUN: spirv-dis -o %t2.spvasm %t.spv
; RUN: FileCheck %s < %t2.spvasm
; RUN: spirv-val %t.spv

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

declare spir_func i32 @_Z20get_image_array_size31opencl.image2d_array_rw_t.float(target("spirv.Image", float, 1, 0, 1, 0, 2, 0, 2, 0))

define spir_kernel void @foo(ptr addrspace(1) %out, target("spirv.Image", float, 1, 0, 1, 0, 2, 0, 2, 0) %img) {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i32] } zeroinitializer)
  %1 = getelementptr { [0 x i32] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %2 = call target("spirv.Image", float, 1, 0, 1, 0, 2, 0, 2, 0) @_Z14clspv.resource.1(i32 0, i32 1, i32 7, i32 1, i32 1, i32 0, target("spirv.Image", float, 1, 0, 1, 0, 2, 0, 2, 0) undef)
  %call = tail call spir_func i32 @_Z20get_image_array_size31opencl.image2d_array_rw_t.float(target("spirv.Image", float, 1, 0, 1, 0, 2, 0, 2, 0) %2)
  store i32 %call, ptr addrspace(1) %1, align 4
  ret void
}

declare target("spirv.Image", float, 1, 0, 1, 0, 2, 0, 2, 0) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, target("spirv.Image", float, 1, 0, 1, 0, 2, 0, 2, 0))
declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i32] })

; CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
; CHECK-DAG: [[v3uint:%[^ ]+]] = OpTypeVector [[uint]] 3
; CHECK-DAG: [[float:%[^ ]+]] = OpTypeFloat 32
; CHECK-DAG: [[imgTy:%[^ ]+]] = OpTypeImage [[float]] 2D 0 1 0 2 Unknown
; CHECK:     [[load:%[^ ]+]] = OpLoad [[imgTy]]
; CHECK:     [[imgQuery:%[^ ]+]] = OpImageQuerySize [[v3uint]] [[load]]
; CHECK:     [[arraySize:%[^ ]+]] = OpCompositeExtract [[uint]] [[imgQuery]] 2
; CHECK:     OpStore {{.*}} [[arraySize]]
