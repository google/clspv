; RUN: clspv-opt --passes=long-vector-lowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @abs(<8 x i32> addrspace(1)* %srcA, <8 x i32> addrspace(1)* %srcB, <8 x i32> addrspace(1)* %dst) {
entry:
  %0 = load <8 x i32>, <8 x i32> addrspace(1)* %srcA, align 32
  %1 = load <8 x i32>, <8 x i32> addrspace(1)* %srcB, align 32
  %call = call spir_func <8 x i32> @llvm.fshl.v8i32(<8 x i32> %0, <8 x i32> %0, <8 x i32> %1)
  store <8 x i32> %call, <8 x i32> addrspace(1)* %dst, align 32
  ret void
}

declare <8 x i32> @llvm.fshl.v8i32(<8 x i32>, <8 x i32>, <8 x i32>)

; CHECK: call spir_func i32 @llvm.fshl.i32(i32
; CHECK: call spir_func i32 @llvm.fshl.i32(i32
; CHECK: call spir_func i32 @llvm.fshl.i32(i32
; CHECK: call spir_func i32 @llvm.fshl.i32(i32
; CHECK: call spir_func i32 @llvm.fshl.i32(i32
; CHECK: call spir_func i32 @llvm.fshl.i32(i32
; CHECK: call spir_func i32 @llvm.fshl.i32(i32
; CHECK: call spir_func i32 @llvm.fshl.i32(i32
