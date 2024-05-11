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
    @State private var xmarkGlowing = false
    @State private var infoGlowing = false
    @State private var showSettings = false
    @State private var isPopoverShowing = false
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: .leading, vertical: .top)) {
            ZStack {
                Color.clear
                    .background(.ultraThinMaterial)
                    .environment(\.controlActiveState, .active)
                    //.environment(\.colorScheme, .dark)
                HStack {
                    Spacer()
                    if #available(macOS 13, *) {
                        Button(action: {
                            appDelegate.closeMainWindow()
                            appDelegate.prepRecord(type: "audio", screens: SCContext.getSCDisplayWithMouse(), windows: nil, applications: nil)
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
                                appDelegate.showAreaSelector()
                                var currentDisplay = SCContext.getSCDisplayWithMouse()
                                mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .rightMouseDown, .leftMouseDown, .otherMouseDown]) { event in
                                    let display = SCContext.getSCDisplayWithMouse()
                                    if display != currentDisplay {
                                        currentDisplay = display
                                        for w in NSApplication.shared.windows.filter({ $0.title == "Area Selector".local || $0.title == "Start Recording".local}) { w.close() }
                                        appDelegate.showAreaSelector()
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
                        isPopoverShowing.toggle()
                    }, label: {
                        SelectorView(title: "Mobile Device".local, symbol: "apps.ipad")
                            .cornerRadius(8)
                    }).buttonStyle(.plain)
                        .popover(isPresented: $isPopoverShowing, arrowEdge: .bottom) { iDevicePopoverView() }
                    Divider().frame(height: 70)
                    Button(action: {
                        showSettings = true
                    }, label: {
                        SelectorView(title: "Preferences".local, symbol: "gearshape")
                            .cornerRadius(8)
                    })
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showSettings) {
                        SettingsView()
                    }
                    Spacer()
                }.padding([.top, .bottom], 10).padding([.leading, .trailing], 19.5)
            }
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
                .padding([.leading, .trailing, .top], 7)
            }
        }//.frame(width: 800)
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

extension AppDelegate {
    func closeMainWindow() { for w in NSApplication.shared.windows.filter({ $0.title == "QuickRecorder".local }) { w.close() } }
    
    func showAreaSelector() {
        guard let scDisplay = SCContext.getSCDisplayWithMouse() else { return }
        guard let screen = scDisplay.nsScreen else { return }
        let screenshotWindow = ScreenshotWindow(contentRect: screen.frame, styleMask: [], backing: .buffered, defer: false)
        screenshotWindow.title = "Area Selector".local
        //screenshotWindow.isReleasedWhenClosed = true
        screenshotWindow.orderFront(self)
        screenshotWindow.orderFrontRegardless()
        let wX = (screen.frame.width - 590) / 2 + screen.frame.minX
        let wY = screen.visibleFrame.minY + 70
        let contentView = NSHostingView(rootView: AreaSelector(screen: scDisplay))
        contentView.frame = NSRect(x: wX, y: wY, width: 590, height: 70)
        contentView.focusRingType = .none
        //areaPanel = NSWindow(contentRect: contentView.frame, styleMask: [.titled], backing: .buffered, defer: false)
        areaPanel.setFrame(contentView.frame, display: true)
        areaPanel.level = .screenSaver
        areaPanel.title = "Start Recording".local
        areaPanel.standardWindowButton(.closeButton)?.isHidden = true
        areaPanel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        areaPanel.standardWindowButton(.zoomButton)?.isHidden = true
        areaPanel.contentView = contentView
        areaPanel.titleVisibility = .hidden
        areaPanel.isReleasedWhenClosed = false
        areaPanel.titlebarAppearsTransparent = true
        areaPanel.isMovableByWindowBackground = true
        //areaPanel.setFrameOrigin(NSPoint(x: wX, y: wY))
        areaPanel.makeKeyAndOrderFront(self)
    }
    
    func createNewWindow(view: some View, title: String, random: Bool = false) {
        guard let screen = SCContext.getScreenWithMouse() else { return }
        var seed = 0.0
        if random { seed = CGFloat(Int(arc4random_uniform(401)) - 200) }
        let wX = (screen.frame.width - 780) / 2 + seed + screen.frame.minX
        let wY = (screen.frame.height - 555) / 2 + 100 + seed + screen.frame.minY
        var window = NSWindow()
        let contentView = NSHostingView(rootView: view)
        contentView.frame = NSRect(x: wX, y: wY, width: 780, height: 555)
        window = NSWindow(contentRect: contentView.frame, styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = title
        window.contentView = contentView
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
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
            return self.scaleEffect(0.79).padding(.leading, -4)
        } else {
            return self
        }
    }
}


/*#Preview {
    ContentView()
}
*/
