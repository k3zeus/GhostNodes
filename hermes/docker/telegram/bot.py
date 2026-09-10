#!/usr/bin/env python3
"""
GhostNodes — Hermes Telegram Bridge Bot
Bridges Telegram messages to Open WebUI API (OpenAI-compatible).

Environment variables:
  TELEGRAM_BOT_TOKEN       — Bot token from @BotFather
  OPENWEBUI_BASE_URL       — Internal URL of Open WebUI (http://hermes-webui:8080)
  OPENWEBUI_API_KEY        — API key from Open WebUI settings
  ALLOWED_TELEGRAM_USERS   — Comma-separated user IDs (empty = allow all)
  DEFAULT_MODEL            — Model to use (e.g., openai/gpt-4o-mini)
"""

import os
import logging
import httpx
from telegram import Update
from telegram.ext import (
    Application,
    CommandHandler,
    MessageHandler,
    ContextTypes,
    filters,
)

# ── Config ────────────────────────────────────────────────────
BOT_TOKEN = os.environ["TELEGRAM_BOT_TOKEN"]
WEBUI_URL = os.environ.get("OPENWEBUI_BASE_URL", "http://hermes-webui:8080")
API_KEY = os.environ.get("OPENWEBUI_API_KEY", "")
ALLOWED_USERS = os.environ.get("ALLOWED_TELEGRAM_USERS", "")
DEFAULT_MODEL = os.environ.get("DEFAULT_MODEL", "openai/gpt-4o-mini")

ALLOWED_SET = set()
if ALLOWED_USERS.strip():
    ALLOWED_SET = {int(uid.strip()) for uid in ALLOWED_USERS.split(",") if uid.strip()}

logging.basicConfig(
    format="%(asctime)s [%(levelname)s] %(message)s",
    level=logging.INFO,
)
logger = logging.getLogger("hermes-telegram")

# ── Per-user conversation history (in-memory) ────────────────
conversations: dict[int, list[dict]] = {}
MAX_HISTORY = 20


def is_authorized(user_id: int) -> bool:
    """Check if user is allowed to use the bot."""
    if not ALLOWED_SET:
        return True  # No whitelist = allow all
    return user_id in ALLOWED_SET


async def chat_completion(messages: list[dict]) -> str:
    """Send messages to Open WebUI's OpenAI-compatible API."""
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": DEFAULT_MODEL,
        "messages": messages,
        "stream": False,
        "max_tokens": 2048,
    }

    async with httpx.AsyncClient(timeout=120.0) as client:
        resp = await client.post(
            f"{WEBUI_URL}/api/chat/completions",
            json=payload,
            headers=headers,
        )
        resp.raise_for_status()
        data = resp.json()
        return data["choices"][0]["message"]["content"]


# ── Handlers ──────────────────────────────────────────────────

async def cmd_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Handle /start command."""
    user_id = update.effective_user.id
    if not is_authorized(user_id):
        await update.message.reply_text("⛔ Unauthorized. Your ID: " + str(user_id))
        return

    conversations[user_id] = []
    await update.message.reply_text(
        "👻 *Hermes Agent Online*\n\n"
        f"Model: `{DEFAULT_MODEL}`\n"
        "Send any message to chat.\n"
        "/clear — Reset conversation\n"
        "/model — Show current model",
        parse_mode="Markdown",
    )


async def cmd_clear(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Clear conversation history."""
    user_id = update.effective_user.id
    conversations[user_id] = []
    await update.message.reply_text("🗑️ Conversation cleared.")


async def cmd_model(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Show current model."""
    await update.message.reply_text(f"🤖 Current model: `{DEFAULT_MODEL}`", parse_mode="Markdown")


async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Process user message and return AI response."""
    user_id = update.effective_user.id

    if not is_authorized(user_id):
        await update.message.reply_text("⛔ Unauthorized. Your ID: " + str(user_id))
        return

    user_text = update.message.text
    if not user_text:
        return

    # Build conversation history
    if user_id not in conversations:
        conversations[user_id] = []

    conversations[user_id].append({"role": "user", "content": user_text})

    # Trim history
    if len(conversations[user_id]) > MAX_HISTORY:
        conversations[user_id] = conversations[user_id][-MAX_HISTORY:]

    # System prompt
    messages = [
        {
            "role": "system",
            "content": (
                "You are Hermes, a helpful AI assistant running on a GhostNode "
                "sovereign server. Be concise, accurate, and friendly. "
                "Respond in the same language as the user."
            ),
        },
        *conversations[user_id],
    ]

    # Send typing indicator
    await update.message.chat.send_action("typing")

    try:
        response = await chat_completion(messages)
        conversations[user_id].append({"role": "assistant", "content": response})
        await update.message.reply_text(response, parse_mode="Markdown")
    except httpx.HTTPStatusError as e:
        logger.error("API error: %s — %s", e.response.status_code, e.response.text)
        await update.message.reply_text(f"❌ API Error: {e.response.status_code}")
    except Exception as e:
        logger.error("Unexpected error: %s", e)
        await update.message.reply_text("❌ Something went wrong. Check logs.")


# ── Main ──────────────────────────────────────────────────────

def main():
    logger.info("Starting Hermes Telegram Bridge...")
    logger.info("WebUI URL: %s", WEBUI_URL)
    logger.info("Model: %s", DEFAULT_MODEL)
    logger.info("Allowed users: %s", ALLOWED_SET or "ALL")

    app = Application.builder().token(BOT_TOKEN).build()

    app.add_handler(CommandHandler("start", cmd_start))
    app.add_handler(CommandHandler("clear", cmd_clear))
    app.add_handler(CommandHandler("model", cmd_model))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))

    logger.info("Bot is running. Polling...")
    app.run_polling(allowed_updates=Update.ALL_TYPES)


if __name__ == "__main__":
    main()
