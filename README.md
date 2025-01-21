# LPDDR5 Controller Project

This project implements an LPDDR5 memory controller and model in SystemVerilog for simulation purposes.

## Project Structure

- `ddrc/`: LPDDR5 controller implementation
  - `lpddr5_controller.sv`: Main controller logic
  - `lpddr5_params.sv`: Parameters and type definitions
- `ddr/`: LPDDR5 memory model
  - `lpddr5_model.sv`: Memory model implementation
- `tb/`: Testbench files
  - `lpddr5_tb.sv`: Main testbench

## Build Requirements

- CMake (>= 3.8)
- Verilator
- C++20 compiler (for coroutine support)

## Building the Project

```bash
mkdir build
cd build
cmake ..
make
```

## Current Issues

1. Data Write/Read Mismatch
   - The testbench shows that written data (0xdeadbeef) cannot be read back correctly
   - Timing issue: DRAM activation happens after read completion
   - Possible causes:
     - Bank activation timing not properly handled
     - Data path issues in the memory model
     - Command sequencing problems in the controller

## Next Steps

1. Debug the data path:
   - Add more debug prints in the memory model's write/read paths
   - Verify bank activation timing
   - Check if data is actually being written to memory array
2. Improve command sequencing:
   - Ensure proper ordering of ACT -> RW commands
   - Add timing checks for tRCD (RAS to CAS delay)
3. Add more test cases:
   - Multiple bank access
   - Different data patterns
   - Refresh operations
