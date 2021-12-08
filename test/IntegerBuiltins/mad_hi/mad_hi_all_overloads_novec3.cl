// RUN: clspv -int8 %s -o %t.spv -vec3-to-vec4
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[void:[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[uchar:[0-9a-zA-Z_]+]] = OpTypeInt 8 0
// CHECK-DAG: %[[v2uchar:[0-9a-zA-Z_]+]] = OpTypeVector %[[uchar]] 2
// CHECK-DAG: %[[v4uchar:[0-9a-zA-Z_]+]] = OpTypeVector %[[uchar]] 4
// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[v2ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 2
// CHECK-DAG: %[[v4ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 4
// CHECK-DAG: %[[v2uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 2
// CHECK-DAG: %[[v4uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 4
// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[v2ulong:[0-9a-zA-Z_]+]] = OpTypeVector %[[ulong]] 2
// CHECK-DAG: %[[v4ulong:[0-9a-zA-Z_]+]] = OpTypeVector %[[ulong]] 4
// CHECK-DAG: %[[uchar_10:[0-9a-zA-Z_]+]] = OpConstant %[[uchar]] 10
// CHECK-DAG: %[[uchar_2:[0-9a-zA-Z_]+]] = OpConstant %[[uchar]] 2
// CHECK-DAG: %[[__original_id_54:[0-9]+]] = OpConstantComposite %[[v2uchar]] %[[uchar_10]] %[[uchar_10]]
// CHECK-DAG: %[[__original_id_55:[0-9]+]] = OpConstantComposite %[[v2uchar]] %[[uchar_2]] %[[uchar_2]]
// CHECK-DAG: %[[__original_id_58:[0-9]+]] = OpConstantComposite %[[v4uchar]] %[[uchar_10]] %[[uchar_10]] %[[uchar_10]] %[[uchar_10]]
// CHECK-DAG: %[[__original_id_59:[0-9]+]] = OpConstantComposite %[[v4uchar]] %[[uchar_2]] %[[uchar_2]] %[[uchar_2]] %[[uchar_2]]
// CHECK-DAG: %[[ushort_10:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 10
// CHECK-DAG: %[[ushort_2:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 2
// CHECK-DAG: %[[__original_id_62:[0-9]+]] = OpConstantComposite %[[v2ushort]] %[[ushort_10]] %[[ushort_10]]
// CHECK-DAG: %[[__original_id_63:[0-9]+]] = OpConstantComposite %[[v2ushort]] %[[ushort_2]] %[[ushort_2]]
// CHECK-DAG: %[[__original_id_66:[0-9]+]] = OpConstantComposite %[[v4ushort]] %[[ushort_10]] %[[ushort_10]] %[[ushort_10]] %[[ushort_10]]
// CHECK-DAG: %[[__original_id_67:[0-9]+]] = OpConstantComposite %[[v4ushort]] %[[ushort_2]] %[[ushort_2]] %[[ushort_2]] %[[ushort_2]]
// CHECK-DAG: %[[uint_10:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 10
// CHECK-DAG: %[[uint_2:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 2
// CHECK-DAG: %[[__original_id_70:[0-9]+]] = OpConstantComposite %[[v2uint]] %[[uint_10]] %[[uint_10]]
// CHECK-DAG: %[[__original_id_71:[0-9]+]] = OpConstantComposite %[[v2uint]] %[[uint_2]] %[[uint_2]]
// CHECK-DAG: %[[__original_id_74:[0-9]+]] = OpConstantComposite %[[v4uint]] %[[uint_10]] %[[uint_10]] %[[uint_10]] %[[uint_10]]
// CHECK-DAG: %[[__original_id_75:[0-9]+]] = OpConstantComposite %[[v4uint]] %[[uint_2]] %[[uint_2]] %[[uint_2]] %[[uint_2]]
// CHECK-DAG: %[[ulong_10:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 10
// CHECK-DAG: %[[ulong_2:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 2
// CHECK-DAG: %[[__original_id_78:[0-9]+]] = OpConstantComposite %[[v2ulong]] %[[ulong_10]] %[[ulong_10]]
// CHECK-DAG: %[[__original_id_79:[0-9]+]] = OpConstantComposite %[[v2ulong]] %[[ulong_2]] %[[ulong_2]]
// CHECK-DAG: %[[__original_id_82:[0-9]+]] = OpConstantComposite %[[v4ulong]] %[[ulong_10]] %[[ulong_10]] %[[ulong_10]] %[[ulong_10]]
// CHECK-DAG: %[[__original_id_83:[0-9]+]] = OpConstantComposite %[[v4ulong]] %[[ulong_2]] %[[ulong_2]] %[[ulong_2]] %[[ulong_2]]
// CHECK:     %[[__original_id_91:[0-9]+]] = OpSMulExtended %[[_struct_5:[0-9a-zA-Z_]+]] %[[uchar_10]] %[[uchar_2]]
// CHECK:     %[[__original_id_92:[0-9]+]] = OpSMulExtended %[[_struct_7:[0-9a-zA-Z_]+]] %[[__original_id_54]] %[[__original_id_55]]
// CHECK:     %[[__original_id_93:[0-9]+]] = OpSMulExtended %[[_struct_9:[0-9a-zA-Z_]+]] %[[__original_id_58]] %[[__original_id_59]]
// CHECK:     %[[__original_id_94:[0-9]+]] = OpSMulExtended %[[_struct_11:[0-9a-zA-Z_]+]] %[[__original_id_58]] %[[__original_id_59]]
// CHECK:     %[[__original_id_95:[0-9]+]] = OpUMulExtended %[[_struct_12:[0-9a-zA-Z_]+]] %[[uchar_10]] %[[uchar_2]]
// CHECK:     %[[__original_id_96:[0-9]+]] = OpUMulExtended %[[_struct_13:[0-9a-zA-Z_]+]] %[[__original_id_54]] %[[__original_id_55]]
// CHECK:     %[[__original_id_97:[0-9]+]] = OpUMulExtended %[[_struct_14:[0-9a-zA-Z_]+]] %[[__original_id_58]] %[[__original_id_59]]
// CHECK:     %[[__original_id_98:[0-9]+]] = OpUMulExtended %[[_struct_15:[0-9a-zA-Z_]+]] %[[__original_id_58]] %[[__original_id_59]]
// CHECK:     %[[__original_id_99:[0-9]+]] = OpSMulExtended %[[_struct_17:[0-9a-zA-Z_]+]] %[[ushort_10]] %[[ushort_2]]
// CHECK:     %[[__original_id_100:[0-9]+]] = OpSMulExtended %[[_struct_19:[0-9a-zA-Z_]+]] %[[__original_id_62]] %[[__original_id_63]]
// CHECK:     %[[__original_id_101:[0-9]+]] = OpSMulExtended %[[_struct_21:[0-9a-zA-Z_]+]] %[[__original_id_66]] %[[__original_id_67]]
// CHECK:     %[[__original_id_102:[0-9]+]] = OpSMulExtended %[[_struct_23:[0-9a-zA-Z_]+]] %[[__original_id_66]] %[[__original_id_67]]
// CHECK:     %[[__original_id_103:[0-9]+]] = OpUMulExtended %[[_struct_24:[0-9a-zA-Z_]+]] %[[ushort_10]] %[[ushort_2]]
// CHECK:     %[[__original_id_104:[0-9]+]] = OpUMulExtended %[[_struct_25:[0-9a-zA-Z_]+]] %[[__original_id_62]] %[[__original_id_63]]
// CHECK:     %[[__original_id_105:[0-9]+]] = OpUMulExtended %[[_struct_26:[0-9a-zA-Z_]+]] %[[__original_id_66]] %[[__original_id_67]]
// CHECK:     %[[__original_id_106:[0-9]+]] = OpUMulExtended %[[_struct_27:[0-9a-zA-Z_]+]] %[[__original_id_66]] %[[__original_id_67]]
// CHECK:     %[[__original_id_107:[0-9]+]] = OpSMulExtended %[[_struct_28:[0-9a-zA-Z_]+]] %[[uint_10]] %[[uint_2]]
// CHECK:     %[[__original_id_108:[0-9]+]] = OpSMulExtended %[[_struct_30:[0-9a-zA-Z_]+]] %[[__original_id_70]] %[[__original_id_71]]
// CHECK:     %[[__original_id_109:[0-9]+]] = OpSMulExtended %[[_struct_32:[0-9a-zA-Z_]+]] %[[__original_id_74]] %[[__original_id_75]]
// CHECK:     %[[__original_id_110:[0-9]+]] = OpSMulExtended %[[_struct_34:[0-9a-zA-Z_]+]] %[[__original_id_74]] %[[__original_id_75]]
// CHECK:     %[[__original_id_111:[0-9]+]] = OpUMulExtended %[[_struct_35:[0-9a-zA-Z_]+]] %[[uint_10]] %[[uint_2]]
// CHECK:     %[[__original_id_112:[0-9]+]] = OpUMulExtended %[[_struct_36:[0-9a-zA-Z_]+]] %[[__original_id_70]] %[[__original_id_71]]
// CHECK:     %[[__original_id_113:[0-9]+]] = OpUMulExtended %[[_struct_37:[0-9a-zA-Z_]+]] %[[__original_id_74]] %[[__original_id_75]]
// CHECK:     %[[__original_id_114:[0-9]+]] = OpUMulExtended %[[_struct_38:[0-9a-zA-Z_]+]] %[[__original_id_74]] %[[__original_id_75]]
// CHECK:     %[[__original_id_115:[0-9]+]] = OpSMulExtended %[[_struct_40:[0-9a-zA-Z_]+]] %[[ulong_10]] %[[ulong_2]]
// CHECK:     %[[__original_id_116:[0-9]+]] = OpSMulExtended %[[_struct_42:[0-9a-zA-Z_]+]] %[[__original_id_78]] %[[__original_id_79]]
// CHECK:     %[[__original_id_117:[0-9]+]] = OpSMulExtended %[[_struct_44:[0-9a-zA-Z_]+]] %[[__original_id_82]] %[[__original_id_83]]
// CHECK:     %[[__original_id_118:[0-9]+]] = OpSMulExtended %[[_struct_46:[0-9a-zA-Z_]+]] %[[__original_id_82]] %[[__original_id_83]]
// CHECK:     %[[__original_id_119:[0-9]+]] = OpUMulExtended %[[_struct_47:[0-9a-zA-Z_]+]] %[[ulong_10]] %[[ulong_2]]
// CHECK:     %[[__original_id_120:[0-9]+]] = OpUMulExtended %[[_struct_48:[0-9a-zA-Z_]+]] %[[__original_id_78]] %[[__original_id_79]]
// CHECK:     %[[__original_id_121:[0-9]+]] = OpUMulExtended %[[_struct_49:[0-9a-zA-Z_]+]] %[[__original_id_82]] %[[__original_id_83]]
// CHECK:     %[[__original_id_122:[0-9]+]] = OpUMulExtended %[[_struct_50:[0-9a-zA-Z_]+]] %[[__original_id_82]] %[[__original_id_83]]

void kernel test() {
    volatile char c1 = mad_hi((char)10, (char)2, (char)7);
    volatile char2 c2 = mad_hi((char2)10, (char2)2, (char)7);
    volatile char3 c3 = mad_hi((char3)10, (char3)2, (char)7);
    volatile char4 c4 = mad_hi((char4)10, (char4)2, (char)7);

    volatile uchar uc1 = mad_hi((uchar)10, (uchar)2, (uchar)7);
    volatile uchar2 uc2 = mad_hi((uchar2)10, (uchar2)2, (uchar)7);
    volatile uchar3 uc3 = mad_hi((uchar3)10, (uchar3)2, (uchar)7);
    volatile uchar4 uc4 = mad_hi((uchar4)10, (uchar4)2, (uchar)7);

    volatile short s1 = mad_hi((short)10, (short)2, (short)7);
    volatile short2 s2 = mad_hi((short2)10, (short2)2, (short)7);
    volatile short3 s3 = mad_hi((short3)10, (short3)2, (short)7);
    volatile short4 s4 = mad_hi((short4)10, (short4)2, (short)7);

    volatile ushort us1 = mad_hi((ushort)10, (ushort)2, (ushort)7);
    volatile ushort2 us2 = mad_hi((ushort2)10, (ushort2)2, (ushort)7);
    volatile ushort3 us3 = mad_hi((ushort3)10, (ushort3)2, (ushort)7);
    volatile ushort4 us4 = mad_hi((ushort4)10, (ushort4)2, (ushort)7);

    volatile int i1 = mad_hi((int)10, (int)2, (int)7);
    volatile int2 i2 = mad_hi((int2)10, (int2)2, (int)7);
    volatile int3 i3 = mad_hi((int3)10, (int3)2, (int)7);
    volatile int4 i4 = mad_hi((int4)10, (int4)2, (int)7);

    volatile uint ui1 = mad_hi((uint)10, (uint)2, (uint)7);
    volatile uint2 ui2 = mad_hi((uint2)10, (uint2)2, (uint)7);
    volatile uint3 ui3 = mad_hi((uint3)10, (uint3)2, (uint)7);
    volatile uint4 ui4 = mad_hi((uint4)10, (uint4)2, (uint)7);

    volatile long l1 = mad_hi((long)10, (long)2, (long)7);
    volatile long2 l2 = mad_hi((long2)10, (long2)2, (long)7);
    volatile long3 l3 = mad_hi((long3)10, (long3)2, (long)7);
    volatile long4 l4 = mad_hi((long4)10, (long4)2, (long)7);

    volatile ulong ul1 = mad_hi((ulong)10, (ulong)2, (ulong)7);
    volatile ulong2 ul2 = mad_hi((ulong2)10, (ulong2)2, (ulong)7);
    volatile ulong3 ul3 = mad_hi((ulong3)10, (ulong3)2, (ulong)7);
    volatile ulong4 ul4 = mad_hi((ulong4)10, (ulong4)2, (ulong)7);
}

