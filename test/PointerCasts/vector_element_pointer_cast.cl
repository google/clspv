// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis %t.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// Verify that indexing a vector via a scalar pointer cast (((type*)&vec)[idx])
// produces the same register-promoted vector extract/insert codegen as vec[idx]
// without spilling the vector to a Function-scope OpVariable.

// CHECK-NOT: OpVariable {{.*}} Function

// Kernel 1: dynamic read and write on float4
// CHECK: OpFunction
// CHECK: OpVectorExtractDynamic %float {{%[0-9a-zA-Z_]+}} {{%[0-9a-zA-Z_]+}}
// CHECK: OpVectorInsertDynamic %v4float {{%[0-9a-zA-Z_]+}} %float_42 {{%[0-9a-zA-Z_]+}}
// CHECK: OpReturn

// Kernel 2: constant-index read/write and dynamic compound assignment on int2
// CHECK: OpFunction
// CHECK: OpCompositeExtract %uint {{%[0-9a-zA-Z_]+}} 0
// CHECK: OpIAdd %uint
// CHECK: OpCompositeInsert %v2uint {{%[0-9a-zA-Z_]+}} {{%[0-9a-zA-Z_]+}} 1
// CHECK: OpVectorExtractDynamic %uint {{%[0-9a-zA-Z_]+}} {{%[0-9a-zA-Z_]+}}
// CHECK: OpIAdd %uint
// CHECK: OpVectorInsertDynamic %v2uint {{%[0-9a-zA-Z_]+}} {{%[0-9a-zA-Z_]+}} {{%[0-9a-zA-Z_]+}}
// CHECK: OpReturn

// Kernel 3: dynamic read and write on 3-component vector (int3)
// CHECK: OpFunction
// CHECK: OpVectorExtractDynamic %uint {{%[0-9a-zA-Z_]+}} {{%[0-9a-zA-Z_]+}}
// CHECK: OpVectorInsertDynamic %v3uint {{%[0-9a-zA-Z_]+}} %uint_7 {{%[0-9a-zA-Z_]+}}
// CHECK: OpReturn

// Kernel 4: 2D unrolled array of float4 accessed with constant indices
// CHECK: OpFunction
// CHECK: OpCompositeExtract %float {{%[0-9a-zA-Z_]+}} 0
// CHECK: OpCompositeExtract %float {{%[0-9a-zA-Z_]+}} 1
// CHECK: OpCompositeExtract %float {{%[0-9a-zA-Z_]+}} 2
// CHECK: OpCompositeExtract %float {{%[0-9a-zA-Z_]+}} 3
// CHECK: OpReturn

// Kernel 5: array of float4 with unrolled outer index and dynamic inner index
// CHECK: OpFunction
// CHECK: OpVectorInsertDynamic %v4float
// CHECK: OpVectorInsertDynamic %v4float
// CHECK: OpVectorExtractDynamic %float
// CHECK: OpVectorExtractDynamic %float
// CHECK: OpReturn

// Kernel 6: struct containing a float4 accessed via scalar pointer cast
// CHECK: OpFunction
// CHECK: OpVectorExtractDynamic %float
// CHECK: OpVectorInsertDynamic %v4float
// CHECK: OpReturn

void kernel test_vec4(global float4 *in, global float *out_scalar,
                      global float4 *out_vec, uint idx) {
  float4 v = *in;
  *out_scalar = ((float *)&v)[idx];
  ((float *)&v)[idx] = 42.0f;
  *out_vec = v;
}

void kernel test_vec2_int(global int2 *inout, uint idx) {
  int2 v = *inout;
  ((int *)&v)[1] = ((int *)&v)[0] + 5;
  ((int *)&v)[idx] += 10;
  *inout = v;
}

void kernel test_vec3_int(global int3 *in, global int *out_scalar,
                          global int3 *out_vec, uint idx) {
  int3 v = *in;
  *out_scalar = ((int *)&v)[idx];
  ((int *)&v)[idx] = 7;
  *out_vec = v;
}

void kernel test_vec4_array_unrolled(global float4 *in, global float *out) {
  float4 arr[3];
  float sum = 0.0f;
  for (int i = 0; i < 3; ++i) {
    arr[i] = in[i];
  }
  for (int i = 0; i < 3; ++i) {
    for (int j = 0; j < 4; ++j) {
      sum += ((float *)&arr[i])[j];
    }
  }
  *out = sum;
}

void kernel test_vec4_array_dynamic_col(global float4 *inout, global float *out,
                                        uint col) {
  float4 arr[2];
  for (int i = 0; i < 2; ++i) {
    arr[i] = inout[i];
  }
  for (int i = 0; i < 2; ++i) {
    ((float *)&arr[i])[col] += (float)(i + 1);
  }
  float sum = 0.0f;
  for (int i = 0; i < 2; ++i) {
    sum += ((float *)&arr[i])[col];
    inout[i] = arr[i];
  }
  *out = sum;
}

struct Holder {
  int tag;
  float4 vec;
};

void kernel test_struct_with_vec(global float4 *in, global float4 *out,
                                 global float *out_elem, uint idx) {
  struct Holder h;
  h.tag = 1;
  h.vec = *in;
  *out_elem = ((float *)&h.vec)[idx];
  ((float *)&h.vec)[idx] = (float)h.tag;
  *out = h.vec;
}
