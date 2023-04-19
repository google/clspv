// RUN: clspv --cl-std=CLC++ --inline-entry-points %s -o %t.spv --show-producer-ir &> %t.ll
// RUN: spirv-val --target-env spv1.0 %t.spv
// RUN: FileCheck %s < %t.ll

// CHECK-NOT: addrspacecast
// CHECK-NOT: ptr addrspace({{.*}}) null

float loop(const float *data, unsigned num) {
    float res = 0;
    for (unsigned j = 0; j < num; ++j) {
        res += to_private(data)[j];
    }
    return res;
}

kernel void k(global float* out) {
    float in[128];
    unsigned index = get_global_id(0);
    out[index] = loop(in, index);
}
