// RUN: clspv %s -o %t.spv
// RUN: spirv-dis %t.spv -o %t.spvasm
// RUN: spirv-val --target-env spv1.0 %t.spv

int foo(private unsigned char *tab, unsigned int stride) {
  int res = 0;
  for (int i = 0; i < 128; i++, tab += stride) {
    res += *tab;
  }
  return res;
}

void kernel k(global int *out) {
private
  unsigned char tab[128];
  out[get_global_id(0)] = foo(tab, 4);
}
