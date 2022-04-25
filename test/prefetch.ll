; RUN: clspv-opt --passes=replace-opencl-builtin %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @test(i32 addrspace(1)* %mem) local_unnamed_addr {
entry:
  tail call spir_func void @_Z8prefetchPU3AS1Kij(i32 addrspace(1)* %mem, i32 12)
  ;CHECK-NOT: call spir_func void @_Z8prefetchPU3AS1Kij
  ret void
}

declare spir_func void @_Z8prefetchPU3AS1Kij(i32 addrspace(1)*, i32) local_unnamed_addr
