// RUN: clspv -w -pod-ubo -verify %s

typedef struct {
  struct { int x[4]; int y; } x[2]; //expected-note{{here}}
} data_type;

__kernel void foo(__global data_type *data, data_type pod_arg) { //expected-error{{clspv restriction: to satisfy UBO ArrayStride restrictions, element size must be a multiple of array alignment}}
  data->x[0].x[0] = pod_arg.x[0].x[0];
}

