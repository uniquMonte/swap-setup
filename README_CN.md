# Linux VPS Swap 交换空间管理脚本

中文文档 | [English](README.md)

一个为 Linux VPS 快速添加、删除和管理 swap 交换空间的一键脚本。

## 功能特性

- ✅ 添加 swap 交换空间,支持自定义大小(1GB、2GB、4GB、8GB 或自定义)
- ✅ 完全删除 swap 交换空间
- ✅ 查看当前 swap 状态
- ✅ 安装脚本到系统,方便随时使用
- ✅ 自动持久化(重启后自动生效)
- ✅ 优化的 swap 设置(swappiness 和缓存压力)
- ✅ 交互式菜单界面
- ✅ 支持命令行参数
- ✅ 彩色输出,更易读

## 快速开始

### 一键安装并运行

```bash
bash <(curl -Ls https://raw.githubusercontent.com/uniquMonte/swap-setup/main/install.sh)
```

这将启动交互式菜单,你可以:
- 添加/创建 swap 交换空间
- 删除 swap 交换空间
- 永久安装脚本到系统
- 卸载脚本

### 安装到系统

要永久安装脚本到系统:

```bash
# 运行安装程序
bash <(curl -Ls https://raw.githubusercontent.com/uniquMonte/swap-setup/main/install.sh)

# 然后选择选项 3 "安装脚本到系统"
# 或者使用命令行参数:
bash <(curl -Ls https://raw.githubusercontent.com/uniquMonte/swap-setup/main/install.sh) install
```

安装后,你可以随时运行:

```bash
swap-manager
```

## 使用方法

### 交互式菜单

不带参数运行脚本将启动交互式菜单:

```bash
sudo swap-manager
# 或
sudo bash install.sh
```

### 命令行参数

脚本也支持直接使用命令行:

```bash
# 添加 swap (交互式选择大小)
sudo swap-manager add

# 删除 swap
sudo swap-manager remove

# 显示 swap 状态
sudo swap-manager status

# 安装脚本到系统
sudo swap-manager install

# 从系统卸载脚本
sudo swap-manager uninstall
```

## 工作原理

### 添加 Swap

1. **创建 swap 文件** 位置: `/swapfile`
2. **设置适当的权限** (600)
3. **格式化为 swap 空间**
4. **启用 swap**
5. **设置持久化** 添加到 `/etc/fstab`
6. **优化系统设置**:
   - `vm.swappiness=10` (仅在需要时使用 swap)
   - `vm.vfs_cache_pressure=50` (平衡的缓存保留)

### 删除 Swap

1. **禁用 swap** 空间
2. **删除 swap 文件**
3. **清理** `/etc/fstab` 条目

## 系统要求

- 基于 Linux 的操作系统
- Root 权限 (sudo)
- `bash` shell
- `curl` (用于一键安装)

## Swap 大小建议

| 内存大小 | 建议 Swap 大小 |
|---------|---------------|
| 512 MB  | 1 GB          |
| 1 GB    | 2 GB          |
| 2 GB    | 2-4 GB        |
| 4 GB    | 2-4 GB        |
| 8 GB+   | 2-4 GB        |

**注意**: 对于 VPS 服务器,swap 特别有用,可以防止内存峰值时的内存不足错误。

## 什么是 Swap?

Swap 交换空间是硬盘存储的一部分,当系统的 RAM 内存用完时,它充当虚拟内存。它有助于:
- 防止内存不足导致的崩溃
- 处理内存峰值
- 提高低内存系统的稳定性

## 系统兼容性

已测试并可在以下系统上运行:
- Ubuntu (18.04, 20.04, 22.04, 24.04)
- Debian (9, 10, 11, 12)
- CentOS / Rocky Linux / AlmaLinux (7, 8, 9)
- Fedora
- 其他使用 systemd 的 Linux 发行版

## 故障排除

### 权限被拒绝

确保使用 root 权限运行:

```bash
sudo bash install.sh
```

### 磁盘空间问题

创建 swap 之前检查可用磁盘空间:

```bash
df -h /
```

确保有足够的可用空间来创建你想要的 swap 大小。

### 重启后 Swap 未生效

检查 `/etc/fstab` 中是否存在条目:

```bash
cat /etc/fstab | grep swapfile
```

如果缺失,再次运行"添加/创建 Swap"时脚本会重新添加。

## 安全说明

- swap 文件使用权限 `600` 创建(仅 root 可读/写)
- swap 文件位置: `/swapfile`
- 系统配置文件: `/etc/fstab` 和 `/etc/sysctl.conf`

## 卸载

要完全删除脚本和 swap:

1. **删除 swap 空间**: 使用菜单中的选项 2
2. **卸载脚本**: 使用菜单中的选项 4

或使用命令行:

```bash
sudo swap-manager remove      # 删除 swap
sudo swap-manager uninstall   # 删除脚本
```

## 贡献

欢迎在 [https://github.com/uniquMonte/swap-setup](https://github.com/uniquMonte/swap-setup) 提交 issues 和 pull requests

## 许可证

MIT 许可证 - 可自由使用和修改。

## 作者

**uniquMonte**

- GitHub: [@uniquMonte](https://github.com/uniquMonte)

## 更新日志

### 版本 1.0.0 (2025-01-08)
- 首次发布
- 添加/删除 swap 功能
- 交互式菜单界面
- 命令行参数支持
- 自动优化设置
- 安装/卸载脚本功能
