# AI Development Toolkit

Complete AI development environment with Docker-based tools and IDE integrations.

## 🚀 Quick Start

```powershell
# Run the automated installer
.\AI-Toolkit-Auto.ps1

# Use the AI helper script
.\ai.ps1 help
```

## 📦 What's Included

### Docker Container (ai-toolkit)
- **Python 3.11** with comprehensive AI/ML stack
- **OpenAI API** client
- **Anthropic Claude** API client
- **Google Gemini** API client
- **PyTorch 2.4.0** (CPU version)
- **Transformers 4.44.0** (Hugging Face)
- **LangChain** with OpenAI/Anthropic integrations
- **shell-gpt** (sgpt) CLI
- **chatgpt-cli** for terminal interactions

### IDE Tools
- **VS Code** with Continue and GitHub Copilot extensions
- **Cursor IDE** with AI assistance
- **Void Editor** (optional)

## 🔧 Usage

### Quick Commands (Using ai.ps1 helper)

```powershell
# Interactive shell
.\ai.ps1 shell

# Python REPL
.\ai.ps1 python

# Shell-GPT
.\ai.ps1 sgpt "explain async/await in Python"

# Check status
.\ai.ps1 status

# View logs
.\ai.ps1 logs
```

### Direct Docker Commands

```powershell
# Run shell-gpt
docker exec -it ai-toolkit sgpt "your prompt here"

# Python script
docker exec -it ai-toolkit python myscript.py

# Interactive bash
docker exec -it ai-toolkit bash

# Test OpenAI
docker exec -it ai-toolkit python -c "import openai; print(openai.__version__)"
```

### Using the Workspace

Files in `C:\Users\<username>\AI-Tools\workspace\` are automatically mounted to `/app/workspace` in the container.

```powershell
# Create a Python script
New-Item -Path "$env:USERPROFILE\AI-Tools\workspace\test.py" -ItemType File

# Run it in the container
docker exec -it ai-toolkit python /app/workspace/test.py
```

## 🔑 API Keys

Set these environment variables before running the installer:

```powershell
$env:OPENAI_API_KEY = "sk-..."
$env:ANTHROPIC_API_KEY = "sk-ant-..."
$env:GEMINI_API_KEY = "..."
```

## 🐳 Docker Management

```powershell
# Start containers
cd $env:USERPROFILE\AI-Tools
docker-compose up -d

# Stop containers
docker-compose down

# Rebuild after changes
docker-compose build --no-cache
docker-compose up -d

# View all containers
docker ps
```

## 📚 Example Use Cases

### 1. Code Generation with OpenAI

```python
# Inside container: docker exec -it ai-toolkit python
import openai
import os

openai.api_key = os.getenv("OPENAI_API_KEY")

response = openai.chat.completions.create(
    model="gpt-4",
    messages=[{"role": "user", "content": "Write a Python function to sort a list"}]
)

print(response.choices[0].message.content)
```

### 2. Using Shell-GPT

```powershell
# Quick questions
docker exec -it ai-toolkit sgpt "what is Docker?"

# Code generation
docker exec -it ai-toolkit sgpt --code "create a FastAPI endpoint"

# Shell commands
docker exec -it ai-toolkit sgpt --shell "list all running processes"
```

### 3. Hugging Face Transformers

```python
from transformers import pipeline

# Sentiment analysis
classifier = pipeline("sentiment-analysis")
result = classifier("I love using AI tools!")
print(result)
```

## 🛠️ Troubleshooting

### Container not starting
```powershell
docker logs ai-toolkit
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### API key issues
```powershell
# Check if keys are set in container
docker exec ai-toolkit env | Select-String "API_KEY"
```

## 🎯 Next Steps

1. ✅ Set up API keys
2. ✅ Run `.\AI-Toolkit-Auto.ps1`
3. ✅ Test with `.\ai.ps1 status`
4. ✅ Try `.\ai.ps1 sgpt "Hello AI!"`
5. ✅ Explore VS Code with Continue extension
6. ✅ Build your first AI-powered project!
