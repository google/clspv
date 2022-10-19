; RUN: clspv-opt --passes=physical-pointer-args %s -o %t --physical-storage-buffers
; RUN: FileCheck %s < %t

; kernel void copy(global short *a, global int *b, int x, int y)

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

@__spirv_GlobalInvocationId = local_unnamed_addr addrspace(5) global <3 x i32> zeroinitializer
@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define spir_kernel void @copy(i16 addrspace(1)* %a, i32 addrspace(1)* %b, i32 %x, i32 %y) !clspv.pod_args_impl !0 {
entry:
  %0 = load i32, i32 addrspace(5)* getelementptr (<3 x i32>, <3 x i32> addrspace(5)* @__spirv_GlobalInvocationId, i64 0, i64 0), align 16
  %1 = zext i32 %0 to i64
  %arrayidx = getelementptr inbounds i16, i16 addrspace(1)* %a, i64 %1
  %2 = load i16, i16 addrspace(1)* %arrayidx, align 2
  %conv = sext i16 %2 to i32
  %add = add i32 %y, %x
  %add1 = add i32 %add, %conv
  %arrayidx2 = getelementptr inbounds i32, i32 addrspace(1)* %b, i64 %1
  store i32 %add1, i32 addrspace(1)* %arrayidx2, align 4
  ret void
}

!0 = !{i32 2}

; Check the pointer args are converted and used correctly
; CHECK: @copy(i64 %0, i64 %1, i32 %2, i32 %3)
; CHECK: %[[ptr_a:[0-9a-z]+]] = inttoptr i64 %0 to i16 addrspace(1)*, !clspv.pointer_from_pod
; CHECK: %[[ptr_b:[0-9a-z]+]] = inttoptr i64 %1 to i32 addrspace(1)*, !clspv.pointer_from_pod
; CHECK: getelementptr inbounds i16, i16 addrspace(1)* %[[ptr_a]]
; CHECK: getelementptr inbounds i32, i32 addrspace(1)* %[[ptr_b]]
