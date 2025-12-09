#!/usr/bin/env python3
"""
VCD 波形文件网页查看器 - 支持可视化图表
"""

import http.server
import socketserver
import os
from pathlib import Path
import json
import re
from urllib.parse import parse_qs, urlparse

PORT = 8080
VCD_FILE = "waves/post_syn.vcd"

class VCDParser:
    """简单的 VCD 解析器"""
    def __init__(self, vcd_file, max_signals=20, max_time=1000):
        self.vcd_file = vcd_file
        self.max_signals = max_signals
        self.max_time = max_time
        self.signals = {}
        self.timescale = "1ns"
        
    def parse(self):
        """解析 VCD 文件"""
        with open(self.vcd_file, 'r', errors='ignore') as f:
            in_header = True
            current_time = 0
            signal_count = 0
            
            for line in f:
                line = line.strip()
                
                # 解析时间刻度
                if line.startswith('$timescale'):
                    self.timescale = next(f).strip()
                    continue
                
                # 解析变量定义
                if line.startswith('$var'):
                    if signal_count >= self.max_signals:
                        continue
                    parts = line.split()
                    if len(parts) >= 5:
                        var_type = parts[1]
                        size = parts[2]
                        identifier = parts[3]
                        name = parts[4]
                        
                        self.signals[identifier] = {
                            'name': name,
                            'type': var_type,
                            'size': size,
                            'values': []
                        }
                        signal_count += 1
                    continue
                
                # 结束头部
                if line.startswith('$enddefinitions'):
                    in_header = False
                    continue
                
                if in_header:
                    continue
                
                # 解析时间戳
                if line.startswith('#'):
                    current_time = int(line[1:])
                    if current_time > self.max_time:
                        break
                    continue
                
                # 解析信号值变化
                if line and not line.startswith('$'):
                    if line[0] in '01xzXZ':
                        value = line[0]
                        identifier = line[1:]
                    elif line[0] == 'b':
                        parts = line.split()
                        if len(parts) >= 2:
                            value = parts[0][1:]  # 去掉 'b'
                            identifier = parts[1]
                        else:
                            continue
                    else:
                        continue
                    
                    if identifier in self.signals:
                        self.signals[identifier]['values'].append({
                            'time': current_time,
                            'value': value
                        })
        
        return self.get_chart_data()
    
    def get_chart_data(self):
        """转换为图表数据格式"""
        chart_data = {
            'timescale': self.timescale,
            'signals': []
        }
        
        for identifier, signal in self.signals.items():
            if signal['values']:
                chart_data['signals'].append({
                    'name': signal['name'],
                    'type': signal['type'],
                    'size': signal['size'],
                    'values': signal['values'][:100]  # 限制每个信号的数据点
                })
        
        return chart_data

class WaveformHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)
        
        if parsed.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            self.wfile.write(self.get_html().encode())
        elif parsed.path == '/api/waveform':
            self.serve_waveform_data()
        elif parsed.path == '/vcd':
            self.serve_vcd()
        else:
            super().do_GET()
    
    def serve_waveform_data(self):
        """提供波形数据 API"""
        query = parse_qs(urlparse(self.path).query)
        max_signals = int(query.get('signals', [20])[0])
        max_time = int(query.get('time', [1000])[0])
        
        try:
            parser = VCDParser(VCD_FILE, max_signals, max_time)
            data = parser.parse()
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(data).encode())
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode())
    
    def serve_vcd(self):
        """提供 VCD 文件的前 10000 行"""
        vcd_path = Path(VCD_FILE)
        if not vcd_path.exists():
            self.send_error(404, "VCD file not found")
            return
        
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        
        with open(vcd_path, 'r', errors='ignore') as f:
            for i, line in enumerate(f):
                if i >= 10000:
                    self.wfile.write(b"\n... (truncated, file too large) ...\n")
                    break
                self.wfile.write(line.encode('utf-8', errors='ignore'))
    
    def get_html(self):
        vcd_path = Path(VCD_FILE)
        file_size = vcd_path.stat().st_size / (1024 * 1024) if vcd_path.exists() else 0
        
        return f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>VCD 波形查看器</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <style>
        body {{
            font-family: Arial, sans-serif;
            margin: 20px;
            background: #f5f5f5;
        }}
        .container {{
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }}
        h1 {{
            color: #333;
            border-bottom: 2px solid #4CAF50;
            padding-bottom: 10px;
        }}
        .info {{
            background: #e8f5e9;
            padding: 15px;
            border-radius: 4px;
            margin: 20px 0;
        }}
        .controls {{
            background: #f5f5f5;
            padding: 15px;
            border-radius: 4px;
            margin: 20px 0;
        }}
        .controls label {{
            margin-right: 10px;
            font-weight: bold;
        }}
        .controls input {{
            margin-right: 20px;
            padding: 5px;
            border: 1px solid #ccc;
            border-radius: 4px;
        }}
        .btn {{
            background: #4CAF50;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            margin: 5px;
        }}
        .btn:hover {{
            background: #45a049;
        }}
        .chart-container {{
            margin: 20px 0;
            background: white;
            padding: 20px;
            border-radius: 4px;
            border: 1px solid #ddd;
        }}
        .signal-list {{
            max-height: 400px;
            overflow-y: auto;
            background: #fafafa;
            padding: 10px;
            border-radius: 4px;
            margin: 10px 0;
        }}
        .signal-item {{
            padding: 8px;
            margin: 5px 0;
            background: white;
            border-left: 4px solid #4CAF50;
            border-radius: 2px;
        }}
        #loading {{
            text-align: center;
            padding: 20px;
            color: #666;
        }}
        .waveform-canvas {{
            background: #263238;
            border-radius: 4px;
            margin: 10px 0;
        }}
    </style>
</head>
<body>
    <div class="container">
        <h1>🌊 VCD 波形文件可视化查看器</h1>
        
        <div class="info">
            <div><strong>文件:</strong> {VCD_FILE}</div>
            <div><strong>大小:</strong> {file_size:.1f} MB</div>
            <div><strong>状态:</strong> {'✅ 文件存在' if vcd_path.exists() else '❌ 文件不存在'}</div>
        </div>
        
        <div class="controls">
            <label>信号数量:</label>
            <input type="number" id="maxSignals" value="10" min="1" max="50">
            
            <label>时间范围:</label>
            <input type="number" id="maxTime" value="1000" min="100" max="100000">
            
            <button class="btn" onclick="loadWaveform()">📊 加载波形图</button>
            <button class="btn" onclick="loadSignalList()">📋 显示信号列表</button>
            <a class="btn" href="/vcd" download="post_syn.vcd">💾 下载 VCD</a>
        </div>
        
        <div id="loading" style="display:none;">⏳ 加载中...</div>
        
        <div id="signalList" class="signal-list" style="display:none;"></div>
        
        <div id="charts"></div>
        
        <div style="margin-top: 20px; padding: 15px; background: #f0f0f0; border-radius: 4px;">
            <h3>📖 使用说明</h3>
            <ul>
                <li><strong>信号数量:</strong> 控制显示多少个信号（建议 5-20 个）</li>
                <li><strong>时间范围:</strong> 控制显示的时间跨度（单位取决于 VCD 文件）</li>
                <li><strong>加载波形图:</strong> 生成可视化波形图表</li>
                <li><strong>显示信号列表:</strong> 查看所有解析的信号信息</li>
            </ul>
            
            <h3>⚠️ 注意事项</h3>
            <ul>
                <li>VCD 文件较大时，建议减少信号数量和时间范围</li>
                <li>首次加载可能需要几秒钟</li>
                <li>如需查看完整波形，请下载 VCD 文件使用 GTKWave</li>
            </ul>
        </div>
    </div>
    
    <script>
        let chartInstances = [];
        
        function loadWaveform() {{
            const maxSignals = document.getElementById('maxSignals').value;
            const maxTime = document.getElementById('maxTime').value;
            const loading = document.getElementById('loading');
            const charts = document.getElementById('charts');
            
            loading.style.display = 'block';
            charts.innerHTML = '';
            
            // 清除旧图表
            chartInstances.forEach(chart => chart.destroy());
            chartInstances = [];
            
            fetch(`/api/waveform?signals=${{maxSignals}}&time=${{maxTime}}`)
                .then(response => response.json())
                .then(data => {{
                    loading.style.display = 'none';
                    
                    if (data.error) {{
                        charts.innerHTML = `<div style="color:red;">错误: ${{data.error}}</div>`;
                        return;
                    }}
                    
                    if (data.signals.length === 0) {{
                        charts.innerHTML = '<div>未找到信号数据</div>';
                        return;
                    }}
                    
                    // 为每个信号创建图表
                    data.signals.forEach((signal, index) => {{
                        createSignalChart(signal, index);
                    }});
                }})
                .catch(error => {{
                    loading.style.display = 'none';
                    charts.innerHTML = `<div style="color:red;">加载失败: ${{error}}</div>`;
                }});
        }}
        
        function createSignalChart(signal, index) {{
            const charts = document.getElementById('charts');
            
            const container = document.createElement('div');
            container.className = 'chart-container';
            
            const title = document.createElement('h3');
            title.textContent = `${{signal.name}} (${{signal.type}}, ${{signal.size}} bit)`;
            container.appendChild(title);
            
            const canvas = document.createElement('canvas');
            canvas.id = `chart-${{index}}`;
            canvas.className = 'waveform-canvas';
            container.appendChild(canvas);
            
            charts.appendChild(container);
            
            // 准备数据
            const times = signal.values.map(v => v.time);
            const values = signal.values.map(v => {{
                if (v.value === '0') return 0;
                if (v.value === '1') return 1;
                if (v.value.startsWith('0') || v.value.startsWith('1')) {{
                    return parseInt(v.value, 2) || 0;
                }}
                return 0;
            }});
            
            // 创建图表
            const ctx = canvas.getContext('2d');
            const chart = new Chart(ctx, {{
                type: 'line',
                data: {{
                    labels: times,
                    datasets: [{{
                        label: signal.name,
                        data: values,
                        borderColor: `hsl(${{index * 137.5}}, 70%, 50%)`,
                        backgroundColor: `hsla(${{index * 137.5}}, 70%, 50%, 0.1)`,
                        stepped: true,
                        borderWidth: 2,
                        pointRadius: 2
                    }}]
                }},
                options: {{
                    responsive: true,
                    maintainAspectRatio: true,
                    aspectRatio: 4,
                    scales: {{
                        x: {{
                            title: {{
                                display: true,
                                text: 'Time'
                            }}
                        }},
                        y: {{
                            title: {{
                                display: true,
                                text: 'Value'
                            }},
                            beginAtZero: true
                        }}
                    }},
                    plugins: {{
                        legend: {{
                            display: false
                        }}
                    }}
                }}
            }});
            
            chartInstances.push(chart);
        }}
        
        function loadSignalList() {{
            const maxSignals = document.getElementById('maxSignals').value;
            const maxTime = document.getElementById('maxTime').value;
            const loading = document.getElementById('loading');
            const signalList = document.getElementById('signalList');
            
            loading.style.display = 'block';
            signalList.style.display = 'none';
            
            fetch(`/api/waveform?signals=${{maxSignals}}&time=${{maxTime}}`)
                .then(response => response.json())
                .then(data => {{
                    loading.style.display = 'none';
                    signalList.style.display = 'block';
                    
                    if (data.error) {{
                        signalList.innerHTML = `<div style="color:red;">错误: ${{data.error}}</div>`;
                        return;
                    }}
                    
                    let html = `<h3>信号列表 (共 ${{data.signals.length}} 个)</h3>`;
                    html += `<div><strong>时间刻度:</strong> ${{data.timescale}}</div><br>`;
                    
                    data.signals.forEach((signal, i) => {{
                        html += `
                            <div class="signal-item">
                                <strong>${{i+1}}. ${{signal.name}}</strong><br>
                                类型: ${{signal.type}} | 位宽: ${{signal.size}} | 数据点: ${{signal.values.length}}
                            </div>
                        `;
                    }});
                    
                    signalList.innerHTML = html;
                }})
                .catch(error => {{
                    loading.style.display = 'none';
                    signalList.innerHTML = `<div style="color:red;">加载失败: ${{error}}</div>`;
                }});
        }}
    </script>
</body>
</html>"""

def main():
    os.chdir(Path(__file__).parent)
    
    vcd_path = Path(VCD_FILE)
    if not vcd_path.exists():
        print(f"❌ 错误: VCD 文件不存在: {vcd_path.absolute()}")
        print("\n请先运行仿真生成波形文件:")
        print("  python run_post_syn_sim.py --simulator iverilog --netlist ics55")
        return
    
    file_size = vcd_path.stat().st_size / (1024 * 1024)
    
    # 尝试多个端口
    ports = [PORT, 8081, 8082, 8083, 8888, 9000]
    httpd = None
    
    for port in ports:
        try:
            socketserver.TCPServer.allow_reuse_address = True
            httpd = socketserver.TCPServer(("", port), WaveformHandler)
            print("=" * 60)
            print("VCD 波形文件可视化查看器")
            print("=" * 60)
            print(f"文件: {VCD_FILE}")
            print(f"大小: {file_size:.1f} MB")
            print(f"端口: {port}")
            print("=" * 60)
            print(f"\n🌐 在浏览器中打开: http://localhost:{port}")
            print(f"   或从其他机器访问: http://<服务器IP>:{port}")
            print("\n按 Ctrl+C 停止服务器\n")
            break
        except OSError:
            if port == ports[-1]:
                print(f"❌ 错误: 所有端口都被占用 {ports}")
                return
            continue
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n\n服务器已停止")
    finally:
        httpd.server_close()

if __name__ == "__main__":
    main()
