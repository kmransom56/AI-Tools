#!/usr/bin/env python3
"""
Python helper for port management
Can be imported by Python-based AI tools
"""

import subprocess
import json
import os
from pathlib import Path

def get_port_cli_path():
    """Get the path to port-cli.ps1"""
    # Try environment variable first
    cli_path = os.environ.get('PORT_CLI_PATH')
    if cli_path and os.path.exists(cli_path):
        return cli_path
    
    # Try relative to this script
    script_dir = Path(__file__).parent.parent
    cli_path = script_dir / 'port-cli.ps1'
    if cli_path.exists():
        return str(cli_path)
    
    # Try in AI-Tools directory
    home = Path.home()
    cli_path = home / 'AI-Tools' / 'port-cli.ps1'
    if cli_path.exists():
        return str(cli_path)
    
    return None

def get_port(application_name, preferred_port=0):
    """
    Get an available port for an application.
    
    Args:
        application_name: Name of the application
        preferred_port: Preferred port (0 to auto-assign)
    
    Returns:
        Port number or None if no port available
    """
    cli_path = get_port_cli_path()
    if not cli_path:
        raise FileNotFoundError("port-cli.ps1 not found")
    
    cmd = ['powershell', '-File', cli_path, 'get', '-ApplicationName', application_name]
    if preferred_port > 0:
        cmd.extend(['-Port', str(preferred_port)])
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=True
        )
        return int(result.stdout.strip())
    except subprocess.CalledProcessError:
        return None

def get_registered_port(application_name):
    """
    Get the registered port for an application.
    
    Args:
        application_name: Name of the application
    
    Returns:
        Port number or None if not registered
    """
    cli_path = get_port_cli_path()
    if not cli_path:
        raise FileNotFoundError("port-cli.ps1 not found")
    
    cmd = ['powershell', '-File', cli_path, 'check', '-ApplicationName', application_name]
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=True
        )
        return int(result.stdout.strip())
    except subprocess.CalledProcessError:
        return None

def read_registry():
    """
    Read the port registry directly from JSON.
    
    Returns:
        Dictionary with registry data or None
    """
    registry_path = os.environ.get(
        'PORT_REGISTRY_PATH',
        os.path.join(os.path.expanduser('~'), 'AI-Tools', 'port-registry.json')
    )
    
    if os.path.exists(registry_path):
        with open(registry_path, 'r') as f:
            return json.load(f)
    return None

if __name__ == '__main__':
    # Example usage
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python port-helper.py <application_name> [preferred_port]")
        sys.exit(1)
    
    app_name = sys.argv[1]
    preferred = int(sys.argv[2]) if len(sys.argv) > 2 else 0
    
    port = get_port(app_name, preferred)
    if port:
        print(f"Assigned port: {port}")
    else:
        print("No port available", file=sys.stderr)
        sys.exit(1)

