// RUN: clspv --cl-std=CLC++ --inline-entry-points %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv --cl-std=CLC++ --inline-entry-points %s -o %t.spv -untyped-pointers
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: FileCheck %s < %t.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-COUNT-16: OpStore

struct Data
{
  unsigned char m_u8_1;
  unsigned char m_u8_2;
  unsigned char m_u8_3;
  unsigned char m_u8_4;
  uchar2 m_u8v2_1;
  uchar2 m_u8v2_2;
  uchar4 m_u8v4_1;
  uchar4 m_u8v4_2;
};

__kernel void podTest(__global Data* output,
                      const unsigned char u8_1,
                      const unsigned char u8_2,
                      const unsigned char u8_3,
                      const unsigned char u8_4,
                      const uchar2 u8v2_1,
                      const uchar2 u8v2_2,
                      const uchar4 u8v4_1,
                      const uchar4 u8v4_2,
                      const Data v)
{
  output[0].m_u8_1 = u8_1;
  output[0].m_u8_2 = u8_2;
  output[0].m_u8_3 = u8_3;
  output[0].m_u8_4 = u8_4;
  output[0].m_u8v2_1 = u8v2_1;
  output[0].m_u8v2_2 = u8v2_2;
  output[0].m_u8v4_1 = u8v4_1;
  output[0].m_u8v4_2 = u8v4_2;
  output[1] = v;
}
