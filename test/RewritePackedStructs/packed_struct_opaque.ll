; RUN: clspv-opt --passes=rewrite-packed-structs --opaque-pointers %s -o %t
; RUN: FileCheck %s < %t

%struct = type <{ i32, i8 }>

define spir_kernel void @test(ptr addrspace(1) nocapture %in) {
  %1 = call spir_func i32 @_Z13get_global_idj(i32 0)
  %2 = getelementptr inbounds %struct, ptr addrspace(1) %in, i32 %1
  store %struct <{ i32 2100483600, i8 127 }>, ptr addrspace(1) %2
  ret void
}

declare spir_func i32 @_Z13get_global_idj(i32)

; CHECK: define spir_kernel void @test(ptr addrspace(1) nocapture %in) {
; CHECK: [[allocated_tmp_struct_ptr:%[_a-zA-Z0-9]+]] = alloca %struct, align 8, addrspace(1)
; CHECK: store <{ [5 x i8] }> zeroinitializer, ptr addrspace(1) %in, align 1
; CHECK: [[idx:%[_a-zA-Z0-9]+]] = call spir_func i32 @_Z13get_global_idj(i32 0)
; CHECK: [[tmp_struct_ptr:%[_a-zA-Z0-9]+]] = getelementptr inbounds %struct, ptr addrspace(1) [[allocated_tmp_struct_ptr]], i32 [[idx]]
; CHECK: store %struct <{ i32 2100483600, i8 127 }>, ptr addrspace(1) [[tmp_struct_ptr]], align 1

; CHECK: [[tmp_struct:%[_a-zA-Z0-9]+]] = load %struct, ptr addrspace(1) [[allocated_tmp_struct_ptr]], align 1

; CHECK: [[tmp_struct_value1:%[_a-zA-Z0-9]+]] = extractvalue %struct [[tmp_struct]], 0
; CHECK: [[tmp_struct_value1_vec:%[_a-zA-Z0-9]+]] = bitcast i32 [[tmp_struct_value1]] to <4 x i8>
; CHECK: [[tmp_struct_value1_vec_element1:%[_a-zA-Z0-9]+]] = extractelement <4 x i8> [[tmp_struct_value1_vec]], i64 0
; CHECK: [[input_buffer_struct_value1_ptr:%[_a-zA-Z0-9]+]] = getelementptr <{ [5 x i8] }>, ptr addrspace(1) %in, i32 0, i32 0, i32 0
; CHECK: store i8 [[tmp_struct_value1_vec_element1]], ptr addrspace(1) [[input_buffer_struct_value1_ptr]], align 1
; CHECK: [[tmp_struct_value1_vec_element2:%[_a-zA-Z0-9]+]] = extractelement <4 x i8> [[tmp_struct_value1_vec]], i64 1
; CHECK: [[input_buffer_struct_value2_ptr:%[_a-zA-Z0-9]+]] = getelementptr <{ [5 x i8] }>, ptr addrspace(1) %in, i32 0, i32 0, i32 1
; CHECK: store i8 [[tmp_struct_value1_vec_element2]], ptr addrspace(1) [[input_buffer_struct_value2_ptr]], align 1
; CHECK: [[tmp_struct_value1_vec_element3:%[_a-zA-Z0-9]+]] = extractelement <4 x i8> [[tmp_struct_value1_vec]], i64 2
; CHECK: [[input_buffer_struct_value3_ptr:%[_a-zA-Z0-9]+]] = getelementptr <{ [5 x i8] }>, ptr addrspace(1) %in, i32 0, i32 0, i32 2
; CHECK: store i8 [[tmp_struct_value1_vec_element3]], ptr addrspace(1) [[input_buffer_struct_value3_ptr]], align 1
; CHECK: [[tmp_struct_value1_vec_element4:%[_a-zA-Z0-9]+]] = extractelement <4 x i8> [[tmp_struct_value1_vec]], i64 3
; CHECK: [[input_buffer_struct_value4_ptr:%[_a-zA-Z0-9]+]] = getelementptr <{ [5 x i8] }>, ptr addrspace(1) %in, i32 0, i32 0, i32 3
; CHECK: store i8 [[tmp_struct_value1_vec_element4]], ptr addrspace(1) [[input_buffer_struct_value4_ptr]], align 1

; CHECK: [[tmp_struct_value2:%[_a-zA-Z0-9]+]] = extractvalue %struct [[tmp_struct]], 1
; CHECK: [[tmp_struct_value2_vec:%[_a-zA-Z0-9]+]] = bitcast i8 [[tmp_struct_value2]] to <1 x i8>
; CHECK: [[tmp_struct_value2_vec_element1:%[_a-zA-Z0-9]+]] = extractelement <1 x i8> [[tmp_struct_value2_vec]], i64 0
; CHECK: [[input_buffer_struct_value5_ptr:%[_a-zA-Z0-9]+]] = getelementptr <{ [5 x i8] }>, ptr addrspace(1) %in, i32 0, i32 0, i32 4
; CHECK: store i8 [[tmp_struct_value2_vec_element1]], ptr addrspace(1) [[input_buffer_struct_value5_ptr]], align 1
