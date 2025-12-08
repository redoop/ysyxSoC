module ysyx_00000001 (
    input clock,
    input reset,
    input io_interrupt,
    
    // AXI4 Master
    input io_master_awready,
    output io_master_awvalid,
    output [3:0] io_master_awid,
    output [31:0] io_master_awaddr,
    output [7:0] io_master_awlen,
    output [2:0] io_master_awsize,
    output [1:0] io_master_awburst,
    output io_master_awlock,
    output [3:0] io_master_awcache,
    output [2:0] io_master_awprot,
    output [3:0] io_master_awqos,
    
    input io_master_wready,
    output io_master_wvalid,
    output [31:0] io_master_wdata,
    output [3:0] io_master_wstrb,
    output io_master_wlast,
    
    output io_master_bready,
    input io_master_bvalid,
    input [3:0] io_master_bid,
    input [1:0] io_master_bresp,
    
    input io_master_arready,
    output io_master_arvalid,
    output [3:0] io_master_arid,
    output [31:0] io_master_araddr,
    output [7:0] io_master_arlen,
    output [2:0] io_master_arsize,
    output [1:0] io_master_arburst,
    output io_master_arlock,
    output [3:0] io_master_arcache,
    output [2:0] io_master_arprot,
    output [3:0] io_master_arqos,
    
    output io_master_rready,
    input io_master_rvalid,
    input [3:0] io_master_rid,
    input [31:0] io_master_rdata,
    input [1:0] io_master_rresp,
    input io_master_rlast,
    
    // AXI4 Slave (unused)
    output io_slave_awready,
    input io_slave_awvalid,
    input [3:0] io_slave_awid,
    input [31:0] io_slave_awaddr,
    input [7:0] io_slave_awlen,
    input [2:0] io_slave_awsize,
    input [1:0] io_slave_awburst,
    input io_slave_awlock,
    input [3:0] io_slave_awcache,
    input [2:0] io_slave_awprot,
    input [3:0] io_slave_awqos,
    
    output io_slave_wready,
    input io_slave_wvalid,
    input [31:0] io_slave_wdata,
    input [3:0] io_slave_wstrb,
    input io_slave_wlast,
    
    input io_slave_bready,
    output io_slave_bvalid,
    output [3:0] io_slave_bid,
    output [1:0] io_slave_bresp,
    
    output io_slave_arready,
    input io_slave_arvalid,
    input [3:0] io_slave_arid,
    input [31:0] io_slave_araddr,
    input [7:0] io_slave_arlen,
    input [2:0] io_slave_arsize,
    input [1:0] io_slave_arburst,
    input io_slave_arlock,
    input [3:0] io_slave_arcache,
    input [2:0] io_slave_arprot,
    input [3:0] io_slave_arqos,
    
    input io_slave_rready,
    output io_slave_rvalid,
    output [3:0] io_slave_rid,
    output [31:0] io_slave_rdata,
    output [1:0] io_slave_rresp,
    output io_slave_rlast
);

    // PicoRV32 signals
    wire        mem_valid;
    wire        mem_instr;
    reg         mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0]  mem_wstrb;
    reg  [31:0] mem_rdata;
    
    // State machine
    localparam IDLE = 2'd0, READ = 2'd1, WRITE = 2'd2, RESP = 2'd3;
    reg [1:0] state;
    
    // PicoRV32 instance
    picorv32 #(
        .ENABLE_MUL(1),
        .ENABLE_DIV(1),
        .COMPRESSED_ISA(1)
    ) cpu (
        .clk(clock),
        .resetn(~reset),
        .trap(),
        .mem_valid(mem_valid),
        .mem_instr(mem_instr),
        .mem_ready(mem_ready),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata)
    );
    
    // AXI4 Master - Read Address Channel
    assign io_master_arvalid = (state == IDLE) && mem_valid && (mem_wstrb == 4'b0000);
    assign io_master_araddr = mem_addr;
    assign io_master_arid = 4'b0;
    assign io_master_arlen = 8'b0;
    assign io_master_arsize = 3'b010; // 4 bytes
    assign io_master_arburst = 2'b01; // INCR
    assign io_master_arlock = 1'b0;
    assign io_master_arcache = 4'b0;
    assign io_master_arprot = 3'b0;
    assign io_master_arqos = 4'b0;
    
    // AXI4 Master - Read Data Channel
    assign io_master_rready = (state == READ);
    
    // AXI4 Master - Write Address Channel
    assign io_master_awvalid = (state == IDLE) && mem_valid && (mem_wstrb != 4'b0000);
    assign io_master_awaddr = mem_addr;
    assign io_master_awid = 4'b0;
    assign io_master_awlen = 8'b0;
    assign io_master_awsize = 3'b010;
    assign io_master_awburst = 2'b01;
    assign io_master_awlock = 1'b0;
    assign io_master_awcache = 4'b0;
    assign io_master_awprot = 3'b0;
    assign io_master_awqos = 4'b0;
    
    // AXI4 Master - Write Data Channel
    assign io_master_wvalid = (state == WRITE);
    assign io_master_wdata = mem_wdata;
    assign io_master_wstrb = mem_wstrb;
    assign io_master_wlast = 1'b1;
    
    // AXI4 Master - Write Response Channel
    assign io_master_bready = (state == RESP);
    
    // AXI4 Slave - Tie off (unused)
    assign io_slave_awready = 1'b0;
    assign io_slave_wready = 1'b0;
    assign io_slave_bvalid = 1'b0;
    assign io_slave_bid = 4'b0;
    assign io_slave_bresp = 2'b0;
    assign io_slave_arready = 1'b0;
    assign io_slave_rvalid = 1'b0;
    assign io_slave_rid = 4'b0;
    assign io_slave_rdata = 32'b0;
    assign io_slave_rresp = 2'b0;
    assign io_slave_rlast = 1'b0;
    
    // State machine
    always @(posedge clock) begin
        if (reset) begin
            state <= IDLE;
            mem_ready <= 1'b0;
            mem_rdata <= 32'b0;
        end else begin
            mem_ready <= 1'b0;
            case (state)
                IDLE: begin
                    if (mem_valid) begin
                        if (mem_wstrb == 4'b0000) begin
                            // Read
                            if (io_master_arready) begin
                                state <= READ;
                            end
                        end else begin
                            // Write
                            if (io_master_awready) begin
                                state <= WRITE;
                            end
                        end
                    end
                end
                
                READ: begin
                    if (io_master_rvalid) begin
                        mem_rdata <= io_master_rdata;
                        mem_ready <= 1'b1;
                        state <= IDLE;
                    end
                end
                
                WRITE: begin
                    if (io_master_wready) begin
                        state <= RESP;
                    end
                end
                
                RESP: begin
                    if (io_master_bvalid) begin
                        mem_ready <= 1'b1;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule
