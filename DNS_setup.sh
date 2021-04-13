#!/bin/sh
user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.66 Safari/537.36'
linux_version=$(cat /etc/redhat-release | awk -F ' ' '{print $4}'| awk -F '.' '{print $1}') 
[ -z "$linux_version" ] && echo "【提示】暂时不支持非CentOS系统" && exit 0

yn_error (){
    echo -e "\033[31mWARNING 只能输入 [Y/N]\033[0m"
}

if [ "$linux_version" == 8 ];then
    echo "当前系统为CentOS8，经过测试支持使用本脚本"
else
    echo "当前系统为CentOS$linux_version，暂未作测试，不保证能运行正常"
fi
while :; do
read -p "是否继续安装？[Y/N] " var
case $var in
    [yY])
        break;;
    [nN]|"")
        exit 0;;
    *)
        yn_error
        continue;;
esac
done

if [ -z "$(command -v smartdns)" ];then
    echo "【提示】开始部署SmartDNS"
    cd ~
    tag="$( wget -T 5 -t 3 --user-agent "$user_agent" --max-redirect=0 --output-document=-  https://github.com/pymumu/smartdns/releases/latest  2>&1 | grep releases/tag | awk -F '/' '{print $NF}' | awk -F ' ' '{print $1}' )" ; [ -z "$tag" ] && echo $tag
    file_name="$( wget -T 5 -t 3 --user-agent "$user_agent" -q --output-document=-  https://github.com/pymumu/smartdns/releases/latest  2>&1 | grep '<a href="/pymumu/smartdns/releases/download/' | awk -F '/' '{print $NF}' | awk -F '"' '{print $1}' | grep 'x86_64-linux-all.tar.gz')"
	[[ -z $tag || -z $file_name ]] && tag=Release33 && file_name=smartdns.1.2020.09.08-2235.x86_64-linux-all.tar.gz && echo "获取最新版本信息失败，将安装旧版！"
    

    version=$( echo $file_name | awk -F 'smartdns.' '{print $2}'| awk -F '.x86_64' '{print $1}' )
    echo "【提示】准备安装的版本为$version"
    urls=(https://download.fastgit.org/pymumu/smartdns/releases/download https://cdn.jsdelivr.net/gh/pymumu/smartdns/releases/download https://github.com/pymumu/smartdns/releases/download)
    for url in ${urls[@]};
    do
    wget -q --spider $urls/$tag/$file_name && wget -qO- $urls/$tag/$file_name | tar zx && { echo "【提示】SmartDNS二进制文件下载成功"; break; }
    done
    
    cd smartdns
    chmod +x ./install
    ./install -i >>/dev/null && echo "【提示】SmartDNS安装完成"
    cd .. && rm -f smartdns*.tar.gz && rm -rf smartdns &&  echo "【提示】已清理缓存文件"

    urls=(https://github.com/lurenJBD/CentOS_DNS_Server_deployment_script/raw/main https://cdn.jsdelivr.net/gh/lurenJBD/CentOS_DNS_Server_deployment_script@main https://cdn.staticaly.com/gh/lurenJBD/CentOS_DNS_Server_deployment_script/main)
    for url in ${urls[@]};
    do
        wget -q --spider $url/SmartDNS/smartdns.conf && wget -T 5 -qO /etc/smartdns/smartdns.conf $url/SmartDNS/smartdns.conf && { echo "【提示】SmartDNS配置文件下载成功"; break; }
    done
    echo "【提示】SmartDNS配置放在/etc/smartdns/ 下"
    systemctl enable smartdns
    systemctl start smartdns
    echo "【提示】SmartDNS安装完成"
else
    echo "【提示】检测到SmartDNS已安装，不再重复安装"
fi

if [ -z "$(command -v chinadns-ng)" ];then
echo "【提示】开始部署ChinaDNS-NG"
yum  install -y git make gcc supervisor
cd /opt
git clone https://github.com/zfl9/chinadns-ng
cd chinadns-ng
make && sudo make install
#配置 Supervisor 守护进程 
# python2
# pip install supervisord
# python3
# pip3 install git+https://github.com/Supervisor/supervisor
echo_supervisord_conf > /etc/supervisord.conf
sed -i "169c[include]" /etc/supervisord.conf
sed -i "170cfiles = /etc/supervisord.d/*.ini" /etc/supervisord.conf
mkdir /etc/supervisord.d
cat >/etc/supervisord.d/ChinaDNS-NG.ini <<EOF
[program:chinadns-ng]
command=bash /opt/chinadns-ng/chinadns-ng.sh
process_name=ChinaDNS-NG
directory=/opt/chinadns-ng/
autostart=true
startsecs=1
startretries=1
autorestart=false
priority=100
user=root
EOF
cat >/opt/chinadns-ng/chinadns-ng.sh <<EOF
ipset -F chnroute
ipset -F chnroute6
ipset -R -exist </opt/chinadns-ng/chnroute.ipset
ipset -R -exist </opt/chinadns-ng/chnroute6.ipset
/usr/local/bin/chinadns-ng -l 8053 -n -b 0.0.0.0 -c 127.0.0.1#8051 -t 127.0.0.1#8052 --chnlist-first -m /opt/chinadns-ng/chnlist.txt -g /opt/chinadns-ng/gfwlist.txt &
EOF

#配置 Supervisor 作为服务开机启动 
cat >/lib/systemd/system/supervisor.service <<EOF
[Unit]
Description=supervisor
After=network.target
 
[Service]
Type=forking
ExecStart=/usr/bin/supervisord -c /etc/supervisord.conf
ExecStop=/usr/bin/supervisorctl $OPTIONS shutdown
ExecReload=/usr/bin/supervisorctl $OPTIONS reload
KillMode=process
Restart=on-failure
RestartSec=30s
 
[Install]
WantedBy=multi-user.target
EOF
wget -qO /opt/chinadns-ng/iplist_update.sh https://raw.githubusercontent.com/lurenJBD/CentOS_DNS_Server_deployment_script/main/ChinaDNS-NG/iplist_update.sh
bash /opt/chinadns-ng/iplist_update.sh
wget -qO /opt/chinadns-ng/chroute_update.sh https://raw.githubusercontent.com/lurenJBD/CentOS_DNS_Server_deployment_script/main/ChinaDNS-NG/chroute_update.sh
#bash /opt/chinadns-ng/chroute_update.sh
systemctl enable supervisor
systemctl start supervisor

echo "【提示】ChinaDNS-NG安装完成"
else
    echo "【提示】检测到ChinaDNS-NG已安装，不再重复安装"
fi

if [ -z "$(command -v /opt/AdGuardHome/AdGuardHome)" ];then
echo "【提示】开始部署AdGuardHome"
curl -sSL https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/scripts/install.sh | sh
#mkdir /opt/AdGuardHome
mkdir /opt/AdGuardHome/data
mkdir /opt/AdGuardHome/data/filters
wget -qO /opt/AdGuardHome/AdGuardHome.yaml https://github.com/lurenJBD/CentOS_DNS_Server_deployment_script/raw/main/AdGuardHome/AdGuardHome.yaml
wget -qO /opt/AdGuardHome/data/filters/1.txt https://easylist.to/easylist/easylist.txt
wget -qO /opt/AdGuardHome/data/filters/2.txt https://raw.githubusercontent.com/cjx82630/cjxlist/master/cjx-annoyance.txt
wget -qO /opt/AdGuardHome/data/filters/3.txt https://cdn.jsdelivr.net/gh/neoFelhz/neohosts@gh-pages/basic/hosts
wget -qO /opt/AdGuardHome/data/filters/4.txt https://easylist-downloads.adblockplus.org/easyprivacy.txt

firewall-cmd --zone=public --add-port=3000/tcp --permanent
firewall-cmd --zone=public --add-port=53/tcp --permanent
firewall-cmd --zone=public --add-port=53/udp --permanent
systemctl restart firewalld
echo "【提示】已开放防火墙53，3000端口"
systemctl disable dnsmasq
systemctl stop dnsmasq
pkill dnsmasq
#dnsmasq=$(netstat -anp | grep dnsmasq | head -n 1)
#if [ "$dnsmasq" != "" ];then
#pkill dnsmasq
#chkconfig dnsmasq off                                    
#fi
#sed -i "58cno-resolv" /etc/dnsmasq.conf
#sed -i "59cserver=127.0.0.1#5353" /etc/dnsmasq.conf

systemctl enable AdGuardHome
systemctl start AdGuardHome

#/opt/AdGuardHome/AdGuardHome -s start
/opt/AdGuardHome/AdGuardHome &
echo "【提示】AdGuardHome管理账户：admin，密码：admin"

echo "【提示】AdGuardHome安装完成"
else
    echo "【提示】检测到AdGuardHome已安装，不再重复安装"
fi

echo "【提示】一键部署DNS服务脚本已执行完成，请重启系统"
