; RUN: clspv-opt --passes=rewrite-packed-structs %s -o %t
; RUN: FileCheck %s < %t
; TODO(#1005): convert to opaque pointers when pass is fixed
; XFAIL: *

%struct = type <{ i8, float }>

define spir_kernel void @test(%struct addrspace(1)* nocapture %in) {
  %1 = call spir_func i32 @_Z13get_global_idj(i32 0)
  %2 = getelementptr inbounds %struct, %struct addrspace(1)* %in, i32 %1
  store %struct <{ i8 127, float 0.0 }>, %struct addrspace(1)* %2
  ret void
}

declare spir_func i32 @_Z13get_global_idj(i32)

; CHECK: define spir_kernel void @test(<{ [5 x i8] }> addrspace(1)* nocapture %in) {
; CHECK: [[input_buffer_bitcast:%[_a-zA-Z0-9]+]] = bitcast <{ [5 x i8] }> addrspace(1)* %in to %struct addrspace(1)*
; CHECK: [[idx:%[_a-zA-Z0-9]+]] = call spir_func i32 @_Z13get_global_idj(i32 0)
; CHECK: [[struct:%[_a-zA-Z0-9]+]] = getelementptr inbounds %struct, %struct addrspace(1)* [[input_buffer_bitcast]], i32 [[idx]]
; CHECK: store %struct <{ i8 127, float 0.000000e+00 }>, %struct addrspace(1)* %3, align 1
