
### 1: On macOS 26.4, macbook pro 16 with M4 MAX (16 cores):

```
==============================
        COMPARISON
==============================

  --- Speed ---
  deserialize:     rust-sonic = 21.891 ms   java-dsljson = 28.660 ms
  serialize:       rust-sonic = 13.457 ms   java-dsljson = 29.003 ms

  --- Memory ---
  rust:            rust-sonic peak RSS = 99.500 MiB
  java:            java-dsljson heap used = 739.223 MiB   total (heap+non-heap) = 746.174 MiB

  --- CPU time ---
  rust:            rust-sonic = 2.253 s
  java:            java-dsljson = 4.754 s

  Winner:
  deserialize:     rust-sonic wins — 21.891 ms vs 28.660 ms  (1.31x, 23.6% less)
  serialize:       rust-sonic wins — 13.457 ms vs 29.003 ms  (2.16x, 53.6% less)
  memory:          rust-sonic wins — 99.500 MiB vs 746.174 MiB  (7.50x, 86.7% less)
  cpu_time:        rust-sonic wins — 2.253 s vs 4.754 s  (2.11x, 52.6% less)
```
