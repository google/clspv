// RUN: clspv -w -c++ -inline-entry-points -verify %s

void kernel test(global int* ptr) {}
void kernel test(local int* ptr) {} //expected-error{{kernel functions can't be overloaded}}
