
# Open-VSCode Server 部署与管理指南

本仓库包含基于 Docker Compose 部署与管理个人专属 Web IDE (**Open-VSCode Server**) 的核心配置文件与自动化脚本。该方案直接采用微软官方最新的 VS Code Web 架构，支持挂载宿主机当前用户的主目录，并通过硬件和网络优化提供极致流畅的浏览器编程体验。

---

## 🏗️ 架构特点

1. **原汁原味原生体验**：像素级还原最新版本地 VS Code 的界面、快捷键及操作逻辑。
2. **完美权限映射**：通过动态注入宿主机当前用户的 `UID` 和 `GID`，彻底避免容器内写代码、创建文件在宿主机上产生 `root` 权限锁定的问题。
3. **极致性能**：依托官方原生 Web 架构与异步 Worker 处理，大文件滚动与多标签页切换比传统魔改方案更为流畅。

---

## 📂 项目结构

```text
├── docker-compose.yml   # Docker 容器编排配置文件
├── dev.sh               # 自动化管理脚本 (支持 start/stop/restart/logs/status)
└── README.md            # 本使用说明文档

```

---

## 🛠️ 快速开始

### 1. 准备环境

确保宿主机已安装 **Docker** 以及 **Docker Compose**（新版 Docker 已原生集成 `docker compose` 命令）。

### 2. 获取并配置项目文件

#### 📄 创建 `docker-compose.yml`

```yaml
version: '3.8'

services:
  openvscode-server:
    image: gitpod/openvscode-server:latest
    container_name: openvscode-server
    # 自动重启策略：除非手动停止，否则服务器重启或容器崩溃时会自动重启
    restart: unless-stopped
    ports:
      - "80:3000"
    environment:
      # 为了避免网页端写代码时产生权限问题，
      # 这里会将容器内运行用户的 UID 和 GID 映射为你本地当前的登录用户。
      - PUID=${MY_UID}
      - PGID=${MY_GID}
    volumes:
      # 将当前用户的整个家目录（~）挂载到容器内的工作空间
      - ${HOME}:/home/workspace:cached

```

#### 📄 创建 `dev.sh` 管理脚本

```bash
#!/bin/bash

# 定义颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_err()  { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查当前目录是否存在 docker-compose.yml
if [ ! -f "docker-compose.yml" ]; then
    log_err "当前目录下未找到 docker-compose.yml 文件！"
    exit 1
fi

# 核心：自动获取当前用户的 UID 和 GID
export MY_UID=$(id -u)
export MY_GID=$(id -g)

case "$1" in
    start)
        log_info "正在启动 Open-VSCode Server (后台模式)..."
        if docker compose version >/dev/null 2>&1; then
            docker compose up -d
        else
            docker-compose up -d
        fi
        log_info "服务已启动！请在浏览器访问 http://localhost (如果是服务器请访问对应 IP)"
        ;;
        
    stop)
        log_info "正在停止 Open-VSCode Server..."
        if docker compose version >/dev/null 2>&1; then
            docker compose down
        else
            docker-compose down
        fi
        log_info "服务已停止。"
        ;;
        
    restart)
        log_info "正在重启 Open-VSCode Server..."
        if docker compose version >/dev/null 2>&1; then
            docker compose restart
        else
            docker-compose restart
        fi
        log_info "服务已重启。"
        ;;
        
    logs)
        log_info "正在查看容器实时日志 (按 Ctrl+C 退出)..."
        if docker compose version >/dev/null 2>&1; then
            docker compose logs -f
        else
            docker-compose logs -f
        fi
        ;;
        
    status)
        log_info "当前容器运行状态："
        if docker compose version >/dev/null 2>&1; then
            docker compose ps
        else
            docker-compose ps
        fi
        ;;
        
    *)
        echo "============================================="
        echo -e "  ${YELLOW}Open-VSCode Server 管理脚本${NC}"
        echo "============================================="
        echo "使用方法: $0 [命令]"
        echo ""
        echo "可用命令:"
        echo "  start   - 注入当前用户 UID/GID 并启动 IDE (后台运行)"
        echo "  stop    - 停止并移除容器"
        echo "  restart - 重启 IDE 容器"
        echo "  logs    - 查看 IDE 运行日志"
        echo "  status  - 查看容器当前的运行状态"
        echo "============================================="
        exit 1
        ;;
esac

```

### 3. 赋予脚本执行权限

```bash
chmod +x dev.sh

```

---

## 🚀 运维命令示例

你可以完全通过 `./dev.sh` 脚本对 Web IDE 进行全生命周期管理：

* **一键启动服务**：
```bash
./dev.sh start

```


*(注：如果你的 Linux 环境限制了 80 端口，请使用 `sudo ./dev.sh start`，脚本仍能精准映射你当前普通用户的 UID)*
* **查看运行状态**：
```bash
./dev.sh status

```


* **查看实时容器日志**：
```bash
./dev.sh logs

```


* **停止并移除服务**：
```bash
./dev.sh stop

```



---

## 🧩 插件生态说明

由于微软的服务条款限制，非官方编译版本的 IDE 无法直接连接官方的 VS Code Marketplace。本系统默认接入开源的 **Open VSX Registry**。

* 绝大多数前端常用插件（如 `Prettier`、`ESLint`、`Vue - Official` 等）在 Open VSX 均有完善维护，开箱即用。
* 若需要安装个别未上架的商业插件，可前往网络手动下载对应的 `.vsix` 文件，并在 Web 界面中通过 “从 VSIX 安装...” 功能手动导入。

---

## 🔒 核心安全提示（极重要）

1. **公网暴露警告**：Open-VSCode Server 默认未启用内置密码验证机制。**由于其直接挂载了宿主机的家目录（包含你的 SSH 密钥、`.env` 文件等高度敏感数据），强烈禁止直接在公网开放裸奔 80 端口！**
2. **推荐安全加固方案**：
* **本地局域网/内网穿透**：仅在内网或通过安全外网穿透工具（如 WireGuard、Tailscale）访问。
* **反向代理鉴权**：在公网部署时，请务必前置 **Nginx**、**Caddy** 或 **Nginx Proxy Manager**，并配置 **HTTPS 证书** 以及 **Basic Auth (用户密码认证)** 挡在最前端。



