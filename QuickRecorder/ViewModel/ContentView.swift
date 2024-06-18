//
//  ContentView.swift
//  QuickRecorder
//
//  Created by apple on 2024/4/16.
//

import SwiftUI
import AVFoundation
import ScreenCaptureKit

struct ContentView: View {
    var fromStatusBar = false
    @State private var xmarkGlowing = false
    @State private var infoGlowing = false
    //@State private var showSettings = false
    @State private var isPopoverShowing = false
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
            ZStack {
                if !fromStatusBar {
                    Color.clear
                        .background(.ultraThinMaterial)
                        .environment(\.controlActiveState, .active)
                        .cornerRadius(14)
                    //.environment(\.colorScheme, .dark)
                }
                HStack {
                    Spacer()
                    if #available(macOS 13, *) {
                        Button(action: {
                            appDelegate.closeMainWindow()
                            AppDelegate.shared.prepRecord(type: "audio", screens: SCContext.getSCDisplayWithMouse(), windows: nil, applications: nil)
                        }, label: {
                            SelectorView(title: "System Audio".local, symbol: "waveform")
                                .cornerRadius(8)
                        })
                        .buttonStyle(.plain)
                        Divider().frame(height: 70)
                    }
                    Button(action: {
                        appDelegate.closeMainWindow()
                        appDelegate.createNewWindow(view: ScreenSelector(), title: "Screen Selector".local)
                    }, label: {
                        SelectorView(title: "Screen".local, symbol: "tv.inset.filled")
                            .cornerRadius(8)
                    }).buttonStyle(.plain)
                    Divider().frame(height: 70)
                    Button(action: {
                        appDelegate.closeMainWindow()
                        SCContext.updateAvailableContent{
                            DispatchQueue.main.async {
                                appDelegate.showAreaSelector(size: NSSize(width: 600, height: 450))
                                var currentDisplay = SCContext.getSCDisplayWithMouse()
                                mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .rightMouseDown, .leftMouseDown, .otherMouseDown]) { event in
                                    let display = SCContext.getSCDisplayWithMouse()
                                    if display != currentDisplay {
                                        currentDisplay = display
                                        appDelegate.closeAllWindow()
                                        appDelegate.showAreaSelector(size: NSSize(width: 600, height: 450))
                                    }
                                }
                            }
                        }
                    }, label: {
                        SelectorView(title: "Screen Area".local, symbol: "viewfinder")
                            .cornerRadius(8)
                    })
                    .buttonStyle(.plain)
                    Divider().frame(height: 70)
                    Button(action: {
                        appDelegate.closeMainWindow()
                        appDelegate.createNewWindow(view: AppSelector(), title: "App Selector".local)
                    }, label: {
                        SelectorView(title: "Application".local, symbol: "app", overlayer: "App")
                            .cornerRadius(8)
                    }).buttonStyle(.plain)
                    Divider().frame(height: 70)
                    Button(action: {
                        appDelegate.closeMainWindow()
                        appDelegate.createNewWindow(view: WinSelector(), title: "Window Selector".local)
                    }, label: {
                        SelectorView(title: "Window".local, symbol: "macwindow")
                            .cornerRadius(8)
                    }).buttonStyle(.plain)
                    Divider().frame(height: 70)
                    Button(action: {
                        isPopoverShowing = true
                    }, label: {
                        SelectorView(title: "Mobile Device".local, symbol: "apps.ipad")
                            .cornerRadius(8)
                    }).buttonStyle(.plain)
                        .popover(isPresented: $isPopoverShowing, arrowEdge: .bottom) { iDevicePopoverView(closePopover: { isPopoverShowing = false })}
                    Divider().frame(height: 70)
                    Button(action: {
                        appDelegate.closeMainWindow()
                        appDelegate.openSettingPanel()
                        //if fromStatusBar { appDelegate.openSettingPanel() } else { showSettings = true }
                    }, label: {
                        SelectorView(title: "Preferences".local, symbol: "gearshape")
                            .cornerRadius(8)
                    })
                    .buttonStyle(.plain)
                    //.sheet(isPresented: $showSettings) { SettingsView() }
                    Spacer()
                }.padding([.top, .bottom], 10).padding([.leading, .trailing], 19.5)
            }
            if fromStatusBar {
                Button(action: {
                    NSApp.terminate(self)
                }, label: {
                    Text("Quit")
                        .font(.system(size: 8, weight: .bold))
                        .opacity(xmarkGlowing ? 1.0 : 0.4)
                        .foregroundStyle(.secondary)
                        .onHover{ hovering in xmarkGlowing = hovering }
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(.secondary.opacity(xmarkGlowing ? 1.0 : 0.4), lineWidth: 1)
                                .padding(-1).padding([.leading, .trailing], -0.7)
                        )
                })
                .buttonStyle(.plain)
                .padding([.leading, .top], 6.5)
            } else {
                if #available(macOS 14, *) {
                    Button(action: {
                        appDelegate.closeMainWindow()
                    }, label: {
                        Image(systemName: "x.circle")
                            .font(.system(size: 12, weight: .bold))
                            .opacity(xmarkGlowing ? 1.0 : 0.4)
                            .foregroundStyle(.secondary)
                            .onHover{ hovering in xmarkGlowing = hovering }
                    })
                    .buttonStyle(.plain)
                    .padding([.leading, .top], 6.5)
                }
            }
        }
        /*.overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .strokeBorder(.secondary.opacity(fromStatusBar ? 0.0 : 0.4), lineWidth: isMacOS14 ? 1.5 : 0.0)
        )*/
    }
    
    struct SelectorView: View {
        var title = "No Title".local
        var symbol = "app"
        var overlayer = ""
        @State private var backgroundOpacity = 0.0001
        
        var body: some View {
            VStack(spacing: 6) {
                Text(title)
                    .opacity(0.95)
                    .font(.system(size: 12))
                ZStack {
                    Image(systemName: symbol)
                        .opacity(0.95)
                        .font(.system(size: 36))
                    Text(overlayer)
                        .fontWeight(.bold)
                        .opacity(0.95)
                        .font(.system(size: 11))
                }
            }
            .frame(width: 110, height: 80)
            .onHover{ hovering in
                backgroundOpacity = hovering ? 0.2 : 0.0001
            }
            .background( .primary.opacity(backgroundOpacity) )
        }
    }
}

struct CountdownView: View {
    @State var countdownValue: Int = 00
    @State private var timer: Timer?
    var atEnd: () -> Void

    var body: some View {
        ZStack {
            Color("mypurple").environment(\.colorScheme, .dark)
            Text("\(countdownValue)")
                .font(.system(size: 72))
                .foregroundColor(.white)
                .offset(y: -10)
            Button(action: {
                timer?.invalidate()
                if let w = NSApp.windows.first(where: { $0.title == "Countdown Panel".local }) { w.close() }
            }, label: {
                ZStack {
                    Color.white.opacity(0.2)
                    Text("Cancel").foregroundColor(.white)
                }.frame(width: 120, height: 24)
            })
            .buttonStyle(.plain)
            .padding(.top, 96)
        }
        .frame(width: 120, height: 120)
        .cornerRadius(10)
        .onAppear{
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                if countdownValue > 1 {
                    countdownValue -= 1
                } else {
                    timer.invalidate()
                    if let w = NSApp.windows.first(where: { $0.title == "Countdown Panel".local }) { w.close() }
                    atEnd()
                }
            }
        }
    }
}


extension AppDelegate {
    
    func closeMainWindow() { for w in NSApplication.shared.windows.filter({ $0.title == "QuickRecorder".local }) { w.close() } }
    
    func closeAllWindow(except: String = "") { for w in NSApp.windows.filter({ $0.title != "Item-0" && $0.title != "" && $0.title != except }) { w.close() }}
    
    func showAreaSelector(size: NSSize, noPanel: Bool = false) {
        guard let scDisplay = SCContext.getSCDisplayWithMouse() else { return }
        guard let screen = scDisplay.nsScreen else { return }
        let screenshotWindow = ScreenshotWindow(contentRect: screen.frame, styleMask: [], backing: .buffered, defer: false, size: size, force: noPanel)
        screenshotWindow.title = "Area Selector".local
        screenshotWindow.orderFront(self)
        screenshotWindow.orderFrontRegardless()
        if !noPanel {
            let wX = (screen.frame.width - 700) / 2 + screen.frame.minX
            let wY = screen.visibleFrame.minY + 80
            let contentView = NSHostingView(rootView: AreaSelector(screen: scDisplay))
            contentView.frame = NSRect(x: wX, y: wY, width: 780, height: 110)
            contentView.focusRingType = .none
            let areaPanel = NSWindow(contentRect: contentView.frame, styleMask: [.fullSizeContentView], backing: .buffered, defer: false)
            areaPanel.setFrame(contentView.frame, display: true)
            areaPanel.level = .screenSaver
            areaPanel.title = "Start Recording".local
            areaPanel.contentView = contentView
            areaPanel.backgroundColor = .clear
            areaPanel.titleVisibility = .hidden
            areaPanel.isReleasedWhenClosed = false
            areaPanel.titlebarAppearsTransparent = true
            areaPanel.isMovableByWindowBackground = true
            //areaPanel.setFrameOrigin(NSPoint(x: wX, y: wY))
            areaPanel.orderFront(self)
        }
    }
    
    func createCountdownPanel(screen: SCDisplay, action: @escaping () -> Void) {
        guard let screen = screen.nsScreen else { return }
        let countdown = ud.integer(forKey: "countdown")
        if countdown == 0 {
            action()
        } else {
            let wX = (screen.frame.width - 120) / 2 + screen.frame.minX
            let wY = (screen.frame.height - 120) / 2 + screen.frame.minY
            let frame =  NSRect(x: wX, y: wY, width: 120, height: 120)
            let contentView = NSHostingView(rootView: CountdownView(countdownValue: countdown, atEnd: action))
            contentView.frame = frame
            countdownPanel.contentView = contentView
            countdownPanel.setFrame(frame, display: true)
            countdownPanel.makeKeyAndOrderFront(self)
        }
    }
    
    func createNewWindow(view: some View, title: String, random: Bool = false) {
        guard let screen = SCContext.getScreenWithMouse() else { return }
        closeAllWindow()
        var seed = 0.0
        if random { seed = CGFloat(Int(arc4random_uniform(401)) - 200) }
        let wX = (screen.frame.width - 780) / 2 + seed + screen.frame.minX
        let wY = (screen.frame.height - 555) / 2 + 100 + seed + screen.frame.minY
        let contentView = NSHostingView(rootView: view)
        contentView.frame = NSRect(x: wX, y: wY, width: 780, height: 555)
        let window = NSWindow(contentRect: contentView.frame, styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = title
        window.contentView = contentView
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(self)
        window.orderFrontRegardless()
    }

    func createAlert(title: String, message: String, button1: String, button2: String = "") -> NSAlert {
        let alert = NSAlert()
        alert.messageText = title.local
        alert.informativeText = message.local
        alert.addButton(withTitle: button1.local)
        if button2 != "" {
            alert.addButton(withTitle: button2.local)
        }
        alert.alertStyle = .critical
        return alert
    }
}

extension View {
    func needScale() -> some View {
        if #available(macOS 13, *) {
            return self.scaleEffect(0.8).padding(.leading, -4)
        } else {
            return self
        }
    }
}


/*#Preview {
    ContentView()
}
*/
