// RUN: clspv -verify %s

kernel void pipes(read_only pipe int in, write_only pipe int out) {
    //expected-error@3{{type specifier missing, defaults to 'int'; ISO C99 and later do not support implicit int}}
    //expected-error@3{{access qualifier can only be used for pipe and image type}}
    //expected-warning@3{{unused parameter 'pipe'}}
    //expected-error@3{{expected ')'}}
    //expected-note@3{{to match this '('}}
    reserve_id_t ires = reserve_read_pipe(in, 2); //expected-error{{use of undeclared identifier 'reserve_id_t'}}
    reserve_id_t ores = reserve_write_pipe(out, 2); //expected-error{{use of undeclared identifier 'reserve_id_t'}}
}
