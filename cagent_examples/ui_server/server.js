// tiny Express UI endpoint that forwards JSON payloads to PowerShell Invoke-UIAgent
const express = require('express');
const bodyParser = require('body-parser');
const { spawn } = require('child_process');

const app = express();
app.use(bodyParser.json());

/**
 * POST /invoke
 * Expected payload:
 *   {
 *     "language": "python" | "typescript",
 *     "input": "User description of code to generate",
 *     "options": { ...optional... }
 *   }
 */
app.post('/invoke', (req, res) => {
  const { language, input, options } = req.body;
  if (!language || !input) {
    return res.status(400).json({ error: 'Missing required fields: language and input' });
  }

  const agentMap = {
    python: 'python_generator_agent.yaml',
    typescript: 'typescript_generator_agent.yaml',
  };
  const agentFile = agentMap[language.toLowerCase()];
  if (!agentFile) {
    return res.status(400).json({ error: `Unsupported language: ${language}` });
  }

  const payload = JSON.stringify({ agent: agentFile, input, options: options || {} });
  const psCommand = `powershell -NoProfile -Command "Import-Module \"${process.env.PSModulePath || 'C:\\Users\\Keith Ransom\\AI-Tools\\PortManager\\PortManager.psm1'}\"; Invoke-UIAgent -Payload '${payload.replace(/'/g, "''")}'"`;
  const child = spawn('cmd', ['/c', psCommand], { shell: true });
  let stdout = '';
  let stderr = '';
  child.stdout.on('data', data => (stdout += data.toString()));
  child.stderr.on('data', data => (stderr += data.toString()));
  child.on('close', code => {
    if (code === 0) {
      res.json({ success: true, result: stdout.trim() });
    } else {
      res.status(500).json({ success: false, error: stderr.trim() || 'Unknown error' });
    }
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`UI server listening on port ${PORT}`));
