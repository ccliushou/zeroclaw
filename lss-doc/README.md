# 在当前机器交叉编译 ZeroClaw（aarch64 与 x86_64）

本说明记录如何在一台 x86_64 Linux 构建机上，同时构建适用于 Linux aarch64 与 Linux x86_64 的 ZeroClaw 二进制，并打包生成可分发的 tar.gz 产物。

## 先决条件

- 系统依赖（Debian/Ubuntu）
  - `sudo apt-get update && sudo apt-get install -y build-essential pkg-config git libssl-dev`
- Rust 工具链
  - `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`
  - `source $HOME/.cargo/env`
- 交叉编译工具链（用于 aarch64）
  - `sudo apt-get install -y gcc-aarch64-linux-gnu g++-aarch64-linux-gnu libc6-dev-arm64-cross`

## 快速开始：一键脚本

在仓库根目录执行：

```bash
bash lss-doc/build-cross.sh
```

脚本会：
- 自动添加所需 Rust 目标（`aarch64-unknown-linux-gnu`、`x86_64-unknown-linux-gnu`）
- 使用系统 `aarch64-linux-gnu-gcc` 作为链接器构建 aarch64 版本
- 构建 x86_64 版本
- 将两种架构的可执行文件分别打包为 tar.gz 并计算 SHA256
- 默认产出目录：`dist/`

默认输出文件与校验：
- `dist/zeroclaw-aarch64-unknown-linux-gnu.tar.gz`
- `dist/zeroclaw-aarch64-unknown-linux-gnu.tar.gz.sha256`
- `dist/zeroclaw-x86_64-unknown-linux-gnu.tar.gz`
- `dist/zeroclaw-x86_64-unknown-linux-gnu.tar.gz.sha256`

### 可选参数（通过环境变量）
- `FEATURES`：启用的特性列表（逗号分隔），例如：
  - `FEATURES="hardware,peripheral-rpi" bash lss-doc/build-cross.sh`
- `PROFILE`：Cargo 构建 Profile（默认 `release`），例如：
  - `PROFILE=release-fast bash lss-doc/build-cross.sh`
- `OUTDIR`：产物输出目录（默认 `dist`），例如：
  - `OUTDIR=/tmp/zc-out bash lss-doc/build-cross.sh`

## 手动构建（不使用脚本）

添加目标：
```bash
rustup target add aarch64-unknown-linux-gnu
rustup target add x86_64-unknown-linux-gnu
```

构建 aarch64（使用系统交叉链接器）：
```bash
CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc \
CC_aarch64_unknown_linux_gnu=aarch64-linux-gnu-gcc \
CXX_aarch64_unknown_linux_gnu=aarch64-linux-gnu-g++ \
cargo build --target aarch64-unknown-linux-gnu --release
```

构建 x86_64：
```bash
cargo build --target x86_64-unknown-linux-gnu --release
```

打包与校验（示例）：
```bash
tar -C target/aarch64-unknown-linux-gnu/release -czf zeroclaw-aarch64-unknown-linux-gnu.tar.gz zeroclaw
sha256sum zeroclaw-aarch64-unknown-linux-gnu.tar.gz > zeroclaw-aarch64-unknown-linux-gnu.tar.gz.sha256

tar -C target/x86_64-unknown-linux-gnu/release -czf zeroclaw-x86_64-unknown-linux-gnu.tar.gz zeroclaw
sha256sum zeroclaw-x86_64-unknown-linux-gnu.tar.gz > zeroclaw-x86_64-unknown-linux-gnu.tar.gz.sha256
```

## 在目标设备上验证

上传并解压：
```bash
scp dist/zeroclaw-aarch64-unknown-linux-gnu.tar.gz user@host:/opt/zeroclaw/
ssh user@host 'cd /opt/zeroclaw && tar xzf zeroclaw-aarch64-unknown-linux-gnu.tar.gz && chmod +x zeroclaw'
```

基本检查：
```bash
file /opt/zeroclaw/zeroclaw
/opt/zeroclaw/zeroclaw --help
```

首次初始化（可选）：
```bash
/opt/zeroclaw/zeroclaw onboard
```

直接运行：
```bash
/opt/zeroclaw/zeroclaw agent
```

## 说明

- 产物为 GNU glibc 动态链接版本，适配常见 Linux 发行版；如需进一步兼容性（如 musl 静态版），可扩展脚本为 `*-unknown-linux-musl` 目标。
- 若需要硬件相关能力（GPIO/串口等），请通过 `FEATURES` 启用相应特性，例如：`hardware,peripheral-rpi`。

