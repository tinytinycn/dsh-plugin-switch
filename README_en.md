<p align="center">
  <strong><a href="README.md">简体中文</a></strong> | <strong><a href="README_en.md">English</a></strong>
</p>

---

# DSH Plugin Switch (`dsh-plugin-switch`)

`dsh-plugin-switch` is a command-line utility for developers to switch seamlessly between **local source development versions (`pnpm link`)** and **published online NPM versions (`online`)** when developing DSH plugins.

---

## Features

- 🔄 **Bidirectional Switching**: Effortlessly toggle between local development links (`pnpm link`) and published online versions (`unlink` + `add`).
- 🔍 **Smart Project Discovery**: Automatically detects current directory when executed inside a plugin, supports explicit relative/absolute paths, or recursively locates matching projects under `$DSH_PROJECTS_ROOT` by package name or folder name.
- 🛠️ **Automatic Build**: Built-in `--build` / `-b` flag triggers `pnpm/yarn/npm run build` before linking.
- 📊 **Comprehensive Status Inspection**: Clear visibility into current plugin mode (local `LINK` vs remote `ONLINE`), actual filesystem destination, installed version, declared version in manifest, and the latest published version on NPM registry.
- 🌐 **Multi-Profile Support**: Easily target different DSH profiles via `-p / --profile` (defaults to `web`).

---

## Repository Structure

- Main script: `switch-plugin.sh`
- Convenient symlink: `switch.sh` -> `switch-plugin.sh`

---

## Installation & Setup

### 1. Configure Global Alias (Recommended)

Set up an alias in your shell configuration to run `dsh-switch` from any directory:

```bash
# Method A: Add an alias to ~/.zshrc (or ~/.bashrc)
echo 'alias dsh-switch="/path/to/dsh-plugin-switch/switch.sh"' >> ~/.zshrc
source ~/.zshrc

# Method B: Symlink to your system PATH
ln -s /path/to/dsh-plugin-switch/switch.sh /usr/local/bin/dsh-switch
```

> **Note**: Replace `/path/to/dsh-plugin-switch` with the actual path where this repository is located.

### 2. Environment Variables (Optional)

You can customize defaults via environment variables:
- `DSH_PROJECTS_ROOT`: Base search directory for local plugin projects. Defaults to `$HOME/dsh-projects`.
- `DSH_PROFILE`: Default DSH Profile name. Defaults to `web`.

---

## Common Commands & Usage

> The following examples assume you have configured the `dsh-switch` alias. If not, use `/path/to/switch.sh` or `./switch.sh` directly.

### 1. Switch to Local Development Version (`local` / `link` / `dev`)

- **Method A: Run directly inside the plugin directory (auto-detects project)**
  ```bash
  cd /path/to/your-plugin
  dsh-switch local
  ```

- **Method B: Pass the plugin directory path**
  ```bash
  dsh-switch local /path/to/your-plugin
  ```

- **Method C: Pass the plugin name or package name (searches under `$DSH_PROJECTS_ROOT`)**
  ```bash
  dsh-switch local your-plugin-name
  # Or use scoped package name
  dsh-switch local @scope/your-plugin-name
  ```

- **With `--build` option (automatically runs build before linking)**
  ```bash
  dsh-switch local your-plugin-name --build
  ```

---

### 2. Switch to Published Online Version (`online` / `unlink` / `prod`)

- **Switch to latest published version (`latest`)**
  ```bash
  dsh-switch online your-plugin-name
  ```

- **Switch to a specific published version**
  ```bash
  dsh-switch online your-plugin-name 1.0.0
  # Or use the -v / --version flag
  dsh-switch online your-plugin-name -v 1.0.0
  ```

---

### 3. Check Plugin Status (`status` / `check` / `info`)

- **Inspect detailed status for a specific plugin**
  ```bash
  dsh-switch status your-plugin-name
  ```
  *Output displays: mode (local LINK or remote ONLINE), resolved filesystem path, installed version, declared dependency version, and latest NPM registry version.*

- **Overview of all plugins installed in the current profile**
  ```bash
  dsh-switch status
  ```

---

### 4. Other Options & Commands

- **List installed plugins in the current profile**
  ```bash
  dsh-switch ls
  ```

- **Specify a DSH Profile (defaults to `web`)**
  ```bash
  dsh-switch -p other-profile status
  ```

---

## Notes

After switching a plugin version, remember to refresh or restart your DSH Web GUI (e.g. `http://127.0.0.1:3080`) to ensure updated plugin code and frontend assets are loaded.
