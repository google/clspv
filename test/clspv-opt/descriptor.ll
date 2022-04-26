; RUN: clspv-opt %s --passes=allocate-descriptors -o %t.ll 2> %t.out.txt
; RUN: FileCheck %s < %t.ll

; CHECK: %0 = call { [0 x i32] } addrspace(1)* @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0)

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(7) global <3 x i32> zeroinitializer

; Function Attrs: norecurse nounwind
define spir_kernel void @foo(i32 addrspace(1)* nocapture readonly %in, i32 addrspace(1)* nocapture %out) local_unnamed_addr #0 !kernel_arg_addr_space !3 !kernel_arg_access_qual !4 !kernel_arg_type !5 !kernel_arg_base_type !5 !kernel_arg_type_qual !6 {
entry:
  %0 = load i32, i32 addrspace(1)* %in, align 4
  store i32 %0, i32 addrspace(1)* %out, align 4
  ret void
}

attributes #0 = { norecurse nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="0" "stackrealign" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.module.flags = !{!0}
!opencl.ocl.version = !{!1}
!opencl.spir.version = !{!1}
!llvm.ident = !{!2}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, i32 2}
!2 = !{!"clang version 6.0.0 (https://github.com/llvm-mirror/clang 82fcdc620f7367f0ffc24b8ade93539e0bfd9e30) (https://github.com/llvm-mirror/llvm 82f73ee5b37a2a4cc1bdad02bebaaaba71b65400)"}
!3 = !{i32 1, i32 1}
!4 = !{!"none", !"none"}
!5 = !{!"int*", !"int*"}
!6 = !{!"", !""}
