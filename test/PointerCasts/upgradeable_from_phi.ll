; RUN: clspv-opt --passes=simplify-pointer-bitcast %s -o %t.ll
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK-DAG: phi ptr addrspace(1) [ [[gepA:%[^ ]+]], %blockA ], [ [[gepB:%[^ ]+]], %blockB ]
; CHECK-DAG: [[gepA]] = getelementptr <4 x i8>, ptr addrspace(1) %a, i32 2
; CHECK-DAG: [[gepB]] = getelementptr <4 x i8>, ptr addrspace(1) %a, i32 32

define spir_kernel void @foo(ptr addrspace(1) %a, i1 %cmp) {
entry:
  br i1 %cmp, label %blockA, label %blockB
blockA:
  %gepA = getelementptr <4 x i8>, ptr addrspace(1) %a, i32 2
  br label %end
blockB:
  %gepB = getelementptr i8, ptr addrspace(1) %a, i32 128
  br label %end
end:
  %phi = phi ptr addrspace(1) [ %gepA, %blockA ], [ %gepB, %blockB ]
  ret void
}
