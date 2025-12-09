`timescale 1ns / 1ps

module test_compact_accel;
    reg clock;
    reg reset;
    reg [31:0] io_reg_addr;
    reg [31:0] io_reg_wdata;
    wire [31:0] io_reg_rdata;
    reg io_reg_wen;
    reg io_reg_ren;
    wire io_reg_valid;
    
    // 实例化加速器（需要从生成的Verilog中提取）
    // SimpleCompactAccel dut (
    //     .clock(clock),
    //     .reset(reset),
    //     .io_reg_addr(io_reg_addr),
    //     .io_reg_wdata(io_reg_wdata),
    //     .io_reg_rdata(io_reg_rdata),
    //     .io_reg_wen(io_reg_wen),
    //     .io_reg_ren(io_reg_ren),
    //     .io_reg_valid(io_reg_valid)
    // );
    
    // 时钟生成
    initial begin
        clock = 0;
        forever #5 clock = ~clock;
    end
    
    // 测试任务
    task write_reg(input [31:0] addr, input [31:0] data);
        begin
            @(posedge clock);
            io_reg_addr = addr;
            io_reg_wdata = data;
            io_reg_wen = 1;
            io_reg_ren = 0;
            @(posedge clock);
            io_reg_wen = 0;
        end
    endtask
    
    task read_reg(input [31:0] addr, output [31:0] data);
        begin
            @(posedge clock);
            io_reg_addr = addr;
            io_reg_ren = 1;
            io_reg_wen = 0;
            @(posedge clock);
            io_reg_ren = 0;
            data = io_reg_rdata;
        end
    endtask
    
    // 测试流程
    initial begin
        $display("=== CompactAccel Test ===");
        
        // 初始化
        reset = 1;
        io_reg_addr = 0;
        io_reg_wdata = 0;
        io_reg_wen = 0;
        io_reg_ren = 0;
        
        #20;
        reset = 0;
        #20;
        
        // 测试1: 2x2矩阵乘法
        $display("Test 1: 2x2 identity matrix");
        
        // 设置矩阵大小
        write_reg(32'h01C, 32'd2);
        
        // 写入矩阵A
        write_reg(32'h100, 32'd1);
        write_reg(32'h104, 32'd2);
        write_reg(32'h120, 32'd3);
        write_reg(32'h124, 32'd4);
        
        // 写入矩阵B (单位矩阵)
        write_reg(32'h300, 32'd1);
        write_reg(32'h304, 32'd0);
        write_reg(32'h320, 32'd0);
        write_reg(32'h324, 32'd1);
        
        // 启动计算
        write_reg(32'h000, 32'd1);
        
        // 等待完成
        #1000;
        
        $display("Test completed");
        $finish;
    end
    
    // 监控
    initial begin
        $dumpfile("compact_accel.vcd");
        $dumpvars(0, test_compact_accel);
    end
    
endmodule
