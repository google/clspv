; RUN: clspv -x ir %s %s2 -o %t
; RUN: spirv-val %t
; RUN: spirv-dis -o %t2 %t
; RUN: FileCheck %s < %t2

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_kernel void @foo(i32 addrspace(1)* align 4 %dst, i32 addrspace(1)* align 4 %src) {
entry:
  call spir_func void @bar(i32 addrspace(1)* %dst, i32 addrspace(1)* %src)
  ret void
}

declare spir_func void @bar(i32 addrspace(1)*, i32 addrspace(1)*)

; CHECK: OpEntryPoint GLCompute [[entry_point:%[^ ]+]] "foo"
; CHECK: [[entry_point]] = OpFunction
; CHECK-NEXT: OpLabel
; CHECK-NEXT: OpAccessChain
; CHECK-NEXT: OpAccessChain
; CHECK-NEXT: OpLoad
; CHECK-NEXT: OpStore
; CHECK-NEXT: OpReturn
; CHECK-NEXT: OpFunctionEnd
