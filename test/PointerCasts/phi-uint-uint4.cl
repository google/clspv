// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0
// RUN: FileCheck %s < %t.spvasm

// CHECK: [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK: [[runtime:%[^ ]+]] = OpTypeRuntimeArray [[uint]]
// CHECK: [[struct:%[^ ]+]] = OpTypeStruct [[runtime]]
// CHECK: [[ptr:%[^ ]+]] = OpTypePointer StorageBuffer [[struct]]
// CHECK: [[uint_ptr:%[^ ]+]] = OpTypePointer StorageBuffer [[uint]]
// CHECK: [[var:%[^ ]+]] = OpVariable [[ptr]] StorageBuffer
// CHECK: [[gep:%[^ ]+]] = OpAccessChain [[uint_ptr]] [[var]]
// CHECK: [[phi:%[^ ]+]] = OpPhi [[uint_ptr]] [[gep]] [[label:%[^ ]+]] [[gep2:%[^ ]+]] [[label2:%[^ ]+]]
// CHECK: [[gep2]] = OpPtrAccessChain [[uint_ptr]] [[phi]]


void kernel foo(__global uint* buf, uint cst) {
    size_t gid = get_global_id(0);
    __global uint4* buf4 = buf + gid * 4 * cst;
    uint acc = 0;
    do {
        acc += buf4[0].x;
        buf4 += 4;
    } while (cst--);
    buf[gid] = acc;
}
