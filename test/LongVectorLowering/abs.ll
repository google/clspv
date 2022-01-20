; RUN: clspv-opt --LongVectorLowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @abs(<8 x i32> addrspace(1)* %src, <8 x i32> addrspace(1)* %dst) {
entry:
  %0 = load <8 x i32>, <8 x i32> addrspace(1)* %src, align 32
  %call = call spir_func <8 x i32> @_Z3absDv8_i(<8 x i32> %0)
  store <8 x i32> %call, <8 x i32> addrspace(1)* %dst, align 32
  ret void
}

declare spir_func <8 x i32> @_Z3absDv8_i(<8 x i32>)

; CHECK: call spir_func i32 @_Z3absi(i32
; CHECK: call spir_func i32 @_Z3absi(i32
; CHECK: call spir_func i32 @_Z3absi(i32
; CHECK: call spir_func i32 @_Z3absi(i32
; CHECK: call spir_func i32 @_Z3absi(i32
; CHECK: call spir_func i32 @_Z3absi(i32
; CHECK: call spir_func i32 @_Z3absi(i32
; CHECK: call spir_func i32 @_Z3absi(i32
