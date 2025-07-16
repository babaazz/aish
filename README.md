# 🤖 aish - AI Shell Assistant

A production-quality, local-only CLI tool that converts natural language into shell commands and executes them safely with real-time streaming output.

## ✨ Features

- **🧠 Intelligent Planning**: Uses LangGraph to break down complex tasks into steps
- **🔄 Real-time Streaming**: Live stdout/stderr output during command execution
- **🔐 Safety First**: Built-in command validation and user confirmation
- **📝 Complete History**: All commands and outputs logged to `~/.aish/history.log`
- **🎯 Multiple Backends**: OpenAI GPT-4 or local Ollama models
- **⚡ Fast & Responsive**: Optimized for quick command generation and execution
- **🛡️ Secure**: Local-only processing with no data sent to external services (except LLM API)

## 🚀 Quick Start

### Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/your-repo/aish.git
   cd aish
   ```

2. **Run the installation script:**

   ```bash
   ./install.sh
   ```

3. **Configure your AI backend:**

   ```bash
   cp .env.example .env
   # Edit .env with your preferred settings
   ```

4. **For OpenAI (recommended):**

   ```bash
   export OPENAI_API_KEY='your-api-key-here'
   ```

5. **For Ollama (local):**

   ```bash
   # Install Ollama from https://ollama.ai
   ollama pull llama2
   export AISH_BACKEND=ollama
   ```

6. **Restart your shell and test:**
   ```bash
   source ~/.zshrc  # or ~/.bashrc
   aish --help
   aish "show current directory"
   ```

## 🎯 Usage

### Interactive Mode

```bash
aish
🤖 aish > install nginx and start the service
🤖 aish > show me all running processes
🤖 aish > create a backup of my home directory
```

### Single Command Mode

```bash
aish "install docker and start the service"
aish "show disk usage for all mounted filesystems"
aish "find all Python files in the current directory"
```

### Command Options

```bash
aish --help        # Show help
aish --version     # Show version
aish --history     # Show command history
```

## 🔧 Configuration

### Environment Variables

| Variable           | Default                  | Description                                  |
| ------------------ | ------------------------ | -------------------------------------------- |
| `AISH_BACKEND`     | `openai`                 | AI backend: `openai` or `ollama`             |
| `AISH_AGENT_MODE`  | `langgraph`              | Agent mode: `langgraph` or `basic`           |
| `OPENAI_API_KEY`   | -                        | OpenAI API key (required for OpenAI backend) |
| `OPENAI_MODEL`     | `gpt-4`                  | OpenAI model to use                          |
| `OLLAMA_MODEL`     | `llama2`                 | Ollama model to use                          |
| `OLLAMA_BASE_URL`  | `http://localhost:11434` | Ollama server URL                            |
| `AISH_MAX_RETRIES` | `3`                      | Maximum retry attempts                       |
| `AISH_TIMEOUT`     | `30`                     | Request timeout in seconds                   |
| `AISH_DEBUG`       | `false`                  | Enable debug output                          |

### Configuration File

Create a `.env` file in the aish directory:

```bash
# Backend Configuration
AISH_BACKEND=openai
AISH_AGENT_MODE=langgraph

# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_MODEL=gpt-4

# Ollama Configuration (if using Ollama)
OLLAMA_MODEL=llama2
OLLAMA_BASE_URL=http://localhost:11434

# Agent Configuration
AISH_MAX_RETRIES=3
AISH_TIMEOUT=30
AISH_DEBUG=false
```

## 🧠 AI Backend Options

### OpenAI (Recommended)

**Pros:**

- Excellent command understanding and generation
- Fast response times
- Reliable and consistent output
- Supports latest GPT-4 models

**Cons:**

- Requires API key and internet connection
- Costs money per API call
- Data sent to OpenAI servers

**Setup:**

```bash
export AISH_BACKEND=openai
export OPENAI_API_KEY='your-api-key-here'
export OPENAI_MODEL=gpt-4  # or gpt-3.5-turbo for faster/cheaper
```

### Ollama (Local)

**Pros:**

- Completely local and private
- No API costs
- Works offline
- Support for many open-source models

**Cons:**

- Requires local installation and setup
- Slower than cloud APIs
- May require powerful hardware
- Variable quality depending on model

**Setup:**

```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Pull a model
ollama pull llama2  # or codellama, mistral, etc.

# Configure aish
export AISH_BACKEND=ollama
export OLLAMA_MODEL=llama2
```

## 📋 How It Works

aish uses a sophisticated LangGraph-based agent with three main stages:

```
Natural Language → Plan → Generate Commands → Execute → Stream Output
```

### 1. **Planning Stage**

- Breaks down your request into logical steps
- Identifies dependencies and proper order
- Estimates time and identifies risks

### 2. **Command Generation**

- Converts each step into appropriate shell commands
- Adapts to your operating system and available tools
- Provides alternatives for failed commands

### 3. **Execution Stage**

- Asks for confirmation before running commands
- Streams output in real-time
- Handles errors gracefully with retry options
- Logs everything to history

## 🛡️ Safety Features

- **Command Validation**: Blocks dangerous commands like `rm -rf /`
- **User Confirmation**: Always asks before executing commands
- **Sudo Detection**: Warns when commands require elevated privileges
- **Safe Defaults**: Conservative approach to system modifications
- **Execution Logging**: Complete audit trail of all commands

## 📁 Project Structure

```
aish/
├── aish.sh                      # Zsh wrapper script
├── aish_agent/
│   ├── __init__.py
│   ├── agent_langgraph.py       # Main LangGraph agent
│   ├── config.py                # Configuration management
│   ├── command_executor.py      # Secure command execution
│   ├── planner_node.py          # Task planning node
│   ├── command_node.py          # Command generation node
│   └── execute_node.py          # Command execution node
├── install.sh                   # Installation script
├── requirements.txt             # Python dependencies
├── README.md                    # This file
└── LICENSE                      # License file
```

## 🔍 Examples

### System Administration

```bash
aish "install nginx and configure it to start on boot"
aish "show me system resource usage"
aish "create a new user called 'developer' with sudo privileges"
```

### Development

```bash
aish "set up a Python virtual environment and install Django"
aish "find all TODO comments in my codebase"
aish "run the test suite and show only failures"
```

### File Management

```bash
aish "backup my Documents folder to an external drive"
aish "find and delete all files larger than 1GB in Downloads"
aish "organize my photos by date"
```

### Network & Security

```bash
aish "check which ports are open on this machine"
aish "show me the current firewall rules"
aish "test connectivity to google.com"
```

## 🔧 Troubleshooting

### Common Issues

**1. Command not found**

```bash
# Make sure aish is in your PATH
echo $PATH | grep -q "$HOME/.aish" || source ~/.zshrc
```

**2. Python dependencies missing**

```bash
# Reinstall dependencies
pip3 install --user -r requirements.txt
```

**3. OpenAI API errors**

```bash
# Check your API key
echo $OPENAI_API_KEY
# Verify it's valid at https://platform.openai.com/api-keys
```

**4. Ollama connection issues**

```bash
# Check if Ollama is running
ollama list
# Start Ollama if needed
ollama serve
```

### Debug Mode

Enable debug output for troubleshooting:

```bash
export AISH_DEBUG=true
aish "your command here"
```

## 📊 Performance

- **Cold start**: ~2-3 seconds (includes LLM planning)
- **Command generation**: ~1-2 seconds per step
- **Execution**: Real-time streaming output
- **Memory usage**: ~50-100MB (depending on model)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Make your changes and test thoroughly
4. Submit a pull request

### Development Setup

```bash
git clone https://github.com/your-repo/aish.git
cd aish
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## 📜 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Documentation**: [Wiki](https://github.com/your-repo/aish/wiki)
- **Issues**: [GitHub Issues](https://github.com/your-repo/aish/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-repo/aish/discussions)

## ⚠️ Disclaimer

aish is a powerful tool that can execute system commands. Always review commands before execution and use appropriate caution, especially with sudo privileges. The authors are not responsible for any damage caused by misuse of this tool.

---

**Made with ❤️ by the aish team**
