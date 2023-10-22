#!/usr/bin/env bash

set -eu -o pipefail

pushd terraform/ &> /dev/null
xray_server_user="${XRAY_SERVER_USER:-$(terraform output -raw xray_server_user)}"
xray_server_host="${XRAY_SERVER_HOST:-$(terraform output -raw xray_server_ipv6)}"
popd &> /dev/null
ssh "$xray_server_user"@"$xray_server_host" bash -s << 'EOF'
    set -eu -o pipefail

    xray_server_cname="$(cat ~/xray_server_cname)"
    xray_client_uuid="$(xray uuid)"
    sudo python3 <<END
import json

config = "/usr/local/etc/xray/config.json"
with open(config, "r") as f:
    main_config = json.load(f)
inbound_protos = main_config["inbounds"]
vless_proto_config = next(filter(lambda x: x["protocol"] == "vless", inbound_protos))
vless_proto_config["settings"]["clients"].append({"id": "${xray_client_uuid}", "flow": "xtls-rprx-vision", "email": "${xray_client_uuid}", "level": 0})

with open(config, "w") as f:
    json.dump(main_config, f, indent=2)
END
    sudo systemctl restart xray

    echo "Added new client: $xray_client_uuid"
    
    vless_conn_string="vless://${xray_client_uuid}@${xray_server_cname}:443?security=tls&sni=${xray_server_cname}&alpn=http/1.1,h2&fp=edge&type=tcp&flow=xtls-rprx-vision&encryption=none#${xray_server_cname}"
    echo "VLESS connection string: $vless_conn_string"
    echo -n "$vless_conn_string" | qrencode -t ansiutf8
EOF
