# ConvertX Home Assistant Add-on

This add-on runs the `kosztyk/convertx-clamav:user` container inside Home Assistant.

## Features

- Web UI on `http://<HA-IP>:8080/`
- Optional ingress: open directly from the HA sidebar
- Built-in ClamAV scanning via `CLAMAV_URL`
- Persistent data in the add-on data directory, mapped to `/app/data`

## Configuration

Edit `config.yaml` for:

- `JWT_SECRET`
- `HTTP_ALLOWED`
- `TZ`
- `AUTO_DELETE_EVERY_N_HOURS`
- `CLAMAV_URL`

After editing, **Restart** the add-on.

## Access

- From LAN: `http://homeassistant.local:8080/` or `http://<HA-IP>:8080/`
- From HA UI: Add-on details → **OPEN WEB UI** (or via ingress if enabled)
