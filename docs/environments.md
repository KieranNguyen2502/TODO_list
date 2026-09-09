# Environments & API base URLs

The Flutter app must never hardcode a base URL — read it from build config (e.g. `--dart-define=API_BASE_URL=...`
or a `.env` loaded via `flutter_dotenv`) so switching environments doesn't require touching code.

| # | Environment                          | Backend location                | `API_BASE_URL` value                          | Notes |
|---|---------------------------------------|----------------------------------|------------------------------------------------|-------|
| 1 | Local backend + Android emulator      | `localhost:8000` on host machine | `http://10.0.2.2:8000`                          | `10.0.2.2` is the emulator's alias for the host loopback. Dev convenience only — never ships. |
| 2 | Local backend + physical device, same LAN | `localhost:8000` on host machine | `http://<host-LAN-IP>:8000` (e.g. `http://192.168.1.42:8000`) | Find host IP via `ipconfig getifaddr en0` (mac) or `ip addr`. Phone and laptop must be on the same Wi-Fi. Check host firewall allows inbound 8000. |
| 3 | Deployed backend + Android emulator   | Hosted (e.g. Render/Fly/Railway) | `https://<your-deployed-domain>`                | First real test of the production API contract, still from a convenient emulator. |
| 4 | Deployed backend + foreign physical device | Hosted | `https://<your-deployed-domain>`                | The actual target scenario: a phone on a different network entirely reaching the public API. Confirms TLS, CORS, and DNS all actually work — not just "reachable on my LAN." |

## Recommended progression
Test in order 1 → 2 → 3 → 4. Don't jump straight to deployed — if something's broken in the ownership/auth
flow, it's much faster to debug against a local backend you can see logs for than a deployed one.

## Things to verify at each stage
- **CORS**: FastAPI's `CORS_ORIGINS` must permit the Flutter app's origin (mobile apps don't send a
  browser `Origin` header the same way, but keep this tight before any web build is added).
- **TLS**: stage 3/4 only — confirm the cert is valid and Flutter's HTTP client isn't configured to
  ignore cert errors (a common local-dev hack that must not survive to deployed testing).
- **Supabase reachability**: the *backend* talks to Supabase, not the Flutter app — so this is really
  "can the deployed backend host reach Supabase," which is usually fine unless there's an egress
  firewall rule on the hosting provider.
