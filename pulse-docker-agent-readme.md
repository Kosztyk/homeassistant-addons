
 <img width="617" height="393" alt="image" src="https://github.com/user-attachments/assets/54ca36cf-2c74-4d33-bbef-44d9b877be0e" />
 
# 🐧 Pulse Docker Agent – Home Assistant Add-on

[![GitHub Repo stars](https://img.shields.io/github/stars/kosztyk/pulse-docker-agent-addon?style=flat-square)](https://github.com/kosztyk/pulse-docker-agent-addon)
[![Docker Pulls](https://img.shields.io/docker/pulls/kosztyk/pulse-docker-agent?style=flat-square)](https://hub.docker.com/r/kosztyk/pulse-docker-agent)
![Home Assistant](https://img.shields.io/badge/Home%20Assistant-add--on-41BDF5?style=flat-square&logo=homeassistant&logoColor=white)

A Home Assistant add-on that runs the **Pulse Docker Agent**, allowing your Home Assistant host and Docker containers to be monitored by the
[Pulse PVE Monitoring](https://github.com/rcourtman/Pulse) platform.

---


## 📊 What is Pulse PVE Monitoring?

**Pulse** is a modern, lightweight monitoring platform designed for:


- 🖥️ Proxmox VE nodes  
- 🐳 Docker hosts & containers  
- 💽 Storage & hardware stats  
- 🧠 System & resource metrics  

Pulse gives you:

- Real‑time dashboards  
- Auto-discovery of hosts  
- Minimal resource usage  
- Push-based agents  
- A unified web UI for all monitored systems  

🔗 **Official project and docs:**  
👉 https://github.com/rcourtman/Pulse

---

## 🧩 What This Add-on Does

This add-on installs and runs the **Pulse Docker Agent** on the same system where Home Assistant is running.  
It enables Pulse to collect metrics such as:

- CPU, RAM, disk usage of the Docker host running Home Assistant  
- Status and metrics of Docker containers  
- Extra remote Docker targets if configured

Under the hood, the add-on:

- Downloads the correct `pulse-docker-agent` binary for your architecture  
- Reads configuration from the Home Assistant add-on options  
- Exposes the Docker API (as per HA add-on permissions)  
- Sends metrics to your Pulse server at the configured interval  

---


## ⚙️ Home Assistant Add-on Configuration

The add-on exposes these options via the Home Assistant UI:

| Option          | Required | Description |
|-----------------|----------|-------------|
| `pulse_url`     | ✅       | URL of your Pulse server (e.g. `http://192.168.1.20:7655`) |
| `api_token`     | ✅       | API token created in Pulse with `docker:report` scope |
| `interval`      | ✅       | Report interval, e.g. `30s`, `60s` |
| `log_level`     | ✅       | `debug`, `info`, `warn`, `error` |
| `agent_version` | ✅       | Pulse agent version / tag to download |
| `extra_targets` | ✅       | Comma-separated list of extra Docker hosts |



> ℹ️ The add-on should validate that `pulse_url` and `api_token` are set before starting, and log a clear error if not.

> **Protection mode should be off for addon to work properlly.**
<img width="1066" height="592" alt="Screenshot 2025-12-03 at 16 49 14" src="https://github.com/user-attachments/assets/bc382533-9384-4661-be8a-586cb8403883" />


---

## 🚀 Installation in Home Assistant

1. Open **Home Assistant**  
2. Go to **Settings → Add-ons → Add-on Store**  
3. Click **⋮ (top-right) → Repositories**  
4. Add this repository URL:

   ```text
   https://github.com/kosztyk/pulse-docker-agent-addon
   ```

5. Click **Add**, then close the dialog  
6. You should now see **Pulse Docker Agent** in the add-on list  
7. Click it → **Install**  
8. Open the **Configuration** tab, set at least:

   - `pulse_url` – your Pulse server URL  
   - `api_token` – token with `docker:report` permissions
     
  **Protection mode should be off for addon to work properlly.**

9. Go back to **Info** tab → click **Start**  
10. (Optional) Enable **Start on boot**

Your Home Assistant host should now appear in the Pulse UI as a Docker host 🎉

---

## 🧪 Supported Architectures

The published Docker image is multi-arch:

- `amd64`  
- `arm64`

Docker and Home Assistant automatically select the correct image for your CPU.

---

## 🖼 Screenshots

You can add screenshots to the `screenshots/` folder and reference them here.  
For example:

```markdown
![Pulse dashboard showing Home Assistant Docker host](screenshots/pulse-dashboard.png)
```

---

## 🔗 Useful Links

- 🧠 **Pulse main repo:** https://github.com/rcourtman/Pulse  
- 📚 **Pulse docs:** https://github.com/rcourtman/Pulse/tree/main/docs  
- 🐳 **Docker image:** https://hub.docker.com/r/kosztyk/pulse-docker-agent  

---


## ⚠️ Disclaimer

This project is an **unofficial** Home Assistant add-on for the Pulse monitoring system.  
Please use at your own risk and always back up your Home Assistant configuration.

