; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

; CHECK-DAG: [[out:%[a-zA-Z0-9_.]+]] = type { { i32 }, { i32 } }
; CHECK-DAG: [[in:%[a-zA-Z0-9_.]+]] = type { { [2 x i16] }, { <4 x i8> } }

; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load [[in]], [[in]] addrspace(1)*
; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractvalue [[in]] [[ld]], 0
; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = extractvalue { [2 x i16] } [[ex]], 0
; CHECK: [[ex0_0:%[a-zA-Z0-9_.]+]] = extractvalue [2 x i16] [[ex0]], 0
; CHECK: [[ex0_1:%[a-zA-Z0-9_.]+]] = extractvalue [2 x i16] [[ex0]], 1
; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractvalue [[in]] [[ld]], 1
; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = extractvalue { <4 x i8> } [[ex]], 0
; CHECK: [[ex1_0:%[a-zA-Z0-9_.]+]] = extractelement <4 x i8> [[ex1]], i64 0
; CHECK: [[ex1_1:%[a-zA-Z0-9_.]+]] = extractelement <4 x i8> [[ex1]], i64 1
; CHECK: [[ex1_2:%[a-zA-Z0-9_.]+]] = extractelement <4 x i8> [[ex1]], i64 2
; CHECK: [[ex1_3:%[a-zA-Z0-9_.]+]] = extractelement <4 x i8> [[ex1]], i64 3

; CHECK: [[zext0_0:%[a-zA-Z0-9_.]+]] = zext i16 [[ex0_0]] to i64
; CHECK: [[zext0_1:%[a-zA-Z0-9_.]+]] = zext i16 [[ex0_1]] to i64
; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i64 [[zext0_1]], 16
; CHECK: [[or1:%[a-zA-Z0-9_.]+]] = or i64 [[zext0_0]], [[shl]]
; CHECK: [[zext1_0:%[a-zA-Z0-9_.]+]] = zext i8 [[ex1_0]] to i64
; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i64 [[zext1_0]], 32
; CHECK: [[or2:%[a-zA-Z0-9_.]+]] = or i64 [[or1]], [[shl]]
; CHECK: [[zext1_1:%[a-zA-Z0-9_.]+]] = zext i8 [[ex1_1]] to i64
; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i64 [[zext1_1]], 40
; CHECK: [[or3:%[a-zA-Z0-9_.]+]] = or i64 [[or2]], [[shl]]
; CHECK: [[zext1_2:%[a-zA-Z0-9_.]+]] = zext i8 [[ex1_2]] to i64
; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i64 [[zext1_2]], 48
; CHECK: [[or4:%[a-zA-Z0-9_.]+]] = or i64 [[or3]], [[shl]]
; CHECK: [[zext1_3:%[a-zA-Z0-9_.]+]] = zext i8 [[ex1_3]] to i64
; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i64 [[zext1_3]], 56
; CHECK: [[or:%[a-zA-Z0-9_.]+]] = or i64 [[or4]], [[shl]]

; CHECK: [[trunc:%[a-zA-Z0-9_.]+]] = trunc i64 [[or]] to i32
; CHECK: [[insert:%[a-zA-Z0-9_.]+]] = insertvalue { i32 } undef, i32 [[trunc]], 0
; CHECK: [[insert0:%[a-zA-Z0-9_.]+]] = insertvalue [[out]] undef, { i32 } [[insert]], 0
; CHECK: [[shr:%[a-zA-Z0-9_.]+]] = lshr i64 [[or]], 32
; CHECK: [[trunc:%[a-zA-Z0-9_.]+]] = trunc i64 [[shr]] to i32
; CHECK: [[insert:%[a-zA-Z0-9_.]+]] = insertvalue { i32 } undef, i32 [[trunc]], 0
; CHECK: [[insert1:%[a-zA-Z0-9_.]+]] = insertvalue [[out]] [[insert0]], { i32 } [[insert]], 1
; CHECK: store [[out]] [[insert1]], [[out]] addrspace(1)*

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.__in = type { { [2 x i16] }, { <4 x i8> } }
%struct.__out = type { { i32 }, { i32 } }

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: norecurse nounwind
define spir_kernel void @testCopyInstance1(%struct.__in addrspace(1)* nocapture readonly %src, %struct.__out addrspace(1)* nocapture %dst) local_unnamed_addr #0 !kernel_arg_addr_space !3 !kernel_arg_access_qual !4 !kernel_arg_type !5 !kernel_arg_base_type !6 !kernel_arg_type_qual !7 {
entry:
  %0 = bitcast %struct.__in addrspace(1)* %src to i64 addrspace(1)*
  %1 = bitcast %struct.__out addrspace(1)* %dst to i64 addrspace(1)*
  %2 = load i64, i64 addrspace(1)* %0, align 4
  store i64 %2, i64 addrspace(1)* %1, align 4
  ret void
}

attributes #0 = { norecurse nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "denorms-are-zero"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.module.flags = !{!0}
!opencl.ocl.version = !{!1}
!opencl.spir.version = !{!1}
!llvm.ident = !{!2}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, i32 2}
!2 = !{!"clang version 9.0.0 (https://github.com/llvm-mirror/clang 7c21fe2c07d1df4480ddf35a03d218e0f5b4af3d) (https://github.com/llvm-mirror/llvm 26882c9d258b62748a7266207513a06990c8decc)"}
!3 = !{i32 1, i32 1}
!4 = !{!"none", !"none"}
!5 = !{!"InstanceTest*", !"InstanceTest*"}
!6 = !{!"struct __InstanceTest*", !"struct __InstanceTest*"}
!7 = !{!"const", !""}



