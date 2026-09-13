# Management console

An internal admin/ops console for the facial biometric verification platform.
It reads the platform's shared analytics Postgres database and gives ops and
fraud teams a UI over audit logs, fraud rejections, SIM-swap orders and
transactions, per-transaction PDF activity reports, and a chatbot that can
answer questions about the verification pipeline.

This repository holds only the management console and what it needs to build
and run standalone — it does not include the platform's main verification
Backend, which lives in a separate deployment and merely shares the same
analytics database.

---

## Layout

```
management-console/
  management-backend/     FastAPI API — analytics queries, auth, PDF reports, chatbot
  management-frontend/    React + Vite + TypeScript SPA
  management-design/      Architecture / process-flow diagrams (mermaid)
  Dockerfile               Multi-stage build — one image serves API + SPA (see below)
process_document/          Process docs indexed for the chatbot (offline, see below)
pyproject.toml / uv.lock   Shared Python dependency resolution for management-backend
```

The frontend bundle is built at image-build time and served by the same
FastAPI process, so the API and UI ship as a single container.

## Running locally

Requires [uv](https://docs.astral.sh/uv/) and Node 22+.

```bash
cp .env.example .env      # then fill in OPENAI_API_KEY and the analytics DB values
uv sync

# API on :8001, from management-console/management-backend
cd management-console/management-backend
uv run --project ../.. uvicorn main:app --reload --port 8001

# UI on :5174, proxying /api to the API above
cd management-console/management-frontend
npm install && npm run dev
```

Open `http://127.0.0.1:8001/docs` for interactive Swagger docs, or
`http://localhost:5174` for the SPA.

Or run the production shape in one container, built from the **repo root**
(so it can reach `pyproject.toml`/`uv.lock`):

```bash
docker build -f management-console/Dockerfile -t management-console .
docker run --rm -p 8001:8001 --env-file .env management-console
```

## Endpoints

| Method | Path                                              | Purpose                                   |
|--------|---------------------------------------------------|--------------------------------------------|
| GET    | `/health`                                          | Liveness check                             |
| POST   | `/api/v1/chat`                                     | Ask the System Chatbot (Fraud Assistant) a question |
| POST   | `/api/v1/auth/login`                               | Plaintext credential check against `users` |
| GET    | `/api/v1/analytics/audit-logs`                     | Process/audit log entries, filterable      |
| GET    | `/api/v1/analytics/fraud-rejections`               | Fraud rejection records                    |
| GET    | `/api/v1/analytics/fraud-rejections/summary`       | Fraud rejections grouped by rule           |
| GET    | `/api/v1/analytics/sim-swap-orders`                | SIM-swap orders, filterable                |
| GET    | `/api/v1/analytics/sim-swap-orders/status-summary` | SIM-swap orders grouped by status          |
| GET    | `/api/v1/analytics/sim-swap-orders/volume-by-day`  | SIM-swap order volume over time            |
| GET    | `/api/v1/analytics/transactions`                   | Transactions, filterable                   |
| GET    | `/api/v1/analytics/transactions/status-summary`    | Transactions grouped by status             |
| GET    | `/api/v1/analytics/transactions/volume-by-day`     | Transaction volume over time               |
| GET    | `/api/v1/analytics/transactions/{id}/report`       | Per-transaction PDF activity report        |
| GET    | `/docs`                                            | OpenAPI UI                                 |

All analytics routes read from the same Postgres analytics DB as the main
platform's `Backend/analytics_api` and `Backend/analytics_sync` services.

## Frontend

The SPA (`management-console/management-frontend`) has four pages behind a
login gate:

- **Audit Logs** — process/audit log search
- **Fraud Intelligence Repo** — fraud rejection records and rule summaries
- **Transaction Report** — transaction search, status summaries, and
  per-transaction PDF report download
- **System Chatbot** — a Fraud Assistant chat backed by `POST /api/v1/chat`

## System Chatbot document index

`system_llm.py`'s agent answers from `process_document/*.txt`, embedded into
the `process_docs` table via `pgvector`. After adding or editing any of those
files, re-run the indexer (never part of the container build, so this always
happens offline):

```bash
cd management-console/management-backend
uv run --project ../.. python index_process_docs.py
```

Requires `OPENAI_API_KEY` and the analytics DB env vars (below).

## Environment variables

See `.env.example`. In short:

| Variable | Purpose |
|---|---|
| `OPENAI_API_KEY` | Used by the System Chatbot's OpenAI Agents SDK agent and for embeddings |
| `MANAGEMENT_CORS_ALLOW_ORIGINS` | Allowed origins for the API (default `http://localhost:5174`) |
| `ANALYTICS_DATABASE_URL` | Full Postgres connection string, or build one from the vars below |
| `analytics_postgres_host` / `_port` / `_username` / `_password` / `analytics_database` | Analytics Postgres connection, piece by piece |

## Checks

```bash
uv run ruff check .          # lint
uv run ruff format --check . # formatting

cd management-console/management-frontend
npm run lint                 # ESLint
npm run build                # type-check + production build
```
