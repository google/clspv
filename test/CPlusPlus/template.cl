// RUN: clspv %target -cl-std=CLC++ -inline-entry-points %s -o %t.spv
// RUN: clspv-reflection %t.spv -o %t.dmap
// RUN: FileCheck %s < %t.dmap -check-prefix=MAP
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// MAP: kernel,test_template,arg,out,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer

// CHECK: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK: %[[uint_233:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 233
// CHECK: OpStore {{.*}} %[[uint_233]]


template <int T>
struct Fibonacci
{
    enum { value = (Fibonacci<T - 1>::value + Fibonacci<T - 2>::value) };
};

template <>
struct Fibonacci<0>
{
    enum { value = 1 };
};

template <>
struct Fibonacci<1>
{
    enum { value = 1 };
};

template <>
struct Fibonacci<2>
{
    enum { value = 1 };
};

void kernel test_template(global int* out) {
    *out = Fibonacci<13>::value;
}

