package lpddr5_params;
    // Basic configuration parameters
    parameter ADDR_WIDTH = 40;
    parameter DATA_WIDTH = 32;
    parameter MAX_CHANNELS = 2;
    parameter MAX_BURST_LENGTH = 16;
    parameter PRIORITY_WIDTH = 4;
    parameter CMD_QUEUE_DEPTH = 32;

    // Bank GROUP parameters
    parameter BANK_GROUP_COUNT = 4;  // Number of rows per bank
    parameter BANK_GROUP_ADDRESS_WIDTH = $clog2(BANK_GROUP_COUNT); // Compute required bit-width


    // Bank parameters
    parameter BANK_PER_BANK_GROUP_COUNT = 4;  // Number of rows per bank
    parameter BANK_PER_BANK_GROUP_ADDRESS_WIDTH = $clog2(BANK_PER_BANK_GROUP_COUNT); // Compute required bit-width
    parameter BANK_NUMBER = BANK_PER_BANK_GROUP_COUNT * BANK_GROUP_COUNT;

    // Row parameters
    parameter ROW_PER_BANK_GROUP_COUNT = 49152;  // Number of rows per bank
    parameter ROW_PER_BANK_GROUP_ADDRESS_WIDTH = $clog2(ROW_PER_BANK_GROUP_COUNT); // Compute required bit-width

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
