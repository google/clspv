; RUN: clspv-opt --passes=spirv-producer %s -o %t.ll -producer-out-file %t.spv -spv-version=1.4 -module-constants-in-storage-buffer
; RUN: spirv-dis %t.spv -o %t.spvasm
; RUN: FileCheck %s < %t.spvasm
; RUN: spirv-val --target-env vulkan1.1spv1.4 %t.spv

; CHECK: OpEntryPoint GLCompute %{{.*}} "test" {{.*}} [[constant_data_storage_buffer_var:%[a-zA-Z0-9_]+]]
; CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
; CHECK: [[uint_16:%[a-zA-Z0-9_]+]] = OpConstant [[uint]] 16
; CHECK: [[uint_array_16:%[a-zA-Z0-9_]+]] = OpTypeArray [[uint]] [[uint_16]]
; CHECK: [[struct_module_constants:%[a-zA-Z0-9_]+]] = OpTypeStruct [[uint_array_16]]
; CHECK: [[struct_module_constants_ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[struct_module_constants]]
; CHECK: [[constant_data_storage_buffer_var]] = OpVariable [[struct_module_constants_ptr]] StorageBuffer


target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

@__spirv_WorkgroupSize = local_unnamed_addr addrspace(8) global <3 x i32> zeroinitializer
@clspv.clustered_constants = internal addrspace(2) constant { [16 x i32] } { [16 x i32] [i32 17, i32 1, i32 11, i32 12, i32 1955, i32 11, i32 5, i32 1985, i32 113, i32 1, i32 24, i32 1984, i32 7, i32 23, i32 1979, i32 97] }

define spir_kernel void @test(i32 addrspace(1)* nocapture %out, { i32 } %podargs) local_unnamed_addr !clspv.pod_args_impl !9 !kernel_arg_map !10 {
entry:
  %0 = call { [0 x i32] } addrspace(1)* @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, { [0 x i32] } zeroinitializer)
  %1 = getelementptr { [0 x i32] }, { [0 x i32] } addrspace(1)* %0, i32 0, i32 0, i32 0
  %2 = call { { i32 } } addrspace(9)* @_Z14clspv.resource.1(i32 -1, i32 1, i32 5, i32 1, i32 1, i32 0, { { i32 } } zeroinitializer)
  %3 = getelementptr { { i32 } }, { { i32 } } addrspace(9)* %2, i32 0, i32 0
  %4 = load { i32 }, { i32 } addrspace(9)* %3, align 4
  %idx = extractvalue { i32 } %4, 0
  %5 = getelementptr inbounds { [16 x i32] }, { [16 x i32] } addrspace(2)* @clspv.clustered_constants, i32 0, i32 0, i32 %idx
  %6 = load i32, i32 addrspace(2)* %5, align 4
  store i32 %6, i32 addrspace(1)* %1, align 4
  ret void
}

declare { [0 x i32] } addrspace(1)* @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, { [0 x i32] })

declare { { i32 } } addrspace(9)* @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, { { i32 } })

!clspv.descriptor.index = !{!4}

!4 = !{i32 1}
!9 = !{i32 2}
!10 = !{!11, !12}
!11 = !{!"out", i32 0, i32 0, i32 0, i32 0, !"buffer"}
!12 = !{!"idx", i32 1, i32 1, i32 0, i32 4, !"pod_pushconstant"}
