package lpddr5_params;
    // Basic configuration parameters
    parameter ADDR_WIDTH = 40;
    parameter DATA_WIDTH = 32;
    parameter MAX_CHANNELS = 4;
    parameter MAX_BURST_LENGTH = 16;
    parameter PRIORITY_WIDTH = 4;
    parameter CMD_QUEUE_DEPTH = 32;
    parameter BANK_NUM = 8;
    parameter ROW_WIDTH = 16;     // Row address width
    // Timing parameters (for simulation, using reduced values)
    parameter CL = 4;         // CAS Latency
    parameter tRCD = 4;       // RAS to CAS Delay
    parameter tRP = 4;        // Row Precharge Time
    parameter tRAS = 10;      // Row Active Time
    parameter tRC = 14;       // Row Cycle Time
    parameter tWR = 4;        // Write Recovery Time
    parameter tRFC = 20;      // Refresh Cycle Time
    parameter tREFI = 100;    // Refresh Interval (reduced for simulation)
    

endpackage
