// RUN: clspv %s --emit-ir=%t.ll
// RUN: FileCheck %s < %t.ll

void kernel foo(global double *out, int in)
{
  *out = in / 2.304;
}

// CHECK: define spir_kernel void @foo(double addrspace(1)* %out, i32 %in) #0 !kernel_arg_addr_space !3 !kernel_arg_access_qual !4 !kernel_arg_type !5 !kernel_arg_base_type !5 !kernel_arg_type_qual !6 {
// CHECK: entry:
// CHECK:   %out.addr = alloca double addrspace(1)*, align 4
// CHECK:   %in.addr = alloca i32, align 4
// CHECK:   %1 = load double addrspace(1)*, double addrspace(1)** %out.addr, align 4
// CHECK:  store double %div, double addrspace(1)* %1, align 8
