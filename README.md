<p align="center">
  <strong><a href="README.md">简体中文</a></strong> | <strong><a href="README_en.md">English</a></strong>
</p>

---

# DSH 插件版本切换工具 (`dsh-plugin-switch`)

`dsh-plugin-switch` 是一个用于在开发 DSH 插件时，在 **本地源码开发版本 (`pnpm link`)** 与 **线上 NPM 发布版本 (`online`)** 之间快速、自由切换的命令行脚本工具。

---

## 核心特性

- 🔄 **双向自由切换**：支持一键在本地开发版本（`pnpm link`）与线上发布版本（`unlink` + `add`）之间无缝切换。
- 🔍 **智能目录识别**：支持直接在插件目录下运行自动识别当前项目，或通过路径指定，或直接传入插件名/包名在项目根目录下自动递归搜索。
- 🛠️ **自动构建支持**：提供 `--build` / `-b` 选项，在切换到本地链接前自动触发 `pnpm/yarn/npm run build`。
- 📊 **状态全面查看**：清晰展示插件模式（本地 LINK 还是线上 ONLINE）、链接指向的真实路径、已安装版本号、清单声明版本以及线上最新发布版本。
- 🌐 **多 Profile 适配**：支持 `-p / --profile` 参数，灵活适配不同的 DSH Profile 环境（默认 `web`）。

---

## 目录结构

- 主脚本: `switch-plugin.sh`
- 快捷软链接: `switch.sh` -> `switch-plugin.sh`

---

## 安装与配置

### 1. 配置全局快捷命令（推荐）

将脚本配置为全局别名，便于在任意终端路径下直接使用 `dsh-switch`：

```bash
# 方式 A：在 ~/.zshrc (或 ~/.bashrc) 中配置 alias
echo 'alias dsh-switch="/path/to/dsh-plugin-switch/switch.sh"' >> ~/.zshrc
source ~/.zshrc

# 方式 B：创建软链接到系统的 PATH 目录
ln -s /path/to/dsh-plugin-switch/switch.sh /usr/local/bin/dsh-switch
```

> **说明**：请将 `/path/to/dsh-plugin-switch` 替换为您本地存放本仓库的实际目录路径。

### 2. 环境变量（可选）

可以通过环境变量自定义默认行为：
- `DSH_PROJECTS_ROOT`：插件源码根目录，默认值为 `$HOME/dsh-projects`。使用包名切换时，脚本会在此目录下递归查找对应项目。
- `DSH_PROFILE`：默认 DSH Profile 名称，默认值为 `web`。

---

## 常用命令与示例

> 以下示例以配置了全局别名 `dsh-switch` 为例。若未配置别名，可直接用 `/path/to/switch.sh` 或 `./switch.sh` 代替。

### 1. 切换到本地开发版本 (`local` / `link` / `dev`)

- **方式 A：在插件项目目录下直接运行（自动识别当前项目）**
  ```bash
  cd /path/to/your-plugin
  dsh-switch local
  ```

- **方式 B：传入项目目录路径**
  ```bash
  dsh-switch local /path/to/your-plugin
  ```

- **方式 C：直接传入项目名或包名（自动在 `$DSH_PROJECTS_ROOT` 下递归查找）**
  ```bash
  dsh-switch local your-plugin-name
  # 或使用完整包名
  dsh-switch local @scope/your-plugin-name
  ```

- **带 `--build` 选项（链接前自动执行 `pnpm run build`）**
  ```bash
  dsh-switch local your-plugin-name --build
  ```

---

### 2. 切换回线上发布版本 (`online` / `unlink` / `prod`)

- **切换回最新线上版本 (`latest`)**
  ```bash
  dsh-switch online your-plugin-name
  ```

- **切换回线上指定版本**
  ```bash
  dsh-switch online your-plugin-name 1.0.0
  # 或使用 -v / --version 参数
  dsh-switch online your-plugin-name -v 1.0.0
  ```

---

### 3. 查看插件状态 (`status` / `check` / `info`)

- **查看指定插件详细状态**
  ```bash
  dsh-switch status your-plugin-name
  ```
  *输出包含：当前状态模式（本地 LINK 还是线上 ONLINE）、链接指向的本地真实路径、已安装版本号、清单声明版本、以及 NPM 线上最新版本号。*

- **查看当前 Profile 下所有插件的概览列表**
  ```bash
  dsh-switch status
  ```

---

### 4. 其它选项与命令

- **列出 Profile 已安装插件树**
  ```bash
  dsh-switch ls
  ```

- **指定 DSH Profile（默认是 `web`）**
  ```bash
  dsh-switch -p other-profile status
  ```

---

## 注意事项

切换插件版本后，建议刷新或重启 DSH Web GUI（如 `http://127.0.0.1:3080`），以确保最新的插件代码和资源加载生效。
