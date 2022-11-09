; RUN: clspv-opt --passes=rewrite-packed-structs %s -o %t
; RUN: FileCheck %s < %t

%struct = type <{ i32, float }>

define spir_kernel void @test(%struct addrspace(1)* nocapture %in) {
  %1 = call spir_func i32 @_Z13get_global_idj(i32 0)
  %2 = getelementptr inbounds %struct, %struct addrspace(1)* %in, i32 %1
  store %struct <{ i32 2100483600, float 0.0 }>, %struct addrspace(1)* %2
  ret void
}

declare spir_func i32 @_Z13get_global_idj(i32)

; CHECK: define spir_kernel void @test(%struct addrspace(1)* nocapture %in) {
