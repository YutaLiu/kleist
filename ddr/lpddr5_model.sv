module lpddr5_model
    import lpddr5_params::*;
#(
    parameter CHANNELS = 2,
    parameter BURST_LENGTH = 16,
    parameter DATA_BITS = 32
) (
    input  logic clk,
    input  logic rst_n,
    
    //Dram interface
    input  dram_cmd_t              dram_cmd,
    input  logic [ADDR_WIDTH-1:0]  dram_addr,
    input  logic [CHANNELS-1:0][DATA_BITS-1:0][BURST_LENGTH-1:0] dram_wdata,
    output logic [CHANNELS-1:0][DATA_BITS-1:0][BURST_LENGTH-1:0] dram_rdata,
    output logic                   dram_ready
);

    // array sim
    logic [DATA_BITS-1:0] memory[CHANNELS][2**20]; 
    
    // Bank status
    logic [BANK_NUM-1:0] bank_active;
    logic [ADDR_WIDTH-1:0] active_row[BANK_NUM];
    
    // counter
    logic [15:0] tRCD_counter;   // RAS to CAS delay
    logic [15:0] tRP_counter;    // Precharge to activate delay
    logic [15:0] tRAS_counter;   // Row active time
    logic [15:0] tRC_counter;    // Row cycle time
    logic [15:0] tWR_counter;    // Write recovery time
    logic [15:0] tRFC_counter;   // Refresh cycle time
    logic [15:0] cas_counter;    // CAS latency counter

    // bank index 
    logic [$clog2(BANK_NUM)-1:0] current_bank;
    
    // Bank state machine 
    typedef enum logic [2:0] {
        IDLE,
        ACTIVATING,
        ACTIVE,
        READING,
        WRITING,
        PRECHARGING,
        REFRESHING
    } bank_state_t;
    
    bank_state_t bank_state[BANK_NUM];

    // 初始化和重置邏輯
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            $display("[%0t] DRAM: Reset asserted", $time);
            bank_active <= '0;
            tRCD_counter <= '0;
            tRP_counter <= '0;
            tRAS_counter <= '0;
            tRC_counter <= '0;
            tWR_counter <= '0;
            tRFC_counter <= '0;
            cas_counter <= '0;
            dram_ready <= 1'b1;
            dram_rdata <= '0;
            for (int i = 0; i < BANK_NUM; i++) begin
                bank_state[i] <= IDLE;
                active_row[i] <= '0;
            end
        end else begin
            // 更新計數器
            if (tRCD_counter > 0) tRCD_counter <= tRCD_counter - 1;
            if (tRP_counter > 0) tRP_counter <= tRP_counter - 1;
            if (tRAS_counter > 0) tRAS_counter <= tRAS_counter - 1;
            if (tRC_counter > 0) tRC_counter <= tRC_counter - 1;
            if (tWR_counter > 0) tWR_counter <= tWR_counter - 1;
            if (tRFC_counter > 0) tRFC_counter <= tRFC_counter - 1;
            if (cas_counter > 0) cas_counter <= cas_counter - 1;

            // 命令處理
            current_bank = dram_addr[ADDR_WIDTH-1:ADDR_WIDTH-$clog2(BANK_NUM)];
            
            case (dram_cmd)
                CMD_ACT: begin
                    if (bank_state[current_bank] == IDLE && tRP_counter == 0) begin
                        $display("[%0t] DRAM: Activating row %h", $time, dram_addr);
                        bank_state[current_bank] <= ACTIVATING;
                        bank_active[current_bank] <= 1'b1;
                        active_row[current_bank] <= dram_addr;
                        tRCD_counter <= tRCD;
                        tRAS_counter <= tRAS;
                        dram_ready <= 1'b0;
                    end
                end

                CMD_RD: begin
                    if (bank_state[current_bank] == ACTIVE && tRCD_counter == 0) begin
                        $display("[%0t] DRAM: Reading from address %h", $time, dram_addr);
                        bank_state[current_bank] <= READING;
                        cas_counter <= CL;
                        dram_ready <= 1'b0;
                        
                        for (int ch = 0; ch < CHANNELS; ch++) begin
                            for (int b = 0; b < BURST_LENGTH; b++) begin
                                dram_rdata[ch][0][b] <= memory[ch][dram_addr[19:0]];
                            end
                        end
                    end
                end

                CMD_WR: begin
                    if (bank_state[current_bank] == ACTIVE && tRCD_counter == 0) begin
                        $display("[%0t] DRAM: Writing to address %h", $time, dram_addr);
                        bank_state[current_bank] <= WRITING;
                        tWR_counter <= tWR;
                        dram_ready <= 1'b0;
                        
                        for (int ch = 0; ch < CHANNELS; ch++) begin
                            for (int b = 0; b < BURST_LENGTH; b++) begin
                                memory[ch][dram_addr[19:0]] <= dram_wdata[ch][0][b];
                            end
                        end
                    end
                end

                CMD_PRE: begin
                    if (bank_state[current_bank] != PRECHARGING && 
                        tRAS_counter == 0) begin
                        $display("[%0t] DRAM: Precharging bank %0d", $time, current_bank);
                        bank_state[current_bank] <= PRECHARGING;
                        bank_active[current_bank] <= 1'b0;
                        tRP_counter <= tRP;
                        dram_ready <= 1'b0;
                    end
                end

                CMD_REF: begin
                    $display("[%0t] DRAM: Refresh cycle started", $time);
                    if (!(|bank_active) && tRP_counter == 0) begin
                        for (int i = 0; i < BANK_NUM; i++) begin
                            bank_state[i] <= REFRESHING;
                        end
                        bank_active <= '0;
                        tRFC_counter <= tRFC;
                        dram_ready <= 1'b0;
                    end
                end

                default: begin // CMD_NOP
                    // 更新Bank狀態
                    for (int i = 0; i < BANK_NUM; i++) begin
                        case (bank_state[i])
                            ACTIVATING: begin
                                if (tRCD_counter == 0)
                                    bank_state[i] <= ACTIVE;
                            end
                            
                            READING: begin
                                if (cas_counter == 0)
                                    bank_state[i] <= ACTIVE;
                            end
                            
                            WRITING: begin
                                if (tWR_counter == 0)
                                    bank_state[i] <= ACTIVE;
                            end
                            
                            PRECHARGING: begin
                                if (tRP_counter == 0)
                                    bank_state[i] <= IDLE;
                            end
                            
                            REFRESHING: begin
                                if (tRFC_counter == 0)
                                    bank_state[i] <= IDLE;
                            end
                            
                            default: begin
                                // IDLE state, no action needed
                            end
                        endcase
                    end
                    
                    // Set ready when all timing constraints are met
                    if (tRCD_counter == 0 && tRP_counter == 0 && 
                        tRAS_counter == 0 && tRC_counter == 0 && 
                        tWR_counter == 0 && tRFC_counter == 0 && 
                        cas_counter == 0) begin
                        dram_ready <= 1'b1;
                    end
                end
            endcase
        end
    end

endmodule
