#!/bin/bash

# 脚本名称 / Script Name: pve7to8_upgrade.sh
# 用途 / Purpose: 将 Proxmox VE 7.4-19 升级到 Proxmox VE 8.x，适用于无订阅、无虚拟机、无 Ceph 的系统
#                      Upgrade Proxmox VE 7.4-19 to Proxmox VE 8.x for systems without subscription, VMs, or Ceph
# 作者 / Author: VmShell INC https://vmshell.com
# 日期 / Date: April 28, 2025
# 要求 / Requirements: 以 root 身份在 Proxmox VE 7.4-19 (Debian 11 Bullseye) 上运行，需联网
#                      Run as root on Proxmox VE 7.4-19 (Debian 11 Bullseye) with internet access
# 许可 / License: MIT License
# 注意 / Notes: 使用社区（无订阅）存储库，自动备份，安装常用工具，记录日志
#               Uses community (no-subscription) repositories, auto-backup, installs common tools, logs output

# 设置错误退出 / Exit on error
set -e

# 日志文件 / Log file
LOG_FILE="/var/log/pve7to8_upgrade.log"
# 备份目录 / Backup directory
BACKUP_DIR="/root/pve_backup_$(date +%Y%m%d_%H%M%S)"

# 函数：打印步骤信息 / Function: Print step information
print_step() {
    echo "==============================================================" | tee -a "$LOG_FILE"
    echo "步骤 $1 / STEP $1: $2" | tee -a "$LOG_FILE"
    echo "==============================================================" | tee -a "$LOG_FILE"
}

# 函数：检查命令执行状态 / Function: Check command execution status
check_status() {
    if [ $? -eq 0 ]; then
        echo "成功 / SUCCESS: $1 完成 / Completed successfully." | tee -a "$LOG_FILE"
    else
        echo "错误 / ERROR: $1 失败 / Failed. 请检查日志 / Check $LOG_FILE for details." | tee -a "$LOG_FILE"
        echo "建议 / Suggestion: 运行 'apt -f install' 或检查网络连接 / Run 'apt -f install' or check network." | tee -a "$LOG_FILE"
        exit 1
    fi
}

# 函数：显示简单进度条 / Function: Show simple progress bar
show_progress() {
    local msg=$1
    echo -n "$msg " | tee -a "$LOG_FILE"
    for i in {1..5}; do
        echo -n "." | tee -a "$LOG_FILE"
        sleep 1
    done
    echo " 完成 / Done" | tee -a "$LOG_FILE"
}

# 步骤 1：验证 root 权限 / Step 1: Verify root privileges
print_step 1 "验证 root 权限 / Verifying root privileges"
if [ "$(id -u)" -ne 0 ]; then
    echo "错误 / ERROR: 必须以 root 身份运行 / Must run as root." | tee -a "$LOG_FILE"
    exit 1
fi
echo "已确认 root 权限 / Root privileges confirmed." | tee -a "$LOG_FILE"

# 步骤 2：检查磁盘空间 / Step 2: Check disk space
print_step 2 "检查磁盘空间（需至少 5GB） / Checking disk space (requires at least 5GB)"
FREE_SPACE=$(df -h / | awk 'NR==2 {print $4}' | grep -o '[0-9.]\+')
if [ -z "$FREE_SPACE" ] || [ $(echo "$FREE_SPACE < 5" | bc -l) -eq 1 ]; then
    echo "错误 / ERROR: 根分区空间不足 / Insufficient root partition space (< 5GB)." | tee -a "$LOG_FILE"
    exit 1
fi
echo "根分区可用空间 / Root partition free space: ${FREE_SPACE}GB" | tee -a "$LOG_FILE"

# 步骤 3：测试网络连接 / Step 3: Test network connectivity
print_step 3 "测试网络连接 / Testing network connectivity"
ping -c 4 ftp.uk.debian.org > /dev/null 2>&1
check_status "网络连接测试 / Network connectivity test"
echo "网络连接正常 / Network connectivity confirmed." | tee -a "$LOG_FILE"

# 步骤 4：检查当前 Proxmox VE 版本 / Step 4: Check current Proxmox VE version
print_step 4 "检查当前 Proxmox VE 版本 / Checking current Proxmox VE version"
if ! command -v pveversion >/dev/null 2>&1; then
    echo "错误 / ERROR: 未检测到 Proxmox VE / Proxmox VE not detected." | tee -a "$LOG_FILE"
    exit 1
fi
PVE_VERSION=$(pveversion)
if [[ ! $PVE_VERSION =~ pve-manager/7\.[4-9] ]]; then
    echo "错误 / ERROR: 需 Proxmox VE 7.4 或更高版本 / Requires Proxmox VE 7.4 or higher. Found: $PVE_VERSION" | tee -a "$LOG_FILE"
    exit 1
fi
echo "当前版本 / Current version: $PVE_VERSION" | tee -a "$LOG_FILE"

# 步骤 5：显示硬件信息 / Step 5: Display hardware information
print_step 5 "显示硬件信息 / Displaying hardware information"
echo "CPU: $(lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs)" | tee -a "$LOG_FILE"
echo "内存 / Memory: $(free -h | awk '/Mem:/ {print $2}')" | tee -a "$LOG_FILE"
echo "虚拟化支持 / Virtualization support: $(egrep -c '(vmx|svm)' /proc/cpuinfo | awk '{print $1 > 0 ? "Yes" : "No"}')" | tee -a "$LOG_FILE"

# 步骤 6：备份关键配置文件 / Step 6: Backup critical configuration files
print_step 6 "备份关键配置文件 / Backing up critical configuration files"
mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/pve_config_backup.tar.gz" /etc /var/lib/pve-cluster 2>/dev/null
check_status "配置文件备份 / Configuration backup"
echo "备份保存至 / Backup saved to: $BACKUP_DIR/pve_config_backup.tar.gz" | tee -a "$LOG_FILE"

# 步骤 7：更新 Proxmox VE 7.4 到最新补丁 / Step 7: Update Proxmox VE 7.4 to latest patch
print_step 7 "更新 Proxmox VE 7.4 到最新补丁 / Updating Proxmox VE 7.4 to latest patch"
show_progress "正在更新 / Updating"
apt update
check_status "APT 更新 / APT update"
apt full-upgrade -y
check_status "系统升级 / System upgrade"
echo "Proxmox VE 7.4 已更新到最新 / Proxmox VE 7.4 updated to latest." | tee -a "$LOG_FILE"

# 步骤 8：安装常用工具 / Step 8: Install common tools
print_step 8 "安装常用工具 / Installing common tools"
show_progress "正在安装 / Installing"
apt update -y && apt install -y screen curl wget unzip zip cron nano vim
check_status "常用工具安装 / Common tools installation"
echo "已安装工具 / Installed tools: screen, curl, wget, unzip, zip, cron, nano, vim" | tee -a "$LOG_FILE"

# 步骤 9：运行 Proxmox VE 7 到 8 升级检查 / Step 9: Run Proxmox VE 7 to 8 upgrade checker
print_step 9 "运行 Proxmox VE 7 到 8 升级检查 / Running Proxmox VE 7 to 8 upgrade checker"
if ! command -v pve7to8 >/dev/null 2>&1; then
    echo "错误 / ERROR: 未找到 pve7to8 检查工具 / pve7to8 checker not found." | tee -a "$LOG_FILE"
    exit 1
fi
pve7to8 --full > pve7to8_check.log
check_status "pve7to8 检查 / pve7to8 checker"
if grep -q "FAILURES:.*[1-9]" pve7to8_check.log; then
    echo "错误 / ERROR: 升级检查发现问题 / Upgrade checker found issues. 查看 / Review pve7to8_check.log" | tee -a "$LOG_FILE"
    exit 1
fi
echo "升级检查通过 / Upgrade checker passed. 无严重问题 / No critical issues." | tee -a "$LOG_FILE"

# 步骤 10：配置 Debian 12 (Bookworm) 和 Proxmox VE 社区源 / Step 10: Configure Debian 12 (Bookworm) and Proxmox VE community sources
print_step 10 "配置 Debian 12 (Bookworm) 和 Proxmox VE 社区源 / Configuring Debian 12 (Bookworm) and Proxmox VE community sources"
# 清空并配置 /etc/apt/sources.list / Clear and configure /etc/apt/sources.list
> /etc/apt/sources.list
echo "deb http://ftp.uk.debian.org/debian bookworm main contrib" > /etc/apt/sources.list
echo "deb http://ftp.uk.debian.org/debian bookworm-updates main contrib" >> /etc/apt/sources.list
echo "deb http://security.debian.org/debian-security bookworm-security main contrib" >> /etc/apt/sources.list
check_status "Debian 源配置 / Debian sources configuration"

# 禁用企业源 / Disable enterprise source
> /etc/apt/sources.list.d/pve-enterprise.list
echo "# deb https://enterprise.proxmox.com/debian/pve bookworm pve-enterprise" > /etc/apt/sources.list.d/pve-enterprise.list
check_status "禁用企业源 / Disabling enterprise source"

# 配置 Proxmox VE 无订阅源 / Configure Proxmox VE no-subscription source
> /etc/apt/sources.list.d/pve.list
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve.list
check_status "Proxmox VE 无订阅源配置 / Proxmox VE no-subscription source configuration"

# 清空 Ceph 源（若存在） / Clear Ceph sources (if any)
> /etc/apt/sources.list.d/ceph.list
check_status "清空 Ceph 源 / Clearing Ceph sources"

# 步骤 11：更新 APT 缓存 / Step 11: Update APT cache
print_step 11 "更新 APT 缓存 / Updating APT cache"
show_progress "正在更新 / Updating"
apt update
check_status "APT 缓存更新 / APT cache update"
echo "APT 缓存更新成功 / APT cache updated successfully." | tee -a "$LOG_FILE"

# 步骤 12：执行系统升级到 Proxmox VE 8 / Step 12: Perform system upgrade to Proxmox VE 8
print_step 12 "执行系统升级到 Proxmox VE 8 / Performing system upgrade to Proxmox VE 8"
show_progress "正在升级 / Upgrading"
apt full-upgrade -y
check_status "系统升级到 Proxmox VE 8 / System upgrade to Proxmox VE 8"
echo "系统已升级到 Proxmox VE 8 / System upgraded to Proxmox VE 8." | tee -a "$LOG_FILE"

# 步骤 13：安装 systemd-boot（若使用 UEFI 和 ZFS） / Step 13: Install systemd-boot (if using UEFI and ZFS)
print_step 13 "检查并安装 systemd-boot（若适用） / Checking and installing systemd-boot (if applicable)"
if proxmox-boot-tool status >/dev/null 2>&1; then
    if proxmox-boot-tool status | grep -q "zfs"; then
        apt install -y systemd-boot
        check_status "systemd-boot 安装 / systemd-boot installation"
        echo "已安装 systemd-boot 以支持 UEFI/ZFS / systemd-boot installed for UEFI/ZFS." | tee -a "$LOG_FILE"
    else
        echo "未检测到 ZFS，跳过 systemd-boot 安装 / No ZFS detected, skipping systemd-boot." | tee -a "$LOG_FILE"
    fi
else
    echo "proxmox-boot-tool 不适用，跳过 systemd-boot / proxmox-boot-tool not applicable, skipping systemd-boot." | tee -a "$LOG_FILE"
fi

# 步骤 14：清理 APT 缓存 / Step 14: Clean APT cache
print_step 14 "清理 APT 缓存 / Cleaning APT cache"
apt clean
check_status "APT 缓存清理 / APT cache cleanup"
echo "APT 缓存已清理 / APT cache cleaned." | tee -a "$LOG_FILE"

# 步骤 15：清理旧内核（可选） / Step 15: Clean old kernels (optional)
print_step 15 "清理旧内核（可选） / Cleaning old kernels (optional)"
apt autoremove --purge -y
check_status "旧内核清理 / Old kernels cleanup"
echo "旧内核已清理 / Old kernels cleaned." | tee -a "$LOG_FILE"

# 步骤 16：重启系统 / Step 16: Reboot system
print_step 16 "重启系统以应用更改 / Rebooting system to apply changes"
echo "系统将在 10 秒后重启，按 Ctrl+C 取消 / System will reboot in 10 seconds, press Ctrl+C to cancel." | tee -a "$LOG_FILE"
sleep 10
reboot

# 注意：以下为手动验证步骤，需重启后执行 / Note: Manual verification steps to run after reboot
cat << EOF | tee -a "$LOG_FILE"
==============================================================
升级完成！请重启后手动验证 / Upgrade complete! Please verify after reboot:
1. 检查版本 / Check version:
   pveversion  # 应显示 pve-manager/8.x.x / Should show pve-manager/8.x.x
2. 检查内核 / Check kernel:
   uname -r    # 应显示 6.2.x 或更高 / Should show 6.2.x or higher (e.g., 6.8.4-3-pve)
3. 检查日志 / Check logs:
   cat $LOG_FILE
4. 备份文件 / Backup files:
   $BACKUP_DIR/pve_config_backup.tar.gz

如有问题，请提交 VmShell工单
==============================================================
EOF
