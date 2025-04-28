#!/bin/bash

# 1. 升级前提醒用户
echo "============================================================="
echo "将开始将 PVE 7.4 升级到 PVE 8.0，升级过程中将会更新系统和安装常用命令工具"
echo "请确保你已经做好了数据备份，确保没有正在运行的重要虚拟机。"
echo "============================================================="

# 2. 清空现有的 apt 源配置文件并添加新的 PVE 8 源
echo "步骤 2: 配置 PVE 8 的 APT 源..."

# 清空现有的源文件
echo "清空现有的源配置..."
echo "" > /etc/apt/sources.list

# 添加 PVE 8 的源配置
echo "deb http://download.proxmox.com/debian/pve bullseye pve-no-subscription" > /etc/apt/sources.list.d/pve-upgrade.list

# 3. 导入 Proxmox 的 GPG 密钥
echo "步骤 3: 导入 Proxmox 的 GPG 密钥..."

# 下载并添加密钥
wget -qO - https://enterprise.proxmox.com/debian/proxmox-release-8.x.gpg | tee /etc/apt/trusted.gpg.d/proxmox-release.gpg

# 4. 更新 APT 包索引
echo "步骤 4: 更新 APT 包索引..."

# 更新软件包列表
apt update -y

# 5. 安装常用命令工具
echo "步骤 5: 安装常用工具..."

# 安装 screen, curl, wget, unzip, zip, cron, nano, vim 等常用命令工具
apt install -y screen curl wget unzip zip cron nano vim

# 6. 更新现有的所有包
echo "步骤 6: 更新现有的系统包..."

# 升级系统中所有可升级的软件包
apt full-upgrade -y

# 7. 安装 Proxmox VE 8 的核心包
echo "步骤 7: 安装 PVE 8 核心组件..."

# 安装 PVE 8 的核心组件
apt install proxmox-ve-2.5 pve-manager -y

# 8. 完成所有软件包的更新并重启系统
echo "步骤 8: 完成系统升级并重启..."

# 执行系统更新并确保所有包是最新的
apt dist-upgrade -y

# 重启系统
reboot

# 9. 更新 GRUB 配置
echo "步骤 9: 更新 GRUB 配置..."

# 更新 GRUB 启动配置
update-grub

# 10. 升级完成，通知用户
echo "============================================================="
echo "PVE 7.4 升级到 PVE 8.0 已完成！"
echo "升级过程中已安装常用工具，如 screen, curl, wget, unzip, zip, cron, nano, vim 等。"
echo "系统已重启，检查是否正常启动。"
echo "============================================================="
