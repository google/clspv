; RUN: clspv-opt --LongVectorLowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_func void @test() {
entry:
  %ptr = load <8 x float> addrspace(1)*, <8 x float> addrspace(1)** undef, align 4
  %data = getelementptr inbounds <8 x float>, <8 x float> addrspace(1)* %ptr, i32 undef
  ret void
}

; CHECK: getelementptr inbounds
; CHECK-SAME: [[FLOAT8:{ float, float, float, float, float, float, float, float }]],
; CHECK-SAME: [[FLOAT8]] addrspace(1)* {{%[^ ]+}}, i32 undef
