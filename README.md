A sample project created to learn Zig

###Single threaded with no SIMD. Performance:
Render completed in 290ms
File write completed in 46ms
Total time 336ms

###Single threaded with SIMD. Performance:
Render completed in 231ms
File write completed in 45ms
Total time 276ms

###Multi threaded with SIMD Performance:
Render completed in 69ms
File write completed in 50ms
Total time 119ms

➜  zig_ray_tracer git:(main) ✗ sudo perf stat ./zig-out/bin/zig_ray_tracer
Render completed in 43ms
File write completed in 59ms
Total time 102ms

 ➜  zig_ray_tracer git:(main) ✗ sudo perf stat ./zig-out/bin/zig_ray_tracer
[sudo] password for arun: 
Render completed in 43ms
File write completed in 59ms
Total time 102ms

 Performance counter stats for './zig-out/bin/zig_ray_tracer':

            469.38 msec task-clock                       #    4.512 CPUs utilized             
                38      context-switches                 #   80.957 /sec                      
                31      cpu-migrations                   #   66.044 /sec                      
             8,164      page-faults                      #   17.393 K/sec                     
     1,144,286,365      cpu_atom/instructions/           #    0.82  insn per cycle              (29.33%)
     2,631,950,130      cpu_core/instructions/           #    1.33  insn per cycle              (65.57%)
     1,394,871,930      cpu_atom/cycles/                 #    2.972 GHz                         (29.88%)
     1,977,764,050      cpu_core/cycles/                 #    4.214 GHz                         (65.57%)
        72,601,656      cpu_atom/branches/               #  154.675 M/sec                       (29.95%)
       332,063,434      cpu_core/branches/               #  707.446 M/sec                       (65.57%)
            61,468      cpu_atom/branch-misses/          #    0.08% of all branches             (29.96%)
           475,599      cpu_core/branch-misses/          #    0.14% of all branches             (65.57%)
             TopdownL1 (cpu_core)                 #     36.4 %  tma_backend_bound      
                                                  #      9.9 %  tma_bad_speculation    
                                                  #     25.1 %  tma_frontend_bound     
                                                  #     28.5 %  tma_retiring             (65.57%)
                                                  #      6.3 %  tma_bad_speculation    
                                                  #     19.1 %  tma_retiring             (30.22%)
                                                  #     69.9 %  tma_backend_bound      
                                                  #      4.7 %  tma_frontend_bound       (30.67%)

       0.104038848 seconds time elapsed

       0.427472000 seconds user
       0.043741000 seconds sys