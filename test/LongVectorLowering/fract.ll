; RUN: clspv-opt --passes=long-vector-lowering %s -o %t
; RUN: FileCheck %s < %t

; CHECK: call spir_func float @_Z5fractff(float 0.000000e+00, float addrspace(3)* getelementptr inbounds ([16 x float], [16 x float] addrspace(3)* @gv, i32 0, i32 0))
; CHECK: call spir_func float @_Z5fractff(float 0.000000e+00, float addrspace(3)* getelementptr inbounds ([16 x float], [16 x float] addrspace(3)* @gv, i32 0, i32 1))
; CHECK: call spir_func float @_Z5fractff(float 0.000000e+00, float addrspace(3)* getelementptr inbounds ([16 x float], [16 x float] addrspace(3)* @gv, i32 0, i32 2))
; CHECK: call spir_func float @_Z5fractff(float 0.000000e+00, float addrspace(3)* getelementptr inbounds ([16 x float], [16 x float] addrspace(3)* @gv, i32 0, i32 3))
; CHECK: call spir_func float @_Z5fractff(float 0.000000e+00, float addrspace(3)* getelementptr inbounds ([16 x float], [16 x float] addrspace(3)* @gv, i32 0, i32 4))
; CHECK: call spir_func float @_Z5fractff(float 0.000000e+00, float addrspace(3)* getelementptr inbounds ([16 x float], [16 x float] addrspace(3)* @gv, i32 0, i32 5))
; CHECK: call spir_func float @_Z5fractff(float 0.000000e+00, float addrspace(3)* getelementptr inbounds ([16 x float], [16 x float] addrspace(3)* @gv, i32 0, i32 6))
; CHECK: call spir_func float @_Z5fractff(float 0.000000e+00, float addrspace(3)* getelementptr inbounds ([16 x float], [16 x float] addrspace(3)* @gv, i32 0, i32 7))
; CHECK: call spir_func float @_Z5fractff(float 0.000000e+00, float addrspace(3)* getelementptr inbounds ([16 x float], [16 x float] addrspace(3)* @gv, i32 0, i32 8))
; CHECK: call spir_func float @_Z5fractff(float 0.000000e+00, float addrspace(3)* getelementptr inbounds ([16 x float], [16 x float] addrspace(3)* @gv, i32 0, i32 9))
; CHECK: call spir_func float @_Z5fractff(float 0.000000e+00, float addrspace(3)* getelementptr inbounds ([16 x float], [16 x float] addrspace(3)* @gv, i32 0, i32 10))
; CHECK: call spir_func float @_Z5fractff(float 0.000000e+00, float addrspace(3)* getelementptr inbounds ([16 x float], [16 x float] addrspace(3)* @gv, i32 0, i32 11))
; CHECK: call spir_func float @_Z5fractff(float 0.000000e+00, float addrspace(3)* getelementptr inbounds ([16 x float], [16 x float] addrspace(3)* @gv, i32 0, i32 12))
; CHECK: call spir_func float @_Z5fractff(float 0.000000e+00, float addrspace(3)* getelementptr inbounds ([16 x float], [16 x float] addrspace(3)* @gv, i32 0, i32 13))
; CHECK: call spir_func float @_Z5fractff(float 0.000000e+00, float addrspace(3)* getelementptr inbounds ([16 x float], [16 x float] addrspace(3)* @gv, i32 0, i32 14))
; CHECK: call spir_func float @_Z5fractff(float 0.000000e+00, float addrspace(3)* getelementptr inbounds ([16 x float], [16 x float] addrspace(3)* @gv, i32 0, i32 15))

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@gv = internal addrspace(3) global <16 x float> zeroinitializer, align 32

define void @test() {
entry:
  %call = call spir_func <16 x float> @_Z5fractDv16_fPU3AS3S_(<16 x float> zeroinitializer, <16 x float> addrspace(3)* @gv)
  ret void
}

declare spir_func <16 x float> @_Z5fractDv16_fPU3AS3S_(<16 x float>, <16 x float> addrspace(3)*)

