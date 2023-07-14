; RUN: clspv-opt --passes=rewrite-packed-structs %s -o %t
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
; CHECK: [[idx:%[_a-zA-Z0-9]+]] = call spir_func i32 @_Z13get_global_idj(i32 0)
; CHECK: [[gep:%[_a-zA-Z0-9]+]] = getelementptr <{ [5 x i8] }>, ptr addrspace(1) %in, i32 [[idx]]
; CHECK: store %struct <{ i32 2100483600, i8 127 }>, ptr addrspace(1) [[gep]], align 1
