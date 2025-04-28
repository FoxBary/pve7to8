# pve7to8
PVE7.4-19的系统 升级到最新的PVE8的系统


一键执行命令:
curl -sSL https://github.com/FoxBary/pve7to8/raw/main/pve7to8.sh -o pve7to8.sh && chmod +x pve7to8.sh && ./pve7to8.sh





Proxmox VE 7 到 8 升级脚本 / Proxmox VE 7 to 8 Upgrade Script
概述 / Overview
此脚本用于将 Proxmox VE 7.4-19 升级到 Proxmox VE 8.x，适用于无企业订阅、无运行虚拟机、无 Ceph 的系统。它使用社区（无订阅）存储库，自动备份关键配置，安装常用工具（如 screen、curl、wget 等），并提供详细的日志记录和错误处理。脚本由 VmShell INC 开发，欢迎通过 GitHub 反馈问题。
This script upgrades Proxmox VE 7.4-19 to Proxmox VE 8.x on systems without enterprise subscriptions, running VMs, or Ceph. It uses community (no-subscription) repositories, automatically backs up critical configurations, installs common tools (e.g., screen, curl, wget), and provides detailed logging and error handling. Developed by VmShell INC, feedback is welcome via GitHub.
功能 / Features

中英文双语注释，便于全球用户理解 / Bilingual (Chinese/English) comments for global users
自动备份 /etc 和 /var/lib/pve-cluster / Auto-backup of /etc and /var/lib/pve-cluster
检查磁盘空间（至少 5GB）和网络连接 / Disk space (min 5GB) and network connectivity checks
显示硬件信息（CPU、内存、虚拟化支持） / Hardware info display (CPU, memory, virtualization support)
进度条和详细日志记录（/var/log/pve7to8_upgrade.log） / Progress bar and detailed logging (/var/log/pve7to8_upgrade.log)
错误恢复建议和 GitHub 反馈链接 / Error recovery suggestions and GitHub issue link
清理旧内核，优化系统 / Clean old kernels for system optimization
支持 UEFI/ZFS 环境的 systemd-boot 安装 / Install systemd-boot for UEFI/ZFS environments

使用方法 / Usage

下载脚本 / Download the script:wget https://raw.githubusercontent.com/FoxBary/pve7to8/main/pve7to8_upgrade.sh


设置执行权限 / Set executable permissions:chmod +x pve7to8_upgrade.sh


以 root 身份运行 / Run as root:./pve7to8_upgrade.sh


按照屏幕提示操作，升级完成后重启 / Follow on-screen instructions, reboot after completion.

要求 / Requirements

Proxmox VE 7.4-19（基于 Debian 11 Bullseye） / Proxmox VE 7.4-19 (based on Debian 11 Bullseye)
联网环境 / Internet access
root 权限 / Root privileges
根分区至少 5GB 可用空间 / At least 5GB free space on root partition

日志与备份 / Logs and Backups

日志文件 / Log file: /var/log/pve7to8_upgrade.log
备份文件 / Backup file: /root/pve_backup_[timestamp]/pve_config_backup.tar.gz

验证升级 / Verify Upgrade
重启后运行以下命令验证 / Run these commands after reboot to verify:
pveversion  # 应显示 pve-manager/8.x.x / Should show pve-manager/8.x.x
uname -r    # 应显示 6.2.x 或更高 / Should show 6.2.x or higher (e.g., 6.8.4-3-pve)

错误处理 / Error Handling

检查日志 / Check logs: cat /var/log/pve7to8_upgrade.log
修复依赖问题 / Fix dependency issues: apt -f install
恢复备份 / Restore backup:tar -xzf /root/pve_backup_[timestamp]/pve_config_backup.tar.gz -C /


反馈问题 / Report issues: GitHub Issues

常见问题 / FAQ

升级失败怎么办？ / What if the upgrade fails?检查 /var/log/pve7to8_upgrade.log 和 pve7to8_check.log，运行 apt -f install 修复依赖，或在 GitHub 提交 issue。Check /var/log/pve7to8_upgrade.log and pve7to8_check.log, run apt -f install to fix dependencies, or submit an issue on GitHub.

网络缓慢怎么办？ / What if the network is slow?编辑 pve7to8_upgrade.sh，将 ftp.uk.debian.org 替换为 deb.debian.org，然后重新运行。Edit pve7to8_upgrade.sh, replace ftp.uk.debian.org with deb.debian.org, and rerun.

需要企业订阅吗？ / Is an enterprise subscription required?无需订阅，脚本使用社区（无订阅）存储库。No subscription needed; the script uses community (no-subscription) repositories.


贡献 / Contributing
欢迎提交 pull requests 或 issues 到 GitHub 仓库。Welcome pull requests or issues at GitHub repository.
许可 / License
MIT License
联系 / Contact

作者 / Author: VmShell INC
网站 / Website: https://vmshell.com
GitHub: https://github.com/FoxBary/pve7to8

