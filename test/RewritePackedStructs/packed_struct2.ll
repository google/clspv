; RUN: clspv-opt --passes="rewrite-packed-structs" %s -o %t
; RUN: FileCheck %s < %t
; TODO(#1005): pass is generating bad code
; XFAIL: *

%struct = type <{ i32, i16 }>

define spir_kernel void @test(ptr addrspace(1) nocapture %in) {
  %1 = call spir_func i32 @_Z13get_global_idj(i32 0)
  %2 = getelementptr inbounds %struct, ptr addrspace(1) %in, i32 %1
  store %struct <{ i32 2100483600, i16 127 }>, ptr addrspace(1) %2
  ret void
}

declare spir_func i32 @_Z13get_global_idj(i32)

; CHECK: [[alloca:%[a-zA-Z0-9_.]+]] = alloca %struct
; CHECK: store %struct <{ i32 2100483600, i16 127 }>, ptr addrspace(1) [[alloca]]
; CHECK: [[gid:%[a-zA-Z0-9_.]+]] = call spir_func i32 @_Z13get_global_idj(i32 0)
; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load %struct, ptr addrspace(1) [[alloca]]

; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = extractvalue %struct [[ld]], 0
; CHECK: [[cast0:%[a-zA-Z0-9_.]+]] = bitcast i32 [[ex0]] to <4 x i8>
; CHECK: [[ex00:%[a-zA-Z0-9_.]+]] = extractelement <4 x i8> [[cast0]], i64 0
; CHECK: [[gep0:%[a-zA-Z0-9_.]+]] = getelementptr <{ [6 x i8] }>, ptr addrspace(1) %in, i32 [[gid]], i32 0, i32 0
; CHECK: store i8 [[ex00]], ptr addrspace(1) [[gep0]]
; CHECK: [[ex01:%[a-zA-Z0-9_.]+]] = extractelement <4 x i8> [[cast0]], i64 1
; CHECK: [[gep1:%[a-zA-Z0-9_.]+]] = getelementptr <{ [6 x i8] }>, ptr addrspace(1) %in, i32 [[gid]], i32 0, i32 1
; CHECK: store i8 [[ex00]], ptr addrspace(1) [[gep1]]
; CHECK: [[ex02:%[a-zA-Z0-9_.]+]] = extractelement <4 x i8> [[cast0]], i64 1
; CHECK: [[gep2:%[a-zA-Z0-9_.]+]] = getelementptr <{ [6 x i8] }>, ptr addrspace(1) %in, i32 [[gid]], i32 0, i32 2
; CHECK: store i8 [[ex00]], ptr addrspace(1) [[gep2]]
; CHECK: [[ex03:%[a-zA-Z0-9_.]+]] = extractelement <4 x i8> [[cast0]], i64 1
; CHECK: [[gep3:%[a-zA-Z0-9_.]+]] = getelementptr <{ [6 x i8] }>, ptr addrspace(1) %in, i32 [[gid]], i32 0, i32 3
; CHECK: store i8 [[ex00]], ptr addrspace(1) [[gep3]]

; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = extractvalue %struct [[ld]], 1
; CHECK: [[cast1:%[a-zA-Z0-9_.]+]] = bitcast i16 [[ex1]] to <2 x i8>
; CHECK: [[ex10:%[a-zA-Z0-9_.]+]] = extractelement <2 x i8> [[cast1]], i64 0
; CHECK: [[gep0:%[a-zA-Z0-9_.]+]] = getelementptr <{ [6 x i8] }>, ptr addrspace(1) %in, i32 [[gid]], i32 0, i32 4
; CHECK: store i8 [[ex10]], ptr addrspace(1) [[gep]]
; CHECK: [[ex11:%[a-zA-Z0-9_.]+]] = extractelement <2 x i8> [[cast1]], i64 1
; CHECK: [[gep1:%[a-zA-Z0-9_.]+]] = getelementptr <{ [6 x i8] }>, ptr addrspace(1) %in, i32 [[gid]], i32 0, i32 5
; CHECK: store i8 [[ex11]], ptr addrspace(1) [[gep]]
