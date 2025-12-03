# 🧠 Tesseract OCR API – Home Assistant Add-on  
Local FastAPI-based OCR service for solving numeric CAPTCHAs

<p align="center">
  <img src="https://img.shields.io/badge/Addon-Tesseract%20OCR-blue?style=for-the-badge&logo=tesseract-ocr" />
  <img src="https://img.shields.io/badge/Home%20Assistant-Addon-41BDF5?style=for-the-badge&logo=homeassistant" />
  <img src="https://img.shields.io/github/license/kosztyk/homeassistant-addons?style=for-the-badge" />
</p>

---

## 📌 Overview

**Tesseract OCR API** is a lightweight, high-performance **local OCR service** built using:

- 🚀 **FastAPI**
- 🔡 **Tesseract OCR (digits mode optimized)**
- ⚡ Fast, memory-optimized image preprocessing
- 🧊 Full offline processing (no cloud services)
- 🔒 Secure and private (runs entirely inside Home Assistant)

This add-on is ideal for:

- Automatic CAPTCHA solving  
- Local integrations that require numeric OCR (e.g., **RAR ITP Checker**)  
- High-throughput OCR workloads  
- Private home-lab environments with strict no-cloud policies  

---

## ✨ Features

| Feature | Description |
|--------|-------------|
| 🧠 **Local OCR engine** | Runs Tesseract OCR inside the add-on container — no internet needed. |
| 🚀 **FastAPI backend** | High-performance async HTTP server (Uvicorn). |
| 🔢 **Digits-only mode** | Optimized for CAPTCHAs with numeric codes. |
| 🖼️ **Advanced preprocessing** | Auto-denoising, thresholding, resizing, binarization. |
| 📂 **File and URL support** | OCR images uploaded as files OR fetched from external URLs. |
| 🩺 **Health endpoint** | Easy monitoring via `/health`. |
| 📦 **Lightweight** | Small image, low RAM/CPU usage. |

---

## 🛠 Installation

### 🔹 Add this repository to Home Assistant

1. Go to  
   **Settings → Add-ons → Add-on Store**  
2. Click the **⋮ (three dots)** → **Repositories**  
3. Add:

```
https://github.com/<your-username>/homeassistant-addons
```

4. You will see a new section:  
   **“Kosztyk Home Assistant Add-ons”**
5. Select **Tesseract OCR API** → Install → Start

---

## 🚀 API Usage

Once the add-on is running, it exposes:

```
http://<homeassistant-ip>:8000
```

---

### ✅ Health check

```
GET /health
```

Example:

```json
{ "status": "ok" }
```

---

### 📤 OCR via file upload

```
POST /ocr/file?expected_length=4
```

Example with `curl`:

```bash
curl -F "file=@captcha.png"   "http://homeassistant.local:8000/ocr/file?expected_length=4"
```

Response:

```json
{
  "text": "8372",
  "length": 4,
  "expected_length": 4,
  "filename": "captcha.png"
}
```

---

### 🌐 OCR via URL

```
POST /ocr/url
```

Body:

```json
{
  "url": "https://example.com/captcha.png",
  "expected_length": 4
}
```

Response:

```json
{
  "text": "4921",
  "length": 4,
  "expected_length": 4
}
```

---

## 🔍 Internals & Behavior

- Uses **Tesseract PSM 7/8** (single-line digits only)
- Aggressive preprocessing improves accuracy:
  - grayscale normalization  
  - blur + contrast enhancement  
  - adaptive thresholding  
  - anti-noise filtering  
  - enforced resizing  
- Returns only **digits 0–9** (non-digit characters are stripped)
- Fully asynchronous and very fast (<20ms per image on typical CPUs)

---


## 🧪 Testing

Quick local test (Linux/macOS):

```bash
curl http://localhost:8000/health
```

OCR test:

```bash
curl -F "file=@tests/captcha1.png" http://localhost:8000/ocr/file?expected_length=4
```

---


## 📝 License

This project is licensed under the **MIT License** — free for personal or commercial use.


---

## ❤️ Support the Project

If you find this add-on useful, consider giving the repo a ⭐ on GitHub — it helps visibility and development.
