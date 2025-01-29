cmake_minimum_required(VERSION 3.8)
project(ddr_controller)

# Set C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
if (NOT verilator_FOUND)
    message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
endif()

# Add source files
set(VERILOG_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/ddrc/lpddr5_params.sv
    ${CMAKE_CURRENT_SOURCE_DIR}/ddrc/lpddr5_controller_struct.sv
    ${CMAKE_CURRENT_SOURCE_DIR}/ddrc/lpddr5_controller_enum.sv
    ${CMAKE_CURRENT_SOURCE_DIR}/ddr/lpddr5_model.sv
    ${CMAKE_CURRENT_SOURCE_DIR}/ddrc/lpddr5_controller.sv
    ${CMAKE_CURRENT_SOURCE_DIR}/tb/lpddr5_tb.sv
)

# Create a new executable target name ddr_sim , and use sim_main.cpp as the source file
add_executable(ddr_sim sim_main.cpp)

# Create Verilated objects
verilate(ddr_sim
    SOURCES ${VERILOG_SOURCES}
    TOP_MODULE lpddr5_tb
    PREFIX Vlpddr5_tb
    TRACE
    VERILATOR_ARGS --timing -Wno-PINMISSING -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND
)
