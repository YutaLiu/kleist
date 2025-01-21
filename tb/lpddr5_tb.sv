module lpddr5_tb;
    import lpddr5_params::*;

    // general parameters
    localparam CHANNELS = 2;
    localparam BURST_LENGTH = 16;
    localparam DATA_BITS = 32;
    
    // clock and reset
    logic clk;
    logic rst_n;
    
    // controller interface signals
    logic                    cmd_valid;
    logic                    cmd_rw;
    logic [PRIORITY_WIDTH-1:0] cmd_priority;
    logic [ADDR_WIDTH-1:0]   cmd_addr;
    logic [CHANNELS-1:0][DATA_BITS-1:0][BURST_LENGTH-1:0] cmd_wdata;
    logic [CHANNELS-1:0][DATA_BITS-1:0][BURST_LENGTH-1:0] cmd_rdata;
    logic                    cmd_ready;
    
    // DRAM model interface signals
    dram_cmd_t              dram_cmd;
    logic [ADDR_WIDTH-1:0]  dram_addr;
    logic [CHANNELS-1:0][DATA_BITS-1:0][BURST_LENGTH-1:0] dram_wdata;
    logic [CHANNELS-1:0][DATA_BITS-1:0][BURST_LENGTH-1:0] dram_rdata;
    logic                   dram_ready;

    // clock generation
    initial begin
        clk = 0;
        forever begin
            /* verilator lint_off STMTDLY */
            #5 clk = ~clk;
            /* verilator lint_on STMTDLY */
        end
    end

    // Instantiate controller
    lpddr5_controller u_controller (
        .clk(clk),
        .rst_n(rst_n),
        .cmd_valid(cmd_valid),
        .cmd_rw(cmd_rw),
        .cmd_priority(cmd_priority),
        .cmd_addr(cmd_addr),
        .cmd_wdata(cmd_wdata),
        .cmd_rdata(cmd_rdata),
        .cmd_ready(cmd_ready),
        .dram_cmd(dram_cmd),
        .dram_addr(dram_addr),
        .dram_wdata(dram_wdata),
        .dram_rdata(dram_rdata),
        .dram_ready(dram_ready)
    );

    // Instantiate DRAM model
    lpddr5_model u_dram (
        .clk(clk),
        .rst_n(rst_n),
        .dram_cmd(dram_cmd),
        .dram_addr(dram_addr),
        .dram_wdata(dram_wdata),
        .dram_rdata(dram_rdata),
        .dram_ready(dram_ready)
    );

    // Test stimulus
    initial begin
        $display("[%0t] Starting simulation...", $time);
        // Initialize signals
        rst_n = 1;
        cmd_valid = 0;
        cmd_rw = 0;
        cmd_priority = 0;
        cmd_addr = '0;
        cmd_wdata = '0;

        // Apply reset
        $display("[%0t] Asserting reset...", $time);
        /* verilator lint_off STMTDLY */
        #10 rst_n = 0;
        #10 rst_n = 1;
        /* verilator lint_on STMTDLY */
        $display("[%0t] Reset released", $time);

        // Write test
        $display("[%0t] Starting write test...", $time);
        @(posedge clk);
        cmd_valid = 1;
        cmd_rw = 1;  // Write operation
        cmd_addr = 32'h1000;
        cmd_wdata[0][0][0] = 32'hdeadbeef;
        /* verilator lint_off STMTDLY */
        #1;  // Wait for command to be registered
        /* verilator lint_on STMTDLY */
        
        while (!cmd_ready) begin
            @(posedge clk);
        end
        cmd_valid = 0;
        $display("[%0t] Write command accepted", $time);

        // Wait for write to complete
        while (!dram_ready) begin
            @(posedge clk);
        end
        $display("[%0t] Write completed", $time);

        // Read test
        $display("[%0t] Starting read test...", $time);
        @(posedge clk);
        cmd_valid = 1;
        cmd_rw = 0;  // Read operation
        cmd_addr = 32'h1000;
        /* verilator lint_off STMTDLY */
        #1;  // Wait for command to be registered
        /* verilator lint_on STMTDLY */
        
        while (!cmd_ready) begin
            @(posedge clk);
        end
        cmd_valid = 0;
        $display("[%0t] Read command accepted", $time);

        // Wait for read to complete
        while (!dram_ready) begin
            @(posedge clk);
        end
        $display("[%0t] Read completed", $time);

        // Check read data
        if (cmd_rdata[0][0][0] === 32'hdeadbeef) begin
            $display("[%0t] TB: Read data matches written data", $time);
        end else begin
            $display("[%0t] TB: Read data mismatch. Expected: %h, Got: %h", 
                    $time, 32'hdeadbeef, cmd_rdata[0][0][0]);
        end

        // End simulation
        /* verilator lint_off STMTDLY */
        #100 $finish;
        /* verilator lint_on STMTDLY */
    end

endmodule
