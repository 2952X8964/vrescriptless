#!/bin/bash

set -e

echo "是否确认搭建 hysteria2？(y/n)"
read -r confirm
[[ "$confirm" != "y" ]] && echo "已取消。" && exit 0

# 安装 hysteria2
bash <(curl -fsSL https://get.hy2.sh/)
systemctl enable hysteria-server.service

# 创建配置目录
mkdir -p /etc/hysteria

# 获取用户输入
read -p "请输入监听端口（如 443）: " port
read -p "请选择 TLS 证书方式（输入 1 表示自动申请证书，输入 2 表示指定证书路径）: " tls_choice

if [[ "$tls_choice" == "1" ]]; then
    read -p "请输入你的域名（必须已解析到本机IP）: " domain
elif [[ "$tls_choice" == "2" ]]; then
    read -p "请输入证书路径（如 /etc/hysteria/certificate.crt）: " cert_path
    read -p "请输入私钥路径（如 /etc/hysteria/private.key）: " key_path
else
    echo "输入无效，退出。"
    exit 1
fi

read -p "请输入设置的连接密码: " password
read -p "请输入伪装网址（如 www.cloudflare.com）: " fake_site

# 生成配置文件
cat <<EOF > /etc/hysteria/config.yaml
listen: :$port #监听端口
EOF

if [[ "$tls_choice" == "1" ]]; then
cat <<EOF >> /etc/hysteria/config.yaml
acme:
  domains:
    - $domain #你的域名，需要先解析到服务器ip
  email: tesdt@sharkladddddddssers.com

#使用指定证书或自签证书（文件位置）
#tls:
#  cert: /etc/hysteria/certificate.crt
#  key: /etc/hysteria/private.key
EOF
else
cat <<EOF >> /etc/hysteria/config.yaml
#acme:
#  domains:
#    - www.example.com #你的域名，需要先解析到服务器ip
#  email: tesdt@sharkladddddddssers.com

#使用指定证书或自签证书（文件位置）
tls:
  cert: $cert_path
  key: $key_path
EOF
fi

cat <<EOF >> /etc/hysteria/config.yaml

auth:
  type: password
  password: $password #设置认证密码

masquerade:
  type: proxy
  proxy:
    url: https://$fake_site #网址
    rewriteHost: true
EOF

# 重启并检查服务状态
systemctl restart hysteria-server.service
status=$(systemctl is-active hysteria-server.service)

# 展示状态
echo
echo "----------------------------------------"
echo "Hysteria2 服务状态: $status"
if [[ "$status" == "active" ]]; then
    echo "✅ Hysteria2 搭建成功！"
else
    echo "❌ Hysteria2 启动失败，请检查日志。"
fi

echo
echo "--------- 你填写的配置信息 ---------"
echo "监听端口: $port"
if [[ "$tls_choice" == "1" ]]; then
    echo "TLS方式: 自动申请"
    echo "域名: $domain"
else
    echo "TLS方式: 指定路径"
    echo "证书路径: $cert_path"
    echo "私钥路径: $key_path"
fi
echo "认证密码: $password"
echo "伪装网址: https://$fake_site"
echo "配置文件位置: /etc/hysteria/config.yaml"
echo "----------------------------------------"

# 卸载函数
echo
echo "是否要生成卸载脚本？(y/n)"
read -r uninstall
if [[ "$uninstall" == "y" ]]; then
cat <<'EOF' > /usr/local/bin/uninstall-hysteria2.sh
#!/bin/bash
echo "正在卸载 hysteria2..."
systemctl stop hysteria-server.service
systemctl disable hysteria-server.service
rm -f /etc/systemd/system/hysteria-server.service
rm -rf /etc/hysteria
rm -f /usr/local/bin/hysteria
echo "✅ hysteria2 已卸载完成"
EOF
chmod +x /usr/local/bin/uninstall-hysteria2.sh
echo "卸载脚本已保存为 /usr/local/bin/uninstall-hysteria2.sh，运行它即可卸载。"
fi
