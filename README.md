# U2723QE-Volume-Fix Setup Guide

### 📜 Context (Why this exists)
The Dell U2723QE monitor uses the **MediaTek MT9800** controller. Its 3.5mm AUX jack gain is not mapped to the DDC/CI protocol. As a result, macOS locks the volume slider to 100% when outputting via DisplayPort/USB-C, making it impossible to adjust headphone volume using the keyboard.

### ✨ Key Features
1. **Digital Bridge**: Intercepts system audio using BlackHole and forwards it to the physical monitor.
2. **Digital Gain**: Implements 0% - 100% volume scaling in code, bypassing the hardware lock.
3. **Smart Pass-through**: Automatically detects the active output. When switching to devices like the SB521A Soundbar or internal speakers, the app releases control to native macOS logic.
4. **Low-Latency Performance**: Built with native Swift using manual buffer pumping; negligible CPU usage and no perceptible delay.

---

### 🛠 Installation Pipeline (Step-by-Step)

#### 1. Install Homebrew
Open Terminal and run:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 2. Install BlackHole 2ch
Run the following command to install the virtual audio driver:
```bash
brew install --cask blackhole-2ch
```

#### 3. Verify and Activate BlackHole
*   **Check**: Go to `System Settings -> Sound -> Output` and look for **BlackHole 2ch**.
*   **Force Activation**: If it doesn't appear, run the following in Terminal:
    ```bash
    sudo killall coreaudiod
    ```
*   **Sample Rate Sync**: Open the `Audio MIDI Setup` app. Ensure both **DELL U2723QE** and **BlackHole 2ch** are set to the same sample rate (e.g., **48.0 kHz**).

#### 4. Prepare the Script
Create a file named `main.swift` in your project folder and paste the final "Smart Reconnect" version of the code.

#### 5. Confirm Device Names (Crucial)
Before compiling, ensure the strings in the `getDeviceID` function match your system's names exactly:
*   In `main.swift` (around line 80):
```swift
// Change "U2723QE" if your monitor appears with a different name in Sound Settings
guard let bhID = getDeviceID(named: "BlackHole"), 
      let dellID = getDeviceID(named: "U2723QE") 
else { exit(1) }
```

#### 6. Compile the Program
Run the compilation command:
```bash
swiftc main.swift -o DellAudioBridge
```

#### 7. Grant System Permissions
1.  **Launch the app once**: `./DellAudioBridge`
2.  **Microphone Permission**: You will see a yellow dot in the menu bar. Ensure **Terminal** is checked under `System Settings -> Privacy & Security -> Microphone`.
3.  **Accessibility Permission**: Go to `System Settings -> Privacy & Security -> Accessibility` and check **Terminal**. 
    *   *Note: If already checked, toggle it off and on again to refresh the permissions.*

#### 8. Automate (Background & Auto-start)
1.  **Wrap as an App**: Open **Automator** -> New **Application**.
2.  **Add Action**: Select **Run Shell Script** and enter:
    ```bash
    # Clean up old processes
    pkill DellAudioBridge
    sleep 1
    # Start the daemon silently (Replace with your actual absolute path)
    /Users/YOUR_USERNAME/Project/AudioBridge/DellAudioBridge > /dev/null 2>&1 &
    ```
3.  **Save**: Save as `DellAudioFix.app` in your Applications folder.
4.  **Auto-start**: Go to `System Settings -> General -> Login Items` and add this app to the list.

---

### 🕹 Usage
*   **Headphone Mode**: Select **BlackHole 2ch** in the Volume menu. Use your keyboard to control the volume.
*   **Soundbar Mode**: Select **DELL SB521A** (or other devices) in the Volume menu. The app will automatically step aside and allow native control.
