// RUN: clspv %s -long-vector -o %t.spv -int8 -cluster-pod-kernel-args -std430-ubo-layout
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: clspv-reflection %t.spv -o %t.map -d
// RUN: FileCheck %s < %t.map -check-prefix=MAP
// RUN: spirv-val --target-env vulkan1.0 --uniform-buffer-standard-layout %t.spv

// Checks that the lowering of long-vector arguments doesn't invalidate the
// clustered POD arg struct's layout and the reflection data matches

__kernel void test(char8 c, uchar8 uc, short8 s, ushort8 us, int8 i, uint8 ui,
float8 f, __global float8 *result) {
    result[0] = convert_float8(c);
    result[1] = convert_float8(uc);
    result[2] = convert_float8(s);
    result[3] = convert_float8(us);
    result[4] = convert_float8(i);
    result[5] = convert_float8(ui);
    result[6] = f;
}

// CHECK: OpMemberDecorate [[struct_ssbo:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpMemberDecorate [[struct:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpMemberDecorate [[struct]] 1 Offset 8
// CHECK: OpMemberDecorate [[struct]] 2 Offset 16
// CHECK: OpMemberDecorate [[struct]] 3 Offset 32
// CHECK: OpMemberDecorate [[struct]] 4 Offset 64
// CHECK: OpMemberDecorate [[struct]] 5 Offset 96
// CHECK: OpMemberDecorate [[struct]] 6 Offset 128

// MAP: kernel,test,arg,c,argOrdinal,0,descriptorSet,0,binding,1,offset,0,argKind,pod_ubo,argSize,8
// MAP: kernel,test,arg,uc,argOrdinal,1,descriptorSet,0,binding,1,offset,8,argKind,pod_ubo,argSize,8
// MAP: kernel,test,arg,s,argOrdinal,2,descriptorSet,0,binding,1,offset,16,argKind,pod_ubo,argSize,16
// MAP: kernel,test,arg,us,argOrdinal,3,descriptorSet,0,binding,1,offset,32,argKind,pod_ubo,argSize,16
// MAP: kernel,test,arg,i,argOrdinal,4,descriptorSet,0,binding,1,offset,64,argKind,pod_ubo,argSize,32
// MAP: kernel,test,arg,ui,argOrdinal,5,descriptorSet,0,binding,1,offset,96,argKind,pod_ubo,argSize,32
// MAP: kernel,test,arg,f,argOrdinal,6,descriptorSet,0,binding,1,offset,128,argKind,pod_ubo,argSize,32
