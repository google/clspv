// RUN: clspv %target %s -long-vector -o %t.spv -int8
// RUN: spirv-dis -o %t.spvasm %t.spv
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

typedef struct S {
  char a;
  char b;
  char2 c;
  char3 d;
  char4 e;
  char8 f;
  char g[4];
} S;

kernel void foo(global S* data) {
  (*data).a = 0;
  (*data).b = 0;
  (*data).c = (char2)0;
  (*data).d = (char3)0;
  (*data).e = (char4)0;
  (*data).f = (char8)0;
  (*data).g[0] = 0;
  (*data).g[1] = 0;
  (*data).g[2] = 0;
  (*data).g[3] = 0;
}

// CHECK: OpCapability Int8
// CHECK: OpMemberDecorate [[struct:%[a-zA-Z0-9_]+]] 0 Offset 0
// CHECK: OpMemberDecorate [[struct]] 1 Offset 1
// CHECK: OpMemberDecorate [[struct]] 2 Offset 2
// CHECK: OpMemberDecorate [[struct]] 3 Offset 4
// CHECK: OpMemberDecorate [[struct]] 4 Offset 8
// CHECK: OpMemberDecorate [[struct]] 5 Offset 12
// CHECK: OpMemberDecorate [[struct]] 6 Offset 16
// CHECK: OpMemberDecorate [[struct]] 7 Offset 24
// CHECK: OpMemberDecorate [[struct]] 8 Offset 28
// CHECK: OpDecorate [[rta:%[a-zA-Z0-9_]+]] ArrayStride 32
// CHECK: OpDecorate [[var:%[a-zA-Z0-9_]+]] DescriptorSet
// CHECK: OpDecorate [[array:%[a-zA-Z0-9_]+]] ArrayStride 1
// CHECK: [[uint:%[a-zA-Z0-9_]+]] = OpTypeInt 32 0
// CHECK: [[char:%[a-zA-Z0-9_]+]] = OpTypeInt 8 0
// CHECK: [[char2:%[a-zA-Z0-9_]+]] = OpTypeVector [[char]] 2
// CHECK: [[char3:%[a-zA-Z0-9_]+]] = OpTypeVector [[char]] 3
// CHECK: [[char4:%[a-zA-Z0-9_]+]] = OpTypeVector [[char]] 4
// CHECK: [[one:%[a-zA-Z0-9_]+]] = OpConstant {{.*}} 1
// CHECK: [[padding:%[a-zA-Z0-9_]+]] = OpTypeArray [[uint]] [[one]]
// CHECK: [[eight:%[a-zA-Z0-9_]+]] = OpConstant {{.*}} 8
// CHECK: [[char8:%[a-zA-Z0-9_]+]] = OpTypeArray [[char]] [[eight]]
// CHECK: [[four:%[a-zA-Z0-9_]+]] = OpConstant {{.*}} 4
// CHECK: [[array:%[a-zA-Z0-9_]+]] = OpTypeArray [[char]] [[four]]
// CHECK: [[struct:%[a-zA-Z0-9_]+]] = OpTypeStruct [[char]] [[char]] [[char2]] [[char3]] [[char4]] [[padding]] [[char8]] [[array]] [[padding]]
// CHECK: [[rta:%[a-zA-Z0-9_]+]] = OpTypeRuntimeArray [[struct]]
// CHECK: [[block:%[a-zA-Z0-9_]+]] = OpTypeStruct [[rta]]
// CHECK: [[ptr:%[a-zA-Z0-9_]+]] = OpTypePointer StorageBuffer [[block]]
// CHECK: [[var]] = OpVariable [[ptr]] StorageBuffer
