; RUN: clspv-opt --passes="rewrite-packed-structs,replace-pointer-bitcast" %s -o %t
; RUN: FileCheck %s < %t

%struct = type <{ i32, i16 }>

define spir_kernel void @test(ptr addrspace(1) nocapture %in) {
  %1 = load %struct, ptr addrspace(1) %in
  %2 = call spir_func i32 @_Z13get_global_idj(i32 0)
  %3 = getelementptr inbounds %struct, ptr addrspace(1) %in, i32 %2
  store %struct %1, ptr addrspace(1) %3
  ret void
}

declare spir_func i32 @_Z13get_global_idj(i32)

; CHECK:  [[gid:%[^ ]+]] = call spir_func i32 @_Z13get_global_idj(i32 0)
; CHECK:  [[gep:%[^ ]+]] = getelementptr <{ [6 x i8] }>, ptr addrspace(1) %in, i32 [[gid]]
; CHECK:  [[load0:%[^ ]+]] = extractvalue %struct {{.*}}, 0
; CHECK:  [[load1:%[^ ]+]] = extractvalue %struct {{.*}}, 1

; CHECK:  [[trunc:%[^ ]+]] = trunc i32 [[load0]] to i8
; CHECK:  [[arr0:%[^ ]+]] = insertvalue [6 x i8] poison, i8 [[trunc]], 0

; CHECK:  [[lshr:%[^ ]+]] = lshr i32 [[load0]], 8
; CHECK:  [[trunc:%[^ ]+]] = trunc i32 [[lshr]] to i8
; CHECK:  [[arr1:%[^ ]+]] = insertvalue [6 x i8] [[arr0]], i8 [[trunc]], 1

; CHECK:  [[lshr:%[^ ]+]] = lshr i32 [[load0]], 16
; CHECK:  [[trunc:%[^ ]+]] = trunc i32 [[lshr]] to i8
; CHECK:  [[arr2:%[^ ]+]] = insertvalue [6 x i8] [[arr1]], i8 [[trunc]], 2

; CHECK:  [[lshr:%[^ ]+]] = lshr i32 [[load0]], 24
; CHECK:  [[trunc:%[^ ]+]] = trunc i32 [[lshr]] to i8
; CHECK:  [[arr3:%[^ ]+]] = insertvalue [6 x i8] [[arr2]], i8 [[trunc]], 3

; CHECK:  [[trunc:%[^ ]+]] = trunc i16 [[load1]] to i8
; CHECK:  [[arr4:%[^ ]+]] = insertvalue [6 x i8] [[arr3]], i8 [[trunc]], 4

; CHECK:  [[lshr:%[^ ]+]] = lshr i16 [[load1]], 8
; CHECK:  [[trunc:%[^ ]+]] = trunc i16 [[lshr]] to i8
; CHECK:  [[arr5:%[^ ]+]] = insertvalue [6 x i8] [[arr4]], i8 [[trunc]], 5

; CHECK:  [[struct:%[^ ]+]] = insertvalue <{ [6 x i8] }> poison, [6 x i8] [[arr5]], 0
; CHECK:  [[addr:%[^ ]+]] = getelementptr <{ [6 x i8] }>, ptr addrspace(1) [[gep]], i32 0
; CHECK:  store <{ [6 x i8] }> [[struct]], ptr addrspace(1) [[addr]], align 1
