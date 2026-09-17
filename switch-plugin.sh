#!/usr/bin/env bash
# ==============================================================================
# dsh-plugin-switch.sh
# 自由切换 DSH 插件的「本地开发版本 (link)」与「线上发布版本 (online/npm)」
# ==============================================================================

set -eo pipefail

# 默认配置
DEFAULT_PROFILE="web"
PROFILE="${DSH_PROFILE:-$DEFAULT_PROFILE}"
PROJECTS_ROOT="${DSH_PROJECTS_ROOT:-$HOME/dsh-projects}"

# 终端彩色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

print_help() {
    cat << EOF
${BOLD}DSH 插件版本自由切换工具 (dsh-plugin-switch)${NC}

${BOLD}用法:${NC}
  $0 <子命令> [参数...] [选项...]

${BOLD}子命令:${NC}
  ${CYAN}local${NC}   [路径 | 包名]   切换到本地开发版本 (pnpm link)
  ${CYAN}online${NC}  [包名 | 路径]   切换到线上发布版本 (pnpm unlink + add)
  ${CYAN}status${NC}  [包名]          查看当前插件（或全部插件）的链接状态
  ${CYAN}ls${NC}                    列出当前 profile 所有安装的插件
  ${CYAN}help${NC}                  显示此帮助信息

${BOLD}选项:${NC}
  -p, --profile <name>    指定 DSH Profile (默认: ${GREEN}web${NC})
  -b, --build             切换到本地前自动执行 build (仅用于 local 命令)
  -v, --version <version> 指定线上版本号 (默认: ${GREEN}latest${NC}，仅用于 online 命令)
  -h, --help              显示帮助

${BOLD}使用示例:${NC}
  # 1. 切换到本地开发版本 (在项目目录下直接运行)
  cd /path/to/your-plugin
  $0 local

  # 2. 切换到本地开发版本 (指定路径或项目名，并先 build)
  $0 local /path/to/your-plugin --build
  $0 local your-plugin-name

  # 3. 切换回线上版本 (默认安装最新版 latest)
  $0 online your-plugin-name

  # 4. 切换回线上指定版本
  $0 online your-plugin-name -v 1.0.0

  # 5. 查看插件状态
  $0 status your-plugin-name
  $0 status

EOF
}

# 获取 profile 目录
get_profile_dir() {
    local prof="$1"
    local dir="$HOME/.dsh/profiles/$prof"
    if [ ! -d "$dir" ]; then
        error "Profile 目录不存在: $dir"
        exit 1
    fi
    echo "$dir"
}

# 从 package.json 解析包名
get_pkg_name_from_dir() {
    local target_dir="$1"
    if [ ! -f "$target_dir/package.json" ]; then
        return 1
    fi
    node -e "try { const p = require('$target_dir/package.json'); if (p.name) console.log(p.name); } catch(e){}"
}

# 在 ~/dsh-projects 下查找对应的目录
find_local_project_dir() {
    local query="$1"

    # 1. 如果本身是绝对路径或相对路径，且存在 package.json
    if [ -d "$query" ] && [ -f "$query/package.json" ]; then
        cd "$query" && pwd
        return 0
    fi

    # 2. 如果在 PROJECTS_ROOT 下直接存在同名子目录
    if [ -d "$PROJECTS_ROOT/$query" ] && [ -f "$PROJECTS_ROOT/$query/package.json" ]; then
        echo "$PROJECTS_ROOT/$query"
        return 0
    fi

    # 3. 遍历 PROJECTS_ROOT 下 2~3 层目录匹配目录名或 package.json 的 name
    local matched_dir=""
    while IFS= read -r pkg_json; do
        local dir
        dir=$(dirname "$pkg_json")
        local pkg_name
        pkg_name=$(get_pkg_name_from_dir "$dir" || true)
        local base_name
        base_name=$(basename "$dir")

        if [ "$pkg_name" = "$query" ] || [ "$base_name" = "$query" ]; then
            matched_dir="$dir"
            break
        fi
    done < <(find "$PROJECTS_ROOT" -maxdepth 4 -name "package.json" ! -path "*/node_modules/*" 2>/dev/null)

    if [ -n "$matched_dir" ]; then
        echo "$matched_dir"
        return 0
    fi

    return 1
}

# ------------------------------------------------------------------------------
# 子命令: local (切换到本地开发版)
# ------------------------------------------------------------------------------
cmd_local() {
    local target_input=""
    local do_build=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -b|--build)
                do_build=true
                shift
                ;;
            -*)
                error "未知参数: $1"
                exit 1
                ;;
            *)
                if [ -z "$target_input" ]; then
                    target_input="$1"
                else
                    error "多余的参数: $1"
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # 确定目标项目目录
    local target_dir=""
    if [ -z "$target_input" ]; then
        if [ -f "./package.json" ]; then
            target_dir=$(pwd)
        else
            error "未指定插件路径，且当前目录不存在 package.json"
            error "用法: $0 local <路径或包名>"
            exit 1
        fi
    else
        target_dir=$(find_local_project_dir "$target_input" || true)
        if [ -z "$target_dir" ]; then
            error "无法找到插件目录: $target_input (已搜索 $PROJECTS_ROOT)"
            exit 1
        fi
    fi

    target_dir=$(cd "$target_dir" && pwd)
    local pkg_name
    pkg_name=$(get_pkg_name_from_dir "$target_dir" || true)

    if [ -z "$pkg_name" ]; then
        error "无法从 $target_dir/package.json 解析出包名"
        exit 1
    fi

    info "准备将插件 [${CYAN}$pkg_name${NC}] 切换到本地开发版本:"
    echo -e "  - 本地路径: ${BOLD}$target_dir${NC}"
    echo -e "  - DSH Profile: ${BOLD}$PROFILE${NC}"

    # 可选 build
    if [ "$do_build" = true ]; then
        info "正在执行本地构建 (build)..."
        (
            cd "$target_dir"
            if [ -f "pnpm-lock.yaml" ]; then
                pnpm run build
            elif [ -f "yarn.lock" ]; then
                yarn build
            else
                npm run build
            fi
        )
        success "构建完成!"
    fi

    # 执行 dsh plugin link
    info "正在执行: dsh plugin --profile $PROFILE link $target_dir"
    dsh plugin --profile "$PROFILE" link "$target_dir"

    success "已成功切换到本地开发版本!"
    echo ""
    cmd_status "$pkg_name"
    echo ""
    warn "提示: 请刷新或重启 DSH Web GUI (http://127.0.0.1:3080) 使最新代码生效。"
}

# ------------------------------------------------------------------------------
# 子命令: online (切换到线上发布版)
# ------------------------------------------------------------------------------
cmd_online() {
    local target_input=""
    local target_version="latest"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--version)
                target_version="$2"
                shift 2
                ;;
            -*)
                error "未知参数: $1"
                exit 1
                ;;
            *)
                if [ -z "$target_input" ]; then
                    target_input="$1"
                elif [ "$target_version" = "latest" ]; then
                    # 允许第二个位置参数直接作为版本号，如 switch online dsh-agy-link 0.4.32
                    target_version="$1"
                else
                    error "多余的参数: $1"
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # 确定包名
    local pkg_name=""
    if [ -z "$target_input" ]; then
        if [ -f "./package.json" ]; then
            pkg_name=$(get_pkg_name_from_dir "$(pwd)" || true)
        else
            error "未指定包名，且当前目录不是 npm 项目"
            error "用法: $0 online <包名> [-v 版本号]"
            exit 1
        fi
    else
        # 可能是路径或者包名
        if [ -d "$target_input" ] && [ -f "$target_input/package.json" ]; then
            pkg_name=$(get_pkg_name_from_dir "$target_input" || true)
        else
            pkg_name="$target_input"
        fi
    fi

    # 去除版本号开头的 @ 或 v (如果有)
    target_version="${target_version#@}"
    target_version="${target_version#v}"

    info "准备将插件 [${CYAN}$pkg_name${NC}] 切换到线上版本:"
    echo -e "  - 目标版本: ${BOLD}$target_version${NC}"
    echo -e "  - DSH Profile: ${BOLD}$PROFILE${NC}"

    local prof_dir
    prof_dir=$(get_profile_dir "$PROFILE")

    # 检查是否为已链接状态
    local is_linked=false
    local node_mod="$prof_dir/node_modules/$pkg_name"
    if [ -L "$node_mod" ]; then
        is_linked=true
    fi

    # 解除 unlink
    info "正在解除本地链接 (unlink)..."
    dsh plugin --profile "$PROFILE" unlink "$pkg_name" || true

    # 安装线上版本
    local install_spec="${pkg_name}@${target_version}"
    info "正在安装线上版本: dsh plugin --profile $PROFILE add $install_spec"
    dsh plugin --profile "$PROFILE" add "$install_spec"

    success "已成功切换到线上版本!"
    echo ""
    cmd_status "$pkg_name"
    echo ""
    warn "提示: 请刷新或重启 DSH Web GUI (http://127.0.0.1:3080) 使变更生效。"
}

# ------------------------------------------------------------------------------
# 子命令: status (查看状态)
# ------------------------------------------------------------------------------
cmd_status() {
    local target_pkg="$1"
    local prof_dir
    prof_dir=$(get_profile_dir "$PROFILE")
    local pkg_json="$prof_dir/package.json"

    if [ ! -f "$pkg_json" ]; then
        error "未找到 $pkg_json"
        exit 1
    fi

    if [ -n "$target_pkg" ]; then
        # 检查特定插件
        echo -e "${BOLD}--- 插件状态: $target_pkg (Profile: $PROFILE) ---${NC}"
        local mod_path="$prof_dir/node_modules/$target_pkg"
        if [ ! -e "$mod_path" ] && [ ! -L "$mod_path" ]; then
            warn "插件未在 profile 中安装: $target_pkg"
            return 0
        fi

        local dep_version
        dep_version=$(jq -r ".dependencies[\"$target_pkg\"] // empty" "$pkg_json")

        local status_type=""
        local target_dest=""
        local installed_version=""

        # 判断是否为 symlink
        if [ -L "$mod_path" ]; then
            status_type="LOCAL_LINK"
            target_dest=$(node -e "try { console.log(require('fs').realpathSync('$mod_path')); } catch(e){ console.log(require('fs').readlinkSync('$mod_path')); }")
        else
            status_type="ONLINE_STORE"
            target_dest="pnpm virtual store"
        fi

        if [ -f "$mod_path/package.json" ]; then
            installed_version=$(jq -r ".version // empty" "$mod_path/package.json")
        fi

        if [ "$status_type" = "LOCAL_LINK" ]; then
            echo -e "  状态模式:   ${CYAN}${BOLD}[本地开发版本 (LINK)]${NC}"
            echo -e "  链接目标:   ${BOLD}$target_dest${NC}"
            echo -e "  当前版本:   $installed_version"
            echo -e "  清单声明:   $dep_version"
        else
            echo -e "  状态模式:   ${GREEN}${BOLD}[线上发布版本 (ONLINE)]${NC}"
            echo -e "  当前版本:   ${BOLD}v$installed_version${NC}"
            echo -e "  清单声明:   $dep_version"
        fi

        # 尝试查询 npm 上的最新版本
        local latest_npm=""
        latest_npm=$(npm view "$target_pkg" version 2>/dev/null || true)
        if [ -n "$latest_npm" ]; then
            echo -e "  线上最新:   v$latest_npm"
        fi
    else
        # 列出 profile 下的全部插件概要
        echo -e "${BOLD}=== Profile [$PROFILE] 插件版本状态概览 ===${NC}"
        printf "%-32s %-12s %-10s %s\n" "插件名称" "模式" "版本" "目标/来源"
        echo "--------------------------------------------------------------------------------"

        while IFS= read -r key; do
            local mod_path="$prof_dir/node_modules/$key"
            local mode=""
            local ver=""
            local dest=""

            if [ -L "$mod_path" ]; then
                mode="${CYAN}LINK${NC}"
                dest=$(node -e "try { console.log(require('fs').realpathSync('$mod_path')); } catch(e){ console.log(require('fs').readlinkSync('$mod_path')); }" 2>/dev/null || echo "symlink")
            else
                mode="${GREEN}ONLINE${NC}"
                dest="registry"
            fi

            if [ -f "$mod_path/package.json" ]; then
                ver=$(jq -r ".version // \"-\"" "$mod_path/package.json" 2>/dev/null || echo "-")
            else
                ver="-"
            fi

            printf "%-32s %-20b %-10s %s\n" "$key" "$mode" "$ver" "$dest"
        done < <(jq -r '.dependencies | keys[]' "$pkg_json")
    fi
}

# ------------------------------------------------------------------------------
# 子命令: ls
# ------------------------------------------------------------------------------
cmd_ls() {
    dsh plugin --profile "$PROFILE" ls "$@"
}

# ------------------------------------------------------------------------------
# 主入口解析
# ------------------------------------------------------------------------------
main() {
    if [ $# -eq 0 ]; then
        print_help
        exit 0
    fi

    # 提取全局参数 --profile
    local ARGS=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--profile)
                PROFILE="$2"
                shift 2
                ;;
            -h|--help)
                print_help
                exit 0
                ;;
            *)
                ARGS+=("$1")
                shift
                ;;
        esac
    done

    local SUBCOMMAND="${ARGS[0]:-}"
    local REMAINING_ARGS=("${ARGS[@]:1}")

    case "$SUBCOMMAND" in
        local|link|dev)
            cmd_local "${REMAINING_ARGS[@]}"
            ;;
        online|unlink|prod|remote)
            cmd_online "${REMAINING_ARGS[@]}"
            ;;
        status|check|info)
            cmd_status "${REMAINING_ARGS[@]}"
            ;;
        ls|list)
            cmd_ls "${REMAINING_ARGS[@]}"
            ;;
        help)
            print_help
            ;;
        *)
            error "未知子命令: $SUBCOMMAND"
            echo ""
            print_help
            exit 1
            ;;
    esac
}

main "$@"
