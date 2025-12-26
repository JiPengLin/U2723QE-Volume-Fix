# MonitorAudioBridge-macOS

[English](#english) | [中文](#chinese)

---

## 🇺🇸 English <a id="english"></a>

### 📜 Context (Why this exists)
The Dell U2723QE monitor uses the **MediaTek MT9800** controller. Its 3.5mm AUX jack gain is not mapped to the DDC/CI protocol. As a result, macOS locks the volume slider to 100% when outputting via DisplayPort/USB-C, making it impossible to adjust headphone volume using the keyboard. 

**Update v1.0.1**: This version fixes the "bridge drop" issue when switching monitor inputs (e.g., from HDMI back to Mac).

### ✨ Key Features
1.  **Digital Bridge**: Intercepts system audio using BlackHole and forwards it to the physical monitor.
2.  **Digital Gain**: Implements 0% - 100% volume scaling in code, bypassing the hardware lock.
3.  **Smart Pass-through**: Automatically detects the active output. When switching to devices like the SB521A Soundbar or internal speakers, the app releases control to native macOS logic.
4.  **Auto-Reconnect (v1.0.1)**: Features a 5-second heartbeat timer and listener to automatically restore the bridge when the monitor signal returns.
5.  **Low-Latency Performance**: Built with native Swift using manual buffer pumping; negligible CPU usage and no perceptible delay.

### 🛠 Installation Pipeline (Step-by-Step)

#### 1. Install Homebrew
Run in Terminal:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 2. Install BlackHole 2ch
```bash
brew install --cask blackhole-2ch
```

#### 3. Verify and Activate BlackHole
*   **Check**: Go to `System Settings -> Sound -> Output` and look for **BlackHole 2ch**.
*   **Force Activation**: If it doesn't appear, run: `sudo killall coreaudiod`
*   **Sample Rate Sync**: Open `Audio MIDI Setup`. Ensure both **DELL U2723QE** and **BlackHole 2ch** are set to the same sample rate (e.g., **48.0 kHz**).

#### 4. Prepare the Script
Download `main.swift` into your project folder.

#### 5. Confirm Device Names (Crucial)
In `main.swift` (around line 80), ensure names match your Sound Settings:
```swift
guard let bhID = getDeviceID(named: "BlackHole"), 
      let dellID = getDeviceID(named: "U2723QE") 
else { exit(1) }
```

#### 6. Compile the Program
```bash
swiftc main.swift -o DellAudioBridge
```

#### 7. Grant System Permissions
1.  **Launch once**: `./DellAudioBridge`
2.  **Microphone**: Check **Terminal** in `Privacy & Security -> Microphone`.
3.  **Accessibility**: Check **Terminal** in `Privacy & Security -> Accessibility`. (Toggle off/on if already checked).

#### 8. Automate (Background & Auto-start)
1.  **Wrap as App**: Open **Automator** -> New **Application**.
2.  **Action**: Select **Run Shell Script**.
3.  **Configure**: (⚠️ **Replace `YOUR_USERNAME` with your macOS username**):
    ```bash
    pkill -9 DellAudioBridge
    sleep 1
    /Users/YOUR_USERNAME/Project/AudioBridge/DellAudioBridge > /dev/null 2>&1 &
    ```
4.  **Save & Auto-start**: Save as `DellAudioFix.app` and add to `System Settings -> General -> Login Items`.

---

## 🇨🇳 中文 <a id="chinese"></a>

### 📜 项目前因
Dell U2723QE 显示器采用 **联发科 MT9800** 主控，其 3.5mm AUX 接口增益未映射至 DDC/CI 协议。这导致 macOS 在通过 DisplayPort/USB-C 输出音频时会锁死音量调节（置灰）。

**v1.0.1 更新**: 解决了显示器切换输入源（如 HDMI 切回 Mac）后桥接失效的问题。

### ✨ 核心功能
1.  **数字桥接**：利用 BlackHole 虚拟声卡拦截系统音频并转发至显示器。
2.  **数字增益**：在代码中实现 0% - 100% 音量缩放，绕过硬件锁定。
3.  **智能直通**：自动检测输出设备。当你切回 SB521A 音棒或内置扬声器时，程序自动释放键盘控制权，不干扰原生逻辑。
4.  **自动重连 (v1.0.1)**：引入 5 秒心跳检测，当显示器信号恢复后自动重新建立链路。
5.  **低延迟表现**：基于原生 Swift 编写，采用手动缓冲区搬运技术，CPU 占用极低且无感延迟。

### 🛠 操作流水线

#### 1. 安装 Homebrew
在终端执行：
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 2. 安装 BlackHole 2ch
```bash
brew install --cask blackhole-2ch
```

#### 3. 确认并激活 BlackHole
*   **检查**：在 `系统设置 -> 声音 -> 输出` 中查看是否有 **BlackHole 2ch**。
*   **强制激活**：若未出现，执行 `sudo killall coreaudiod`。
*   **采样率对齐**：打开 `音频 MIDI 设置`，确保 **DELL U2723QE** 和 **BlackHole 2ch** 采样率一致（推荐 **48.0 kHz**）。

#### 4. 准备脚本
下载 `main.swift` 到你的项目文件夹。

#### 5. 确认设备名称 (关键)
在 `main.swift`（约 80 行）确保名称匹配：
```swift
guard let bhID = getDeviceID(named: "BlackHole"), 
      let dellID = getDeviceID(named: "U2723QE") 
else { exit(1) }
```

#### 6. 编译程序
```bash
swiftc main.swift -o DellAudioBridge
```

#### 7. 授予系统权限
1.  **启动一次**：`./DellAudioBridge`
2.  **麦克风**：在 `隐私与安全性 -> 麦克风` 中勾选 **终端**。
3.  **辅助功能**：在 `隐私与安全性 -> 辅助功能` 中勾选 **终端**。（若已勾选，请先关再开以刷新权限）。

#### 8. 自动化（后台与开机自启）
1.  **封装 App**：打开 **自动操作 (Automator)** -> **应用程序**。
2.  **添加动作**：选择 **运行 Shell 脚本**。
3.  **配置** (⚠️ **请将 `YOUR_USERNAME` 替换为你的系统用户名**):
    ```bash
    pkill -9 DellAudioBridge
    sleep 1
    /Users/你的用户名/路径/DellAudioBridge > /dev/null 2>&1 &
    ```
4.  **保存自启**：保存为 `DellAudioFix.app` 并添加至 `系统设置 -> 通用 -> 登录项`。

---

## 📦 Pre-compiled Binary (Apple Silicon / M1, M2, M3, M4)
> **Recommended for non-technical users | 推荐普通用户使用**

**Notice for macOS Security / 安全说明:**
Since this app is not notarized, you will see a security warning. To bypass / 由于未经过苹果公证，系统会拦截运行，请执行：
1. Download from [Releases](https://github.com/JiPengLin/U2723QE-Volume-Fix/releases).
2. Run in Terminal / 在下载目录打开终端执行:
   ```bash
   chmod +x DellAudioBridge
   xattr -cr DellAudioBridge
   ```
3. Run via `./DellAudioBridge`.

*Note: This version will **NOT** work on Intel-based Macs. Intel users must compile from source using `swiftc`.*
---

### 🕹 Usage | 使用方法
*   **Headphone Mode**: Select **BlackHole 2ch** in Output. Use keyboard to adjust volume.
*   **音箱/耳机模式**: 在输出中选择 **BlackHole 2ch**，即可使用键盘调音。
*   **Soundbar Mode**: Select **DELL SB521A**. The app will allow native control.
*   **音棒模式**: 选择 **DELL SB521A**，程序自动直通，恢复原生控制。