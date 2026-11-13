// RUN: clspv %target -verify %s
// RUN: clspv %target -verify %s -rewrite-packed-structs
// RUN: clspv %target -verify %s -DTYPEDEF_CONSTANT
// RUN: clspv %target -verify %s -DLOCAL_AS
// RUN: clspv %target -verify %s -DDEFINED_LATER
// RUN: clspv %target -verify %s -DINLINE_DECL
// RUN: clspv %target -verify %s -DCOMPLETED

#ifdef INLINE_DECL
// expected-warning@+1{{declaration of 'struct nope' will not be visible outside of this function}}
kernel void test(global struct nope* arg) { (void)arg; } // expected-error{{structure types must be complete}}
#else
struct fwd;
typedef struct fwd fwd_t;

void helper(global struct fwd* p);
void helper(global struct fwd* p) { (void)p; }

#ifdef COMPLETED
// expected-no-diagnostics
struct fwd { int x; };
kernel void test(constant fwd_t* arg, global int* out) { *out = arg->x; }
#elif defined(TYPEDEF_CONSTANT)
kernel void test(constant fwd_t* arg) { (void)arg; } // expected-error{{structure types must be complete}}
#elif defined(LOCAL_AS)
kernel void test(local struct fwd* arg) { (void)arg; } // expected-error{{structure types must be complete}}
#elif defined(DEFINED_LATER)
kernel void test(global struct fwd* arg) { (void)arg; } // expected-error{{structure types must be complete}}
struct fwd { int x; };
#else
kernel void test(global struct fwd* arg) { (void)arg; } // expected-error{{structure types must be complete}}
#endif
#endif
