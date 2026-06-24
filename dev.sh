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
        # 兼容旧版本 docker-compose 和新版本 docker compose
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
