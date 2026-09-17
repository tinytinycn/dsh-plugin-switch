# DSH 插件版本切换脚本 (dsh-plugin-switch)

用于在开发 DSH 插件时，在 **本地源码开发版本 (`pnpm link`)** 与 **线上 NPM 发布版本 (`online`)** 之间快速、自由切换。

脚本路径:
- 主脚本: `/Users/tinytinycn/dsh-projects/test/switch-plugin.sh`
- 快捷软链接: `/Users/tinytinycn/dsh-projects/test/switch.sh`

---

## 常用命令与示例

### 1. 切换到本地开发版本 (`local`)

- **方式 A：在插件项目目录下直接运行（自动识别当前项目）**
  ```bash
  cd ~/dsh-projects/agy-spaces/dsh-agy-link-dev
  ~/dsh-projects/test/switch.sh local
  ```

- **方式 B：传入项目目录路径**
  ```bash
  ~/dsh-projects/test/switch.sh local ~/dsh-projects/agy-spaces/dsh-agy-link-dev
  ```

- **方式 C：直接传入项目名或包名（脚本会自动在 `~/dsh-projects` 下递归查找）**
  ```bash
  ~/dsh-projects/test/switch.sh local dsh-agy-link-dev
  # 或
  ~/dsh-projects/test/switch.sh local dsh-agy-link
  ```

- **带 `--build` 选项（链接前自动执行 `pnpm run build`）**
  ```bash
  ~/dsh-projects/test/switch.sh local dsh-agy-link-dev --build
  ```

---

### 2. 切换回线上发布版本 (`online`)

- **切换回最新线上版本 (`latest`)**
  ```bash
  ~/dsh-projects/test/switch.sh online dsh-agy-link
  ```

- **切换回线上指定版本**
  ```bash
  ~/dsh-projects/test/switch.sh online dsh-agy-link 0.4.32
  # 或
  ~/dsh-projects/test/switch.sh online dsh-agy-link -v 0.4.32
  ```

---

### 3. 查看插件状态 (`status`)

- **查看指定插件详细状态**
  ```bash
  ~/dsh-projects/test/switch.sh status dsh-agy-link
  ```
  *输出包含：当前状态模式（本地 LINK 还是线上 ONLINE）、链接指向的本地真实路径、已安装版本号、以及 NPM 线上最新版本号。*

- **查看当前 Profile 下所有插件的概览列表**
  ```bash
  ~/dsh-projects/test/switch.sh status
  ```

---

### 4. 其它选项与命令

- **指定 DSH Profile（默认是 `web`）**
  ```bash
  ~/dsh-projects/test/switch.sh -p web status
  ```

- **列出 Profile 已安装插件树**
  ```bash
  ~/dsh-projects/test/switch.sh ls
  ```

---

## 推荐：配置全局快捷命令

若希望在终端任意目录下直接使用 `dsh-switch` 命令，可在 `~/.zshrc` 中添加 alias：

```bash
echo 'alias dsh-switch="$HOME/dsh-projects/test/switch.sh"' >> ~/.zshrc
source ~/.zshrc
```

之后在任意插件目录直接执行即可：
```bash
dsh-switch local --build    # 切换当前目录插件为本地开发版并构建
dsh-switch online           # 切换回线上版本
dsh-switch status           # 查看状态
```
