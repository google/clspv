; RUN: clspv-opt %s -o %t.ll --passes=simplify-pointer-bitcast
; RUN: FileCheck %s < %t.ll

; CHECK-LABEL: @repro
; CHECK: getelementptr inbounds %struct.outer_t, ptr %c, i32 0, i32 1, i32 1
; CHECK: getelementptr inbounds %struct.outer_t, ptr %c, i32 0, i32 1, i32 1, i32 2
; CHECK-NOT: getelementptr {{.*}} %struct.inner_t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spirv32-unknown-vulkan"

%struct.outer_t = type { %struct.inner_t, %struct.inner_t }
%struct.inner_t = type { [4 x i32], [4 x i32], [4 x i32], [4 x i32], [4 x i32], i32 }

define spir_kernel void @repro(ptr addrspace(1) align 4 %out, i32 %seed) {
entry:
  %c = alloca %struct.outer_t, align 4
  %opad = getelementptr inbounds nuw %struct.outer_t, ptr %c, i32 0, i32 1
  %w0 = getelementptr inbounds nuw %struct.inner_t, ptr %opad, i32 0, i32 1
  store [4 x i32] zeroinitializer, ptr %w0, align 4
  %opad5 = getelementptr inbounds nuw %struct.outer_t, ptr %c, i32 0, i32 1
  %w06 = getelementptr inbounds nuw %struct.inner_t, ptr %opad5, i32 0, i32 1
  %arrayidx7 = getelementptr inbounds [4 x i32], ptr %w06, i32 0, i32 2
  store i32 %seed, ptr %arrayidx7, align 4
  ret void
}
