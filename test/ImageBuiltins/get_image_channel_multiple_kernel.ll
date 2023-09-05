; RUN: clspv-opt %s -o %t.ll --passes=set-image-metadata
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.image1d_ro_t.float.sampled = type opaque

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

declare spir_func i32 @_Z23get_image_channel_order33opencl.image1d_ro_t.float.sampled(ptr addrspace(1) %0)

declare spir_func i32 @_Z27get_image_channel_data_type33opencl.image1d_ro_t.float.sampled(ptr addrspace(1) %0)

define spir_kernel void @fct0(ptr addrspace(1) nocapture writeonly align 4 %dst, ptr addrspace(1) %image, { i32 } %podargs) {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i32] } zeroinitializer)
  %1 = getelementptr { [0 x i32] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %2 = call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 6, i32 1, i32 1, i32 0, %opencl.image1d_ro_t.float.sampled zeroinitializer)
  %3 = call ptr addrspace(9) @_Z14clspv.resource.2(i32 -1, i32 2, i32 5, i32 2, i32 2, i32 0, { { i32 } } zeroinitializer)
  %4 = getelementptr { { i32 } }, ptr addrspace(9) %3, i32 0, i32 0
  %5 = load { i32 }, ptr addrspace(9) %4, align 4
  %off = extractvalue { i32 } %5, 0
  %call.i = tail call spir_func i32 @_Z23get_image_channel_order33opencl.image1d_ro_t.float.sampled(ptr addrspace(1) %2)
  %add.i = add nsw i32 %call.i, %off
  store i32 %add.i, ptr addrspace(1) %1, align 4
  ret void
}

define spir_kernel void @fct1(ptr addrspace(1) nocapture writeonly align 4 %dst, ptr addrspace(1) %image, { i32 } %podargs) {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i32] } zeroinitializer)
  %1 = getelementptr { [0 x i32] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %2 = call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 6, i32 1, i32 1, i32 0, %opencl.image1d_ro_t.float.sampled zeroinitializer)
  %3 = call ptr addrspace(9) @_Z14clspv.resource.2(i32 -1, i32 2, i32 5, i32 2, i32 2, i32 0, { { i32 } } zeroinitializer)
  %4 = getelementptr { { i32 } }, ptr addrspace(9) %3, i32 0, i32 0
  %5 = load { i32 }, ptr addrspace(9) %4, align 4
  %off = extractvalue { i32 } %5, 0
  %call.i = tail call spir_func i32 @_Z27get_image_channel_data_type33opencl.image1d_ro_t.float.sampled(ptr addrspace(1) %2)
  %add.i = add nsw i32 %call.i, %off
  store i32 %add.i, ptr addrspace(1) %1, align 4
  ret void
}

define spir_kernel void @fct2(ptr addrspace(1) nocapture writeonly align 4 %dst, ptr addrspace(1) %image1, ptr addrspace(1) %image2, { i32 } %podargs) {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i32] } zeroinitializer)
  %1 = getelementptr { [0 x i32] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %2 = call ptr addrspace(1) @_Z14clspv.resource.1(i32 0, i32 1, i32 6, i32 1, i32 1, i32 0, %opencl.image1d_ro_t.float.sampled zeroinitializer)
  %3 = call ptr addrspace(1) @_Z14clspv.resource.3(i32 0, i32 2, i32 6, i32 2, i32 3, i32 0, %opencl.image1d_ro_t.float.sampled zeroinitializer)
  %4 = call ptr addrspace(9) @_Z14clspv.resource.4(i32 -1, i32 3, i32 5, i32 3, i32 4, i32 0, { { i32 } } zeroinitializer)
  %5 = getelementptr { { i32 } }, ptr addrspace(9) %4, i32 0, i32 0
  %6 = load { i32 }, ptr addrspace(9) %5, align 4
  %off = extractvalue { i32 } %6, 0
  %call.i = tail call spir_func i32 @_Z23get_image_channel_order33opencl.image1d_ro_t.float.sampled(ptr addrspace(1) %2)
  %call1.i = tail call spir_func i32 @_Z23get_image_channel_order33opencl.image1d_ro_t.float.sampled(ptr addrspace(1) %3)
  %call2.i = tail call spir_func i32 @_Z27get_image_channel_data_type33opencl.image1d_ro_t.float.sampled(ptr addrspace(1) %2)
  %call4.i = tail call spir_func i32 @_Z27get_image_channel_data_type33opencl.image1d_ro_t.float.sampled(ptr addrspace(1) %3)
  %add.i = add i32 %call.i, %off
  %add3.i = add i32 %add.i, %call1.i
  %add5.i = add i32 %add3.i, %call2.i
  %add6.i = add i32 %add5.i, %call4.i
  store i32 %add6.i, ptr addrspace(1) %1, align 4
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5, { [0 x i32] } %6)

declare ptr addrspace(1) @_Z14clspv.resource.1(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5, %opencl.image1d_ro_t.float.sampled %6)

declare ptr addrspace(9) @_Z14clspv.resource.2(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5, { { i32 } } %6)

declare ptr addrspace(1) @_Z14clspv.resource.3(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5, %opencl.image1d_ro_t.float.sampled %6)

declare ptr addrspace(9) @_Z14clspv.resource.4(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5, { { i32 } } %6)

; CHECK: @__push_constants = addrspace(9) global %0 zeroinitializer, !push_constants [[pc:![^ ]+]]

; CHECK: define spir_kernel void @fct0(ptr addrspace(1) nocapture writeonly align 4 %dst, ptr addrspace(1) %image, { i32 } %podargs) !push_constants_image_channel [[fct0_kernel:![^ ]+]]
; CHECK: tail call spir_func i32 @_Z23get_image_channel_order33opencl.image1d_ro_t.float.sampled(ptr addrspace(1) %2), !image_getter_push_constant_offset [[call0:![^ ]+]]

; CHECK: define spir_kernel void @fct1(ptr addrspace(1) nocapture writeonly align 4 %dst, ptr addrspace(1) %image, { i32 } %podargs) !push_constants_image_channel [[fct1_kernel:![^ ]+]]
; CHECK: tail call spir_func i32 @_Z27get_image_channel_data_type33opencl.image1d_ro_t.float.sampled(ptr addrspace(1) %2), !image_getter_push_constant_offset [[call0:![^ ]+]]

; CHECK: define spir_kernel void @fct2(ptr addrspace(1) nocapture writeonly align 4 %dst, ptr addrspace(1) %image1, ptr addrspace(1) %image2, { i32 } %podargs) !push_constants_image_channel [[fct2_kernel:![^ ]+]]

; CHECK-DAG: tail call spir_func i32 @_Z23get_image_channel_order33opencl.image1d_ro_t.float.sampled(ptr addrspace(1) %2), !image_getter_push_constant_offset [[call0:![^ ]+]]
; CHECK-DAG: tail call spir_func i32 @_Z23get_image_channel_order33opencl.image1d_ro_t.float.sampled(ptr addrspace(1) %3), !image_getter_push_constant_offset [[call1:![^ ]+]]
; CHECK-DAG: tail call spir_func i32 @_Z27get_image_channel_data_type33opencl.image1d_ro_t.float.sampled(ptr addrspace(1) %2), !image_getter_push_constant_offset [[call2:![^ ]+]]
; CHECK-DAG: tail call spir_func i32 @_Z27get_image_channel_data_type33opencl.image1d_ro_t.float.sampled(ptr addrspace(1) %3), !image_getter_push_constant_offset [[call3:![^ ]+]]

; CHECK-DAG: [[pc]] = !{i32 8}
; CHECK-DAG: [[fct0_kernel]] = !{i32 1, i32 0, i32 0}
; CHECK-DAG: [[fct1_kernel]] = !{i32 1, i32 0, i32 1}
; CHECK-DAG: [[fct2_kernel]] = !{i32 2, i32 3, i32 1, i32 1, i32 2, i32 1, i32 2, i32 1, i32 0, i32 1, i32 0, i32 0}
