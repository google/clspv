; RUN: clspv -x=ir -arch=spirv64 %s -o %t.spv
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env vulkan1.0 %t.spv

; RUN: clspv -x=ir -arch=spirv64 -physical-storage-buffers %s -o %t.spv
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env vulkan1.2 %t.spv

; %p32 points to the second i32 of in[32 * group_id + local_id + 16].

; CHECK-DAG: [[uint:%[^ ]+]] = OpTypeInt 32 0
; CHECK-DAG: [[ulong:%[^ ]+]] = OpTypeInt 64 0
; CHECK-DAG: [[v2uint:%[^ ]+]] = OpTypeVector [[uint]] 2
; CHECK-DAG: [[ulong_16:%[^ ]+]] = OpConstant [[ulong]] 16
; CHECK: OpIAdd [[ulong]] {{%[^ ]+}} [[ulong_16]]
; CHECK: [[ld:%[^ ]+]] = OpLoad [[ulong]]
; CHECK: [[vec:%[^ ]+]] = OpBitcast [[v2uint]] [[ld]]
; CHECK: [[hi:%[^ ]+]] = OpCompositeExtract [[uint]] [[vec]] 1
; CHECK: OpIAdd [[uint]] [[hi]]

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64-G1"
target triple = "spirv64-unknown-vulkan"

declare spir_func i64 @_Z12get_group_idj(i32)
declare spir_func i64 @_Z12get_local_idj(i32)

define spir_kernel void @foo(ptr addrspace(1) %in, ptr addrspace(1) %out) {
entry:
  %gid = call spir_func i64 @_Z12get_group_idj(i32 0)
  %lid = call spir_func i64 @_Z12get_local_idj(i32 0)
  %gid_idx = shl i64 %gid, 5
  %base = getelementptr i64, ptr addrspace(1) %in, i64 %gid_idx
  %lid_off = shl i64 %lid, 3
  %p64 = getelementptr i8, ptr addrspace(1) %base, i64 %lid_off
  %ld64 = load i64, ptr addrspace(1) %p64, align 8
  %hi_off = add i64 %lid_off, 132
  %p32 = getelementptr i8, ptr addrspace(1) %base, i64 %hi_off
  %ld32 = load i32, ptr addrspace(1) %p32, align 4
  %trunc = trunc i64 %ld64 to i32
  %add = add i32 %ld32, %trunc
  %pout = getelementptr i32, ptr addrspace(1) %out, i64 %lid
  store i32 %add, ptr addrspace(1) %pout, align 4
  ret void
}
