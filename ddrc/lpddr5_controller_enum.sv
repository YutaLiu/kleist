package lpddr5_controller_enum;

    // 方法1：基本的 enum 定義，自動分配值
    typedef enum logic {
        CMD_READ  = 1'b0,
        CMD_WRITE = 1'b1
    } cmd_rw_t;

    // 方法2：指定位寬的 enum
    typedef enum logic [1:0] {
        CMD_TYPE_READ    = 2'b00,
        CMD_TYPE_WRITE   = 2'b01,
        CMD_TYPE_REFRESH = 2'b10,
        CMD_TYPE_NOP     = 2'b11
    } cmd_type_t;

    // 方法3：使用參數化的 enum
    parameter CMD_BITS = 3;

    // Command definitions
    typedef enum logic [CMD_BITS-1:0] {
        CMD_NOP  = 3'b000,
        CMD_ACT  = 3'b001,
        CMD_RD   = 3'b010,
        CMD_WR   = 3'b011,
        CMD_PRE  = 3'b100,
        CMD_REF  = 3'b101,
        CMD_ERR  = 3'b111
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
