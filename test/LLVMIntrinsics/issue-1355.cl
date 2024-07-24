// RUN: clspv %target %s -o %t.spv -cl-std=CLC++ -inline-entry-points
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK: [[src_ptr:%[a-zA-Z0-9_]+]] = OpAccessChain %_ptr_StorageBuffer_uint
// CHECK: [[dst_ptr:%[a-zA-Z0-9_]+]] = OpAccessChain %_ptr_StorageBuffer_uint
// CHECK: [[data:%[a-zA-Z0-9_]+]] = OpLoad %uint [[src_ptr]]
// CHECK: OpStore [[dst_ptr]] [[data]]

kernel void kern(global int *ptr, global int *out) {
    int priv = {};
    int *ppriv = &priv;
    int *pglob = out;
    __builtin_memcpy(pglob, ptr, 1 * sizeof(int));
    __builtin_memcpy(ppriv, ptr, 1 * sizeof(int));
}
