# GhostNodes Web Setup

## Modos suportados

### 1. Host mode

Usado pelo instalador shell do projeto:

- backend FastAPI roda como servico `ghostnodes-web.service`
- frontend React e compilado para `web/frontend/dist`
- credenciais RPC do Bitcoin podem ser lidas de `var/bitcoin-rpc.env`

Fluxo:

```bash
sudo bash halfin/extras/webapp.sh
```

## 2. Docker Compose

Arquivo: `web/docker-compose.yml`

Servicos:

- `ghost-api`: FastAPI
- `ghost-ui`: frontend servido em `:80`

Validacao:

```bash
docker compose -f web/docker-compose.yml config
docker compose -f web/docker-compose.yml build
```

## Integração com Bitcoin

- host mode: use `var/bitcoin-rpc.env`
- compose mode: por padrao o backend usa `BITCOIN_RPC_URL=http://host.docker.internal:8332`
- o compose adiciona `host.docker.internal:host-gateway` para o backend acessar um `bitcoind` rodando no host

## Frontend

- requests usam `src/api.js`
- base padrao: relativa ao mesmo host
- override opcional: `VITE_GHOSTNODES_API_BASE`

Build local:

```bash
cd web/frontend
npm install
npm run build
```

## Backend

Check rapido:

```bash
python -m py_compile web/backend/main.py web/backend/routers/*.py
```

Run local:

```bash
cd web/backend
python -m uvicorn main:app --host 0.0.0.0 --port 8000
```
