; RUN: clspv-opt %s -o %t.ll --passes=spirv-producer -producer-out-file %t.spv
; RUN: spirv-dis -o %t2.spvasm %t.spv
; RUN: FileCheck %s < %t2.spvasm
; RUN: spirv-val %t.spv

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%0 = type { <3 x i32>, <3 x i32>, %1 }
%1 = type { i32 }

@__spirv_GlobalInvocationId = local_unnamed_addr addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer
@__push_constants = local_unnamed_addr addrspace(9) global %0 zeroinitializer, !push_constants !0

define spir_kernel void @foo(i8 addrspace(1)* nocapture writeonly align 1 %dst, i8 addrspace(1)* nocapture readonly align 1 %src, { i32 } %podargs) {
entry:
  %0 = call { [0 x i8] } addrspace(1)* @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i8] } zeroinitializer)
  %1 = call { [0 x i8] } addrspace(1)* @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x i8] } zeroinitializer)
  %2 = call { { i32 } } addrspace(9)* @_Z14clspv.resource.2(i32 -1, i32 2, i32 5, i32 2, i32 2, i32 0, { { i32 } } zeroinitializer)
  %3 = getelementptr { { i32 } }, { { i32 } } addrspace(9)* %2, i32 0, i32 0
  %4 = load { i32 }, { i32 } addrspace(9)* %3, align 4
  %n = extractvalue { i32 } %4, 0
  %5 = getelementptr <3 x i32>, <3 x i32> addrspace(5)* @__spirv_GlobalInvocationId, i32 0, i32 0
  %6 = load i32, i32 addrspace(5)* %5, align 16
  %tobool.i.not = icmp ne i32 %n, 0
  %7 = getelementptr { [0 x i8] }, { [0 x i8] } addrspace(1)* %1, i32 0, i32 0, i32 %n
  %8 = load i8, i8 addrspace(1)* %7, align 1
  %tobool2.i.not = icmp eq i8 %8, 0
  %9 = zext i1 %tobool.i.not to i2
  %trunc = select i1 %tobool2.i.not, i2 %9, i2 -2
  br label %NodeBlock1

NodeBlock1:                                       ; preds = %entry
  %Pivot2 = icmp sge i2 %trunc, 0
  br i1 %Pivot2, label %NodeBlock, label %Flow

NodeBlock:                                        ; preds = %NodeBlock1
  %Pivot = icmp slt i2 %trunc, 1
  br i1 %Pivot, label %sw.bb.i, label %sw.bb9.i

sw.bb.i:                                          ; preds = %NodeBlock
  %10 = getelementptr { [0 x i8] }, { [0 x i8] } addrspace(1)* %1, i32 0, i32 0, i32 %6
  %11 = load i8, i8 addrspace(1)* %10, align 1
  %12 = getelementptr { [0 x i8] }, { [0 x i8] } addrspace(1)* %0, i32 0, i32 0, i32 %6
  store i8 %11, i8 addrspace(1)* %12, align 1
  br label %sw.bb9.i

sw.bb9.i:                                         ; preds = %sw.bb.i, %NodeBlock
  %sub.i = add i32 %6, -2
  %13 = getelementptr { [0 x i8] }, { [0 x i8] } addrspace(1)* %1, i32 0, i32 0, i32 %sub.i
  %14 = load i8, i8 addrspace(1)* %13, align 1
  %add.i = add i32 %6, 7
  %15 = getelementptr { [0 x i8] }, { [0 x i8] } addrspace(1)* %0, i32 0, i32 0, i32 %add.i
  store i8 %14, i8 addrspace(1)* %15, align 1
  br label %Flow

Flow:                                             ; preds = %sw.bb9.i, %NodeBlock1
  %16 = phi i1 [ true, %sw.bb9.i ], [ false, %NodeBlock1 ]
  %17 = phi i1 [ false, %sw.bb9.i ], [ true, %NodeBlock1 ]
  br i1 %17, label %LeafBlock, label %Flow3

LeafBlock:                                        ; preds = %Flow
  %SwitchLeaf = icmp eq i2 %trunc, -2
  br label %Flow3

Flow3:                                            ; preds = %LeafBlock, %Flow
  %18 = phi i1 [ %SwitchLeaf, %LeafBlock ], [ %16, %Flow ]
  br i1 %18, label %sw.bb12.i, label %foo.inner.exit

sw.bb12.i:                                        ; preds = %Flow3
  %add13.i = add i32 %6, 2
  %19 = getelementptr { [0 x i8] }, { [0 x i8] } addrspace(1)* %1, i32 0, i32 0, i32 %add13.i
  %20 = load i8, i8 addrspace(1)* %19, align 1
  %add15.i = add i32 %6, 3
  %21 = getelementptr { [0 x i8] }, { [0 x i8] } addrspace(1)* %0, i32 0, i32 0, i32 %add15.i
  store i8 %20, i8 addrspace(1)* %21, align 1
  br label %foo.inner.exit

foo.inner.exit:                                   ; preds = %sw.bb12.i, %Flow3
  ret void
}

declare { [0 x i8] } addrspace(1)* @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i8] })

declare { [0 x i8] } addrspace(1)* @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [0 x i8] })

declare { { i32 } } addrspace(9)* @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { { i32 } })

!0 = !{i32 1, i32 4, i32 7}

; CHECK-NOT: OpTypeInt 2 0
; CHECK: OpTypeInt 8 0
; CHECK-NOT: OpTypeInt 8 0
; CHECK-NOT: OpTypeInt 2 0
