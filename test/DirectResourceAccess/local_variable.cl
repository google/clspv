// RUN: clspv %target %s -o %t.spv -no-inline-single
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__attribute__((noinline))
void write_local(__global int* in, __local int* tmp, unsigned int id) {
  tmp[id] = in[id];
}

__attribute__((noinline))
void read_local(__global int* out, __local int* tmp, unsigned int id) {
  out[id] = tmp[id];
}

__kernel void local_memory(__global int* in, __global int* out) {
  __local int temp[32];
  unsigned int gid = get_global_id(0);
  write_local(in, temp, gid);
  barrier(CLK_LOCAL_MEM_FENCE | CLK_GLOBAL_MEM_FENCE);
  read_local(out, temp, gid);
}

// CHECK: OpEntryPoint GLCompute [[_46:%[0-9a-zA-Z_]+]] "local_memory"
// CHECK: OpDecorate [[_28:%[0-9a-zA-Z_]+]] Binding 0
// CHECK: OpDecorate [[_29:%[0-9a-zA-Z_]+]] Binding 1
// CHECK-DAG: [[_void:%[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: [[_21:%[0-9a-zA-Z_]+]] = OpVariable {{.*}} Workgroup
// CHECK-DAG: [[_28]] = OpVariable {{.*}} StorageBuffer
// CHECK-DAG: [[_29]] = OpVariable {{.*}} StorageBuffer
// CHECK: [[_46]] = OpFunction [[_void]]
// CHECK: [[_53:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_30:%[0-9a-zA-Z_]+]]
// CHECK: [[_55:%[0-9a-zA-Z_]+]] = OpFunctionCall [[_void]] [[_38:%[0-9a-zA-Z_]+]]
// CHECK: [[_30]] = OpFunction [[_void]]
// CHECK: [[_35:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_28]]
// CHECK: [[_37:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_21]]
// CHECK: [[_38]] = OpFunction [[_void]]
// CHECK: [[_43:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_21]]
// CHECK: [[_45:%[0-9a-zA-Z_]+]] = OpAccessChain {{.*}} [[_29]]
