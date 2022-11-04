// RUN: clspv %target -cl-std=CLC++ -inline-entry-points %s -o %t.spv -arch=spir
// RUN: clspv-reflection %t.spv -o %t.dmap
// RUN: FileCheck %s < %t.dmap -check-prefix=MAP
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-32
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// RUN: clspv %target -cl-std=CLC++ -inline-entry-points %s -o %t.spv -arch=spir64
// RUN: clspv-reflection %t.spv -o %t.dmap
// RUN: FileCheck %s < %t.dmap -check-prefix=MAP
// RUN: spirv-dis -o %t2.spvasm %t.spv
// RUN: FileCheck %s < %t2.spvasm --check-prefixes=CHECK,CHECK-64
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// MAP: kernel,test_objects,arg,gout,argOrdinal,0,descriptorSet,0,binding,0,offset,0,argKind,buffer
// MAP: kernel,test_objects,arg,lout,argOrdinal,1,argKind,local,arrayElemSize,4,arrayNumElemSpecId,3

// CHECK-DAG: %[[uint:[0-9a-zA-Z_]+]] = OpTypeInt 32 0
// CHECK-DAG: %[[_runtimearr_uint:[0-9a-zA-Z_]+]] = OpTypeRuntimeArray %[[uint]]
// CHECK-DAG: %[[_struct_7:[0-9a-zA-Z_]+]] = OpTypeStruct %[[_runtimearr_uint]]
// CHECK-DAG: %[[_ptr_StorageBuffer__struct_7:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[_struct_7]]
// CHECK-DAG: %[[_ptr_Workgroup_uint:[0-9a-zA-Z_]+]] = OpTypePointer Workgroup %[[uint]]
// CHECK-DAG: %[[_ptr_StorageBuffer_uint:[0-9a-zA-Z_]+]] = OpTypePointer StorageBuffer %[[uint]]
// CHECK-DAG: %[[__spc_1:[0-9]+]] = OpSpecConstant %[[uint]] 1
// CHECK-DAG: %[[__spc_2:[0-9]+]] = OpSpecConstant %[[uint]] 1
// CHECK-DAG: %[[__spc_3:[0-9]+]] = OpSpecConstant %[[uint]] 1
// CHECK-DAG: %[[__original_id_2:[0-9]+]] = OpSpecConstant %[[uint]] 1
// CHECK-DAG: %[[_arr_uint_2:[0-9a-zA-Z_]+]] = OpTypeArray %[[uint]] %[[__original_id_2]]
// CHECK-DAG: %[[_ptr_Workgroup__arr_uint_2:[0-9a-zA-Z_]+]] = OpTypePointer Workgroup %[[_arr_uint_2]]
// CHECK-DAG: %[[uint_0:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 0
// CHECK-DAG: %[[uint_1:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 1
// CHECK-DAG: %[[uint_46:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 46
// CHECK-DAG: %[[uint_2:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 2
// CHECK-DAG: %[[uint_92:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 92
// CHECK-DAG: %[[uint_25:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 25
// CHECK-DAG: %[[uint_50:[0-9a-zA-Z_]+]] = OpConstant %[[uint]] 50
// CHECK-64-DAG: %[[ulong:[0-9a-zA-Z_]+]] = OpTypeInt 64 0
// CHECK-64-DAG: %[[ulong_1:[0-9a-zA-Z_]+]] = OpConstant %[[ulong]] 1
// CHECK-DAG: %[[__original_id_27:[0-9]+]] = OpVariable %[[_ptr_StorageBuffer__struct_7]] StorageBuffer
// CHECK-DAG: %[[__original_id_1:[0-9]+]] = OpVariable %[[_ptr_Workgroup__arr_uint_2]] Workgroup
// CHECK:     %[[__original_id_30:[0-9]+]] = OpAccessChain %[[_ptr_Workgroup_uint]] %[[__original_id_1]] %[[uint_0]]
// CHECK:     %[[__original_id_31:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_uint]] %[[__original_id_27]] %[[uint_0]] %[[uint_0]]
// CHECK:     OpStore %[[__original_id_31]] %[[uint_0]]
// CHECK:     %[[__original_id_32:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_uint]] %[[__original_id_27]] %[[uint_0]] %[[uint_1]]
// CHECK:     OpStore %[[__original_id_32]] %[[uint_46]]
// CHECK:     %[[__original_id_33:[0-9]+]] = OpAccessChain %[[_ptr_StorageBuffer_uint]] %[[__original_id_27]] %[[uint_0]] %[[uint_2]]
// CHECK:     OpStore %[[__original_id_33]] %[[uint_92]]
// CHECK:     OpStore %[[__original_id_30]] %[[uint_25]]
// CHECK-64:     %[[__original_id_34:[0-9]+]] = OpAccessChain %[[_ptr_Workgroup_uint]] %[[__original_id_1]] %[[ulong_1]]
// CHECK-32:     %[[__original_id_34:[0-9]+]] = OpAccessChain %[[_ptr_Workgroup_uint]] %[[__original_id_1]] %[[uint_1]]
// CHECK:     OpStore %[[__original_id_34]] %[[uint_50]]


struct s {
    s() : m_val(0) {}
    s(int val) : m_val(val) {}
    int val() const {
        return m_val;
    }
    void dbl() {
        m_val *= 2;
    }
private:
    int m_val;
};

void fill(global int* out) {
    s odef;
    out[0] = odef.val();
    s o(46);
    out[1] = o.val();
    o.dbl();
    out[2] = o.val();
}

void fill(local int* out) {
    s o(25);
    out[0] = o.val();
    o.dbl();
    out[1] = o.val();
}

void kernel test_objects(global int* gout, local int* lout) {
    fill(gout);
    fill(lout);
}

