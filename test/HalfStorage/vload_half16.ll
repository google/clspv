; RUN: clspv-opt %s -o %t --passes=replace-opencl-builtin
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define <16 x float> @foo(ptr addrspace(1) %a, i32 %b) {
entry:
  %0 = call spir_func <16 x float> @_Z12vload_half16jPU3AS1KDh(i32 %b, ptr addrspace(1) %a)
  ret <16 x float> %0
}

declare spir_func <16 x float> @_Z12vload_half16jPU3AS1KDh(i32, ptr addrspace(1))

; CHECK:  [[bx2:%[^ ]+]] = shl i32 %b, 1
; CHECK:  [[gep0:%[^ ]+]] = getelementptr <4 x i32>, ptr addrspace(1) %a, i32 [[bx2]]
; CHECK:  [[idx1:%[^ ]+]] = add i32 [[bx2]], 1
; CHECK:  [[gep1:%[^ ]+]] = getelementptr <4 x i32>, ptr addrspace(1) %a, i32 [[idx1]]
; CHECK:  [[load0:%[^ ]+]] = load <4 x i32>, ptr addrspace(1) [[gep0]], align 16
; CHECK:  [[load1:%[^ ]+]] = load <4 x i32>, ptr addrspace(1) [[gep1]], align 16
; CHECK:  [[val0:%[^ ]+]] = extractelement <4 x i32> [[load0]], i32 0
; CHECK:  [[val1:%[^ ]+]] = extractelement <4 x i32> [[load0]], i32 1
; CHECK:  [[val2:%[^ ]+]] = extractelement <4 x i32> [[load0]], i32 2
; CHECK:  [[val3:%[^ ]+]] = extractelement <4 x i32> [[load0]], i32 3
; CHECK:  [[val4:%[^ ]+]] = extractelement <4 x i32> [[load1]], i32 0
; CHECK:  [[val5:%[^ ]+]] = extractelement <4 x i32> [[load1]], i32 1
; CHECK:  [[val6:%[^ ]+]] = extractelement <4 x i32> [[load1]], i32 2
; CHECK:  [[val7:%[^ ]+]] = extractelement <4 x i32> [[load1]], i32 3
; CHECK:  [[val0f:%[^ ]+]] = call <2 x float> @_Z18spirv.unpack.v2f16(i32 [[val0]])
; CHECK:  [[val1f:%[^ ]+]] = call <2 x float> @_Z18spirv.unpack.v2f16(i32 [[val1]])
; CHECK:  [[val2f:%[^ ]+]] = call <2 x float> @_Z18spirv.unpack.v2f16(i32 [[val2]])
; CHECK:  [[val3f:%[^ ]+]] = call <2 x float> @_Z18spirv.unpack.v2f16(i32 [[val3]])
; CHECK:  [[val4f:%[^ ]+]] = call <2 x float> @_Z18spirv.unpack.v2f16(i32 [[val4]])
; CHECK:  [[val5f:%[^ ]+]] = call <2 x float> @_Z18spirv.unpack.v2f16(i32 [[val5]])
; CHECK:  [[val6f:%[^ ]+]] = call <2 x float> @_Z18spirv.unpack.v2f16(i32 [[val6]])
; CHECK:  [[val7f:%[^ ]+]] = call <2 x float> @_Z18spirv.unpack.v2f16(i32 [[val7]])
; CHECK:  [[ret01:%[^ ]+]] = shufflevector <2 x float> [[val0f]], <2 x float> [[val1f]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK:  [[ret23:%[^ ]+]] = shufflevector <2 x float> [[val2f]], <2 x float> [[val3f]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK:  [[ret45:%[^ ]+]] = shufflevector <2 x float> [[val4f]], <2 x float> [[val5f]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK:  [[ret67:%[^ ]+]] = shufflevector <2 x float> [[val6f]], <2 x float> [[val7f]], <4 x i32> <i32 0, i32 1, i32 2, i32 3>
; CHECK:  [[ret0123:%[^ ]+]] = shufflevector <4 x float> [[ret01]], <4 x float> [[ret23]], <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>
; CHECK:  [[ret4567:%[^ ]+]] = shufflevector <4 x float> [[ret45]], <4 x float> [[ret67]], <8 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>
; CHECK:  [[ret:%[^ ]+]] = shufflevector <8 x float> [[ret0123]], <8 x float> [[ret4567]], <16 x i32> <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 10, i32 11, i32 12, i32 13, i32 14, i32 15>
