`timescale 1ns/1ps

module simple_tb;
    reg clock;
    reg reset;
    
    // 实例化设计
    ysyxSoCFull dut (
        .clock(clock),
        .reset(reset)
    );
    
    // 时钟生成
    initial begin
        clock = 0;
        forever #5 clock = ~clock;  // 100MHz
    end
    
    // 复位和测试
    initial begin
        $display("开始仿真...");
        reset = 1;
        #100;
        reset = 0;
        $display("复位释放");
        
        // 运行一段时间
        #10000;
        
        $display("仿真完成");
        $finish;
    end
    
    // 可选：生成波形
    initial begin
        $dumpfile("waves/post_syn.vcd");
        $dumpvars(0, simple_tb);
    end
endmodule
