#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vlpddr5_tb.h"

vluint64_t main_time = 0;

double sc_time_stamp() {
    return main_time;
}

int main(int argc, char** argv) {
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);
    
    // Create an instance of our module under test
    Vlpddr5_tb *tb = new Vlpddr5_tb;
    
    // Initialize trace dump
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    tb->trace(tfp, 99);
    tfp->open("ddr_sim.vcd");
    
    // Run simulation for 1000 clock cycles
    while (!Verilated::gotFinish() && main_time < 2000) {
        tb->eval();
        tfp->dump(main_time);
        main_time++;
    }
    
    // Clean up
    tfp->close();
    delete tb;
    delete tfp;
    
    return 0;
}
