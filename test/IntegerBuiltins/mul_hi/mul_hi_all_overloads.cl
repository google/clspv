// RUN: clspv -int8 %s -o %t.spv
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// CHECK-DAG: %[[void:[0-9a-zA-Z_]+]] = OpTypeVoid
// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[uchar:[0-9a-zA-Z_]+]] = OpTypeInt 8 0
// CHECK-DAG: %[[v2uchar:[0-9a-zA-Z_]+]] = OpTypeVector %[[uchar]] 2
// CHECK-DAG: %[[v3uchar:[0-9a-zA-Z_]+]] = OpTypeVector %[[uchar]] 3
// CHECK-DAG: %[[v4uchar:[0-9a-zA-Z_]+]] = OpTypeVector %[[uchar]] 4
// CHECK-DAG: %[[ushort:[0-9a-zA-Z_]+]] = OpTypeInt 16 0
// CHECK-DAG: %[[v2ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 2
// CHECK-DAG: %[[v3ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 3
// CHECK-DAG: %[[v4ushort:[0-9a-zA-Z_]+]] = OpTypeVector %[[ushort]] 4
// CHECK-DAG: %[[v2uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 2
// CHECK-DAG: %[[v3uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 3
// CHECK-DAG: %[[v4uint:[0-9a-zA-Z_]+]] = OpTypeVector %[[uint]] 4
// CHECK-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-DAG: %[[v2ulong:[0-9a-zA-Z_]+]] = OpTypeVector %[[ulong]] 2
// CHECK-DAG: %[[v3ulong:[0-9a-zA-Z_]+]] = OpTypeVector %[[ulong]] 3
// CHECK-DAG: %[[v4ulong:[0-9a-zA-Z_]+]] = OpTypeVector %[[ulong]] 4
// CHECK-DAG: %[[uchar_10:[0-9a-zA-Z_]+]] = OpConstant %[[uchar]] 10
// CHECK-DAG: %[[uchar_2:[0-9a-zA-Z_]+]] = OpConstant %[[uchar]] 2
// CHECK-DAG: %[[__original_id_54:[0-9]+]] = OpConstantComposite %[[v2uchar]] %[[uchar_10]] %[[uchar_10]]
// CHECK-DAG: %[[__original_id_55:[0-9]+]] = OpConstantComposite %[[v2uchar]] %[[uchar_2]] %[[uchar_2]]
// CHECK-DAG: %[[__original_id_56:[0-9]+]] = OpConstantComposite %[[v3uchar]] %[[uchar_10]] %[[uchar_10]] %[[uchar_10]]
// CHECK-DAG: %[[__original_id_57:[0-9]+]] = OpConstantComposite %[[v3uchar]] %[[uchar_2]] %[[uchar_2]] %[[uchar_2]]
// CHECK-DAG: %[[__original_id_58:[0-9]+]] = OpConstantComposite %[[v4uchar]] %[[uchar_10]] %[[uchar_10]] %[[uchar_10]] %[[uchar_10]]
// CHECK-DAG: %[[__original_id_59:[0-9]+]] = OpConstantComposite %[[v4uchar]] %[[uchar_2]] %[[uchar_2]] %[[uchar_2]] %[[uchar_2]]
// CHECK-DAG: %[[ushort_10:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 10
// CHECK-DAG: %[[ushort_2:[0-9a-zA-Z_]+]] = OpConstant %[[ushort]] 2
// CHECK-DAG: %[[__original_id_62:[0-9]+]] = OpConstantComposite %[[v2ushort]] %[[ushort_10]] %[[ushort_10]]
// CHECK-DAG: %[[__original_id_63:[0-9]+]] = OpConstantComposite %[[v2ushort]] %[[ushort_2]] %[[ushort_2]]
// CHECK-DAG: %[[__original_id_64:[0-9]+]] = OpConstantComposite %[[v3ushort]] %[[ushort_10]] %[[ushort_10]] %[[ushort_10]]
// CHECK-DAG: %[[__original_id_65:[0-9]+]] = OpConstantComposite %[[v3ushort]] %[[ushort_2]] %[[ushort_2]] %[[ushort_2]]
// CHECK-DAG: %[[__original_id_66:[0-9]+]] = OpConstantComposite %[[v4ushort]] %[[ushort_10]] %[[ushort_10]] %[[ushort_10]] %[[ushort_10]]
// CHECK-DAG: %[[__original_id_67:[0-9]+]] = OpConstantComposite %[[v4ushort]] %[[ushort_2]] %[[ushort_2]] %[[ushort_2]] %[[ushort_2]]
// CHECK-DAG: %[[uint_10:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 10
// CHECK-DAG: %[[uint_2:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 2
// CHECK-DAG: %[[__original_id_70:[0-9]+]] = OpConstantComposite %[[v2uint]] %[[uint_10]] %[[uint_10]]
// CHECK-DAG: %[[__original_id_71:[0-9]+]] = OpConstantComposite %[[v2uint]] %[[uint_2]] %[[uint_2]]
// CHECK-DAG: %[[__original_id_72:[0-9]+]] = OpConstantComposite %[[v3uint]] %[[uint_10]] %[[uint_10]] %[[uint_10]]
// CHECK-DAG: %[[__original_id_73:[0-9]+]] = OpConstantComposite %[[v3uint]] %[[uint_2]] %[[uint_2]] %[[uint_2]]
// CHECK-DAG: %[[__original_id_74:[0-9]+]] = OpConstantComposite %[[v4uint]] %[[uint_10]] %[[uint_10]] %[[uint_10]] %[[uint_10]]
// CHECK-DAG: %[[__original_id_75:[0-9]+]] = OpConstantComposite %[[v4uint]] %[[uint_2]] %[[uint_2]] %[[uint_2]] %[[uint_2]]
// CHECK-DAG: %[[ulong_10:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 10
// CHECK-DAG: %[[ulong_2:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 2
// CHECK-DAG: %[[__original_id_78:[0-9]+]] = OpConstantComposite %[[v2ulong]] %[[ulong_10]] %[[ulong_10]]
// CHECK-DAG: %[[__original_id_79:[0-9]+]] = OpConstantComposite %[[v2ulong]] %[[ulong_2]] %[[ulong_2]]
// CHECK-DAG: %[[__original_id_80:[0-9]+]] = OpConstantComposite %[[v3ulong]] %[[ulong_10]] %[[ulong_10]] %[[ulong_10]]
// CHECK-DAG: %[[__original_id_81:[0-9]+]] = OpConstantComposite %[[v3ulong]] %[[ulong_2]] %[[ulong_2]] %[[ulong_2]]
// CHECK-DAG: %[[__original_id_82:[0-9]+]] = OpConstantComposite %[[v4ulong]] %[[ulong_10]] %[[ulong_10]] %[[ulong_10]] %[[ulong_10]]
// CHECK-DAG: %[[__original_id_83:[0-9]+]] = OpConstantComposite %[[v4ulong]] %[[ulong_2]] %[[ulong_2]] %[[ulong_2]] %[[ulong_2]]
// CHECK:     %[[__original_id_91:[0-9]+]] = OpSMulExtended %[[_struct_5:[0-9a-zA-Z_]+]] %[[uchar_10]] %[[uchar_2]]
// CHECK:     %[[__original_id_92:[0-9]+]] = OpSMulExtended %[[_struct_7:[0-9a-zA-Z_]+]] %[[__original_id_54]] %[[__original_id_55]]
// CHECK:     %[[__original_id_93:[0-9]+]] = OpSMulExtended %[[_struct_9:[0-9a-zA-Z_]+]] %[[__original_id_56]] %[[__original_id_57]]
// CHECK:     %[[__original_id_94:[0-9]+]] = OpSMulExtended %[[_struct_11:[0-9a-zA-Z_]+]] %[[__original_id_58]] %[[__original_id_59]]
// CHECK:     %[[__original_id_95:[0-9]+]] = OpUMulExtended %[[_struct_12:[0-9a-zA-Z_]+]] %[[uchar_10]] %[[uchar_2]]
// CHECK:     %[[__original_id_96:[0-9]+]] = OpUMulExtended %[[_struct_13:[0-9a-zA-Z_]+]] %[[__original_id_54]] %[[__original_id_55]]
// CHECK:     %[[__original_id_97:[0-9]+]] = OpUMulExtended %[[_struct_14:[0-9a-zA-Z_]+]] %[[__original_id_56]] %[[__original_id_57]]
// CHECK:     %[[__original_id_98:[0-9]+]] = OpUMulExtended %[[_struct_15:[0-9a-zA-Z_]+]] %[[__original_id_58]] %[[__original_id_59]]
// CHECK:     %[[__original_id_99:[0-9]+]] = OpSMulExtended %[[_struct_17:[0-9a-zA-Z_]+]] %[[ushort_10]] %[[ushort_2]]
// CHECK:     %[[__original_id_100:[0-9]+]] = OpSMulExtended %[[_struct_19:[0-9a-zA-Z_]+]] %[[__original_id_62]] %[[__original_id_63]]
// CHECK:     %[[__original_id_101:[0-9]+]] = OpSMulExtended %[[_struct_21:[0-9a-zA-Z_]+]] %[[__original_id_64]] %[[__original_id_65]]
// CHECK:     %[[__original_id_102:[0-9]+]] = OpSMulExtended %[[_struct_23:[0-9a-zA-Z_]+]] %[[__original_id_66]] %[[__original_id_67]]
// CHECK:     %[[__original_id_103:[0-9]+]] = OpUMulExtended %[[_struct_24:[0-9a-zA-Z_]+]] %[[ushort_10]] %[[ushort_2]]
// CHECK:     %[[__original_id_104:[0-9]+]] = OpUMulExtended %[[_struct_25:[0-9a-zA-Z_]+]] %[[__original_id_62]] %[[__original_id_63]]
// CHECK:     %[[__original_id_105:[0-9]+]] = OpUMulExtended %[[_struct_26:[0-9a-zA-Z_]+]] %[[__original_id_64]] %[[__original_id_65]]
// CHECK:     %[[__original_id_106:[0-9]+]] = OpUMulExtended %[[_struct_27:[0-9a-zA-Z_]+]] %[[__original_id_66]] %[[__original_id_67]]
// CHECK:     %[[__original_id_107:[0-9]+]] = OpSMulExtended %[[_struct_28:[0-9a-zA-Z_]+]] %[[uint_10]] %[[uint_2]]
// CHECK:     %[[__original_id_108:[0-9]+]] = OpSMulExtended %[[_struct_30:[0-9a-zA-Z_]+]] %[[__original_id_70]] %[[__original_id_71]]
// CHECK:     %[[__original_id_109:[0-9]+]] = OpSMulExtended %[[_struct_32:[0-9a-zA-Z_]+]] %[[__original_id_72]] %[[__original_id_73]]
// CHECK:     %[[__original_id_110:[0-9]+]] = OpSMulExtended %[[_struct_34:[0-9a-zA-Z_]+]] %[[__original_id_74]] %[[__original_id_75]]
// CHECK:     %[[__original_id_111:[0-9]+]] = OpUMulExtended %[[_struct_35:[0-9a-zA-Z_]+]] %[[uint_10]] %[[uint_2]]
// CHECK:     %[[__original_id_112:[0-9]+]] = OpUMulExtended %[[_struct_36:[0-9a-zA-Z_]+]] %[[__original_id_70]] %[[__original_id_71]]
// CHECK:     %[[__original_id_113:[0-9]+]] = OpUMulExtended %[[_struct_37:[0-9a-zA-Z_]+]] %[[__original_id_72]] %[[__original_id_73]]
// CHECK:     %[[__original_id_114:[0-9]+]] = OpUMulExtended %[[_struct_38:[0-9a-zA-Z_]+]] %[[__original_id_74]] %[[__original_id_75]]
// CHECK:     %[[__original_id_115:[0-9]+]] = OpSMulExtended %[[_struct_40:[0-9a-zA-Z_]+]] %[[ulong_10]] %[[ulong_2]]
// CHECK:     %[[__original_id_116:[0-9]+]] = OpSMulExtended %[[_struct_42:[0-9a-zA-Z_]+]] %[[__original_id_78]] %[[__original_id_79]]
// CHECK:     %[[__original_id_117:[0-9]+]] = OpSMulExtended %[[_struct_44:[0-9a-zA-Z_]+]] %[[__original_id_80]] %[[__original_id_81]]
// CHECK:     %[[__original_id_118:[0-9]+]] = OpSMulExtended %[[_struct_46:[0-9a-zA-Z_]+]] %[[__original_id_82]] %[[__original_id_83]]
// CHECK:     %[[__original_id_119:[0-9]+]] = OpUMulExtended %[[_struct_47:[0-9a-zA-Z_]+]] %[[ulong_10]] %[[ulong_2]]
// CHECK:     %[[__original_id_120:[0-9]+]] = OpUMulExtended %[[_struct_48:[0-9a-zA-Z_]+]] %[[__original_id_78]] %[[__original_id_79]]
// CHECK:     %[[__original_id_121:[0-9]+]] = OpUMulExtended %[[_struct_49:[0-9a-zA-Z_]+]] %[[__original_id_80]] %[[__original_id_81]]
// CHECK:     %[[__original_id_122:[0-9]+]] = OpUMulExtended %[[_struct_50:[0-9a-zA-Z_]+]] %[[__original_id_82]] %[[__original_id_83]]

void kernel test() {
    volatile char c1 = mul_hi((char)10, (char)2);
    volatile char2 c2 = mul_hi((char2)10, (char2)2);
    volatile char3 c3 = mul_hi((char3)10, (char3)2);
    volatile char4 c4 = mul_hi((char4)10, (char4)2);

    volatile uchar uc1 = mul_hi((uchar)10, (uchar)2);
    volatile uchar2 uc2 = mul_hi((uchar2)10, (uchar2)2);
    volatile uchar3 uc3 = mul_hi((uchar3)10, (uchar3)2);
    volatile uchar4 uc4 = mul_hi((uchar4)10, (uchar4)2);

    volatile short s1 = mul_hi((short)10, (short)2);
    volatile short2 s2 = mul_hi((short2)10, (short2)2);
    volatile short3 s3 = mul_hi((short3)10, (short3)2);
    volatile short4 s4 = mul_hi((short4)10, (short4)2);

    volatile ushort us1 = mul_hi((ushort)10, (ushort)2);
    volatile ushort2 us2 = mul_hi((ushort2)10, (ushort2)2);
    volatile ushort3 us3 = mul_hi((ushort3)10, (ushort3)2);
    volatile ushort4 us4 = mul_hi((ushort4)10, (ushort4)2);

    volatile int i1 = mul_hi((int)10, (int)2);
    volatile int2 i2 = mul_hi((int2)10, (int2)2);
    volatile int3 i3 = mul_hi((int3)10, (int3)2);
    volatile int4 i4 = mul_hi((int4)10, (int4)2);

    volatile uint ui1 = mul_hi((uint)10, (uint)2);
    volatile uint2 ui2 = mul_hi((uint2)10, (uint2)2);
    volatile uint3 ui3 = mul_hi((uint3)10, (uint3)2);
    volatile uint4 ui4 = mul_hi((uint4)10, (uint4)2);

    volatile long l1 = mul_hi((long)10, (long)2);
    volatile long2 l2 = mul_hi((long2)10, (long2)2);
    volatile long3 l3 = mul_hi((long3)10, (long3)2);
    volatile long4 l4 = mul_hi((long4)10, (long4)2);

    volatile ulong ul1 = mul_hi((ulong)10, (ulong)2);
    volatile ulong2 ul2 = mul_hi((ulong2)10, (ulong2)2);
    volatile ulong3 ul3 = mul_hi((ulong3)10, (ulong3)2);
    volatile ulong4 ul4 = mul_hi((ulong4)10, (ulong4)2);
}

