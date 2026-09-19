# MINDORA Backend (FastAPI)

## Run locally

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # fill in SECRET_KEY and DATABASE_URL at minimum
uvicorn api.main:app --reload
```

Health check: `GET http://localhost:8000/health`
Docs: `http://localhost:8000/docs`

## Structure
See `../docs/ARCHITECTURE.md`, `../docs/API_MAP.md`, `../docs/DATABASE_SCHEMA.md`.
