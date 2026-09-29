#!/usr/bin/env python3
from flask import Flask, jsonify, request, send_file
import subprocess, json, os, platform, psutil
from datetime import datetime

app = Flask(__name__)
PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat(), 'version': '1.0.0'})

@app.route('/status')
def status():
    return jsonify({
        'hostname': platform.node(),
        'os': platform.system(),
        'cpu_percent': psutil.cpu_percent(interval=1),
        'memory': {'total': psutil.virtual_memory().total, 'available': psutil.virtual_memory().available, 'percent': psutil.virtual_memory().percent},
        'disk': {'total': psutil.disk_usage('/').total, 'used': psutil.disk_usage('/').used, 'free': psutil.disk_usage('/').free, 'percent': psutil.disk_usage('/').percent},
        'boot_time': datetime.fromtimestamp(psutil.boot_time()).isoformat(),
        'timestamp': datetime.now().isoformat()
    })

@app.route('/optimize', methods=['POST'])
def optimize():
    result = subprocess.run(['bash', os.path.join(PROJECT_DIR, 'scripts', 'linux.sh')], capture_output=True, text=True, timeout=300)
    return jsonify({'success': result.returncode == 0, 'output': result.stdout, 'errors': result.stderr})

@app.route('/stats')
def stats():
    stats_file = os.path.join(PROJECT_DIR, 'logs', 'stats.json')
    if os.path.exists(stats_file):
        with open(stats_file, 'r') as f:
            return jsonify(json.load(f))
    return jsonify({'error': 'No stats available'})

@app.route('/')
def dashboard():
    return send_file(os.path.join(PROJECT_DIR, 'dashboard', 'index.html'))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=False)
