// RUN: clspv %target %s -o %t.spv
// RUN: spirv-dis %t.spv -o - | FileCheck %s
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: [[DOUBLE:%[0-9a-zA-Z_]+]] = OpTypeFloat 64

// CHECK: OpConvertSToF [[DOUBLE]]
// CHECK: OpConvertUToF [[DOUBLE]]
// CHECK: OpConvertSToF [[DOUBLE]]
// CHECK: OpConvertUToF [[DOUBLE]]
// CHECK: OpConvertSToF [[DOUBLE]]
// CHECK: OpConvertUToF [[DOUBLE]]
// CHECK: OpConvertSToF [[DOUBLE]]
// CHECK: OpConvertUToF [[DOUBLE]]
// CHECK: OpFConvert [[DOUBLE]]
// CHECK: OpFConvert [[DOUBLE]]

#pragma OPENCL EXTENSION cl_khr_fp16 : enable

void kernel test(global char *c, global uchar *uc,
                 global short *s, global ushort *us,
                 global int *i, global uint *ui,
                 global long *l, global ulong *ul,
                 global half *h, global float *f,
                 global double *d, global double *out) {
  out[0] = convert_double(*c);
  out[1] = convert_double(*uc);
  out[2] = convert_double(*s);
  out[3] = convert_double(*us);
  out[4] = convert_double(*i);
  out[5] = convert_double(*ui);
  out[6] = convert_double(*l);
  out[7] = convert_double(*ul);
  out[8] = convert_double(*h);
  out[9] = convert_double(*f);
  out[10] = convert_double(*d);
}
