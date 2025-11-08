# Signal Bridge Setup

1. Tunnel the API locally: `ssh -L 8080:127.0.0.1:8080 rpi5`.
2. Open `http://localhost:8080/v1/qrcodelink?device_name=n8n-rpi5`.
3. In the Signal app go to Settings → Linked devices and scan the QR.
4. Verify the device appears, then test with `curl -X POST http://127.0.0.1:8080/v2/send ...`.
