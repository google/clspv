// RUN: clspv %target -w -cl-std=CLC++ -inline-entry-points -verify %s

void kernel test(global int* ptr) {} //expected-note{{previous definition is here}}
void kernel test(local int* ptr) {}
//expected-error@-1{{conflicting types for 'test'}}
//expected-error@-2{{kernel functions can't be overloaded}}
