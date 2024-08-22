// RUN: clspv %s -o %t.spv --cl-std=CL2.0 --inline-entry-points
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val %t.spv --target-env spv1.0

typedef struct PrefixState {
  uint agg;
  uint inclusive_prefix;
  atomic_uint flag;
} PrefixState;


__kernel void prefix_scan( 
  __global PrefixState *prefix_states,
  __global atomic_uint *partition) {
  __local uint part_id;
  // first thread in each block gets its part by atomically incrementing the global partition variable.
  if (get_local_id(0) == 0) {
    part_id = atomic_fetch_add(partition, 1);
  }

  // one thread in each block updates the aggregate/flag
  if (get_local_id(0) == 0) {
    prefix_states[1].agg = 1;
    atomic_store_explicit(&prefix_states[part_id].flag, 1, memory_order_release);
  }

}
