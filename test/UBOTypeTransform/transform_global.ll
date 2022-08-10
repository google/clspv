; RUN: clspv-opt -int8=0 -constant-args-ubo --passes=ubo-type-transform %s -o %t
; RUN: FileCheck --check-prefixes TYPE,CHECK %s < %t
; RUN: FileCheck --check-prefixes TYPE,DECLARE %s < %t

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; TYPE-DAG: [[DATA_TYPE:%[a-zA-Z0-9_.]+]] = type { i32, i32 }
; TYPE-DAG: [[DATA_TYPE_ARR:%[a-zA-Z0-9_.]+]] = type { [0 x [[DATA_TYPE]]] }
; TYPE-DAG: [[CONST_DATA_TYPE_ARR:%[a-zA-Z0-9_.]+]] = type { [4096 x [[DATA_TYPE]]] }
%data_type = type { i32, [12 x i8] }
%var_array = type { [0 x %data_type] }
%large_array = type { [4096 x %data_type] }

; CHECK-DAG: [[GLOBAL_CONSTANT:@[a-zA-Z0-9_.]+]] = local_unnamed_addr addrspace(2) constant [2 x [[DATA_TYPE]]] [[[DATA_TYPE]] { i32 0, i32 undef }, [[DATA_TYPE]] { i32 1, i32 undef }], align 16
@c_var = local_unnamed_addr addrspace(2) constant [2 x %data_type] [%data_type { i32 0, [12 x i8] undef }, %data_type { i32 1, [12 x i8] undef }], align 16

; CHECK: define spir_kernel void @foo([[DATA_TYPE]] addrspace(1)* {{.*}} align 16 {{%[a-zA-Z0-9_.]+}}, [[DATA_TYPE]] addrspace(2)* {{.*}} align 16 {{%[a-zA-Z0-9_.]+}}, { i32 } {{%[a-zA-Z0-9_.]+}}) !clspv.pod_args_impl [[POD_IMPL_MD:![0-9]+]] {
define spir_kernel void @foo(%data_type addrspace(1)* nocapture writeonly align 16 %global_arg, %data_type addrspace(2)* nocapture readonly align 16 %constant_arg, { i32 } %int_arg) !clspv.pod_args_impl !0 {
entry:
; access arguments
  ; CHECK: [[GLOBAL:%[a-zA-Z0-9_.]+]] = call [[DATA_TYPE_ARR]] addrspace(1)* @_Z14clspv.resource.0({{.*}} [[DATA_TYPE_ARR]] zeroinitializer)
  ; CHECK: [[CONSTANT:%[a-zA-Z0-9_.]+]] = call [[CONST_DATA_TYPE_ARR]] addrspace(2)* @_Z14clspv.resource.1({{.*}} [[CONST_DATA_TYPE_ARR]] zeroinitializer)
  %global = call %var_array addrspace(1)* @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, %var_array zeroinitializer)
  %constant = call %large_array addrspace(2)* @_Z14clspv.resource.1(i32 0, i32 1, i32 1, i32 1, i32 1, i32 0, %large_array zeroinitializer)
  %n_push = call { { i32 } } addrspace(9)* @_Z14clspv.resource.2(i32 -1, i32 2, i32 5, i32 2, i32 2, i32 0, { { i32 } } zeroinitializer)
; get offset value, n, not expected to change
  %n_ptr = getelementptr { { i32 } }, { { i32 } } addrspace(9)* %n_push, i32 0, i32 0
  %n_struct = load { i32 }, { i32 } addrspace(9)* %n_ptr, align 4
  %n = extractvalue { i32 } %n_struct, 0
; read value from constant address space
  ; CHECK: getelementptr [[CONST_DATA_TYPE_ARR]], [[CONST_DATA_TYPE_ARR]] addrspace(2)* [[CONSTANT]]
  %constant_ptr = getelementptr %large_array, %large_array addrspace(2)* %constant, i32 0, i32 0, i32 %n, i32 0
  %constant_x_val = load i32, i32 addrspace(2)* %constant_ptr, align 16

; add the global constant
  ; CHECK: [[C_VAR_PTR:%[a-zA-Z0-9_.]+]] = getelementptr inbounds [2 x [[DATA_TYPE]]], [2 x [[DATA_TYPE]]] addrspace(2)* [[GLOBAL_CONSTANT]]
  ; CHECK: load i32, i32 addrspace(2)* [[C_VAR_PTR]], align 16
  %c_var_ptr = getelementptr inbounds [2 x %data_type], [2 x %data_type] addrspace(2)* @c_var, i32 0, i32 %n, i32 0
  %c_var_val = load i32, i32 addrspace(2)* %c_var_ptr, align 16
  %x_plus_c = add nsw i32 %c_var_val, %constant_x_val

; store back to global address space
  ; CHECK: getelementptr [[DATA_TYPE_ARR]], [[DATA_TYPE_ARR]] addrspace(1)* [[GLOBAL]]
  %global_ptr = getelementptr %var_array, %var_array addrspace(1)* %global, i32 0, i32 0, i32 %n, i32 0
  store i32 %x_plus_c, i32 addrspace(1)* %global_ptr, align 16
  ret void
}

; DECLARE-DAG: declare [[DATA_TYPE_ARR]] addrspace(1)* @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, [[DATA_TYPE_ARR]])
; DECLARE-DAG: declare [[CONST_DATA_TYPE_ARR]] addrspace(2)* @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, [[CONST_DATA_TYPE_ARR]])
; DECLARE-DAG: declare { { i32 } } addrspace(9)* @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { { i32 } })
; functions used to access constant address space
declare %var_array addrspace(1)* @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, %var_array)
declare %large_array addrspace(2)* @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, %large_array)
declare { { i32 } } addrspace(9)* @_Z14clspv.resource.2(i32, i32, i32, i32, i32, i32, { { i32 } })

; CHECK: [[POD_IMPL_MD]] = !{i32 2}
!0 = !{i32 2} ; PodArgImpl::kPushConstant
