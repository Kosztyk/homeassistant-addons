# ClamAV REST API - Home Assistant Add-on

This add-on wraps the [`benzino77/clamav-rest-api`](https://github.com/benzino77/clamav-rest-api)
Docker image so it can be used directly from Home Assistant.

It provides an HTTP endpoint (default `http://<homeassistant>:3000/api/v1/scan`)
that accepts file uploads and scans them via a remote ClamAV daemon (clamd).

## Configuration

Options:

- `clamd_ip` (string): IP/hostname of your existing ClamAV daemon.
- `clamd_port` (int): Port where clamd is listening (usually 3310).
- `app_form_key` (string): Field name expected in the multipart form (default `FILES`).
- `app_max_file_size` (int): Max allowed file size in bytes (default `262144000` = 250 MB).

## Usage

Once started, the add-on exposes port `3000` (configurable in the add-on UI).
Point your applications to:

`http://<homeassistant-host>:3000/api/v1/scan`

with a multipart upload whose file field name is `FILES` (or your configured `app_form_key`).
