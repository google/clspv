// RUN: clspv %target -verify %s

kernel void dse(queue_t queue) { //expected-error{{unknown type name 'queue_t'}}
    ndrange_t ndrange = ndrange_1D(1); //expected-error{{use of undeclared identifier 'ndrange_t'}}
    clk_event_t event; //expected-error{{use of undeclared identifier 'clk_event_t'}}
    enqueue_kernel(queue, //expected-error{{use of undeclared identifier 'enqueue_kernel'}}
                   CLK_ENQUEUE_FLAGS_WAIT_KERNEL, //expected-error{{use of undeclared identifier 'CLK_ENQUEUE_FLAGS_WAIT_KERNEL'}}
                   ndrange, //expected-error{{use of undeclared identifier 'ndrange'}}
                   0, NULL, &event, //expected-error{{use of undeclared identifier 'event'}}
                   ^{ //expected-error{{blocks support disabled}}
                   });
    clk_profiling_info pinfo = CLK_PROFILING_COMMAND_EXEC_TIME; //expected-error{{use of undeclared identifier 'clk_profiling_info'}}
    ulong values[2];
    capture_event_profiling_info(event, pinfo, values);
    //expected-error@14{{use of undeclared identifier 'event'}}
    //expected-error@14{{use of undeclared identifier 'capture_event_profiling_info'}}
    //expected-error@14{{use of undeclared identifier 'pinfo'}}
}
