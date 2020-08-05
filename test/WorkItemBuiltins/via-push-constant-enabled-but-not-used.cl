// RUN: clspv -work-dim -global-offset -cl-std=CL2.0 -inline-entry-points %s -o %t.spv
// RUN: clspv-reflection %t.spv -o %t.dmap
// RUN: FileCheck --check-prefix=DMAP %s < %t.dmap
// RUN: spirv-val --target-env vulkan1.0 %t.spv

// DMAP-NOT: pushconstant,name,dimensions
// DMAP-NOT: pushconstant,name,global_offset
// DMAP-NOT: pushconstant,name,enqueued_local_size

void kernel __attribute__((reqd_work_group_size(1,1,1))) test(int dummy) {}

