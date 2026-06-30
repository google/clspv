// RUN: clspv %target %s -o %t.spv -arch=spirv32 --show-producer-ir &> %t.ll
// RUN: FileCheck %s < %t.ll --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val %t.spv

// RUN: clspv %target %s -o %t.spv -arch=spirv64 --show-producer-ir &> %t.ll
// RUN: FileCheck %s < %t.ll --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val %t.spv

// CHECK: [[val:%[a-zA-Z0-9_.]+]] = load { i32, i32 }
// CHECK: [[x:%[a-zA-Z0-9_.]+]] = extractvalue { i32, i32 } [[val]], 0
// CHECK: [[y:%[a-zA-Z0-9_.]+]] = extractvalue { i32, i32 } [[val]], 1

// CHECK-32: [[x_shl:%[a-zA-Z0-9_.]+]] = shl i32 [[x]], 2
// CHECK-32: [[y_shl:%[a-zA-Z0-9_.]+]] = shl i32 [[y]], 2
// CHECK-32: [[x_off:%[a-zA-Z0-9_.]+]] = add i32 [[x_shl]], [[base:[0-9]+]]
// CHECK-32: [[y_off:%[a-zA-Z0-9_.]+]] = add i32 [[y_shl]], [[base]]
// CHECK-32: [[cond:%[a-zA-Z0-9_.]+]] = icmp {{.*}}ugt i32 [[x_off]], [[y_off]]
// CHECK-32: [[select:%[a-zA-Z0-9_.]+]] = select i1 [[cond]], i32 [[x]], i32 [[y]]
// CHECK-32: getelementptr inbounds [10 x i32], ptr %{{.*}}, i32 0, i32 [[select]]

// CHECK-64: [[x_ext:%[a-zA-Z0-9_.]+]] = sext i32 [[x]] to i64
// CHECK-64: [[x_shl:%[a-zA-Z0-9_.]+]] = shl {{.*}}i64 [[x_ext]], 2
// CHECK-64: [[y_ext:%[a-zA-Z0-9_.]+]] = sext i32 [[y]] to i64
// CHECK-64: [[y_shl:%[a-zA-Z0-9_.]+]] = shl {{.*}}i64 [[y_ext]], 2
// CHECK-64: [[x_off:%[a-zA-Z0-9_.]+]] = add {{.*}}i64 [[x_shl]], [[base:[0-9]+]]
// CHECK-64: [[y_off:%[a-zA-Z0-9_.]+]] = add {{.*}}i64 [[y_shl]], [[base]]
// CHECK-64: [[cond:%[a-zA-Z0-9_.]+]] = icmp {{.*}}ugt i64 [[x_off]], [[y_off]]
// CHECK-64: [[select:%[a-zA-Z0-9_.]+]] = select i1 [[cond]], i64 [[x_ext]], i64 [[y_ext]]
// CHECK-64: getelementptr inbounds [10 x i32], ptr %{{.*}}, i32 0, i64 [[select]]

// CHECK-NOT: select {{.*}} ptr

__kernel void opSelectPrivate(__global int* in, __global int* out, int x, int y) {
  int a[10];
  for (int i=0; i < 10; i++) {
    a[i] = in[i];
  }

  size_t id = get_global_id(0);
  if (&a[x] > &a[y]) {
    out[id] = a[x];
  } else {
    out[id] = a[y];
  }
}

// CHECK-32: [[x2_shl:%[a-zA-Z0-9_.]+]] = shl i32 {{.*}}, 2
// CHECK-32: [[y2_shl:%[a-zA-Z0-9_.]+]] = shl i32 {{.*}}, 2
// CHECK-32: [[x2_off:%[a-zA-Z0-9_.]+]] = add i32 [[x2_shl]], [[base2:[0-9]+]]
// CHECK-32: [[y2_off:%[a-zA-Z0-9_.]+]] = add i32 [[y2_shl]], [[base3:[0-9]+]]
// CHECK-32: [[cond2:%[a-zA-Z0-9_.]+]] = icmp ugt i32 [[x2_off]], [[y2_off]]
// CHECK-32: [[select2:%[a-zA-Z0-9_.]+]] = select i1 [[cond2]], i32 1, i32 2
// CHECK-32: store i32 [[select2]], ptr addrspace(1)

// CHECK-64: store i32 2, ptr addrspace(1)

__kernel void opCompareDifferentPrivate(__global int* out, int x, int y, int idx) {
  int a[10];
  int b[10];
  a[x] = x;
  b[y] = y;

  if (&a[x] > &b[y]) {
    out[idx] = 1;
  } else {
    out[idx] = 2;
  }
}
