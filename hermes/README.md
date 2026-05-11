# Hermes Module — AI Assistant 🤖

## Overview
Hermes is an isolated AI assistant that provides:
1. **Open WebUI** — Modern chat interface supporting 200+ models via OpenRouter
2. **Telegram Bridge** — Chat with your AI from Telegram, anywhere
3. **API-Only Mode** — No local LLM (saves ARM resources), routes to cloud providers

## Architecture
```
┌─────────────────────────────────────────────────────┐
│                    GhostNode                         │
│                                                      │
│  Telegram ──→ telegram-bridge ──→ Open WebUI ──→ API│
│                                       │              │
│  Browser  ──→ Nginx/Tailscale ──→─────┘              │
│                                                      │
│  APIs:  OpenRouter │ OpenAI │ Google AI              │
└─────────────────────────────────────────────────────┘
```

## Quick Start
```bash
sudo bash hermes/install.sh        # Interactive mode
sudo bash hermes/install.sh --yolo  # Automated mode
```

## API Provider Setup

### OpenRouter (Recommended — 200+ models, one key)
1. Sign up at [openrouter.ai](https://openrouter.ai)
2. Generate API key
3. Set `OPENROUTER_API_KEY` in `.env`
4. Models available: GPT-4o, Claude, Gemini, Llama, Mistral, etc.

### OpenAI (Direct)
1. Get key from [platform.openai.com](https://platform.openai.com)
2. In Open WebUI: Settings → Connections → Add OpenAI connection
3. URL: `https://api.openai.com/v1`

### Google AI
1. Get key from [aistudio.google.com](https://aistudio.google.com)
2. In Open WebUI: Settings → Connections → Add connection
3. URL: `https://generativelanguage.googleapis.com/v1beta/openai`

## Telegram Bot Setup

### 1. Create Bot
1. Open Telegram, search for `@BotFather`
2. Send `/newbot`
3. Follow prompts to name your bot
4. Copy the token → `TELEGRAM_BOT_TOKEN` in `.env`

### 2. Get API Key from Open WebUI
1. Access Open WebUI in browser
2. Settings → Account → API Keys → Generate
3. Copy → `HERMES_API_KEY` in `.env`
4. Restart: `docker compose restart telegram-bridge`

### 3. Security
Set `TELEGRAM_ALLOWED_USERS` to your Telegram user ID(s):
- Send `/start` to `@userinfobot` to get your ID
- Multiple users: `TELEGRAM_ALLOWED_USERS=12345,67890`

## Bot Commands
| Command | Description |
|---------|-------------|
| `/start` | Initialize bot |
| `/clear` | Reset conversation history |
| `/model` | Show current model |

## Data & Export
All data is stored in the `hermes_data` Docker volume:
```bash
# Export all data
docker run --rm -v hermes_data:/data -v $(pwd):/backup alpine \
    tar czf /backup/hermes-export.tar.gz -C /data .

# Import
docker run --rm -v hermes_data:/data -v $(pwd):/backup alpine \
    tar xzf /backup/hermes-export.tar.gz -C /data
```

---
*GhostNodes Hermes — Your sovereign AI, your rules.*
