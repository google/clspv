// RUN: clspv -verify %s

// Test that enums are not rejected by the frontend plugin
// expected-no-diagnostics

typedef enum an_enum {
  OPTION1 = 13,
  OPTION2 = 45,
  OPTION3
} an_enum_type;

void kernel test() {
    volatile an_enum_type myenum;
    (void)myenum;
}
