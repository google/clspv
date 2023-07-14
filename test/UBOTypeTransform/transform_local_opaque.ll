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


; CHECK: define dso_local spir_kernel void @foo(ptr addrspace(1){{.*}} align 16 {{%[a-zA-Z0-9_.]+}}, ptr addrspace(2){{.*}} align 16 {{%[a-zA-Z0-9_.]+}}, ptr addrspace(3) {{.*}} align 16 {{%[a-zA-Z0-9_.]+}}) !clspv.pod_args_impl [[POD_IMPL_MD:![0-9]+]] {
define dso_local spir_kernel void @foo(ptr addrspace(1) nocapture writeonly align 16 %data, ptr addrspace(2) nocapture readonly align 16 %c_arg, ptr addrspace(3) nocapture readonly align 16 %l_arg) !clspv.pod_args_impl !0 {
entry:
; get args
; CHECK: [[ARG_LOCAL:%[a-zA-Z0-9_.]+]] = call ptr addrspace(3) @_Z11clspv.local.3(i32 3, [0 x [[DATA_TYPE]]] zeroinitializer)
; CHECK: [[ARG_GLOBAL:%[a-zA-Z0-9_.]+]] = call ptr addrspace(1) @_Z14clspv.resource.0({{.*}} [[DATA_TYPE_ARR]] zeroinitializer)
; CHECK: [[ARG_CONST:%[a-zA-Z0-9_.]+]] = call ptr addrspace(2) @_Z14clspv.resource.1({{.*}} [[CONST_DATA_TYPE_ARR]] zeroinitializer)
  %arg_local = call ptr addrspace(3) @_Z11clspv.local.3(i32 3, [0 x %data_type] zeroinitializer)
  %arg_global = call ptr addrspace(1) @_Z14clspv.resource.0(i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, %var_array zeroinitializer)
  %arg_const = call ptr addrspace(2) @_Z14clspv.resource.1(i32 0, i32 1, i32 1, i32 1, i32 1, i32 0, %large_array zeroinitializer)

; load constant addr space arg value
; CHECK: [[CONST_PTR:%[a-zA-Z0-9_.]+]] = getelementptr [[CONST_DATA_TYPE_ARR]], ptr addrspace(2) [[ARG_CONST]]
; CHECK: [[CONST_VAL:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(2) [[CONST_PTR]], align 16
  %const_ptr = getelementptr %large_array, ptr addrspace(2) %arg_const, i32 0, i32 0, i32 0, i32 0
  %const_val = load i32, ptr addrspace(2) %const_ptr, align 16

; load local addr space arg value
; CHECK: [[LOCAL_PTR:%[a-zA-Z0-9_.]+]] = getelementptr [0 x [[DATA_TYPE]]], ptr addrspace(3) [[ARG_LOCAL]]
; CHECK: [[LOCAL_VAL:%[a-zA-Z0-9_.]+]] = load i32, ptr addrspace(3) [[LOCAL_PTR]], align 16
  %local_ptr = getelementptr [0 x %data_type], ptr addrspace(3) %arg_local, i32 0, i32 0, i32 0
  %local_val = load i32, ptr addrspace(3) %local_ptr, align 16

; CHECK: [[SUM:%[a-zA-Z0-9_.]+]] = add nsw i32 [[LOCAL_VAL]], [[CONST_VAL]]
  %sum = add nsw i32 %local_val, %const_val

; store to global address space
; CHECK: [[GLOBAL_PTR:%[a-zA-Z0-9_.]+]] = getelementptr [[DATA_TYPE_ARR]], ptr addrspace(1) [[ARG_GLOBAL]]
; CHECK: store i32 [[SUM]], ptr addrspace(1) [[GLOBAL_PTR]], align 16
  %global_ptr = getelementptr %var_array, ptr addrspace(1) %arg_global, i32 0, i32 0, i32 0, i32 0
  store i32 %sum, ptr addrspace(1) %global_ptr, align 16
  ret void
}

; DECLARE-DAG: declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, [[DATA_TYPE_ARR]])
; DECLARE-DAG: declare ptr addrspace(2) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, [[CONST_DATA_TYPE_ARR]])
; DECLARE-DAG: declare ptr addrspace(3) @_Z11clspv.local.3(i32, [0 x [[DATA_TYPE]]])
declare ptr addrspace(1) @_Z14clspv.resource.0(i32, i32, i32, i32, i32, i32, %var_array)
declare ptr addrspace(2) @_Z14clspv.resource.1(i32, i32, i32, i32, i32, i32, %large_array)
declare ptr addrspace(3) @_Z11clspv.local.3(i32, [0 x %data_type])

; CHECK: [[POD_IMPL_MD]] = !{i32 2}
!0 = !{i32 2}
