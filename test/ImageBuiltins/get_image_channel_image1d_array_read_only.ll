
; RUN: clspv-opt %s -o %t.ll --passes=set-image-metadata
; RUN: FileCheck %s < %t.ll

; AUTO-GENERATED TEST FILE
; This test was generated by get_image_channel_test_gen.py.
; Please modify that file and regenate the tests to make changes.

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

declare spir_func i32 @_Z23get_image_channel_order45opencl.image1d_array_ro_t.float.sampled(ptr addrspace(1) %0)

declare spir_func i32 @_Z27get_image_channel_data_type45opencl.image1d_array_ro_t.float.sampled(ptr addrspace(1) %0)

define spir_kernel void @order(ptr addrspace(1) writeonly align 4 %dst, ptr addrspace(1) %image) {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i32] } zeroinitializer)
  %1 = getelementptr { [0 x i32] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %2 = call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 6, i32 1, i32 1, i32 0, target("spirv.Image", 0, 0, 1, 0, 1, 0, 0, 0) undef)
  %call = tail call spir_func i32 @_Z23get_image_channel_order45opencl.image1d_array_ro_t.float.sampled(ptr addrspace(1) %2)
  store i32 %call, ptr addrspace(1) %1, align 4
  ret void
}

define spir_kernel void @data_type(ptr addrspace(1) writeonly align 4 %dst, ptr addrspace(1) %image) {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i32] } zeroinitializer)
  %1 = getelementptr { [0 x i32] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %2 = call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 6, i32 1, i32 1, i32 0, target("spirv.Image", 0, 0, 1, 0, 1, 0, 0, 0) undef)
  %call = tail call spir_func i32 @_Z27get_image_channel_data_type45opencl.image1d_array_ro_t.float.sampled(ptr addrspace(1) %2)
  store i32 %call, ptr addrspace(1) %1, align 4
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5, { [0 x i32] } %6)

declare ptr addrspace(1) @_Z14clspv.resource.1(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5, target("spirv.Image", 0, 0, 1, 0, 1, 0, 0, 0) %6)

; CHECK: @__push_constants = addrspace(9) global %0 zeroinitializer, !push_constants [[pc:![^ ]+]]

; CHECK: define spir_kernel void @order(ptr addrspace(1) writeonly align 4 {{.*}}, ptr addrspace(1) {{.*}}) !push_constants_image_channel [[order_kernel:![^ ]+]]
; CHECK: tail call spir_func i32 @_Z23get_image_channel_order45opencl.image1d_array_ro_t.float.sampled(ptr addrspace(1) {{.*}}), !image_getter_push_constant_offset [[call:![^ ]+]]

; CHECK: define spir_kernel void @data_type(ptr addrspace(1) writeonly align 4 {{.*}}, ptr addrspace(1) {{.*}}) !push_constants_image_channel [[data_type_kernel:![^ ]+]]
; CHECK: tail call spir_func i32 @_Z27get_image_channel_data_type45opencl.image1d_array_ro_t.float.sampled(ptr addrspace(1) {{.*}}), !image_getter_push_constant_offset [[call:![^ ]+]]

; CHECK: [[pc]] = !{i32 {{.*}}}
; CHECK: [[order_kernel]] = !{i32 [[ordinal:[^ ]+]], i32 [[order_offset:[^ ]+]], i32 [[order_pc:[^ ]+]]}
; CHECK: [[call]] = !{i32 0}
; CHECK: [[data_type_kernel]] = !{i32 [[ordinal:[^ ]+]], i32 0, i32 [[data_type_pc:[^ ]+]]}
