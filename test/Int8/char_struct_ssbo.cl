// RUN: clspv %target %s -o %t.spv -int8
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

typedef struct S {
  char a;
  char b;
  char2 c;
  char3 d;
  char4 e;
  char f[4];
} S;

kernel void foo(global S* data) {
  (*data).a = 0;
  (*data).b = 0;
  (*data).c = (char2)(0,0);
  (*data).d = (char3)(0,0,0);
  (*data).e = (char4)(0,0,0,0);
  (*data).f[0] = 0;
  (*data).f[1] = 0;
  (*data).f[2] = 0;
  (*data).f[3] = 0;
}

// CHECK: OpCapability Int8
// CHECK: OpMemberDecorate [[struct:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpMemberDecorate [[struct]] 1 Offset 1
// CHECK: OpMemberDecorate [[struct]] 2 Offset 2
// CHECK: OpMemberDecorate [[struct]] 3 Offset 4
// CHECK: OpMemberDecorate [[struct]] 4 Offset 8
// CHECK: OpMemberDecorate [[struct]] 5 Offset 12
// CHECK: OpDecorate [[rta:%[a-zA-Z0-9_]+]] ArrayStride 16
// CHECK: OpDecorate [[var:%[a-zA-Z0-9_]+]] DescriptorSet
// CHECK: OpDecorate [[array:%[a-zA-Z0-9_]+]] ArrayStride 1
// CHECK: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK: [[char2:%[a-zA-Z0-9_]+]] = OpTypeVector [[char]] 2
// CHECK: [[char4:%[a-zA-Z0-9_]+]] = OpTypeVector [[char]] 4
// CHECK: [[four:%[a-zA-Z0-9_]+]] = OpConstant {{.*}} 4
// CHECK: [[array:%[a-zA-Z0-9_]+]] = OpTypeArray [[char]] [[four]]
// CHECK: [[struct:%[a-zA-Z0-9_]+]] = OpTypeStruct [[char]] [[char]] [[char2]] [[char4]] [[char4]] [[array]]
// CHECK: [[rta:%[a-zA-Z0-9_]+]] = OpTypeRuntimeArray [[struct]]
// CHECK: [[block:%[a-zA-Z0-9_]+]] = OpTypeStruct [[rta]]
// CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[block]]
// CHECK: [[var]] = OpVariable [[ptr]] StorageBuffer
