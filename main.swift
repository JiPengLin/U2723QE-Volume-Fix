import Foundation
import AVFoundation
import CoreAudio
import AppKit

// 1. 状态管理类
class BridgeState {
    var blackHoleID: AudioDeviceID = 0
    var dellID: AudioDeviceID = 0
    var volume: Float = 0.5
    let player = AVAudioPlayerNode()
    let outputEngine = AVAudioEngine()
    let inputEngine = AVAudioEngine()
}

// 2. 工具函数：获取设备 ID
func getDeviceID(named name: String) -> AudioDeviceID? {
    var propertyAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    var dataSize: UInt32 = 0
    AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize)
    var deviceIDs = [AudioDeviceID](repeating: 0, count: Int(dataSize) / MemoryLayout<AudioDeviceID>.size)
    AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize, &deviceIDs)
    for id in deviceIDs {
        var nameAddress = AudioObjectPropertyAddress(mSelector: kAudioDevicePropertyDeviceNameCFString, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var nameResult: Unmanaged<CFString>?
        var nameSize = UInt32(MemoryLayout<CFString?>.size)
        if AudioObjectGetPropertyData(id, &nameAddress, 0, nil, &nameSize, &nameResult) == noErr {
            let deviceName = (nameResult?.takeRetainedValue() as String?) ?? ""
            if deviceName.localizedCaseInsensitiveContains(name) { return id }
        }
    }
    return nil
}

func getCurrentDefaultOutputDevice() -> AudioDeviceID {
    var deviceID = kAudioObjectUnknown
    var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
    var propertyAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
    AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize, &deviceID)
    return deviceID
}

// 3. 核心：重连逻辑
func setupAudioLink(state: BridgeState) {
    print("正在初始化音频链路...")
    state.player.stop()
    state.inputEngine.stop()
    state.outputEngine.stop()
    
    // 刷新设备 ID
    if let bhID = getDeviceID(named: "BlackHole"), let dellID = getDeviceID(named: "U2723QE") {
        state.blackHoleID = bhID
        state.dellID = dellID
    }

    do {
        try state.outputEngine.outputNode.auAudioUnit.setDeviceID(state.dellID)
        try state.inputEngine.inputNode.auAudioUnit.setDeviceID(state.blackHoleID)
        
        state.outputEngine.attach(state.player)
        let outputFormat = state.outputEngine.outputNode.outputFormat(forBus: 0)
        state.outputEngine.connect(state.player, to: state.outputEngine.mainMixerNode, format: outputFormat)
        
        state.inputEngine.inputNode.removeTap(onBus: 0)
        state.inputEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: state.inputEngine.inputNode.inputFormat(forBus: 0)) { (buffer, time) in
            state.player.scheduleBuffer(buffer, completionHandler: nil)
        }
        
        try state.outputEngine.start()
        try state.inputEngine.start()
        state.player.play()
        state.player.volume = state.volume
        print("链路已就绪。物理输出 ID: \(state.dellID)")
    } catch {
        print("链路建立失败: \(error)")
    }
}

// 4. UI 提示：由于无法调用系统私有 HUD，我们发送一个简单的通知
func showVolumeNotification(volume: Float) {
    let percent = Int(volume * 100)
    let bar = String(repeating: "●", count: percent / 10) + String(repeating: "○", count: 10 - (percent / 10))
    // 可以在这里加一个打印或者调用通知中心
    print("\r音量: [\(bar)] \(percent)%    ", terminator: ""); fflush(stdout)
}

// 5. 键盘回调
func myEventTapCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    guard let refcon = refcon else { return Unmanaged.passRetained(event) }
    let state = Unmanaged<BridgeState>.fromOpaque(refcon).takeUnretainedValue()
    
    if getCurrentDefaultOutputDevice() != state.blackHoleID {
        return Unmanaged.passRetained(event) 
    }

    if let nsEvent = NSEvent(cgEvent: event), nsEvent.type == .systemDefined {
        let data1 = nsEvent.data1
        let keyCode = (data1 & 0xFFFF0000) >> 16
        if (((data1 & 0x0000FFFF) & 0xff00) >> 8) == 0x0a {
            switch keyCode {
            case 0: state.volume = min(state.volume + 0.0625, 1.0)
            case 1: state.volume = max(state.volume - 0.0625, 0.0)
            case 7, 16: state.volume = (state.player.volume > 0) ? 0 : state.volume
            default: return Unmanaged.passRetained(event)
            }
            state.player.volume = state.volume
            showVolumeNotification(volume: state.volume)
            return nil 
        }
    }
    return Unmanaged.passRetained(event)
}

// --- 主程序流程 ---
let bridgeState = BridgeState()

// 初始查找设备
guard let bhInitial = getDeviceID(named: "BlackHole"), 
      let dellInitial = getDeviceID(named: "U2723QE") else {
    print("未找到硬件，程序退出")
    exit(1)
}
bridgeState.blackHoleID = bhInitial
bridgeState.dellID = dellInitial

// 设置监听：当系统默认输出改变时触发
var propertyAddress = AudioObjectPropertyAddress(
    mSelector: kAudioHardwarePropertyDefaultOutputDevice,
    mScope: kAudioObjectPropertyScopeGlobal,
    mElement: kAudioObjectPropertyElementMain
)

// 将 bridgeState 包装成指针传给回调
let refcon = UnsafeMutableRawPointer(Unmanaged.passRetained(bridgeState).toOpaque())

AudioObjectAddPropertyListener(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, { _, _, _, clientData in
    guard let clientData = clientData else { return noErr }
    let state = Unmanaged<BridgeState>.fromOpaque(clientData).takeUnretainedValue()
    
    // 延迟 0.5 秒等待系统驱动握手完成
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        if getCurrentDefaultOutputDevice() == state.blackHoleID {
            setupAudioLink(state: state)
        }
    }
    return noErr
}, refcon)

// 键盘拦截设置
let eventMask = (1 << NX_SYSDEFINED)
guard let eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap, eventsOfInterest: CGEventMask(eventMask), callback: myEventTapCallback, userInfo: refcon) else {
    exit(1)
}
let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
CGEvent.tapEnable(tap: eventTap, enable: true)

// 初始运行
if getCurrentDefaultOutputDevice() == bridgeState.blackHoleID {
    setupAudioLink(state: bridgeState)
}

print("Dell 音频守护进程已启动。")
CFRunLoopRun()