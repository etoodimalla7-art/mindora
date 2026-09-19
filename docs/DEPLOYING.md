# Deploying the backend so the built app actually works

Codemagic builds a real, installable APK either way — but the app
calls a backend URL baked in at build time (`API_BASE_URL`). Until
that URL points at a backend reachable from the internet, the app
opens fine but every action that needs the network (login, chat,
uploads) will fail.

Quick free/cheap options that run a FastAPI + Postgres app with
minimal setup:
- **Render.com** — connect the GitHub repo, "New Web Service",
  root directory `backend/`, build command
  `pip install -r requirements.txt`, start command
  `uvicorn api.main:app --host 0.0.0.0 --port $PORT`. Add a free
  Postgres instance from Render too, and set `DATABASE_URL` and
  `SECRET_KEY` in its environment variables (see `.env.example`).
- **Railway.app** — similar one-click flow, also offers a free
  Postgres add-on.
- **Fly.io** — more setup (a `fly.toml` + Dockerfile), but a generous
  free tier.

Once deployed, copy the live URL (e.g.
`https://mindora-api.onrender.com/api/v1`) into Codemagic's
**Environment variables** for the `API_BASE_URL` var (Codemagic UI →
your app → workflow → Environment variables — this overrides the
placeholder in `codemagic.yaml` without editing the file), then
re-run the build.
