#!/usr/bin/env node
/**
 * Node.js helper for port management
 * Can be imported by Node.js-based AI tools
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

function getPortCliPath() {
    // Try environment variable first
    let cliPath = process.env.PORT_CLI_PATH;
    if (cliPath && fs.existsSync(cliPath)) {
        return cliPath;
    }
    
    // Try relative to this script
    const scriptDir = __dirname;
    cliPath = path.join(scriptDir, '..', 'port-cli.ps1');
    if (fs.existsSync(cliPath)) {
        return cliPath;
    }
    
    // Try in AI-Tools directory
    const home = os.homedir();
    cliPath = path.join(home, 'AI-Tools', 'port-cli.ps1');
    if (fs.existsSync(cliPath)) {
        return cliPath;
    }
    
    return null;
}

function getPort(applicationName, preferredPort = 0) {
    /**
     * Get an available port for an application.
     * 
     * @param {string} applicationName - Name of the application
     * @param {number} preferredPort - Preferred port (0 to auto-assign)
     * @returns {number|null} Port number or null if no port available
     */
    const cliPath = getPortCliPath();
    if (!cliPath) {
        throw new Error('port-cli.ps1 not found');
    }
    
    let cmd = `powershell -File "${cliPath}" get -ApplicationName "${applicationName}"`;
    if (preferredPort > 0) {
        cmd += ` -Port ${preferredPort}`;
    }
    
    try {
        const result = execSync(cmd, { encoding: 'utf-8' });
        return parseInt(result.trim());
    } catch (error) {
        return null;
    }
}

function getRegisteredPort(applicationName) {
    /**
     * Get the registered port for an application.
     * 
     * @param {string} applicationName - Name of the application
     * @returns {number|null} Port number or null if not registered
     */
    const cliPath = getPortCliPath();
    if (!cliPath) {
        throw new Error('port-cli.ps1 not found');
    }
    
    const cmd = `powershell -File "${cliPath}" check -ApplicationName "${applicationName}"`;
    
    try {
        const result = execSync(cmd, { encoding: 'utf-8' });
        return parseInt(result.trim());
    } catch (error) {
        return null;
    }
}

function readRegistry() {
    /**
     * Read the port registry directly from JSON.
     * 
     * @returns {Object|null} Registry data or null
     */
    const registryPath = process.env.PORT_REGISTRY_PATH || 
        path.join(os.homedir(), 'AI-Tools', 'port-registry.json');
    
    if (fs.existsSync(registryPath)) {
        return JSON.parse(fs.readFileSync(registryPath, 'utf-8'));
    }
    return null;
}

// Export for use as module
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        getPort,
        getRegisteredPort,
        readRegistry
    };
}

// CLI usage
if (require.main === module) {
    const args = process.argv.slice(2);
    
    if (args.length < 1) {
        console.error('Usage: node port-helper.js <application_name> [preferred_port]');
        process.exit(1);
    }
    
    const appName = args[0];
    const preferred = args[1] ? parseInt(args[1]) : 0;
    
    const port = getPort(appName, preferred);
    if (port) {
        console.log(`Assigned port: ${port}`);
    } else {
        console.error('No port available');
        process.exit(1);
    }
}

