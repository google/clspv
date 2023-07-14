; RUN: clspv-opt %s -o %t --passes=cluster-constants
; RUN: FileCheck %s < %t

; Checks are split up due to problems with parsing regexs in FileCheck.
; CHECK: [[global:@[a-zA-Z0-9_.]+]] = internal addrspace(2) constant { [17 x [4 x i32]] }
; CHECK-SAME: [4 x i32] [i32 1, i32 1, i32 1, i32 1]
; CHECK-SAME: [4 x i32] [i32 1, i32 1, i32 1, i32 1]
; CHECK-SAME: [4 x i32] [i32 1, i32 0, i32 0, i32 0]
; CHECK-SAME: [4 x i32] zeroinitializer
; CHECK-SAME: [4 x i32] zeroinitializer
; CHECK-SAME: [4 x i32] zeroinitializer
; CHECK-SAME: [4 x i32] [i32 0, i32 0, i32 1, i32 1]
; CHECK-SAME: [4 x i32] [i32 1, i32 1, i32 1, i32 1]
; CHECK-SAME: [4 x i32] [i32 1, i32 1, i32 0, i32 0]
; CHECK-SAME: [4 x i32] zeroinitializer
; CHECK-SAME: [4 x i32] zeroinitializer
; CHECK-SAME: [4 x i32] zeroinitializer
; CHECK-SAME: [4 x i32] [i32 0, i32 0, i32 0, i32 1]
; CHECK-SAME: [4 x i32] [i32 1, i32 1, i32 1, i32 1]
; CHECK-SAME: [4 x i32] [i32 1, i32 1, i32 1, i32 1]
; CHECK-SAME: [4 x i32] [i32 1, i32 1, i32 1, i32 1]
; CHECK-SAME: [4 x i32] [i32 1, i32 1, i32 1, i32 1]
; CHECK: [[gep:%[a-zA-Z0-9_]+]] = getelementptr inbounds { [17 x [4 x i32]] }, ptr addrspace(2) [[global]], i32 0, i32 0
; CHECK: getelementptr inbounds [17 x [4 x i32]], ptr addrspace(2) [[gep]], i32 0, i32 0, i32 0

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@data = addrspace(2) constant <{ <{ [9 x i32], [8 x i32] }>, [17 x i32], [17 x i32], [17 x i32] }> <{ <{ [9 x i32], [8 x i32] }> <{ [9 x i32] [i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1], [8 x i32] zeroinitializer }>, [17 x i32] [i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1], [17 x i32] zeroinitializer, [17 x i32] [i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1] }>, align 4
@__spirv_WorkgroupSize = addrspace(8) global <3 x i32> zeroinitializer

; Function Attrs: convergent nounwind
define spir_kernel void @foo(ptr addrspace(1) %in, ptr addrspace(1) %out) #0 !kernel_arg_addr_space !3 !kernel_arg_access_qual !4 !kernel_arg_type !5 !kernel_arg_base_type !5 !kernel_arg_type_qual !6 {
entry:
  %gep = getelementptr inbounds [17 x [4 x i32]], ptr addrspace(2) @data, i32 0, i32 0, i32 0
  ret void
}

attributes #0 = { convergent nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "denorms-are-zero"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="0" "stackrealign" "uniform-work-group-size"="true" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.module.flags = !{!0}
!opencl.ocl.version = !{!1}
!opencl.spir.version = !{!1}
!llvm.ident = !{!2}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, i32 2}
!2 = !{!"clang version 9.0.0 (https://github.com/llvm-mirror/clang 7c21fe2c07d1df4480ddf35a03d218e0f5b4af3d) (https://github.com/llvm-mirror/llvm 26882c9d258b62748a7266207513a06990c8decc)"}
!3 = !{i32 1, i32 1}
!4 = !{!"none", !"none"}
!5 = !{!"int*", !"int*"}
!6 = !{!"", !""}

