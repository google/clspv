; RUN: clspv-opt --passes=specialize-image-types %s -o %t -cl-std=CL2.0
; RUN: FileCheck %s < %t

; CHECK-NOT: %opencl.image2d_wo_t
; CHECK: [[image:%opencl.image2d_rw_t.float]] = type opaque
; CHECK-NOT: %opencl.image2d_wo_t
; CHECK: @no_use([[image]] addrspace(1)* %image)

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%opencl.image2d_wo_t = type opaque

define spir_kernel void @no_use(%opencl.image2d_wo_t addrspace(1)* %image) {
entry:
  ret void
}
