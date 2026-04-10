; RUN: clspv-opt --passes=long-vector-lowering %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define spir_kernel void @foo(<8 x float> addrspace(1)* %out, <8 x float> addrspace(1)* %in1, <8 x float> addrspace(1)* %in2) {
entry:
    %0 = load <8 x float>, <8 x float> addrspace(1)* %in1, align 32
    %1 = load <8 x float>, <8 x float> addrspace(1)* %in2, align 32
    %res = call spir_func <8 x float> @llvm.maxnum.v8f(<8 x float> %0, <8 x float> %1)
    store <8 x float> %res, <8 x float> addrspace(1)* %out, align 32
    ret void
}

declare <8 x float> @llvm.maxnum.v8f(<8 x float>, <8 x float>)

; CHECK-LABEL: @foo
; CHECK-COUNT-8: %{{[0-9]+}} = call spir_func float @llvm.maxnum.f32(float %{{[0-9]+}}, float %{{[0-9]+}})
; CHECK-NOT %{{[0-9]+}} = call spir_func <8 x float> @llvm.maxnum.v8f(<8 x float> %{{[0-9]+}}, <8 x float> %{{[0-9]+}})