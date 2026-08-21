; RUN: clspv-opt %s -o %t.ll --passes=spirv-producer -producer-out-file %t.spv
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val %t.spv

; RUN: clspv-opt %s -o %t.flush.ll --passes=spirv-producer -producer-out-file %t.flush.spv -denorm-flush-to-zero=16,64
; RUN: spirv-dis %t.flush.spv -o %t.flush.spvasm
; RUN: FileCheck %s --check-prefix=CHECK-FLUSH < %t.flush.spvasm
; RUN: spirv-val --target-env spv1.4 %t.flush.spv

; CHECK-DAG: [[half:%[a-zA-Z0-9_]+]] = OpTypeFloat 16
; CHECK: [[ld0:%[a-zA-Z0-9_]+]] = OpLoad [[half]]
; CHECK: [[ld1:%[a-zA-Z0-9_]+]] = OpLoad [[half]]
; CHECK: [[min:%[a-zA-Z0-9_]+]] = OpExtInst [[half]] %{{.*}} NMin [[ld0]] [[ld1]]
; CHECK: OpStore {{.*}} [[min]]

; CHECK-FLUSH-DAG: [[half:%[a-zA-Z0-9_]+]] = OpTypeFloat 16
; CHECK-FLUSH-DAG: [[ushort:%[a-zA-Z0-9_]+]] = OpTypeInt 16 0
; CHECK-FLUSH-DAG: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
; CHECK-FLUSH-DAG: [[half_min_norm:%[a-zA-Z0-9_]+]] = OpConstant [[half]] 0x1p-14
; CHECK-FLUSH: [[ld0:%[a-zA-Z0-9_]+]] = OpLoad [[half]]
; CHECK-FLUSH: [[ld1:%[a-zA-Z0-9_]+]] = OpLoad [[half]]
; CHECK-FLUSH: [[sign0:%[a-zA-Z0-9_]+]] = OpBitcast [[half]]
; CHECK-FLUSH: [[abs0:%[a-zA-Z0-9_]+]] = OpBitcast [[half]]
; CHECK-FLUSH: [[cond0:%[a-zA-Z0-9_]+]] = OpFOrdLessThan [[bool]] [[abs0]] [[half_min_norm]]
; CHECK-FLUSH: [[canon0:%[a-zA-Z0-9_]+]] = OpSelect [[half]] [[cond0]] [[sign0]] [[ld0]]
; CHECK-FLUSH: [[sign1:%[a-zA-Z0-9_]+]] = OpBitcast [[half]]
; CHECK-FLUSH: [[abs1:%[a-zA-Z0-9_]+]] = OpBitcast [[half]]
; CHECK-FLUSH: [[cond1:%[a-zA-Z0-9_]+]] = OpFOrdLessThan [[bool]] [[abs1]] [[half_min_norm]]
; CHECK-FLUSH: [[canon1:%[a-zA-Z0-9_]+]] = OpSelect [[half]] [[cond1]] [[sign1]] [[ld1]]
; CHECK-FLUSH: [[min:%[a-zA-Z0-9_]+]] = OpExtInst [[half]] %{{.*}} NMin [[canon0]] [[canon1]]
; CHECK-FLUSH: OpStore {{.*}} [[min]]

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv32-unknown-vulkan"

define dso_local spir_kernel void @test(ptr addrspace(1) nocapture writeonly align 2 %out) !clspv.pod_args_impl !8 {
entry:
  %0 = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x half] } zeroinitializer)
  %1 = getelementptr { [0 x half] }, ptr addrspace(1) %0, i32 0, i32 0, i32 0
  %ld1 = load half, ptr addrspace(1) %1, align 2
  %2 = getelementptr { [0 x half] }, ptr addrspace(1) %0, i32 0, i32 0, i32 1
  %ld2 = load half, ptr addrspace(1) %2, align 2
  %res = call spir_func half @_Z4fminDhDh(half %ld1, half %ld2)
  %3 = getelementptr { [0 x half] }, ptr addrspace(1) %0, i32 0, i32 0, i32 2
  store half %res, ptr addrspace(1) %3, align 2
  ret void
}

declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x half] })
declare spir_func half @_Z4fminDhDh(half, half)

!8 = !{i32 2}
