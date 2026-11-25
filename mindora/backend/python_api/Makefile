.PHONY: install migrate test run lint

install:
	poetry install

migrate:
	poetry run alembic upgrade head

test:
	poetry run pytest -q

run:
	poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

lint:
	poetry run ruff check app
