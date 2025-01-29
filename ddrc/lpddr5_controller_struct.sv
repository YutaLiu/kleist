package lpddr5_controller_struct;
    import lpddr5_params::*;  // 導入參數包

    // Write Command Queue Entry
    typedef struct packed {
        logic                    valid;
        logic [PRIORITY_WIDTH-1:0] cmd_prio;  // cmd_prio
        logic [ADDR_WIDTH-1:0]   addr;
        logic [MAX_BURST_LENGTH-1:0] data_valid;     // 數據有效位
        logic [DATA_WIDTH-1:0][MAX_BURST_LENGTH-1:0] wdata;
    } wcmd_queue_entry_t;

    // Read Command Queue Entry
    typedef struct packed {
        logic                    valid;          // 命令有效位
        logic [PRIORITY_WIDTH-1:0] cmd_prio;     // 命令優先級
        logic [ADDR_WIDTH-1:0]   addr;           // 地址
        logic [MAX_BURST_LENGTH-1:0] data_valid;     // 數據有效位
        logic [DATA_WIDTH-1:0][MAX_BURST_LENGTH-1:0] rdata;
    } rcmd_queue_entry_t;

endpackage