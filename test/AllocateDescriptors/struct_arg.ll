; RUN: clspv-opt -opaque-pointers %s -o %t.ll --passes=allocate-descriptors
; RUN: FileCheck %s < %t.ll

; CHECK: [[type:%[a-zA-Z0-9_.]+]] = type { <4 x i32>, <4 x float> }
; CHECK: call ptr addrspace(3) @_Z11clspv.local.3(i32 3, [0 x [[type]]] zeroinitializer)
; CHECK: call ptr addrspace(1) @_Z14clspv.resource.2(i32 0, i32 2, i32 0, i32 3, i32 2, i32 0, { [0 x [[type]]] } zeroinitializer)
; CHECK: !_Z20clspv.local_spec_ids = !{[[ids:![0-9]+]]}
; CHECK: [[ids]] = !{ptr @test, i32 0, i32 3}

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

%struct.S = type { <4 x i32>, <4 x float> }

define dso_local spir_kernel void @test(ptr addrspace(3) align 16 %wg, ptr addrspace(1) align 16 %in1, ptr addrspace(1) align 16 %in2, ptr addrspace(1) align 16 %out) !clspv.pod_args_impl !8 {
entry:
  %call = call spir_func i32 @_Z12get_local_idj(i32 0)
  %arrayidx = getelementptr inbounds <4 x i32>, ptr addrspace(1) %in1, i32 %call
  %0 = load <4 x i32>, ptr addrspace(1) %arrayidx, align 16
  %arrayidx1 = getelementptr inbounds %struct.S, ptr addrspace(3) %wg, i32 %call
  %x = getelementptr inbounds %struct.S, ptr addrspace(3) %arrayidx1, i32 0, i32 0
  store <4 x i32> %0, ptr addrspace(3) %x, align 16
  %arrayidx2 = getelementptr inbounds <4 x float>, ptr addrspace(1) %in2, i32 %call
  %1 = load <4 x float>, ptr addrspace(1) %arrayidx2, align 16
  %arrayidx3 = getelementptr inbounds %struct.S, ptr addrspace(3) %wg, i32 %call
  %y = getelementptr inbounds %struct.S, ptr addrspace(3) %arrayidx3, i32 0, i32 1
  store <4 x float> %1, ptr addrspace(3) %y, align 16
  call spir_func void @_Z7barrierj(i32 1)
  %arrayidx4 = getelementptr inbounds %struct.S, ptr addrspace(1) %out, i32 %call
  %arrayidx5 = getelementptr inbounds %struct.S, ptr addrspace(3) %wg, i32 %call
  call void @llvm.memcpy.p1.p3.i32(ptr addrspace(1) align 16 %arrayidx4, ptr addrspace(3) align 16 %arrayidx5, i32 32, i1 false)
  ret void
}

declare spir_func i32 @_Z12get_local_idj(i32)

declare spir_func void @_Z7barrierj(i32)

declare void @llvm.memcpy.p1.p3.i32(ptr addrspace(1) noalias nocapture writeonly, ptr addrspace(3) noalias nocapture readonly, i32, i1 immarg)

!llvm.module.flags = !{!0}
!opencl.ocl.version = !{!1}
!opencl.spir.version = !{!1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, i32 2}
!8 = !{i32 1}

