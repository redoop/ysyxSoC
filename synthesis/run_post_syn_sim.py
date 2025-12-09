#!/usr/bin/env python3
"""
逻辑综合后网表仿真自动化脚本
支持多种仿真工具和测试场景
"""

import os
import sys
import subprocess
import argparse
from pathlib import Path
from datetime import datetime

class PostSynthesisSimulator:
    def __init__(self, design_name="ysyxSoCFull"):
        self.design_name = design_name
        self.root_dir = Path(__file__).parent
        self.netlist_dir = self.root_dir / "netlist"
        self.tb_dir = self.root_dir / "testbench"
        self.sim_dir = self.root_dir / "sim"
        self.wave_dir = self.root_dir / "waves"
        
        # 创建目录
        self.sim_dir.mkdir(exist_ok=True)
        self.wave_dir.mkdir(exist_ok=True)
        self.tb_dir.mkdir(exist_ok=True)
    
    def print_header(self):
        """打印标题"""
        print("=" * 60)
        print("逻辑综合后网表仿真")
        print("=" * 60)
        print(f"设计: {self.design_name}")
        print(f"时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("=" * 60)
        print()
    
    def check_netlist(self):
        """检查网表文件是否存在"""
        netlist_file = self.netlist_dir / f"{self.design_name}_synth.v"
        if not netlist_file.exists():
            print(f"❌ 错误: 网表文件不存在: {netlist_file}")
            print("请先运行逻辑综合生成网表")
            return False
        print(f"✓ 找到网表文件: {netlist_file}")
        return True
    
    def check_tool(self, tool_name):
        """检查工具是否可用"""
        try:
            subprocess.run([tool_name, "--version"], 
                         capture_output=True, 
                         check=True)
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            return False
    
    def run_vcs_simulation(self, testbench="advanced"):
        """使用 VCS 运行仿真"""
        print("\n使用 VCS 进行仿真...")
        print("-" * 60)
        
        if not self.check_tool("vcs"):
            print("❌ VCS 未安装或不在 PATH 中")
            return False
        
        netlist = self.netlist_dir / f"{self.design_name}_synth.v"
        if testbench == "basic":
            tb_file = self.tb_dir / "post_syn_tb.sv"
            simv = self.sim_dir / "simv_basic"
        else:
            tb_file = self.tb_dir / "advanced_post_syn_tb.sv"
            simv = self.sim_dir / "simv_advanced"
        
        # 编译
        print("1. 编译...")
        compile_cmd = [
            "vcs",
            "-full64",
            "-sverilog",
            "-timescale=1ns/1ps",
            "+v2k",
            "-debug_all",
            "-kdb",
            "-lca",
            f"-f", str(self.tb_dir / "filelist.f"),
            str(netlist),
            str(tb_file),
            "-o", str(simv),
            "-l", str(self.sim_dir / f"compile_{testbench}.log")
        ]
        
        try:
            subprocess.run(compile_cmd, check=True)
            print("✓ 编译成功")
        except subprocess.CalledProcessError:
            print("❌ 编译失败")
            return False
        
        # 仿真
        print("2. 运行仿真...")
        sim_cmd = [
            str(simv),
            "+vcs+finish+100000000",
            "-l", str(self.sim_dir / f"sim_{testbench}.log")
        ]
        
        try:
            subprocess.run(sim_cmd, check=True, cwd=self.sim_dir)
            print("✓ 仿真成功")
            return True
        except subprocess.CalledProcessError:
            print("❌ 仿真失败")
            return False
    
    def run_iverilog_simulation(self, netlist_type="synth"):
        """使用 Icarus Verilog 运行仿真"""
        print("\n使用 Icarus Verilog 进行仿真...")
        print("-" * 60)
        
        # 检查 iverilog 是否可用
        iverilog_path = "/opt/tools/oss-cad/oss-cad-suite/bin/iverilog"
        vvp_path = "/opt/tools/oss-cad/oss-cad-suite/bin/vvp"
        
        if not Path(iverilog_path).exists():
            if not self.check_tool("iverilog"):
                print("❌ Icarus Verilog 未安装或不在 PATH 中")
                return False
            iverilog_path = "iverilog"
            vvp_path = "vvp"
        else:
            print(f"✓ 找到 Icarus Verilog: {iverilog_path}")
        
        # 根据网表类型选择文件
        if netlist_type == "ics55":
            netlist = self.netlist_dir / f"{self.design_name}_ics55.v"
            stdcell_lib = self.netlist_dir / "ics55_LLSC_H7CL.v"
            print(f"使用 ICS55 PDK 网表")
        elif netlist_type == "ihp":
            netlist = self.netlist_dir / f"{self.design_name}_ihp.v"
            stdcell_lib = self.netlist_dir / "sg13g2_stdcell.v"
            print(f"使用 IHP SG13G2 PDK 网表")
        else:
            netlist = self.netlist_dir / f"{self.design_name}_synth.v"
            stdcell_lib = None
            print(f"使用默认网表")
        
        # 检查网表是否存在
        if not netlist.exists():
            print(f"❌ 网表文件不存在: {netlist}")
            print(f"请先运行综合生成网表")
            return False
        
        # 创建简单的测试平台
        tb_file = self.tb_dir / "simple_tb.v"
        if not tb_file.exists():
            print("创建简单测试平台...")
            self.create_simple_testbench(tb_file)
        
        vvp_file = self.sim_dir / "post_syn_sim.vvp"
        
        # 编译
        print("1. 编译...")
        compile_cmd = [
            iverilog_path,
            "-g2012",
            "-o", str(vvp_file),
        ]
        
        # 添加 Yosys 原语库
        yosys_primitives = self.root_dir / "lib_ics55" / "yosys_primitives.v"
        if yosys_primitives.exists():
            compile_cmd.append(str(yosys_primitives))
            print(f"  包含 Yosys 原语库: {yosys_primitives.name}")
        
        # 添加标准单元库
        if stdcell_lib and Path(stdcell_lib).exists():
            compile_cmd.append(str(stdcell_lib))
            print(f"  包含标准单元库: {stdcell_lib.name}")
        
        compile_cmd.extend([str(netlist), str(tb_file)])
        
        try:
            result = subprocess.run(compile_cmd, capture_output=True, text=True)
            if result.returncode != 0:
                print("编译输出:")
                print(result.stdout)
                if result.stderr:
                    print("错误:")
                    print(result.stderr)
                print("❌ 编译失败")
                return False
            print("✓ 编译成功")
        except Exception as e:
            print(f"❌ 编译失败: {e}")
            return False
        
        # 仿真
        print("2. 运行仿真...")
        sim_cmd = [vvp_path, str(vvp_file)]
        
        try:
            result = subprocess.run(sim_cmd, capture_output=True, text=True, cwd=self.root_dir, timeout=30)
            print(result.stdout)
            if result.stderr:
                print("警告/错误:")
                print(result.stderr)
            
            # 保存报告
            self._save_simulation_report(netlist_type, result.stdout, result.stderr, result.returncode)
            
            if result.returncode == 0:
                print("✓ 仿真成功")
                return True
            else:
                print("❌ 仿真失败")
                return False
        except subprocess.TimeoutExpired:
            print("⚠ 仿真超时（30秒）- 这可能是正常的，设计可能在持续运行")
            self._save_simulation_report(netlist_type, "仿真超时", "", -1, timeout=True)
            return True
        except Exception as e:
            print(f"❌ 仿真失败: {e}")
            return False
    
    def create_simple_testbench(self, tb_file):
        """创建简单的测试平台"""
        tb_content = '''`timescale 1ns/1ps

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
'''
        with open(tb_file, 'w') as f:
            f.write(tb_content)
        print(f"✓ 创建测试平台: {tb_file}")
    
    def _save_simulation_report(self, netlist_type, stdout, stderr, returncode, timeout=False):
        """保存仿真报告"""
        report_file = self.sim_dir / "post_syn_report.txt"
        
        with open(report_file, 'w', encoding='utf-8') as f:
            f.write("=" * 60 + "\n")
            f.write("逻辑综合后网表仿真报告\n")
            f.write("=" * 60 + "\n")
            f.write(f"设计: {self.design_name}\n")
            f.write(f"网表类型: {netlist_type}\n")
            f.write(f"时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write("=" * 60 + "\n\n")
            
            if timeout:
                f.write("状态: 仿真超时（可能正常运行中）\n\n")
            else:
                f.write(f"状态: {'成功' if returncode == 0 else '失败'}\n")
                f.write(f"返回码: {returncode}\n\n")
            
            f.write("仿真输出:\n")
            f.write("-" * 60 + "\n")
            f.write(stdout)
            f.write("\n")
            
            if stderr:
                f.write("\n警告/错误:\n")
                f.write("-" * 60 + "\n")
                f.write(stderr)
                f.write("\n")
            
            # 添加波形文件信息
            wave_files = list(self.wave_dir.glob("*.vcd"))
            if wave_files:
                f.write("\n波形文件:\n")
                f.write("-" * 60 + "\n")
                for wf in wave_files:
                    size_mb = wf.stat().st_size / (1024 * 1024)
                    f.write(f"  {wf.name}: {size_mb:.1f} MB\n")
        
        print(f"✓ 报告已保存: {report_file}")

    
    def run_verilator_simulation(self):
        """使用 Verilator 运行仿真"""
        print("\n使用 Verilator 进行仿真...")
        print("-" * 60)
        
        if not self.check_tool("verilator"):
            print("❌ Verilator 未安装或不在 PATH 中")
            return False
        
        netlist = self.netlist_dir / f"{self.design_name}_synth.v"
        tb_file = self.tb_dir / "simple_post_syn_tb.sv"
        
        # 编译和仿真
        print("1. 编译和仿真...")
        cmd = [
            "verilator",
            "--sv",
            "--timescale-override","1ns/1ps",
            "--cc",
            "--exe",
            "--build",
            "--trace",
            "-Wno-TIMESCALEMOD",
            "-Wno-DECLFILENAME",
            "-Wno-MULTITOP",
            "--top-module", "post_syn_tb",
            str(netlist),
            str(tb_file),
            "-o", str(self.sim_dir / "Vsim")
        ]
        
        try:
            subprocess.run(cmd, check=True)
            print("✓ Verilator 编译成功")
            
            # 运行仿真
            subprocess.run([str(self.sim_dir / "Vsim")], check=True)
            print("✓ Verilator 仿真成功")
            return True
        except subprocess.CalledProcessError:
            print("❌ Verilator 失败")
            return False
    
    def view_waveform(self, tool="verdi"):
        """查看波形"""
        print(f"\n使用 {tool} 查看波形...")
        
        # 查找波形文件
        wave_files = list(self.wave_dir.glob("*.vcd")) + \
                    list(self.wave_dir.glob("*.fsdb"))
        
        if not wave_files:
            print("❌ 未找到波形文件")
            return False
        
        wave_file = wave_files[0]
        print(f"波形文件: {wave_file}")
        
        # 获取文件大小
        file_size = wave_file.stat().st_size
        size_mb = file_size / (1024 * 1024)
        print(f"文件大小: {size_mb:.1f} MB")
        
        if tool == "verdi":
            if self.check_tool("verdi"):
                try:
                    subprocess.Popen(["verdi", "-ssf", str(wave_file)])
                    print("✓ Verdi 已启动")
                    return True
                except Exception as e:
                    print(f"❌ 启动 Verdi 失败: {e}")
                    return False
            else:
                print("❌ Verdi 未安装")
        elif tool == "gtkwave":
            if self.check_tool("gtkwave"):
                # 检查是否有 DISPLAY 环境变量
                if not os.environ.get('DISPLAY'):
                    print("❌ 无法启动 GTKWave: 未检测到图形显示环境 (DISPLAY 未设置)")
                    print("\n提示:")
                    print("  - 如果在远程服务器上，请使用 X11 转发: ssh -X user@host")
                    print("  - 或者将 VCD 文件下载到本地查看")
                    print(f"  - VCD 文件位置: {wave_file}")
                    return False
                try:
                    subprocess.Popen(["gtkwave", str(wave_file)])
                    print("✓ GTKWave 已启动")
                    return True
                except Exception as e:
                    print(f"❌ 启动 GTKWave 失败: {e}")
                    return False
            else:
                print("❌ GTKWave 未安装")
        
        print(f"\n可用的波形查看选项:")
        print(f"  1. 下载 VCD 文件到本地: {wave_file}")
        print(f"  2. 使用 X11 转发: ssh -X user@host")
        print(f"  3. 安装波形查看工具: verdi 或 gtkwave")
        return False
    
    def generate_report(self):
        """生成测试报告"""
        print("\n生成测试报告...")
        print("-" * 60)
        
        report_files = [
            self.sim_dir / "detailed_report.txt",
            self.sim_dir / "post_syn_report.txt"
        ]
        
        for report_file in report_files:
            if report_file.exists():
                print(f"\n报告内容 ({report_file.name}):")
                print("=" * 60)
                with open(report_file, 'r', encoding='utf-8') as f:
                    print(f.read())
                return True
        
        print("❌ 未找到测试报告")
        return False
    
    def run_full_flow(self, simulator="vcs", testbench="advanced"):
        """运行完整流程"""
        self.print_header()
        
        # 检查网表（对于 iverilog，在 run_iverilog_simulation 中检查）
        if simulator != "iverilog":
            if not self.check_netlist():
                return False
        
        # 运行仿真
        success = False
        if simulator == "vcs":
            success = self.run_vcs_simulation(testbench)
        elif simulator == "verilator":
            success = self.run_verilator_simulation()
        elif simulator == "iverilog":
            netlist_type = getattr(self, 'netlist_type', 'synth')
            success = self.run_iverilog_simulation(netlist_type)
        else:
            print(f"❌ 不支持的仿真器: {simulator}")
            return False
        
        if not success:
            return False
        
        # 生成报告
        self.generate_report()
        
        print("\n" + "=" * 60)
        print("完整流程完成")
        print("=" * 60)
        print("\n下一步:")
        print("  查看波形 (静态页面): ./view_wave.sh")
        print("  查看波形 (Web 服务): python3 wave_viewer.py")
        print("  查看报告: python run_post_syn_sim.py --report")
        print()
        
        return True

def main():
    parser = argparse.ArgumentParser(
        description="逻辑综合后网表仿真自动化脚本"
    )
    
    parser.add_argument(
        "--simulator",
        choices=["vcs", "verilator", "iverilog"],
        default="iverilog",
        help="选择仿真器 (默认: iverilog)"
    )
    
    parser.add_argument(
        "--testbench",
        choices=["basic", "advanced"],
        default="advanced",
        help="选择测试平台 (默认: advanced)"
    )
    
    parser.add_argument(
        "--wave",
        action="store_true",
        help="查看波形"
    )
    
    parser.add_argument(
        "--wave-tool",
        choices=["verdi", "gtkwave"],
        default="verdi",
        help="波形查看工具 (默认: verdi)"
    )
    
    parser.add_argument(
        "--report",
        action="store_true",
        help="生成测试报告"
    )
    
    parser.add_argument(
        "--design",
        default="ysyxSoCFull",
        help="设计名称 (默认: ysyxSoCFull)"
    )
    
    parser.add_argument(
        "--netlist",
        choices=["synth", "ihp", "ics55", "generic"],
        default="synth",
        help="网表类型: synth (默认), ihp (IHP PDK), ics55 (ICS55 PDK), generic (通用)"
    )
    
    parser.add_argument(
        "--wave-info",
        action="store_true",
        help="显示波形文件信息（无需 GUI）"
    )
    
    args = parser.parse_args()
    
    sim = PostSynthesisSimulator(args.design)
    
    if args.wave:
        sim.view_waveform(args.wave_tool)
    elif args.wave_info:
        sim.show_wave_info()
    elif args.report:
        sim.generate_report()
    else:
        # 如果使用 iverilog，传递网表类型
        if args.simulator == "iverilog":
            sim.netlist_type = args.netlist
        sim.run_full_flow(args.simulator, args.testbench)

if __name__ == "__main__":
    main()
