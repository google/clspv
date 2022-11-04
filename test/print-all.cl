// RUN: clspv %target %s -cluster-pod-kernel-args -o %t-before.spv -print-before-all 2> %t-before.txt
// RUN: FileCheck -check-prefix=BEFORE %s < %t-before.txt
// RUN: clspv %target %s -cluster-pod-kernel-args -o %t-after.spv -print-after-all 2> %t-after.txt
// RUN: FileCheck -check-prefix=AFTER %s < %t-after.txt

void kernel __attribute__((reqd_work_group_size(1, 1, 1))) foo(global uint* a, uint b)
{
  for (uint i = 0; i < b; i++)
  {
    a[i]++;
  }
}

// Ideally the pass name would be the registered 'cluster-pod-kernel-args-pass'
// name rather than the class name, but it's informative enough

// BEFORE: *** IR Dump Before clspv::ClusterPodKernelArgumentsPass

// AFTER: *** IR Dump After clspv::ClusterPodKernelArgumentsPass
