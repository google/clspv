; RUN: clspv-opt --passes=rewrite-packed-structs %s -o %t
; RUN: FileCheck %s < %t

%struct = type <{ i32, i16 }>

define spir_kernel void @test(%struct addrspace(1)* nocapture %in) {
  %1 = call spir_func i32 @_Z13get_global_idj(i32 0)
  %2 = getelementptr inbounds %struct, %struct addrspace(1)* %in, i32 %1
  store %struct <{ i32 2100483600, i16 127 }>, %struct addrspace(1)* %2
  ret void
}

declare spir_func i32 @_Z13get_global_idj(i32)

; CHECK: define spir_kernel void @test(<{ [6 x i8] }> addrspace(1)* nocapture %in) {
; CHECK: [[input_buffer_bitcast:%[_a-zA-Z0-9]+]] = bitcast <{ [6 x i8] }> addrspace(1)* %in to %struct addrspace(1)*
; CHECK: [[idx:%[_a-zA-Z0-9]+]] = call spir_func i32 @_Z13get_global_idj(i32 0)
; CHECK: [[struct:%[_a-zA-Z0-9]+]] = getelementptr inbounds %struct, %struct addrspace(1)* [[input_buffer_bitcast]], i32 [[idx]]
; CHECK: store %struct <{ i32 2100483600, i16 127 }>, %struct addrspace(1)* [[struct]], align 1
