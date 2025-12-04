# ClamAV Web Client – Home Assistant Add‑on

A Home Assistant add‑on packaging the `rguziy/clamav-web-client` Docker image. Provides a web‑based UI to upload and scan files using your existing ClamAV daemon (`clamd`).

## 🧰 What it is

- `clamav-web-client` is a Docker image that offers a browser-based interface allowing users to upload files and run virus/malware scans via ClamAV.
- It supports connecting to an external ClamAV daemon by specifying host and port via environment variables (`CLAMAV_HOST`, `CLAMAV_PORT`).
- This add-on wraps that image so it can be managed via Home Assistant like any other add-on — install/uninstall, start/stop, port mapping, etc.

## 🚀 Installation

1. Add the folder `clamav-web-client/` (with the `config.yaml` add-on definition) to your Home Assistant add-on repository.
2. Commit and push the changes.
3. In Home Assistant:
   - Go to **Settings → Add-ons → Add-on Store**.
   - Under **⋮ → Repositories**, refresh your custom repo.
   - **Reload** the add‑on store.
4. Install **ClamAV Web Client** from the list.
5. Start the add-on.

## 🔧 Configuration

The add-on uses environment variables to connect to ClamAV:

```
environment:
  CLAMAV_HOST: "192.168.68.73"
  CLAMAV_PORT: "3310"
```

## 🧪 Usage

- Open the Web UI at: `http://<home_assistant_host>:8082/`
- Upload a file.
- View ClamAV scan results.

## ⚠️ Limitations

- Requires a running ClamAV daemon (`clamd`).
- Database must be maintained by your ClamAV daemon.
- Only signature‑based detection.

## 📚 Related Projects

- ClamAV documentation: https://docs.clamav.net
- ClamAV REST API: https://github.com/benzino77/clamav-rest-api
