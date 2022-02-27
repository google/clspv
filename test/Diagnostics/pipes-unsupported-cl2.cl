// RUN: clspv -cl-std=CL2.0 -inline-entry-points -verify %s

kernel void pipes(read_only pipe int in, write_only pipe int out) { //expected-error{{pipes are not supported}}
    reserve_id_t ires = reserve_read_pipe(in, 2); //expected-warning{{unused variable 'ires'}}
    reserve_id_t ores = reserve_write_pipe(out, 2); //expected-warning{{unused variable 'ores'}}
}
