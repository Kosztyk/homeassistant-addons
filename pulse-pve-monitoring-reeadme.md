#<img width="617" height="393" alt="image" src="https://github.com/user-attachments/assets/d4f8f701-9263-47e8-a789-aaf0fe535dc6" />

 **Pulse PVE Monitoring – Home Assistant Add-on**

This repository contains a Home Assistant add-on that runs the
[Pulse](https://github.com/rcourtman/Pulse) monitoring server inside
Home Assistant.

Pulse is a lightweight server for monitoring **Proxmox VE**, Docker,
and other hosts via small agents. This add-on lets you host the Pulse
server directly on your Home Assistant machine and access the web UI
via a browser.

---

## Features

- Runs the official `rcourtman/pulse:latest` Docker image as an add-on
- Exposes the Pulse web UI on port **7655**
- Uses `/data` for persistent storage (handled by Home Assistant)
- Simple configuration via the Home Assistant UI
- Works nicely alongside the Pulse Docker/host agents

---

## Requirements

- Home Assistant OS or Supervised installation
- Architecture: `amd64` or `arm64`
- Internet access on first build to pull the `rcourtman/pulse` image

---

## Installation

## 🛠 How to add this repository to Home Assistant

1. Go to **Settings → Add-ons → Add-on Store**.
2. Click the **⋮ (three dots)** in the top-right → **Repositories**.
3. Add:

   ```text
   https://github.com/Kosztyk/homeassistant-addons
