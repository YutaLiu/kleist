package lpddr5_params;
    // Basic configuration parameters
    parameter ADDR_WIDTH = 40;
    parameter DATA_WIDTH = 32;
    parameter MAX_CHANNELS = 4;
    parameter MAX_BURST_LENGTH = 16;
    parameter PRIORITY_WIDTH = 4;
    parameter CMD_QUEUE_DEPTH = 32;
    parameter BANK_NUM = 8;
    
    // Timing parameters (for simulation, using reduced values)
    parameter CL = 4;         // CAS Latency
    parameter tRCD = 4;       // RAS to CAS Delay
    parameter tRP = 4;        // Row Precharge Time
    parameter tRAS = 10;      // Row Active Time
    parameter tRC = 14;       // Row Cycle Time
    parameter tWR = 4;        // Write Recovery Time
    parameter tRFC = 20;      // Refresh Cycle Time
    parameter tREFI = 100;    // Refresh Interval (reduced for simulation)
    
    // Command definitions
    typedef enum logic [2:0] {
        CMD_NOP  = 3'b000,
        CMD_ACT  = 3'b001,
        CMD_RD   = 3'b010,
        CMD_WR   = 3'b011,
        CMD_PRE  = 3'b100,
        CMD_REF  = 3'b101
    } dram_cmd_t;
    
    // Bank states
    typedef enum logic [2:0] {
        IDLE,
        ACTIVATING,
        ACTIVE,
        READING,
        WRITING,
        PRECHARGING,
        REFRESHING
    } bank_state_t;
    
endpackage
