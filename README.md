# MTProxy Systemd Service

##Deploying your own MTProxy as Systemd service

`nano /lib/systemd/system/mtproxyd.service`

```
[Unit]
Description=MTproxy Public service
After=network.target
StartLimitIntervalSec=0


[Service]
Type=simple
Restart=always
RestartSec=1
User=root
ExecStart=<path/to>/mtproto-proxy -6 -u nobody -p <stat-port> -H <listen-port> -S <secret> --aes-pwd <path/to>/proxy-secret <path/to>/proxy-multi.conf -P <promo-tag> -M 8

[Install]
WantedBy=multi-user.target

```

`setcap 'cap_net_bind_service=+ep' <path/to>/mtproto-proxy`

```
systemctl daemon-reload
systemctl start mtproxyd
systemctl status mtproxyd
systemctl enable mtproxyd
```
