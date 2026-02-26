// RUN: clspv %target -O0 -cl-std=CLC++ -inline-entry-points %s -o %t.spv
// RUN: spirv-val --target-env vulkan1.0 %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: clspv-reflection %t.spv -o %t.map
// RUN: FileCheck %s -check-prefix=MAP < %t.map

// MAP: kernel,testCopyInstance1,arg,src,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP: kernel,testCopyInstance2,arg,dst,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP: kernel,testGlobalInstanceMethod1,arg,instances,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP: kernel,testGlobalInstanceMethod2,arg,instances,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP: kernel,testGlobalInstanceMethod3,arg,instances,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP: kernel,testGlobalInstanceMethod3,arg,dst,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,buffer
// MAP: kernel,testGlobalInstanceMethod4,arg,instances,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP: kernel,testGlobalInstanceMethod4,arg,dst,argOrdinal,1,descriptorSet,0,binding,1,offset,0,argKind,buffer
// MAP: kernel,testLocalInstanceMethod1,arg,dst,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP: kernel,testLocalInstanceMethod2,arg,dst,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP: kernel,testLocalInstance3,arg,dst,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP: kernel,testLocalInstance4,arg,dst,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer

class InstanceTest
{
 public:
  void init()
  {
    data1_ = 0;
    data2_ = 0;
    data3_ = 0;
  }

  uint getValue() const
  {
    return data2_;
  }

  void setValue(const uint value)
  {
    data2_ = value;
  }

  uint data1_;
  uint data2_;
  uint data3_;
};

// Copy a global instance to local
__kernel void testCopyInstance1(const __global InstanceTest* src, __global InstanceTest* dst)
{
  __local InstanceTest instances[16];

  const size_t index = get_global_id(0);
  if (index < 16) {
    instances[index] = src[index];
  }
  barrier(CLK_LOCAL_MEM_FENCE);
  if (index < 16) {
    *dst = instances[index];
  }
}

// Copy a local instance to global
__kernel void testCopyInstance2(__global InstanceTest* dst)
{
  __local InstanceTest instances[16];

  const size_t index = get_global_id(0);
  if (index < 16) {
    dst[index] = instances[index];
  }
}

// Call a member function of global instance
__kernel void testGlobalInstanceMethod1(__global InstanceTest* instances)
{
  const size_t index = get_global_id(0);

  __global InstanceTest* instance = instances + index;
  instance->init();
  instance->setValue(10u);
}

// Call a member function of global instance
__kernel void testGlobalInstanceMethod2(__global InstanceTest* instances)
{
  const size_t index = get_global_id(0);

  instances[index].init();
  instances[index].setValue(10u);
}

// Get a value from global instance
__kernel void testGlobalInstanceMethod3(const __global InstanceTest* instances,
    __global uint* dst)
{
  const size_t index = get_global_id(0);

  const __global InstanceTest* instance = instances + index;
  dst[index] = instance->getValue();
}

// Get a value from global instance
__kernel void testGlobalInstanceMethod4(const __global InstanceTest* instances,
    __global uint* dst)
{
  const size_t index = get_global_id(0);

  dst[index] = instances[index].getValue();
}

// Call a member function of local instance
__kernel void testLocalInstanceMethod1(__global InstanceTest* dst)
{
  __local InstanceTest instances[16];

  const size_t index = get_global_id(0);
  if (index < 16) {
    __local InstanceTest* instance = instances + index;
    instance->init();
    instance->setValue(10u);
    dst[index] = *instance;
  }
}

// Call a member function of local instance
__kernel void testLocalInstanceMethod2(__global InstanceTest* dst)
{
  __local InstanceTest instances[16];

  const size_t index = get_global_id(0);
  if (index < 16) {
    instances[index].init();
    instances[index].setValue(10u);
    dst[index] = instances[index];
  }
}

// Get a value from local instance
__kernel void testLocalInstance3(__global uint* dst, __global uint* src)
{
  __local InstanceTest instances[16];

  const size_t index = get_global_id(0);
  if (index < 16) {
    __local InstanceTest* instance = instances + index;
    InstanceTest tmp;
    instance->setValue(src[index]);
  }
  barrier(CLK_LOCAL_MEM_FENCE);
  if (index < 16) {
    const __local InstanceTest* instance = instances + index;
    dst[index] = instance->getValue();
  }
}

// Get a value from local instance
__kernel void testLocalInstance4(__global uint* dst, __global uint* src)
{
  __local InstanceTest instances[16];

  const size_t index = get_global_id(0);
  if (index < 16) {
    instances[index].setValue(src[index]);
  }
  barrier(CLK_LOCAL_MEM_FENCE);
  if (index < 16) {
    dst[index] = instances[index].getValue();
  }
}

