// TODO: figure out how to setup the pass printing properly again
// XFAIL: *
// RUN: clspv %s -cluster-pod-kernel-args -o %t-before.spv -print-before-all 2> %t-before.txti
// RUN: FileCheck -check-prefix=BEFORE %s < %t-before.txt

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a, uint b)
{
  for (uint i = 0; i < b; i++)
  {
    a[i]++;
  }
}

// BEFORE: *** IR Dump Before Cluster POD Kernel Arguments Pass

// AFTER: *** IR Dump After Cluster POD Kernel Arguments Pass
