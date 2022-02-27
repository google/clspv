// RUN: clspv -cl-std=CL3.0 -verify %s

kernel void pipes(read_only pipe int in, write_only pipe int out) {
    //expected-error@3{{OpenCL C version 3.0 does not support the 'pipe' type qualifier}}
    //expected-error@3{{OpenCL C version 3.0 does not support the 'pipe' type qualifier}}
    //expected-error@3{{access qualifier can only be used for pipe and image type}}
    //expected-error@3{{access qualifier can only be used for pipe and image type}}
    //expected-warning@3{{unused parameter 'in'}}
    //expected-warning@3{{unused parameter 'out'}}
    reserve_id_t ires = reserve_read_pipe(in, 2); //expected-error{{use of undeclared identifier 'reserve_id_t'}}
    reserve_id_t ores = reserve_write_pipe(out, 2); //expected-error{{use of undeclared identifier 'reserve_id_t'}}
}
