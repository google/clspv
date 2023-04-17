; RUN: clspv-opt %s -o %t --passes=replace-opencl-builtin --no-16bit-storage=ssbo
; RUN: FileCheck %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define void @foo(ptr addrspace(1) %a, <3 x float> %b, i32 %c) {
entry:
  call spir_func void @_Z14vstorea_half_3Dv3_fjPU3AS1Dh(<3 x float> %b, i32 %c, ptr addrspace(1) %a)
  ret void
}

declare spir_func void @_Z14vstorea_half_3Dv3_fjPU3AS1Dh(<3 x float>, i32, ptr addrspace(1))


; CHECK:  [[b0:%[^ ]+]] = extractelement <3 x float> %b, i32 0
; CHECK:  [[b1:%[^ ]+]] = extractelement <3 x float> %b, i32 1
; CHECK:  [[b2:%[^ ]+]] = extractelement <3 x float> %b, i32 2

; CHECK:  [[idx0:%[^ ]+]] = shl i32 %c, 2
; CHECK:  [[insert:%[^ ]+]] = insertelement <2 x float> poison, float [[b0]], i32 0
; CHECK:  [[pack:%[^ ]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> [[insert]])
; CHECK:  [[and:%[^ ]+]] = and i32 [[idx0]], 1
; CHECK:  [[lshr:%[^ ]+]] = lshr i32 [[idx0]], 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %a, i32 [[lshr]]
; CHECK:  [[load:%[^ ]+]] = load i32, ptr addrspace(1) [[gep]], align 4
; CHECK:  [[shl1:%[^ ]+]] = shl i32 [[and]], 4
; CHECK:  [[shl2:%[^ ]+]] = shl i32 65535, [[shl1]]
; CHECK:  [[and1:%[^ ]+]] = and i32 [[shl2]], [[load]]
; CHECK:  [[and2:%[^ ]+]] = and i32 [[pack]], 65535
; CHECK:  [[shl3:%[^ ]+]] = shl i32 [[and2]], [[shl1]]
; CHECK:  [[zor:%[^ ]+]] = xor i32 [[and1]], [[shl3]]
; CHECK:  call i32 @spirv.atomic_xor(ptr addrspace(1) [[gep]], i32 1, i32 64, i32 [[zor]])
; CHECK:  call void @llvm.donothing()

; CHECK:  [[add1:%[^ ]+]] = add i32 [[idx0]], 1
; CHECK:  [[insert:%[^ ]+]] = insertelement <2 x float> poison, float [[b1]], i32 0
; CHECK:  [[pack:%[^ ]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> [[insert]])
; CHECK:  [[and:%[^ ]+]] = and i32 [[add1]], 1
; CHECK:  [[lshr:%[^ ]+]] = lshr i32 [[add1]], 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %a, i32 [[lshr]]
; CHECK:  [[load:%[^ ]+]] = load i32, ptr addrspace(1) [[gep]], align 4
; CHECK:  [[shl1:%[^ ]+]] = shl i32 [[and]], 4
; CHECK:  [[shl2:%[^ ]+]] = shl i32 65535, [[shl1]]
; CHECK:  [[and1:%[^ ]+]] = and i32 [[shl2]], [[load]]
; CHECK:  [[and2:%[^ ]+]] = and i32 [[pack]], 65535
; CHECK:  [[shl3:%[^ ]+]] = shl i32 [[and2]], [[shl1]]
; CHECK:  [[zor:%[^ ]+]] = xor i32 [[and1]], [[shl3]]
; CHECK:  call i32 @spirv.atomic_xor(ptr addrspace(1) [[gep]], i32 1, i32 64, i32 [[zor]])
; CHECK:  call void @llvm.donothing()

; CHECK:  [[add2:%[^ ]+]] = add i32 [[add1]], 1
; CHECK:  [[insert:%[^ ]+]] = insertelement <2 x float> poison, float [[b2]], i32 0
; CHECK:  [[pack:%[^ ]+]] = call i32 @_Z16spirv.pack.v2f16(<2 x float> [[insert]])
; CHECK:  [[and:%[^ ]+]] = and i32 [[add2]], 1
; CHECK:  [[lshr:%[^ ]+]] = lshr i32 [[add2]], 1
; CHECK:  [[gep:%[^ ]+]] = getelementptr i32, ptr addrspace(1) %a, i32 [[lshr]]
; CHECK:  [[load:%[^ ]+]] = load i32, ptr addrspace(1) [[gep]], align 4
; CHECK:  [[shl1:%[^ ]+]] = shl i32 [[and]], 4
; CHECK:  [[shl2:%[^ ]+]] = shl i32 65535, [[shl1]]
; CHECK:  [[and1:%[^ ]+]] = and i32 [[shl2]], [[load]]
; CHECK:  [[and2:%[^ ]+]] = and i32 [[pack]], 65535
; CHECK:  [[shl3:%[^ ]+]] = shl i32 [[and2]], [[shl1]]
; CHECK:  [[zor:%[^ ]+]] = xor i32 [[and1]], [[shl3]]
; CHECK:  call i32 @spirv.atomic_xor(ptr addrspace(1) [[gep]], i32 1, i32 64, i32 [[zor]])
; CHECK:  call void @llvm.donothing()
