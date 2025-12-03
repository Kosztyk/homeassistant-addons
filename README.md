# 🧩 Kosztyk Home Assistant Add-ons

A collection of custom Home Assistant add-ons for my homelab.

## 📦 Add-ons

### 🔍 Tesseract OCR API

FastAPI + Tesseract service for solving numeric CAPTCHAs (used by RAR ITP checker, etc.).

- Folder: [`tesseract-api`](./tesseract-api)
- Exposes: `http://<addon-ip>:8000/`
- Endpoints: `/health`, `/ocr/file`, `/ocr/url`

### 📊 Pulse Docker Agent

Agent for [Pulse](https://github.com/rcourtman/Pulse) monitoring (PVE / Docker / hosts).

- Folder: [`pulse-docker-agent`](./pulse-docker-agent)
- Connects to existing Pulse server via URL + API token.

## 🛠 How to add this repository to Home Assistant

1. Go to **Settings → Add-ons → Add-on Store**.
2. Click the **⋮ (three dots)** in the top-right → **Repositories**.
3. Add:

   ```text
   https://github.com/Kosztyk/homeassistant-addons
