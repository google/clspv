; RUN: clspv-opt %s -o %t -ReplaceOpenCLBuiltin
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @foo(half addrspace(1)* %a, <16 x float> %b, i32 %c) {
entry:
  call spir_func void @_Z13vstore_half16Dv16_fjPU3AS1Dh(<16 x float> %b, i32 %c, half addrspace(1)* %a)
  ret void
}

declare spir_func void @_Z13vstore_half16Dv16_fjPU3AS1Dh(<16 x float>, i32, half addrspace(1)*)

; CHECK:  [[b0:%[^ ]+]] = shufflevector <16 x float> %b, <16 x float> undef, <2 x i32> <i32 0, i32 1>
; CHECK:  [[b1:%[^ ]+]] = shufflevector <16 x float> %b, <16 x float> undef, <2 x i32> <i32 2, i32 3>
; CHECK:  [[b2:%[^ ]+]] = shufflevector <16 x float> %b, <16 x float> undef, <2 x i32> <i32 4, i32 5>
; CHECK:  [[b3:%[^ ]+]] = shufflevector <16 x float> %b, <16 x float> undef, <2 x i32> <i32 6, i32 7>
; CHECK:  [[b4:%[^ ]+]] = shufflevector <16 x float> %b, <16 x float> undef, <2 x i32> <i32 8, i32 9>
; CHECK:  [[b5:%[^ ]+]] = shufflevector <16 x float> %b, <16 x float> undef, <2 x i32> <i32 10, i32 11>
; CHECK:  [[b6:%[^ ]+]] = shufflevector <16 x float> %b, <16 x float> undef, <2 x i32> <i32 12, i32 13>
; CHECK:  [[b7:%[^ ]+]] = shufflevector <16 x float> %b, <16 x float> undef, <2 x i32> <i32 14, i32 15>
; CHECK:  [[b0i32:%[^ ]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> [[b0]])
; CHECK:  [[b1i32:%[^ ]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> [[b1]])
; CHECK:  [[b2i32:%[^ ]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> [[b2]])
; CHECK:  [[b3i32:%[^ ]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> [[b3]])
; CHECK:  [[b4i32:%[^ ]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> [[b4]])
; CHECK:  [[b5i32:%[^ ]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> [[b5]])
; CHECK:  [[b6i32:%[^ ]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> [[b6]])
; CHECK:  [[b7i32:%[^ ]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> [[b7]])
; CHECK:  [[b00:%[^ ]+]] = insertelement <4 x i32> undef, i32 [[b0i32]], i32 0
; CHECK:  [[b01:%[^ ]+]] = insertelement <4 x i32> [[b00]], i32 [[b1i32]], i32 1
; CHECK:  [[b02:%[^ ]+]] = insertelement <4 x i32> [[b01]], i32 [[b2i32]], i32 2
; CHECK:  [[b03:%[^ ]+]] = insertelement <4 x i32> [[b02]], i32 [[b3i32]], i32 3
; CHECK:  [[b10:%[^ ]+]] = insertelement <4 x i32> undef, i32 [[b4i32]], i32 0
; CHECK:  [[b11:%[^ ]+]] = insertelement <4 x i32> [[b10]], i32 [[b5i32]], i32 1
; CHECK:  [[b12:%[^ ]+]] = insertelement <4 x i32> [[b11]], i32 [[b6i32]], i32 2
; CHECK:  [[b13:%[^ ]+]] = insertelement <4 x i32> [[b12]], i32 [[b7i32]], i32 3
; CHECK:  [[av4i32:%[^ ]+]] = bitcast half addrspace(1)* %a to <4 x i32> addrspace(1)*
; CHECK:  [[cx2:%[^ ]+]] = shl i32 %c, 1
; CHECK:  [[gep0:%[^ ]+]] = getelementptr <4 x i32>, <4 x i32> addrspace(1)* [[av4i32]], i32 [[cx2]]
; CHECK:  store <4 x i32> [[b03]], <4 x i32> addrspace(1)* [[gep0]], align 16
; CHECK:  [[cx2p1:%[^ ]+]] = add i32 [[cx2]], 1
; CHECK:  [[gep1:%[^ ]+]] = getelementptr <4 x i32>, <4 x i32> addrspace(1)* [[av4i32]], i32 [[cx2p1]]
; CHECK:  store <4 x i32> [[b13]], <4 x i32> addrspace(1)* [[gep1]], align 16
