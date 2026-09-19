# MINDORA backend test suite

```bash
pip install -r requirements.txt
pip install pytest pytest-asyncio
pytest                    # run everything
pytest tests/test_admin.py -v
pytest -k "quiz"          # any test with "quiz" in its name
```

## Structure

- `conftest.py` — shared fixtures: a fresh in-memory SQLite database per
  test (`db_engine`), a real `TestClient` wired to the actual FastAPI app
  with that database (`client`), a real registered user via the real
  HTTP endpoint (`registered_user`), and an admin-elevated variant
  (`admin_user`). Also resets slowapi's rate-limiter state before every
  test — without that, dozens of tests calling `/auth/register` would
  share global rate-limit state and start failing for reasons unrelated
  to what each test actually checks.
- `test_pure_functions.py` — every module's pure business logic (no DB,
  no HTTP). Runs in milliseconds; this is where a regression should be
  caught first.
- `test_*.py` (everything else) — real HTTP integration tests through
  `TestClient`, covering what pure-function tests structurally cannot:
  persistence, cross-module wiring, and — critically, per Phase 17's
  finding — actual response serialization. A service-layer test can
  call a method and assert on the Python object it returns; it cannot
  catch a bug where Pydantic fails to serialize that object into JSON,
  because that only happens at the router layer. Every test file here
  goes through real HTTP requests for exactly that reason.

## Adding a new test

New GET/list endpoints should get at least one real HTTP-level test
here, not only a service-level check — that's the specific gap Phase
17 found (a systemic UUID-serialization bug that 16 phases of
service-level testing had completely missed). If you're only testing
business logic with no persistence or serialization involved, a pure
function in the relevant module plus a test in
`test_pure_functions.py` is faster and sufficient.
