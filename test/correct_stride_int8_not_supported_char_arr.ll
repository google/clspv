// RUN: clspv -int8=0 %target %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

__kernel void helloWorld(__global char* data){
    data[0] = 'H';
    data[1] = 'e';
    data[2] = 'l';
    data[3] = 'l';
    data[4] = 'o';
    data[5] = ' ';
    data[6] = 'W';
    data[7] = 'o';
    data[8] = 'r';
    data[9] = 'l';
    data[10] = 'd';
    data[11] = '!';
    data[12] = '\n';
    data[13] = 0;
}

// CHECK-DAG:  [[uint:%[^ ]+]] = OpTypeInt 32 0
// CHECK-DAG:  OpTypePointer StorageBuffer [[struct:%[^ ]+]]
// CHECK-DAG:  [[struct]] = OpTypeStruct [[runtimearr:%[^ ]+]]
// CHECK-DAG:  OpDecorate [[runtimearr]] ArrayStride 4
