# 一键安装ChinaDNS-NG，SmartDNS，AdGuardHome到CentOS 8
请注意！！！本脚本尚未完成，存在大量BUG，不建议在实体机或ECS上直接运行

# 脚本主要功能 
- 部署并配置SmartDNS
- 部署并配置ChinaDNS-NG，配合Supervisor实现开机启动
- 部署并配置AdGuardHome
无需再手动对各个DNS服务进行配置，已提前将AdGuard配置文件放置再Github中
- 使用CDN网站解决Github下载文件缓慢的问题

# 如何使用
运行命令

`wget -qO DNS_setup.sh https://raw.githubusercontent.com/lurenJBD/CentOS_DNS_Server_deployment_script/main/DNS_setup.sh && bash DNS_setup.sh `

关系结构图
![image](https://user-images.githubusercontent.com/31967654/111603435-51037480-880f-11eb-95ec-fcde89af4bc5.png)
