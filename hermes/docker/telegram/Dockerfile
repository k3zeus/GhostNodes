FROM python:3.12-slim

WORKDIR /app

RUN pip install --no-cache-dir \
    python-telegram-bot==21.* \
    httpx==0.27.* \
    pyyaml==6.*

COPY bot.py .

CMD ["python", "-u", "bot.py"]
