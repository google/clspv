// RUN: clspv --cl-std=CLC++ --inline-entry-points %s -o %t.spv
// RUN: spirv-val --target-env spv1.0 %t.spv

// type_test2.cl
struct Storage
{
  void set(const int value)
  {
    __generic int* ptr = reinterpret_cast<__generic int*>(&value_);
    for (size_t i = 0; i < 4; ++i)
      ptr[i] = value + static_cast<int>(i);
  }

  int sum() const
  {
    __generic const int* ptr = reinterpret_cast<__generic const int*>(&value_);
    int sum = 0;
    for (size_t i = 0; i < 4; ++i)
      sum += ptr[i];
    return sum;
  }

  int4 value_;
};

__kernel void test2(__global int* outputs, __local Storage* storage)
{
  const size_t storage_id = get_local_id(0);
  __local Storage* s = &storage[storage_id];

  const size_t index = get_global_id(0);
  s->set(static_cast<int>(index));
  outputs[index] = s->sum();
}

// type_test3.cl
struct TestStruct2
{
  void set(const int value)
  {
    __generic int* ptr = value_;
    for (size_t i = 0; i < 4; ++i)
      ptr[i] = value + static_cast<int>(i);
  }

  int sum() const
  {
    __generic const int* ptr = value_;
    int sum = 0;
    for (size_t i = 0; i < 4; ++i)
      sum += ptr[i];
    return sum;
  }

  int value_[4];
};

__kernel void test3(__global TestStruct2* inout)
{
  const int sum = inout[0].sum();
  inout[0].set(2 * sum);
}
