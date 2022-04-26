; RUN: clspv-opt %s -o %t --passes=replace-pointer-bitcast
; RUN: FileCheck %s < %t

; CHECK: [[struct:%[a-zA-Z0-9_.]+]] = type { [4 x i16] }
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr [[struct]], [[struct]] addrspace(1)* %src, i32 0
; CHECK: [[ld:%[a-zA-Z0-9_.]+]] = load [[struct]], [[struct]] addrspace(1)* [[gep]]
; CHECK: [[ex:%[a-zA-Z0-9_.]+]] = extractvalue [[struct]] [[ld]], 0
; CHECK: [[ex0:%[a-zA-Z0-9_.]+]] = extractvalue [4 x i16] [[ex]], 0
; CHECK: [[ex1:%[a-zA-Z0-9_.]+]] = extractvalue [4 x i16] [[ex]], 1
; CHECK: [[ex2:%[a-zA-Z0-9_.]+]] = extractvalue [4 x i16] [[ex]], 2
; CHECK: [[ex3:%[a-zA-Z0-9_.]+]] = extractvalue [4 x i16] [[ex]], 3
; CHECK: [[zext0:%[a-zA-Z0-9_.]+]] = zext i16 [[ex0]] to i64
; CHECK: [[zext1:%[a-zA-Z0-9_.]+]] = zext i16 [[ex1]] to i64
; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i64 [[zext1]], 16
; CHECK: [[or1:%[a-zA-Z0-9_.]+]] = or i64 [[zext0]], [[shl]]
; CHECK: [[zext2:%[a-zA-Z0-9_.]+]] = zext i16 [[ex2]] to i64
; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i64 [[zext2]], 32
; CHECK: [[or2:%[a-zA-Z0-9_.]+]] = or i64 [[or1]], [[shl]]
; CHECK: [[zext3:%[a-zA-Z0-9_.]+]] = zext i16 [[ex3]] to i64
; CHECK: [[shl:%[a-zA-Z0-9_.]+]] = shl i64 [[zext3]], 48
; CHECK: [[or3:%[a-zA-Z0-9_.]+]] = or i64 [[or2]], [[shl]]
; CHECK: [[trunc0:%[a-zA-Z0-9_.]+]] = trunc i64 [[or3]] to i16
; CHECK: [[insert0:%[a-zA-Z0-9_.]+]] = insertvalue [4 x i16] undef, i16 [[trunc0]], 0
; CHECK: [[lshr:%[a-zA-Z0-9_.]+]] = lshr i64 [[or3]], 16
; CHECK: [[trunc1:%[a-zA-Z0-9_.]+]] = trunc i64 [[lshr]] to i16
; CHECK: [[insert1:%[a-zA-Z0-9_.]+]] = insertvalue [4 x i16] [[insert0]], i16 [[trunc1]], 1
; CHECK: [[lshr:%[a-zA-Z0-9_.]+]] = lshr i64 [[or3]], 32
; CHECK: [[trunc2:%[a-zA-Z0-9_.]+]] = trunc i64 [[lshr]] to i16
; CHECK: [[insert2:%[a-zA-Z0-9_.]+]] = insertvalue [4 x i16] [[insert1]], i16 [[trunc2]], 2
; CHECK: [[lshr:%[a-zA-Z0-9_.]+]] = lshr i64 [[or3]], 48
; CHECK: [[trunc3:%[a-zA-Z0-9_.]+]] = trunc i64 [[lshr]] to i16
; CHECK: [[insert3:%[a-zA-Z0-9_.]+]] = insertvalue [4 x i16] [[insert2]], i16 [[trunc3]], 3
; CHECK: [[insert:%[a-zA-Z0-9_.]+]] = insertvalue [[struct]] undef, [4 x i16] [[insert3]], 0
; CHECK: [[gep:%[a-zA-Z0-9_.]+]] = getelementptr [[struct]], [[struct]] addrspace(1)* %dst, i32 0
; CHECK: store [[struct]] [[insert]], [[struct]] addrspace(1)* [[gep]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.__InstanceTest = type { [4 x i16] }

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: norecurse nounwind
define spir_kernel void @testCopyInstance1(%struct.__InstanceTest addrspace(1)* nocapture readonly %src, %struct.__InstanceTest addrspace(1)* nocapture %dst) local_unnamed_addr #0 !kernel_arg_addr_space !3 !kernel_arg_access_qual !4 !kernel_arg_type !5 !kernel_arg_base_type !6 !kernel_arg_type_qual !7 {
entry:
  %0 = bitcast %struct.__InstanceTest addrspace(1)* %src to i64 addrspace(1)*
  %1 = bitcast %struct.__InstanceTest addrspace(1)* %dst to i64 addrspace(1)*
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

