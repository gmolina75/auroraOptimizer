#!/usr/bin/env python3
"""
Aurora Optimizer - API REST
"""

from flask import Flask, jsonify, request
import subprocess
import json
import os
import platform
import psutil
from datetime import datetime

app = Flask(__name__)

PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

@app.route('/health', methods=['GET'])
def health():
    """Endpoint de salud"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'version': '1.0.0'
    })

@app.route('/status', methods=['GET'])
def status():
    """Estado del sistema"""
    return jsonify({
        'hostname': platform.node(),
        'os': platform.system(),
        'os_version': platform.version(),
        'cpu_percent': psutil.cpu_percent(interval=1),
        'memory': {
            'total': psutil.virtual_memory().total,
            'available': psutil.virtual_memory().available,
            'percent': psutil.virtual_memory().percent
        },
        'disk': {
            'total': psutil.disk_usage('/').total,
            'used': psutil.disk_usage('/').used,
            'free': psutil.disk_usage('/').free,
            'percent': psutil.disk_usage('/').percent
        },
        'boot_time': datetime.fromtimestamp(psutil.boot_time()).isoformat(),
        'timestamp': datetime.now().isoformat()
    })

@app.route('/optimize', methods=['POST'])
def optimize():
    """Ejecutar optimización"""
    os_type = platform.system().lower()
    
    if os_type == 'linux':
        script = os.path.join(PROJECT_DIR, 'scripts', 'linux.sh')
    elif os_type == 'darwin':
        script = os.path.join(PROJECT_DIR, 'scripts', 'macos.sh')
    else:
        return jsonify({'error': 'Sistema operativo no soportado'}), 400
    
    try:
        result = subprocess.run(['bash', script], capture_output=True, text=True, timeout=300)
        return jsonify({
            'success': result.returncode == 0,
            'output': result.stdout,
            'errors': result.stderr
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/stats', methods=['GET'])
def stats():
    """Estadísticas históricas"""
    stats_file = os.path.join(PROJECT_DIR, 'logs', 'stats.json')
    
    if os.path.exists(stats_file):
        with open(stats_file, 'r') as f:
            return jsonify(json.load(f))
    
    return jsonify({'error': 'No hay estadísticas disponibles'})

@app.route('/config', methods=['GET', 'POST'])
def config():
    """Obtener o actualizar configuración"""
    config_file = os.path.join(PROJECT_DIR, 'config', 'aurora.conf')
    
    if request.method == 'GET':
        if os.path.exists(config_file):
            with open(config_file, 'r') as f:
                return jsonify({'config': f.read()})
        return jsonify({'error': 'Archivo de configuración no encontrado'}), 404
    
    elif request.method == 'POST':
        data = request.get_json()
        if not data or 'config' not in data:
            return jsonify({'error': 'Datos inválidos'}), 400
        
        with open(config_file, 'w') as f:
            f.write(data['config'])
        
        return jsonify({'success': True, 'message': 'Configuración actualizada'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
