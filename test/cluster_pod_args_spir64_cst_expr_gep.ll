; RUN: clspv-opt %s -o %t.ll --passes=cluster-pod-kernel-args-pass
; RUN: FileCheck %s < %t.ll

; CHECK: [[type:%[^ ]+]] = type { <3 x i32>, [[pc:%[^ ]+]] }
; CHECK: [[pc]] = type { i32, i32 }

; CHECK-COUNT-2: load i32, ptr addrspace(9) getelementptr inbounds ([[type]], ptr addrspace(9) @__push_constants, i32 0, i32 0, i64 2), align 4

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

%0 = type { <3 x i32> }

@__push_constants = addrspace(9) global %0 zeroinitializer, !push_constants !0
@__spirv_LocalInvocationId = addrspace(5) global <3 x i32> zeroinitializer

; Function Attrs: convergent norecurse nounwind
define dso_local spir_kernel void @main_function(i64 %0) !clspv.pod_args_impl !16 {
entry:
  %load = load i32, ptr addrspace(9) getelementptr inbounds (<3 x i32>, ptr addrspace(9) @__push_constants, i64 0, i64 2), align 4
  ret void
}

!0 = !{i32 6}
!16 = !{i32 3}
