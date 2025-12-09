`timescale 1ns/1ps

module tb_hello;
    reg clock;
    reg reset;
    
    // 实例化 SoC
    ysyxSoCFull u_soc (
        .clock(clock),
        .reset(reset)
    );
    
    // 时钟生成 - 10MHz (100ns 周期)
    initial begin
        clock = 0;
        forever #50 clock = ~clock;
    end
    
    // 测试流程
    initial begin
        $display("========================================");
        $display("开始 ysyxSoC Hello 测试");
        $display("时间: %t", $time);
        $display("========================================");
        
        // 复位
        reset = 1;
        #200;
        reset = 0;
        $display("[%t] 复位释放", $time);
        
        // 运行足够长的时间让程序执行
        #1000000;  // 1ms
        
        $display("========================================");
        $display("测试完成");
        $display("时间: %t", $time);
        $display("========================================");
        $finish;
    end
    
    // 生成波形文件
    initial begin
        $dumpfile("hello_test.vcd");
        $dumpvars(0, tb_hello);
    end
    
    // 超时保护
    initial begin
        #10000000;  // 10ms 超时
        $display("❌ 测试超时!");
        $finish;
    end
endmodule
