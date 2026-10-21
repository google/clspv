; RUN: clspv-opt %s -o %t.ll --passes=undo-instcombine
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define void @test_reduce_and_v2i1(<2 x i1> %in, ptr addrspace(1) %out) {
entry:
  ; CHECK-LABEL: @test_reduce_and_v2i1
  ; CHECK-NOT: bitcast <2 x i1>
  ; CHECK: [[red:%[a-zA-Z0-9_.]+]] = call i1 @llvm.vector.reduce.and.v2i1(<2 x i1> %in)
  ; CHECK: [[ext:%[a-zA-Z0-9_.]+]] = zext i1 [[red]] to i32
  ; CHECK: store i32 [[ext]]
  %bc = bitcast <2 x i1> %in to i2
  %cmp = icmp eq i2 %bc, -1
  %ext = zext i1 %cmp to i32
  store i32 %ext, ptr addrspace(1) %out, align 4
  ret void
}

define void @test_reduce_not_and_v3i1(<3 x i1> %in, ptr addrspace(1) %out) {
entry:
  ; CHECK-LABEL: @test_reduce_not_and_v3i1
  ; CHECK-NOT: bitcast <3 x i1>
  ; CHECK: [[red:%[a-zA-Z0-9_.]+]] = call i1 @llvm.vector.reduce.and.v3i1(<3 x i1> %in)
  ; CHECK: [[not:%[a-zA-Z0-9_.]+]] = xor i1 [[red]], true
  ; CHECK: [[ext:%[a-zA-Z0-9_.]+]] = zext i1 [[not]] to i32
  ; CHECK: store i32 [[ext]]
  %bc = bitcast <3 x i1> %in to i3
  %cmp = icmp ne i3 %bc, -1
  %ext = zext i1 %cmp to i32
  store i32 %ext, ptr addrspace(1) %out, align 4
  ret void
}

define void @test_reduce_or_v4i1(<4 x i1> %in, ptr addrspace(1) %out) {
entry:
  ; CHECK-LABEL: @test_reduce_or_v4i1
  ; CHECK-NOT: bitcast <4 x i1>
  ; CHECK: [[red:%[a-zA-Z0-9_.]+]] = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %in)
  ; CHECK: [[ext:%[a-zA-Z0-9_.]+]] = zext i1 [[red]] to i32
  ; CHECK: store i32 [[ext]]
  %bc = bitcast <4 x i1> %in to i4
  %cmp = icmp ne i4 %bc, 0
  %ext = zext i1 %cmp to i32
  store i32 %ext, ptr addrspace(1) %out, align 4
  ret void
}

define void @test_reduce_not_or_v4i1(<4 x i1> %in, ptr addrspace(1) %out) {
entry:
  ; CHECK-LABEL: @test_reduce_not_or_v4i1
  ; CHECK-NOT: bitcast <4 x i1>
  ; CHECK: [[red:%[a-zA-Z0-9_.]+]] = call i1 @llvm.vector.reduce.or.v4i1(<4 x i1> %in)
  ; CHECK: [[not:%[a-zA-Z0-9_.]+]] = xor i1 [[red]], true
  ; CHECK: [[ext:%[a-zA-Z0-9_.]+]] = zext i1 [[not]] to i32
  ; CHECK: store i32 [[ext]]
  %bc = bitcast <4 x i1> %in to i4
  %cmp = icmp eq i4 %bc, 0
  %ext = zext i1 %cmp to i32
  store i32 %ext, ptr addrspace(1) %out, align 4
  ret void
}
