; RUN: clspv-opt --vec3-to-vec4 --passes=three-element-vector-lowering --opaque-pointers %s -o %t.ll
; RUN: FileCheck %s < %t.ll

declare void @_Z8spirv.op.63.PU3AS3Dv3_hPU3AS1Dv3_h(i32, ptr, ptr)

define spir_kernel void @simple_call(ptr %a, ptr %b) {
entry:
  %src = getelementptr <3 x i8>, ptr %a, i32 0
  %dst = getelementptr <3 x i8>, ptr %b, i32 0

  store <3 x i8> <i8 1, i8 2, i8 3>, ptr %src
  
  %load = load <3 x i8>, ptr %a

  call void @_Z8spirv.op.63.PU3AS3Dv3_hPU3AS1Dv3_h(i32 63, ptr %dst, ptr %src)
  ret void
}

; CHECK: %src = getelementptr inbounds <4 x i8>, ptr %a, i32 0
; CHECK: %dst = getelementptr inbounds <4 x i8>, ptr %b, i32 0
; CHECK: store <4 x i8> <i8 1, i8 2, i8 3, i8 1>, ptr %src, align 4
; CHECK: %load = load <4 x i8>, ptr %a, align 4
; CHECK: [[localid0:%[a-zA-Z0-9_.]+]] = getelementptr <4 x i8>, ptr %src, i32 0, i32 0
; CHECK: [[localid1:%[a-zA-Z0-9_.]+]] = load i8, ptr [[localid0]], align 1
; CHECK: [[localid2:%[a-zA-Z0-9_.]+]] = getelementptr <4 x i8>, ptr %dst, i32 0, i32 0
; CHECK: store i8 [[localid1]], ptr [[localid2]], align 1
; CHECK: [[localid3:%[a-zA-Z0-9_.]+]] = getelementptr <4 x i8>, ptr %src, i32 0, i32 1
; CHECK: [[localid4:%[a-zA-Z0-9_.]+]] = load i8, ptr [[localid3]], align 1
; CHECK: [[localid5:%[a-zA-Z0-9_.]+]] = getelementptr <4 x i8>, ptr %dst, i32 0, i32 1
; CHECK: store i8 [[localid4]], ptr [[localid5]], align 1
; CHECK: [[localid6:%[a-zA-Z0-9_.]+]] = getelementptr <4 x i8>, ptr %src, i32 0, i32 2
; CHECK: [[localid7:%[a-zA-Z0-9_.]+]] = load i8, ptr [[localid6]], align 1
; CHECK: [[localid8:%[a-zA-Z0-9_.]+]] = getelementptr <4 x i8>, ptr %dst, i32 0, i32 2
; CHECK: store i8 [[localid7]], ptr [[localid8]], align 1
