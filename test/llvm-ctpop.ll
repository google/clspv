; RUN: clspv-opt %s -o %t.ll --passes=spirv-producer --producer-out-file %t.spv
; RUN: spirv-dis -o %t.spvasm %t.spv
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val %t.spv

; CHECK: OpAccessChain
; CHECK-NEXT: OpLoad
; CHECK-NEXT: OpBitCount
; CHECK-NEXT: OpStore
; CHECK-NEXT: OpReturn

source_filename = "kernel.cl"
target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @verifyConstant(i32 addrspace(1)* nocapture writeonly align 4 %base) {
entry:
  %0 = call { i32 } addrspace(1)* @_Z14clspv.resource.1(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { i32 } zeroinitializer)
  %1 = getelementptr { i32 }, { i32 } addrspace(1)* %0, i32 0, i32 0
  %2 = load i32, i32 addrspace(1)* %1, align 4
  %3 = tail call i32 @llvm.ctpop.i32(i32 %2)
  store i32 %3, i32 addrspace(1)* %1, align 4
  ret void
}

declare i32 @llvm.ctpop.i32(i32) #1

declare { i32 } addrspace(1)* @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { i32 })

