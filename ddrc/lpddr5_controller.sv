module lpddr5_controller
    import lpddr5_params::*;
#(
    parameter CHANNELS = 2,
    parameter BURST_LENGTH = 16,
    parameter DATA_BITS = 32
)(
    input  logic clk,
    input  logic rst_n,
    
    // controller interface 
    input  logic                    cmd_valid,
    input  logic                    cmd_rw,      // 1:寫入, 0:讀取
    input  logic [PRIORITY_WIDTH-1:0] cmd_priority,
    input  logic [ADDR_WIDTH-1:0]   cmd_addr,
    input  logic [CHANNELS-1:0][DATA_BITS-1:0][BURST_LENGTH-1:0] cmd_wdata,
    output logic [CHANNELS-1:0][DATA_BITS-1:0][BURST_LENGTH-1:0] cmd_rdata,
    output logic                    cmd_ready,
    
    // DRAM interface 
    output dram_cmd_t              dram_cmd,
    output logic [ADDR_WIDTH-1:0]  dram_addr,
    output logic [CHANNELS-1:0][DATA_BITS-1:0][BURST_LENGTH-1:0] dram_wdata,
    input  logic [CHANNELS-1:0][DATA_BITS-1:0][BURST_LENGTH-1:0] dram_rdata,
    input  logic                   dram_ready
);

    // state machine define 
    typedef enum logic [2:0] {
        IDLE,
        READ_DATA,
        WRITE_DATA,
        REFRESH,
        ACTIVATE,
        PRECHARGE
    } state_t;
    
    state_t current_state;

    // queue packed define
    typedef struct packed {
        logic                    valid;
        logic                    rw;
        logic [PRIORITY_WIDTH-1:0] cmd_prio;  // cmd_prio
        logic [ADDR_WIDTH-1:0]   addr;
        logic [CHANNELS-1:0][DATA_BITS-1:0][BURST_LENGTH-1:0] wdata;
    } cmd_queue_entry_t;

    // command queue
    cmd_queue_entry_t cmd_queue[CMD_QUEUE_DEPTH];
    logic [$clog2(CMD_QUEUE_DEPTH):0] queue_count;
    logic [$clog2(CMD_QUEUE_DEPTH)-1:0] queue_head, queue_tail;

    // Bank status check 
    logic [ADDR_WIDTH-1:0] active_row[BANK_NUM];
    logic bank_open[BANK_NUM];
    logic [$clog2(BANK_NUM)-1:0] current_bank;
    
    // refresh counter
    logic [15:0] refresh_counter;
    localparam REFRESH_INTERVAL = tREFI; // 使用tREFI參數

    // command queue op
    function automatic logic queue_full();
        return queue_count == CMD_QUEUE_DEPTH;
    endfunction

    function automatic logic queue_empty();
        return queue_count == 0;
    endfunction

    // find highest command 
    function automatic logic [$clog2(CMD_QUEUE_DEPTH)-1:0] find_highest_priority();
        logic [$clog2(CMD_QUEUE_DEPTH)-1:0] highest_idx;
        logic [PRIORITY_WIDTH-1:0] highest_prio;  // 改名為highest_prio
        highest_prio = 0;
        highest_idx = queue_head;
        
        for (int i = 0; i < CMD_QUEUE_DEPTH; i++) begin
            logic [$clog2(CMD_QUEUE_DEPTH)-1:0] idx;
            idx = $unsigned({27'b0, queue_head} + i) % CMD_QUEUE_DEPTH;
            if (cmd_queue[idx].valid && cmd_queue[idx].cmd_prio > highest_prio) begin
                highest_prio = cmd_queue[idx].cmd_prio;
                highest_idx = idx;
            end
        end
        return highest_idx;
    endfunction

    // main state machine 
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            $display("[%0t] Controller: Reset asserted", $time);
            current_state <= IDLE;
            cmd_ready <= 1'b1;
            dram_cmd <= CMD_NOP;
            queue_head <= '0;
            queue_tail <= '0;
            queue_count <= '0;
            refresh_counter <= '0;
            for (int i = 0; i < BANK_NUM; i++) begin
                bank_open[i] <= 1'b0;
                active_row[i] <= '0;
            end
            for (int i = 0; i < CMD_QUEUE_DEPTH; i++) begin
                cmd_queue[i].valid <= 1'b0;
            end
        end else begin
            // refresh counter
            if (refresh_counter < REFRESH_INTERVAL)
                refresh_counter <= refresh_counter + 1;

            // command in queue
            if (cmd_valid && !queue_full()) begin
                $display("[%0t] Controller: Received command - RW: %b, Addr: %h", $time, cmd_rw, cmd_addr);
                cmd_queue[queue_tail].valid <= 1'b1;
                cmd_queue[queue_tail].rw <= cmd_rw;
                cmd_queue[queue_tail].addr <= cmd_addr;
                cmd_queue[queue_tail].wdata <= cmd_wdata;
                queue_tail <= $unsigned({27'b0, queue_tail} + 1) % CMD_QUEUE_DEPTH;
                queue_count <= queue_count + 1;
            end

            cmd_ready <= !queue_full();

            case (current_state)
                IDLE: begin
                    if (refresh_counter >= REFRESH_INTERVAL) begin
                        // need refresh
                        $display("[%0t] Controller: Starting refresh cycle", $time);
                        current_state <= REFRESH;
                        dram_cmd <= CMD_REF;
                        refresh_counter <= '0;
                    end else if (!queue_empty()) begin
                        // handle command in queue
                        logic [$clog2(CMD_QUEUE_DEPTH)-1:0] cmd_idx;
                        cmd_idx = find_highest_priority();
                        current_bank = cmd_queue[cmd_idx].addr[ADDR_WIDTH-1:ADDR_WIDTH-$clog2(BANK_NUM)];
                        
                        if (!bank_open[current_bank]) begin
                            $display("[%0t] Controller: Activating bank %0d", $time, current_bank);
                            current_state <= ACTIVATE;
                            dram_cmd <= CMD_ACT;
                            dram_addr <= cmd_queue[cmd_idx].addr;
                            bank_open[current_bank] <= 1'b1;
                            active_row[current_bank] <= cmd_queue[cmd_idx].addr;
                        end else begin
                            if (active_row[current_bank] != cmd_queue[cmd_idx].addr) begin
                                $display("[%0t] Controller: Row mismatch, precharging bank %0d", $time, current_bank);
                                current_state <= PRECHARGE;
                                dram_cmd <= CMD_PRE;
                                bank_open[current_bank] <= 1'b0;
                            end else begin
                                $display("[%0t] Controller: Executing %s command", $time, cmd_queue[cmd_idx].rw ? "write" : "read");
                                current_state <= cmd_queue[cmd_idx].rw ? WRITE_DATA : READ_DATA;
                                dram_cmd <= cmd_queue[cmd_idx].rw ? CMD_WR : CMD_RD;
                                dram_wdata <= cmd_queue[cmd_idx].wdata;
                                dram_addr <= cmd_queue[cmd_idx].addr;
                            end
                        end
                        // remove handle's command from queue
                        cmd_queue[cmd_idx].valid <= 1'b0;
                        if (cmd_idx == queue_head)
                            queue_head <= $unsigned({27'b0, queue_head} + 1) % CMD_QUEUE_DEPTH;
                        queue_count <= queue_count - 1;
                    end else begin
                        dram_cmd <= CMD_NOP;
                    end
                end
                
                WRITE_DATA: begin
                    if (dram_ready) begin
                        current_state <= IDLE;
                        dram_cmd <= CMD_NOP;
                    end
                end
                
                READ_DATA: begin
                    if (dram_ready) begin
                        current_state <= IDLE;
                        dram_cmd <= CMD_NOP;
                        cmd_rdata <= dram_rdata;
                    end
                end

                REFRESH: begin
                    if (dram_ready) begin
                        current_state <= IDLE;
                        dram_cmd <= CMD_NOP;
                    end
                end
                
                ACTIVATE: begin
                    if (dram_ready) begin
                        current_state <= IDLE;
                        dram_cmd <= CMD_NOP;
                    end
                end
                
                PRECHARGE: begin
                    if (dram_ready) begin
                        current_state <= IDLE;
                        dram_cmd <= CMD_NOP;
                    end
                end
                
                default: begin
                    current_state <= IDLE;
                end
            endcase
        end
    end

endmodule
