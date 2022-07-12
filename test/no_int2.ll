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

define spir_kernel void @foo(i32 addrspace(1)* nocapture writeonly align 4 %dst, i32 addrspace(1)* nocapture readonly align 4 %src) {
entry:
  %0 = call { [0 x i32] } addrspace(1)* @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i32] } zeroinitializer)
  %1 = call { [0 x i32] } addrspace(1)* @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0, { [0 x i32] } zeroinitializer)
  %2 = getelementptr inbounds %0, %0 addrspace(9)* @__push_constants, i32 0, i32 2, i32 0
  %n = load i32, i32 addrspace(9)* %2, align 16
  %3 = getelementptr <3 x i32>, <3 x i32> addrspace(5)* @__spirv_GlobalInvocationId, i32 0, i32 0
  %4 = load i32, i32 addrspace(5)* %3, align 16
  %5 = getelementptr inbounds %0, %0 addrspace(9)* @__push_constants, i32 0, i32 1, i32 0
  %6 = load i32, i32 addrspace(9)* %5, align 16
  %7 = add i32 %6, %4
  %tobool.i.not = icmp ne i32 %n, 0
  %8 = getelementptr { [0 x i32] }, { [0 x i32] } addrspace(1)* %1, i32 0, i32 0, i32 %n
  %9 = load i32, i32 addrspace(1)* %8, align 4
  %tobool2.i.not = icmp eq i32 %9, 0
  %10 = zext i1 %tobool.i.not to i2
  %trunc = select i1 %tobool2.i.not, i2 %10, i2 -2
  br label %NodeBlock1

NodeBlock1:
  %Pivot2 = icmp sge i2 %trunc, 0
  br i1 %Pivot2, label %NodeBlock, label %Flow

NodeBlock:
  %Pivot = icmp slt i2 %trunc, 1
  br i1 %Pivot, label %sw.bb.i, label %sw.bb9.i

sw.bb.i:
  %11 = getelementptr { [0 x i32] }, { [0 x i32] } addrspace(1)* %1, i32 0, i32 0, i32 %7
  %12 = load i32, i32 addrspace(1)* %11, align 4
  %13 = getelementptr { [0 x i32] }, { [0 x i32] } addrspace(1)* %0, i32 0, i32 0, i32 %7
  store i32 %12, i32 addrspace(1)* %13, align 4
  br label %sw.bb9.i

sw.bb9.i:
  %sub.i = add i32 %7, -2
  %14 = getelementptr { [0 x i32] }, { [0 x i32] } addrspace(1)* %1, i32 0, i32 0, i32 %sub.i
  %15 = load i32, i32 addrspace(1)* %14, align 4
  %add.i = add i32 %7, 7
  %16 = getelementptr { [0 x i32] }, { [0 x i32] } addrspace(1)* %0, i32 0, i32 0, i32 %add.i
  store i32 %15, i32 addrspace(1)* %16, align 4
  br label %Flow

Flow:
  %17 = phi i1 [ true, %sw.bb9.i ], [ false, %NodeBlock1 ]
  %18 = phi i1 [ false, %sw.bb9.i ], [ true, %NodeBlock1 ]
  br i1 %18, label %LeafBlock, label %Flow3

LeafBlock:
  %SwitchLeaf = icmp eq i2 %trunc, -2
  br label %Flow3

Flow3:
  %19 = phi i1 [ %SwitchLeaf, %LeafBlock ], [ %17, %Flow ]
  br i1 %19, label %sw.bb12.i, label %math_kernel.inner.exit

sw.bb12.i:
  %add13.i = add i32 %7, 2
  %20 = getelementptr { [0 x i32] }, { [0 x i32] } addrspace(1)* %1, i32 0, i32 0, i32 %add13.i
  %21 = load i32, i32 addrspace(1)* %20, align 4
  %add15.i = add i32 %7, 3
  %22 = getelementptr { [0 x i32] }, { [0 x i32] } addrspace(1)* %0, i32 0, i32 0, i32 %add15.i
  store i32 %21, i32 addrspace(1)* %22, align 4
  br label %math_kernel.inner.exit

math_kernel.inner.exit:
  ret void
}

declare { [0 x i32] } addrspace(1)* @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i32] })

declare { [0 x i32] } addrspace(1)* @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { [0 x i32] })

!0 = !{i32 1, i32 4, i32 7}

; CHECK-NOT: OpTypeInt 2 0
; CHECK: OpTypeInt 8 0
