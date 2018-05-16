# MTProxySystemd
Deploying your own MTProxy for Telegram as Systemd service

Don't forget to:
```
chmod +x mtproxyd.sh
systemctl daemon-reload && systemctl enable mtproxyd.service && systemctl start mtproxyd.service
```
