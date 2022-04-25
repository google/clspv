; RUN: clspv-opt --passes=spirv-producer %s -o %t.ll -producer-out-file %t.spv -spv-version=1.4
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env vulkan1.1spv1.4 %t.spv

; CHECK-NOT: OpCapability VariablePointers
; CHECK-DAG: OpCapability VariablePointersStorageBuffer
; CHECK-DAG: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
; CHECK-DAG: [[uint_storage_buffer_ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[uint]]
; CHECK-DAG: [[uint_0:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 0
; CHECK-DAG: [[uint_13:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 13
; CHECK-DAG: [[bool:%[a-zA-Z0-9_]+]] = OpTypeBool
; CHECK: [[arg0ptr:%[a-zA-Z0-9_]+]] = OpAccessChain [[uint_storage_buffer_ptr]] [[arg0:%[a-zA-Z0-9_]+]] [[uint_0]] [[uint_0]]
; CHECK: [[arg0ptr2:%[a-zA-Z0-9_]+]] = OpAccessChain [[uint_storage_buffer_ptr]] [[arg0]] [[uint_0]] [[uint_13]]
; CHECK: [[arg1ptr:%[a-zA-Z0-9_]+]] = OpAccessChain [[uint_storage_buffer_ptr]] [[arg1:%[a-zA-Z0-9_]+]] [[uint_0]] [[uint_0]]
; CHECK: OpPtrEqual [[bool]] [[arg0ptr]] [[arg1ptr]]
; CHECK: OpPtrNotEqual [[bool]] [[arg0ptr]] [[arg1ptr]]
; CHECK: [[diff_ugt:%[a-zA-Z0-9_]+]] = OpPtrDiff [[uint]] [[arg0ptr]] [[arg0ptr2]]
; CHECK: OpSGreaterThan [[bool]] [[diff_ugt]] [[uint_0]]
; CHECK: [[diff_ult:%[a-zA-Z0-9_]+]] = OpPtrDiff [[uint]] [[arg0ptr]] [[arg0ptr2]]
; CHECK: OpSLessThan [[bool]] [[diff_ult]] [[uint_0]]
; CHECK: [[diff_uge:%[a-zA-Z0-9_]+]] = OpPtrDiff [[uint]] [[arg0ptr]] [[arg0ptr2]]
; CHECK: OpSGreaterThanEqual [[bool]] [[diff_uge]] [[uint_0]]
; CHECK: [[diff_ule:%[a-zA-Z0-9_]+]] = OpPtrDiff [[uint]] [[arg0ptr]] [[arg0ptr2]]
; CHECK: OpSLessThanEqual [[bool]] [[diff_ule]] [[uint_0]]


target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer

define dso_local spir_kernel void @test(i32 addrspace(1)* readnone %ptr0, i32 addrspace(1)* readnone %ptr1, i32 addrspace(1)* nocapture %out) local_unnamed_addr !clspv.pod_args_impl !9 {
entry:
  %0 = call { [0 x i32] } addrspace(1)* @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0)
  %arg0ptr = getelementptr { [0 x i32] }, { [0 x i32] } addrspace(1)* %0, i32 0, i32 0, i32 0
  %arg0ptr2 = getelementptr { [0 x i32] }, { [0 x i32] } addrspace(1)* %0, i32 0, i32 0, i32 13
  %1 = call { [0 x i32] } addrspace(1)* @_Z14clspv.resource.1(i32 0, i32 1, i32 0, i32 1, i32 1, i32 0)
  %arg1ptr = getelementptr { [0 x i32] }, { [0 x i32] } addrspace(1)* %1, i32 0, i32 0, i32 0
  %2 = call { [0 x i32] } addrspace(1)* @_Z14clspv.resource.2(i32 0, i32 2, i32 0, i32 2, i32 2, i32 0)
  %3 = getelementptr { [0 x i32] }, { [0 x i32] } addrspace(1)* %2, i32 0, i32 0, i32 0
  %cmp = icmp eq i32 addrspace(1)* %arg0ptr, %arg1ptr
  %conv = zext i1 %cmp to i32
  store i32 %conv, i32 addrspace(1)* %3, align 4
  %cmp1 = icmp ne i32 addrspace(1)* %arg0ptr, %arg1ptr
  %conv2 = zext i1 %cmp1 to i32
  %4 = getelementptr { [0 x i32] }, { [0 x i32] } addrspace(1)* %2, i32 0, i32 0, i32 1
  store i32 %conv2, i32 addrspace(1)* %4, align 4
  %cmp4 = icmp ugt i32 addrspace(1)* %arg0ptr, %arg0ptr2
  %conv5 = zext i1 %cmp4 to i32
  %5 = getelementptr { [0 x i32] }, { [0 x i32] } addrspace(1)* %2, i32 0, i32 0, i32 2
  store i32 %conv5, i32 addrspace(1)* %5, align 4
  %cmp7 = icmp ult i32 addrspace(1)* %arg0ptr, %arg0ptr2
  %conv8 = zext i1 %cmp7 to i32
  %6 = getelementptr { [0 x i32] }, { [0 x i32] } addrspace(1)* %2, i32 0, i32 0, i32 3
  store i32 %conv8, i32 addrspace(1)* %6, align 4
  %cmp10 = icmp uge i32 addrspace(1)* %arg0ptr, %arg0ptr2
  %conv11 = zext i1 %cmp10 to i32
  %7 = getelementptr { [0 x i32] }, { [0 x i32] } addrspace(1)* %2, i32 0, i32 0, i32 4
  store i32 %conv11, i32 addrspace(1)* %7, align 4
  %cmp13 = icmp ule i32 addrspace(1)* %arg0ptr, %arg0ptr2
  %conv14 = zext i1 %cmp13 to i32
  %8 = getelementptr { [0 x i32] }, { [0 x i32] } addrspace(1)* %2, i32 0, i32 0, i32 5
  store i32 %conv14, i32 addrspace(1)* %8, align 4
  ret void
}

declare { [0 x i32] } addrspace(1)* @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32)

declare { [0 x i32] } addrspace(1)* @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32)

declare { [0 x i32] } addrspace(1)* @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32)

!clspv.descriptor.index = !{!4}

!4 = !{i32 1}
!9 = !{i32 2}
