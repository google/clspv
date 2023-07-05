; RUN: clspv-opt %s -o %t.ll --passes=logical-pointer-to-int
; RUN: FileCheck %s < %t.ll

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

define dso_local spir_func i32 @get(ptr %pointer) {
entry:
  %call = ptrtoint ptr %pointer to i32
  ret i32 %call
}

define dso_local spir_func i32 @bar(ptr %pointer) {
entry:
  %call = call spir_func i32 @get(ptr %pointer)
  ret i32 %call
}

define dso_local spir_kernel void @foo(ptr %dst) {
entry:
  %call = call spir_func i32 @bar(ptr %dst)
; CHECK:  store i32 268435456, ptr %dst, align 4
  store i32 %call, ptr %dst, align 4
  ret void
}


