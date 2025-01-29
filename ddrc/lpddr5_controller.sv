module lpddr5_controller
    import lpddr5_params::*;
    import lpddr5_controller_struct::*;
    import lpddr5_controller_enum::*;
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
    input  logic [BURST_LENGTH-1:0] cmd_data_valid,
    input  logic [DATA_BITS-1:0][BURST_LENGTH-1:0] cmd_wdata,
    output logic [DATA_BITS-1:0][BURST_LENGTH-1:0] cmd_rdata,
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

    // command queue
    wcmd_queue_entry_t wcmd_queue[CMD_QUEUE_DEPTH];
    rcmd_queue_entry_t rcmd_queue[CMD_QUEUE_DEPTH];
    logic [$clog2(CMD_QUEUE_DEPTH)-1:0] wqueue_head, wqueue_tail;
    logic [$clog2(CMD_QUEUE_DEPTH)-1:0] rqueue_head, rqueue_tail;
    logic [$clog2(CMD_QUEUE_DEPTH):0] wqueue_count, rqueue_count;

    // bank status
    logic bank_open[BANK_NUM];
    logic [$clog2(BANK_NUM)-1:0] current_bank;
    logic [ROW_WIDTH-1:0] active_row[BANK_NUM];
    
    // refresh counter
    logic [15:0] refresh_counter;
    localparam REFRESH_INTERVAL = tREFI;

    // command queue operations
    function automatic logic queue_full;
        input cmd_rw_t cmd_rw;
        begin
            if (cmd_rw == CMD_READ)
                queue_full = (rqueue_count == CMD_QUEUE_DEPTH);
            else if (cmd_rw == CMD_WRITE)
                queue_full = (wqueue_count == CMD_QUEUE_DEPTH);
            else
                queue_full = 1'b0;
        end
    endfunction

    function automatic logic queue_empty;
        input cmd_rw_t cmd_rw;
        begin
            if (cmd_rw == CMD_READ)
                queue_empty = (rqueue_count == 0);
            else if (cmd_rw == CMD_WRITE)
                queue_empty = (wqueue_count == 0);
            else
                queue_empty = 1'b1;
        end
    endfunction

    function automatic int find_highest_priority;
        input cmd_rw_t cmd_rw;
        int highest_prio;
        int highest_idx;
        begin : find_block
            highest_prio = 0;
            highest_idx = -1;
            
            if (cmd_rw == CMD_READ) begin
                for (int i = 0; i < CMD_QUEUE_DEPTH; i++) begin : search_loop
                    int idx;
                    idx = (rqueue_head + i) % CMD_QUEUE_DEPTH;
                    if (rcmd_queue[idx].valid && rcmd_queue[idx].cmd_prio > highest_prio) begin
                        highest_idx = idx;
                        highest_prio = rcmd_queue[idx].cmd_prio;
                    end
                end
            end else begin
                for (int i = 0; i < CMD_QUEUE_DEPTH; i++) begin : search_loop
                    int idx;
                    idx = (wqueue_head + i) % CMD_QUEUE_DEPTH;
                    if (wcmd_queue[idx].valid && wcmd_queue[idx].cmd_prio > highest_prio) begin
                        highest_idx = idx;
                        highest_prio = wcmd_queue[idx].cmd_prio;
                    end
                end
            end
            find_highest_priority = highest_idx;
        end
    endfunction

    // Reset and initialization
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            $display("[%0t] Controller: Reset asserted", $time);
            current_state <= IDLE;
            cmd_ready <= 1'b1;
            refresh_counter <= '0;
            for (int i = 0; i < BANK_NUM; i++) begin
                bank_open[i] <= 1'b0;
            end
        end else begin
            // refresh counter
            if (refresh_counter < REFRESH_INTERVAL)
                refresh_counter <= refresh_counter + 1;

            case (current_state)
                IDLE: begin
                    if (cmd_valid && !queue_full(cmd_rw_t'(cmd_rw))) begin
                        $display("[%0t] Controller: Received command - RW: %b, Addr: %h", $time, cmd_rw, cmd_addr);
                        if (cmd_rw_t'(cmd_rw) == CMD_READ) begin
                            rqueue_count <= rqueue_count + 1;
                        end else begin
                            wqueue_count <= wqueue_count + 1;
                        end
                        cmd_ready <= !queue_full(cmd_rw_t'(cmd_rw));
                    end

                    // Check if refresh is needed
                    if (refresh_counter >= REFRESH_INTERVAL) begin
                        $display("[%0t] Controller: Starting refresh cycle", $time);
                        refresh_counter <= '0;
                        current_state <= REFRESH;
                    end
                    // Process command if available
                    else if (!queue_empty(CMD_READ) || !queue_empty(CMD_WRITE)) begin

                    end
                end

                READ_DATA: begin
                    if (dram_ready) begin
                        cmd_rdata <= dram_rdata;
                        current_state <= IDLE;
                    end
                end

                WRITE_DATA: begin
                    if (dram_ready) begin
                        current_state <= IDLE;
                    end
                end

                REFRESH: begin
                    if (dram_ready) begin
                        current_state <= IDLE;
                    end
                end

                PRECHARGE: begin
                    if (dram_ready) begin
                        current_state <= IDLE;
                    end
                end

                ACTIVATE: begin
                    if (dram_ready) begin
                        current_state <= IDLE;
                    end
                end

                default: begin
                    current_state <= IDLE;
                end
            endcase
        end
    end
    

endmodule
