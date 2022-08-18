; RUN: clspv-opt --passes=three-element-vector-lowering --vec3-to-vec4 %s -o %t
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@gv = internal global <3 x i32> zeroinitializer, align 32

define void @test() {
entry:
  %load = load <3 x i32>, <3 x i32>* getelementptr (<3 x i32>, <3 x i32>* @gv, i32 1), align 32
  %load2 = load i32, i32* getelementptr (<3 x i32>, <3 x i32>* @gv, i32 1, i32 0), align 32
  ret void
}

; CHECK:  %load = load <4 x i32>, <4 x i32>* getelementptr inbounds (<4 x i32>, <4 x i32>* @gv, i32 1), align 32
; CHECK:  %load2 = load i32, i32* getelementptr inbounds (<4 x i32>, <4 x i32>* @gv, i32 1, i32 0), align 32
