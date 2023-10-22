# xray-on-aws
Tools to setup your own Xray-VLESS server on AWS

# Overview
Unix tools to setup a `t3.nano` (you can change that) instance of [Xray](https://github.com/XTLS/Xray-core) VLESS protocol as a VPN in AWS cloud

**Important note for non-AWS users**

*Even though this repo is designed to be used with AWS, you can still use `ansible-playbooks` to deploy Xray-VLESS on <b>any server</b>.*<br/>
*Navigate directly to [Provision the server](https://github.com/dimkNevidimk/xray-on-aws#provision-the-server) section if this is the case.*

# Prerequisites
1. Create an account in AWS
    * Important: please check [AWS pricing](https://aws.amazon.com/pricing) before proceed, this is not a *free-vpn* setup, you'll be charged according to AWS policies.

2. Create API credentials and write them to `~/.aws/config` file. Note that depending on the region your server would be located in different places
```bash
cat ~/.aws/config
[default]
region=eu-west-2
aws_access_key_id=xxx
aws_secret_access_key=yyy
```

3. Install [terraform](https://developer.hashicorp.com/terraform) and [ansible](https://www.ansible.com) on your system (or use `nix develop`)
4. Setup SSH-keys if not already:
```bash
ssh-keygen -t ed25519 -C "your@email.smth"
```
5. Create yourself a domain name, which would be needed for TLS, e.g. you can use https://freemyip.com

# Usage
## Prepare the server
First start a private server instance in a region you setup in `~/.aws/config`.
```bash
( cd terraform/ ; terraform apply )
```
or if you use different ssh-key than `~/.ssh/id_ed25519`
```bash
( cd terraform/ ; terraform apply -var private_key_file="path-to-your-private-key" )
```
## Provision the server
Assign created domain name to this instance. If you were using `https://freemyip.com`, you can use the following playbook:
```bash
export XRAY_SERVER_HOST="$(cd terraform/ ; terraform output -raw xray_server_ipv6)" # or change to your server name
export XRAY_SERVER_USER="$(cd terraform/ ; terraform output -raw xray_server_user)" # or change to the user on your server
ansible-playbook -i "$XRAY_SERVER_HOST", -u "$XRAY_SERVER_USER" ansible/setup_freemyip_domain_name.yml
```
Then provision this instance with Xray server.
```bash
ansible-playbook -i "$XRAY_SERVER_HOST", -u "$XRAY_SERVER_USER" ansible/setup_xray_server.yml
```
Finally you can generate a QR-code and a connection string to connect to this server from your device
```bash
./add_vless_client.sh
```
scan resulting QR-code from the app which supports VLESS on your device and connect to your own VPN server.

For example as a client application on IOS you can try [FoXray](https://apps.apple.com/us/app/foxray/id6448898396)

# Important note
If you don't need a server anymore, don't forget to terminate it in order to avoid unnecessary costs.
```bash
( cd terraform/ ; terraform destroy ) 
```
