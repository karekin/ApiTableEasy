# APITable 多端扩展技术方案

## 📋 文档信息

- **项目名称**: APITable 多端扩展
- **版本**: v1.0.0
- **创建日期**: 2025-10-03
- **作者**: 技术团队
- **状态**: 方案设计

---

## 🎯 一、方案概述

### 1.1 项目目标

将现有的 APITable Web 项目扩展为支持以下平台：
- ✅ **Web端** (现有)
- 🖥️ **桌面端** (Windows、macOS、Linux)
- 📱 **移动端** (iOS、Android)

### 1.2 技术选型

| 平台 | 技术方案 | 优势 |
|------|----------|------|
| Web | Next.js + React | 现有方案，保持不变 |
| 桌面端 | Electron | 跨平台、Web技术栈、原生功能丰富 |
| 移动端 | WebView (iOS/Android) + PWA | 低成本、快速上线、复用现有代码 |

### 1.3 架构设计原则

- **代码复用最大化**: 核心业务逻辑共享
- **平台特性适配**: 针对不同平台优化体验
- **渐进式开发**: 分阶段实施，降低风险
- **性能优先**: 保证用户体验
- **可维护性**: 统一技术栈，降低维护成本

---

## 🏗️ 二、整体架构设计

### 2.1 项目结构

```
apitable-multi-platform/
├── packages/
│   ├── core/                    # 核心业务逻辑 (共享)
│   ├── components/              # 共享组件库
│   ├── web/                     # Web应用 (现有datasheet)
│   ├── desktop/                 # 桌面端应用 (Electron)
│   │   ├── electron/
│   │   │   ├── main/           # 主进程
│   │   │   ├── preload/        # 预加载脚本
│   │   │   └── renderer/       # 渲染进程
│   │   └── src/                # 桌面端特定代码
│   ├── mobile/                  # 移动端应用
│   │   ├── ios/                # iOS原生壳
│   │   ├── android/            # Android原生壳
│   │   └── shared/             # 移动端共享代码
│   └── shared/                  # 跨平台共享工具
│       ├── bridge/             # 原生桥接
│       ├── storage/            # 存储适配器
│       └── network/            # 网络适配器
├── scripts/                     # 构建脚本
├── docs/                        # 文档
└── package.json
```

### 2.2 架构图

```
┌─────────────────────────────────────────────────────────┐
│                    用户层                                │
├───────────┬──────────────┬──────────────┬──────────────┤
│  Web端    │  桌面端       │  iOS端       │  Android端    │
│  (Browser)│  (Electron)   │  (WebView)   │  (WebView)   │
└───────────┴──────────────┴──────────────┴──────────────┘
            │              │              │              │
            └──────────────┴──────────────┴──────────────┘
                              │
┌─────────────────────────────────────────────────────────┐
│                 平台适配层                               │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐   │
│  │Web API  │  │Electron │  │iOS      │  │Android  │   │
│  │Adapter  │  │Bridge   │  │Bridge   │  │Bridge   │   │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘   │
└─────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────┐
│                 业务逻辑层                               │
│  ┌────────────────────────────────────────────────┐    │
│  │         @apitable/core (核心业务逻辑)           │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐     │    │
│  │  │DataBus   │  │Command   │  │Formula   │     │    │
│  │  │Manager   │  │Manager   │  │Parser    │     │    │
│  │  └──────────┘  └──────────┘  └──────────┘     │    │
│  └────────────────────────────────────────────────┘    │
│  ┌────────────────────────────────────────────────┐    │
│  │       @apitable/components (共享组件库)         │    │
│  └────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────┐
│                 数据服务层                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐             │
│  │Backend   │  │Room      │  │Databus   │             │
│  │Server    │  │Server    │  │Server    │             │
│  └──────────┘  └──────────┘  └──────────┘             │
└─────────────────────────────────────────────────────────┘
```

---

## 🖥️ 三、桌面端开发方案 (Electron)

### 3.1 技术栈

- **框架**: Electron 28+
- **渲染进程**: React 18.2.0 + Next.js
- **主进程**: Node.js
- **IPC通信**: electron-ipc
- **打包工具**: electron-builder

### 3.2 开发步骤

#### 步骤1: 项目初始化 (1-2天)

```bash
# 创建桌面端目录
mkdir -p packages/desktop/electron
cd packages/desktop

# 初始化项目
npm init -y

# 安装依赖
npm install electron electron-builder electron-store
npm install --save-dev @types/node concurrently wait-on
```

**package.json 配置**:
```json
{
  "name": "@apitable/desktop",
  "version": "1.0.0",
  "main": "electron/main/index.js",
  "scripts": {
    "dev": "concurrently \"npm run dev:web\" \"npm run dev:electron\"",
    "dev:web": "cd ../web && npm run dev",
    "dev:electron": "wait-on http://localhost:3000 && electron .",
    "build": "npm run build:web && npm run build:electron",
    "build:web": "cd ../web && npm run build",
    "build:electron": "electron-builder",
    "dist": "npm run build && electron-builder --publish never"
  },
  "build": {
    "appId": "com.apitable.desktop",
    "productName": "APITable Desktop",
    "directories": {
      "output": "dist",
      "buildResources": "resources"
    },
    "files": [
      "electron/**/*",
      "../web/out/**/*"
    ],
    "mac": {
      "category": "public.app-category.productivity",
      "target": ["dmg", "zip"]
    },
    "win": {
      "target": ["nsis", "portable"]
    },
    "linux": {
      "target": ["AppImage", "deb"]
    }
  }
}
```

#### 步骤2: 主进程开发 (3-5天)

**electron/main/index.js**:
```javascript
const { app, BrowserWindow, ipcMain, dialog, Menu, Tray } = require('electron');
const path = require('path');
const Store = require('electron-store');

// 初始化配置存储
const store = new Store();

class DesktopApp {
  constructor() {
    this.mainWindow = null;
    this.tray = null;
    
    this.init();
  }
  
  init() {
    // 应用生命周期
    app.whenReady().then(() => {
      this.createWindow();
      this.createTray();
      this.setupIPC();
      this.setupMenu();
    });
    
    app.on('window-all-closed', () => {
      if (process.platform !== 'darwin') {
        app.quit();
      }
    });
    
    app.on('activate', () => {
      if (BrowserWindow.getAllWindows().length === 0) {
        this.createWindow();
      }
    });
  }
  
  createWindow() {
    this.mainWindow = new BrowserWindow({
      width: 1400,
      height: 900,
      minWidth: 1024,
      minHeight: 768,
      webPreferences: {
        nodeIntegration: false,
        contextIsolation: true,
        preload: path.join(__dirname, '../preload/index.js'),
        webSecurity: true,
        allowRunningInsecureContent: false
      },
      titleBarStyle: 'hiddenInset',
      frame: process.platform !== 'darwin',
      backgroundColor: '#ffffff'
    });
    
    // 加载应用
    if (process.env.NODE_ENV === 'development') {
      this.mainWindow.loadURL('http://localhost:3000');
      this.mainWindow.webContents.openDevTools();
    } else {
      this.mainWindow.loadFile(path.join(__dirname, '../../web/out/index.html'));
    }
    
    // 窗口事件
    this.mainWindow.on('closed', () => {
      this.mainWindow = null;
    });
  }
  
  createTray() {
    this.tray = new Tray(path.join(__dirname, '../../resources/icon.png'));
    
    const contextMenu = Menu.buildFromTemplate([
      { 
        label: '显示窗口', 
        click: () => this.mainWindow?.show() 
      },
      { type: 'separator' },
      { 
        label: '退出', 
        click: () => app.quit() 
      }
    ]);
    
    this.tray.setContextMenu(contextMenu);
    this.tray.setToolTip('APITable Desktop');
  }
  
  setupMenu() {
    const template = [
      {
        label: 'File',
        submenu: [
          {
            label: 'New Window',
            accelerator: 'CmdOrCtrl+N',
            click: () => this.createWindow()
          },
          { type: 'separator' },
          {
            label: 'Exit',
            accelerator: 'CmdOrCtrl+Q',
            click: () => app.quit()
          }
        ]
      },
      {
        label: 'Edit',
        submenu: [
          { role: 'undo' },
          { role: 'redo' },
          { type: 'separator' },
          { role: 'cut' },
          { role: 'copy' },
          { role: 'paste' }
        ]
      },
      {
        label: 'View',
        submenu: [
          { role: 'reload' },
          { role: 'forceReload' },
          { role: 'toggleDevTools' },
          { type: 'separator' },
          { role: 'resetZoom' },
          { role: 'zoomIn' },
          { role: 'zoomOut' }
        ]
      },
      {
        label: 'Help',
        submenu: [
          {
            label: 'Documentation',
            click: async () => {
              const { shell } = require('electron');
              await shell.openExternal('https://help.apitable.com');
            }
          }
        ]
      }
    ];
    
    const menu = Menu.buildFromTemplate(template);
    Menu.setApplicationMenu(menu);
  }
  
  setupIPC() {
    // 文件操作
    ipcMain.handle('dialog:openFile', async () => {
      const result = await dialog.showOpenDialog(this.mainWindow, {
        properties: ['openFile'],
        filters: [
          { name: 'Excel Files', extensions: ['xlsx', 'xls'] },
          { name: 'CSV Files', extensions: ['csv'] },
          { name: 'All Files', extensions: ['*'] }
        ]
      });
      return result;
    });
    
    ipcMain.handle('dialog:saveFile', async (event, defaultPath) => {
      const result = await dialog.showSaveDialog(this.mainWindow, {
        defaultPath,
        filters: [
          { name: 'Excel Files', extensions: ['xlsx'] },
          { name: 'CSV Files', extensions: ['csv'] }
        ]
      });
      return result;
    });
    
    // 系统通知
    ipcMain.handle('notification:show', async (event, { title, body, icon }) => {
      const { Notification } = require('electron');
      new Notification({
        title,
        body,
        icon: icon || path.join(__dirname, '../../resources/icon.png')
      }).show();
    });
    
    // 配置存储
    ipcMain.handle('store:get', async (event, key) => {
      return store.get(key);
    });
    
    ipcMain.handle('store:set', async (event, key, value) => {
      store.set(key, value);
      return true;
    });
    
    // 窗口控制
    ipcMain.handle('window:minimize', () => {
      this.mainWindow?.minimize();
    });
    
    ipcMain.handle('window:maximize', () => {
      if (this.mainWindow?.isMaximized()) {
        this.mainWindow.unmaximize();
      } else {
        this.mainWindow?.maximize();
      }
    });
    
    ipcMain.handle('window:close', () => {
      this.mainWindow?.close();
    });
  }
}

// 启动应用
new DesktopApp();
```

#### 步骤3: 预加载脚本 (1天)

**electron/preload/index.js**:
```javascript
const { contextBridge, ipcRenderer } = require('electron');

// 暴露安全的API给渲染进程
contextBridge.exposeInMainWorld('electronAPI', {
  // 平台信息
  platform: process.platform,
  
  // 文件操作
  openFile: () => ipcRenderer.invoke('dialog:openFile'),
  saveFile: (defaultPath) => ipcRenderer.invoke('dialog:saveFile', defaultPath),
  
  // 系统通知
  showNotification: (options) => ipcRenderer.invoke('notification:show', options),
  
  // 配置存储
  getConfig: (key) => ipcRenderer.invoke('store:get', key),
  setConfig: (key, value) => ipcRenderer.invoke('store:set', key, value),
  
  // 窗口控制
  minimizeWindow: () => ipcRenderer.invoke('window:minimize'),
  maximizeWindow: () => ipcRenderer.invoke('window:maximize'),
  closeWindow: () => ipcRenderer.invoke('window:close'),
  
  // 事件监听
  on: (channel, callback) => {
    ipcRenderer.on(channel, (event, ...args) => callback(...args));
  },
  
  // 移除监听
  off: (channel, callback) => {
    ipcRenderer.removeListener(channel, callback);
  }
});
```

#### 步骤4: 渲染进程适配 (2-3天)

**packages/shared/platform/electron-adapter.ts**:
```typescript
// Electron平台适配器
export class ElectronAdapter {
  private electronAPI: any;
  
  constructor() {
    this.electronAPI = (window as any).electronAPI;
  }
  
  isElectron(): boolean {
    return !!this.electronAPI;
  }
  
  async openFile(): Promise<string[]> {
    if (!this.isElectron()) return [];
    
    const result = await this.electronAPI.openFile();
    if (!result.canceled) {
      return result.filePaths;
    }
    return [];
  }
  
  async saveFile(defaultPath: string): Promise<string | null> {
    if (!this.isElectron()) return null;
    
    const result = await this.electronAPI.saveFile(defaultPath);
    if (!result.canceled) {
      return result.filePath;
    }
    return null;
  }
  
  async showNotification(title: string, body: string): Promise<void> {
    if (!this.isElectron()) {
      // 降级到Web Notification
      if ('Notification' in window && Notification.permission === 'granted') {
        new Notification(title, { body });
      }
      return;
    }
    
    await this.electronAPI.showNotification({ title, body });
  }
  
  async getConfig(key: string): Promise<any> {
    if (!this.isElectron()) {
      return localStorage.getItem(key);
    }
    return await this.electronAPI.getConfig(key);
  }
  
  async setConfig(key: string, value: any): Promise<void> {
    if (!this.isElectron()) {
      localStorage.setItem(key, JSON.stringify(value));
      return;
    }
    await this.electronAPI.setConfig(key, value);
  }
}

export const electronAdapter = new ElectronAdapter();
```

#### 步骤5: Web应用集成 (1-2天)

**packages/web/src/hooks/use-platform.ts**:
```typescript
import { useEffect, useState } from 'react';
import { electronAdapter } from '@apitable/shared/platform/electron-adapter';

export function usePlatform() {
  const [platform, setPlatform] = useState<'web' | 'electron'>('web');
  
  useEffect(() => {
    if (electronAdapter.isElectron()) {
      setPlatform('electron');
    }
  }, []);
  
  return {
    isElectron: platform === 'electron',
    isWeb: platform === 'web',
    adapter: electronAdapter
  };
}
```

**packages/web/src/components/FileUpload.tsx**:
```typescript
import { usePlatform } from '@/hooks/use-platform';

export function FileUpload() {
  const { isElectron, adapter } = usePlatform();
  
  const handleFileSelect = async () => {
    if (isElectron) {
      // Electron原生文件选择
      const files = await adapter.openFile();
      console.log('Selected files:', files);
    } else {
      // Web文件选择
      const input = document.createElement('input');
      input.type = 'file';
      input.click();
    }
  };
  
  return (
    <button onClick={handleFileSelect}>
      选择文件
    </button>
  );
}
```

---

## 📱 四、移动端开发方案 (WebView)

### 4.1 技术栈

- **iOS**: Swift + WKWebView
- **Android**: Kotlin + WebView
- **通信**: JavaScript Bridge
- **PWA**: 作为备选方案

### 4.2 iOS开发

#### 步骤1: 项目创建 (1天)

```bash
# 使用Xcode创建新项目
# 选择: iOS App
# 语言: Swift
# UI: Storyboard
```

#### 步骤2: WebView集成 (2-3天)

**ViewController.swift**:
```swift
import UIKit
import WebKit

class MainViewController: UIViewController {
    
    var webView: WKWebView!
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    override func loadView() {
        let config = WKWebViewConfiguration()
        
        // 配置UserContentController
        let contentController = WKUserContentController()
        contentController.add(self, name: "nativeBridge")
        config.userContentController = contentController
        
        // 配置WebView偏好设置
        config.preferences.javaScriptEnabled = true
        config.allowsInlineMediaPlayback = true
        
        // 创建WebView
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLoadingIndicator()
        loadWebApp()
    }
    
    private func setupLoadingIndicator() {
        loadingIndicator.center = view.center
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
    }
    
    private func loadWebApp() {
        loadingIndicator.startAnimating()
        
        #if DEBUG
        let url = URL(string: "http://localhost:3000")!
        #else
        let url = URL(string: "https://your-apitable-domain.com")!
        #endif
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
}

// MARK: - WKNavigationDelegate
extension MainViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingIndicator.stopAnimating()
        
        // 注入JavaScript，暴露原生功能
        let script = """
        window.nativeApp = {
            platform: 'ios',
            version: '\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")',
            
            uploadFile: function() {
                window.webkit.messageHandlers.nativeBridge.postMessage({
                    action: 'uploadFile'
                });
            },
            
            showNotification: function(title, body) {
                window.webkit.messageHandlers.nativeBridge.postMessage({
                    action: 'showNotification',
                    data: { title: title, body: body }
                });
            },
            
            share: function(content) {
                window.webkit.messageHandlers.nativeBridge.postMessage({
                    action: 'share',
                    data: { content: content }
                });
            },
            
            getConfig: function(key) {
                return new Promise((resolve) => {
                    const callbackId = Date.now();
                    window['_callback_' + callbackId] = resolve;
                    
                    window.webkit.messageHandlers.nativeBridge.postMessage({
                        action: 'getConfig',
                        data: { key: key },
                        callbackId: callbackId
                    });
                });
            },
            
            setConfig: function(key, value) {
                window.webkit.messageHandlers.nativeBridge.postMessage({
                    action: 'setConfig',
                    data: { key: key, value: value }
                });
            }
        };
        """
        
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadingIndicator.stopAnimating()
        showError(message: "加载失败: \(error.localizedDescription)")
    }
}

// MARK: - WKScriptMessageHandler
extension MainViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, 
                              didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let action = body["action"] as? String else {
            return
        }
        
        let data = body["data"] as? [String: Any]
        let callbackId = body["callbackId"] as? Int
        
        switch action {
        case "uploadFile":
            handleFileUpload(callbackId: callbackId)
        case "showNotification":
            handleNotification(data: data)
        case "share":
            handleShare(data: data)
        case "getConfig":
            handleGetConfig(data: data, callbackId: callbackId)
        case "setConfig":
            handleSetConfig(data: data)
        default:
            print("Unknown action: \(action)")
        }
    }
    
    private func handleFileUpload(callbackId: Int?) {
        let picker = UIDocumentPickerViewController(
            documentTypes: ["public.item"],
            in: .import
        )
        picker.delegate = self
        picker.allowsMultipleSelection = false
        
        present(picker, animated: true)
    }
    
    private func handleNotification(data: [String: Any]?) {
        guard let title = data?["title"] as? String,
              let body = data?["body"] as? String else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func handleShare(data: [String: Any]?) {
        guard let content = data?["content"] as? String else {
            return
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [content],
            applicationActivities: nil
        )
        
        present(activityVC, animated: true)
    }
    
    private func handleGetConfig(data: [String: Any]?, callbackId: Int?) {
        guard let key = data?["key"] as? String,
              let callbackId = callbackId else {
            return
        }
        
        let value = UserDefaults.standard.string(forKey: key) ?? ""
        
        let script = "window['_callback_\(callbackId)']('\(value)');"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
    
    private func handleSetConfig(data: [String: Any]?) {
        guard let key = data?["key"] as? String,
              let value = data?["value"] else {
            return
        }
        
        UserDefaults.standard.set(value, forKey: key)
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(
            title: "错误",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate
extension MainViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, 
                       didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        // 将文件路径传递给WebView
        let script = """
        if (window.onFileSelected) {
            window.onFileSelected('\(url.path)');
        }
        """
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
}
```

### 4.3 Android开发

#### 步骤1: 项目创建 (1天)

```kotlin
// 使用Android Studio创建新项目
// 语言: Kotlin
// 最低SDK: API 24 (Android 7.0)
```

#### 步骤2: WebView集成 (2-3天)

**MainActivity.kt**:
```kotlin
package com.apitable.mobile

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.webkit.*
import android.widget.ProgressBar
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import org.json.JSONObject

class MainActivity : AppCompatActivity() {
    
    private lateinit var webView: WebView
    private lateinit var progressBar: ProgressBar
    private var filePathCallback: ValueCallback<Array<Uri>>? = null
    
    companion object {
        private const val FILE_CHOOSER_REQUEST = 1
        private const val PERMISSION_REQUEST = 2
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        webView = findViewById(R.id.webView)
        progressBar = findViewById(R.id.progressBar)
        
        setupWebView()
        loadWebApp()
        requestPermissions()
    }
    
    private fun setupWebView() {
        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            databaseEnabled = true
            allowFileAccess = true
            allowContentAccess = true
            loadWithOverviewMode = true
            useWideViewPort = true
            setSupportZoom(true)
            builtInZoomControls = true
            displayZoomControls = false
            cacheMode = WebSettings.LOAD_DEFAULT
            mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
        }
        
        // 添加JavaScript接口
        webView.addJavascriptInterface(NativeBridge(this), "nativeBridge")
        
        webView.webViewClient = object : WebViewClient() {
            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                progressBar.visibility = ProgressBar.GONE
                injectJavaScript()
            }
            
            override fun onReceivedError(
                view: WebView?,
                request: WebResourceRequest?,
                error: WebResourceError?
            ) {
                super.onReceivedError(view, request, error)
                // 显示错误页面
            }
        }
        
        webView.webChromeClient = object : WebChromeClient() {
            override fun onProgressChanged(view: WebView?, newProgress: Int) {
                progressBar.progress = newProgress
            }
            
            override fun onShowFileChooser(
                webView: WebView?,
                filePathCallback: ValueCallback<Array<Uri>>?,
                fileChooserParams: FileChooserParams?
            ): Boolean {
                this@MainActivity.filePathCallback = filePathCallback
                
                val intent = Intent(Intent.ACTION_GET_CONTENT)
                intent.type = "*/*"
                intent.addCategory(Intent.CATEGORY_OPENABLE)
                
                startActivityForResult(
                    Intent.createChooser(intent, "选择文件"),
                    FILE_CHOOSER_REQUEST
                )
                
                return true
            }
        }
    }
    
    private fun loadWebApp() {
        progressBar.visibility = ProgressBar.VISIBLE
        
        val url = if (BuildConfig.DEBUG) {
            "http://10.0.2.2:3000" // Android模拟器访问本地服务器
        } else {
            "https://your-apitable-domain.com"
        }
        
        webView.loadUrl(url)
    }
    
    private fun injectJavaScript() {
        val script = """
        (function() {
            window.nativeApp = {
                platform: 'android',
                version: '${BuildConfig.VERSION_NAME}',
                
                uploadFile: function() {
                    nativeBridge.uploadFile();
                },
                
                showNotification: function(title, body) {
                    nativeBridge.showNotification(JSON.stringify({
                        title: title,
                        body: body
                    }));
                },
                
                share: function(content) {
                    nativeBridge.share(content);
                },
                
                getConfig: function(key) {
                    return new Promise((resolve) => {
                        const value = nativeBridge.getConfig(key);
                        resolve(value);
                    });
                },
                
                setConfig: function(key, value) {
                    nativeBridge.setConfig(key, value);
                }
            };
            
            // 通知WebApp原生环境已准备好
            if (window.onNativeReady) {
                window.onNativeReady();
            }
        })();
        """
        
        webView.evaluateJavascript(script, null)
    }
    
    private fun requestPermissions() {
        val permissions = arrayOf(
            Manifest.permission.READ_EXTERNAL_STORAGE,
            Manifest.permission.WRITE_EXTERNAL_STORAGE,
            Manifest.permission.CAMERA
        )
        
        val notGranted = permissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
        
        if (notGranted.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                this,
                notGranted.toTypedArray(),
                PERMISSION_REQUEST
            )
        }
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        when (requestCode) {
            FILE_CHOOSER_REQUEST -> {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    filePathCallback?.onReceiveValue(
                        arrayOf(data.data ?: Uri.EMPTY)
                    )
                } else {
                    filePathCallback?.onReceiveValue(null)
                }
                filePathCallback = null
            }
        }
    }
    
    override fun onBackPressed() {
        if (webView.canGoBack()) {
            webView.goBack()
        } else {
            super.onBackPressed()
        }
    }
}

// JavaScript接口
class NativeBridge(private val activity: MainActivity) {
    
    @JavascriptInterface
    fun uploadFile() {
        // 文件上传逻辑
    }
    
    @JavascriptInterface
    fun showNotification(json: String) {
        try {
            val data = JSONObject(json)
            val title = data.getString("title")
            val body = data.getString("body")
            
            // 显示通知
            // 实现略
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    @JavascriptInterface
    fun share(content: String) {
        val intent = Intent(Intent.ACTION_SEND)
        intent.type = "text/plain"
        intent.putExtra(Intent.EXTRA_TEXT, content)
        
        activity.startActivity(Intent.createChooser(intent, "分享到"))
    }
    
    @JavascriptInterface
    fun getConfig(key: String): String {
        val prefs = activity.getSharedPreferences("app_config", MODE_PRIVATE)
        return prefs.getString(key, "") ?: ""
    }
    
    @JavascriptInterface
    fun setConfig(key: String, value: String) {
        val prefs = activity.getSharedPreferences("app_config", MODE_PRIVATE)
        prefs.edit().putString(key, value).apply()
    }
}
```

### 4.4 Web端适配 (1-2天)

**packages/shared/platform/mobile-adapter.ts**:
```typescript
// 移动端平台适配器
export class MobileAdapter {
  private nativeApp: any;
  
  constructor() {
    this.nativeApp = (window as any).nativeApp;
  }
  
  isMobileApp(): boolean {
    return !!this.nativeApp;
  }
  
  getPlatform(): 'ios' | 'android' | 'web' {
    if (!this.isMobileApp()) return 'web';
    return this.nativeApp.platform;
  }
  
  async uploadFile(): Promise<void> {
    if (!this.isMobileApp()) {
      // Web文件上传降级
      const input = document.createElement('input');
      input.type = 'file';
      input.click();
      return;
    }
    
    this.nativeApp.uploadFile();
  }
  
  async showNotification(title: string, body: string): Promise<void> {
    if (!this.isMobileApp()) {
      // Web Notification降级
      if ('Notification' in window && Notification.permission === 'granted') {
        new Notification(title, { body });
      }
      return;
    }
    
    this.nativeApp.showNotification(title, body);
  }
  
  async share(content: string): Promise<void> {
    if (!this.isMobileApp()) {
      // Web Share API降级
      if (navigator.share) {
        await navigator.share({ text: content });
      } else {
        // 复制到剪贴板
        await navigator.clipboard.writeText(content);
        alert('已复制到剪贴板');
      }
      return;
    }
    
    this.nativeApp.share(content);
  }
  
  async getConfig(key: string): Promise<string> {
    if (!this.isMobileApp()) {
      return localStorage.getItem(key) || '';
    }
    
    return await this.nativeApp.getConfig(key);
  }
  
  async setConfig(key: string, value: string): Promise<void> {
    if (!this.isMobileApp()) {
      localStorage.setItem(key, value);
      return;
    }
    
    this.nativeApp.setConfig(key, value);
  }
}

export const mobileAdapter = new MobileAdapter();
```

---

## 🔧 五、统一适配层

### 5.1 平台适配器

**packages/shared/platform/index.ts**:
```typescript
import { ElectronAdapter } from './electron-adapter';
import { MobileAdapter } from './mobile-adapter';

export type Platform = 'web' | 'electron' | 'ios' | 'android';

export class PlatformAdapter {
  private electron: ElectronAdapter;
  private mobile: MobileAdapter;
  
  constructor() {
    this.electron = new ElectronAdapter();
    this.mobile = new MobileAdapter();
  }
  
  getCurrentPlatform(): Platform {
    if (this.electron.isElectron()) return 'electron';
    
    const mobilePlatform = this.mobile.getPlatform();
    if (mobilePlatform !== 'web') return mobilePlatform;
    
    return 'web';
  }
  
  isDesktop(): boolean {
    return this.getCurrentPlatform() === 'electron';
  }
  
  isMobile(): boolean {
    const platform = this.getCurrentPlatform();
    return platform === 'ios' || platform === 'android';
  }
  
  isWeb(): boolean {
    return this.getCurrentPlatform() === 'web';
  }
  
  // 文件操作
  async openFile(): Promise<string[]> {
    const platform = this.getCurrentPlatform();
    
    switch (platform) {
      case 'electron':
        return await this.electron.openFile();
      case 'ios':
      case 'android':
        await this.mobile.uploadFile();
        return [];
      default:
        return new Promise((resolve) => {
          const input = document.createElement('input');
          input.type = 'file';
          input.multiple = true;
          input.onchange = (e: any) => {
            const files = Array.from(e.target.files as FileList);
            resolve(files.map(f => f.name));
          };
          input.click();
        });
    }
  }
  
  // 通知
  async showNotification(title: string, body: string): Promise<void> {
    const platform = this.getCurrentPlatform();
    
    switch (platform) {
      case 'electron':
        await this.electron.showNotification(title, body);
        break;
      case 'ios':
      case 'android':
        await this.mobile.showNotification(title, body);
        break;
      default:
        if ('Notification' in window) {
          if (Notification.permission === 'granted') {
            new Notification(title, { body });
          } else if (Notification.permission !== 'denied') {
            const permission = await Notification.requestPermission();
            if (permission === 'granted') {
              new Notification(title, { body });
            }
          }
        }
    }
  }
  
  // 配置存储
  async getConfig(key: string): Promise<any> {
    const platform = this.getCurrentPlatform();
    
    switch (platform) {
      case 'electron':
        return await this.electron.getConfig(key);
      case 'ios':
      case 'android':
        return await this.mobile.getConfig(key);
      default:
        const value = localStorage.getItem(key);
        return value ? JSON.parse(value) : null;
    }
  }
  
  async setConfig(key: string, value: any): Promise<void> {
    const platform = this.getCurrentPlatform();
    
    switch (platform) {
      case 'electron':
        await this.electron.setConfig(key, value);
        break;
      case 'ios':
      case 'android':
        await this.mobile.setConfig(key, JSON.stringify(value));
        break;
      default:
        localStorage.setItem(key, JSON.stringify(value));
    }
  }
}

// 全局单例
export const platformAdapter = new PlatformAdapter();
```

### 5.2 React Hook封装

**packages/shared/hooks/use-platform.ts**:
```typescript
import { useEffect, useState } from 'react';
import { platformAdapter, Platform } from '../platform';

export function usePlatform() {
  const [platform, setPlatform] = useState<Platform>('web');
  
  useEffect(() => {
    setPlatform(platformAdapter.getCurrentPlatform());
  }, []);
  
  return {
    platform,
    isDesktop: platformAdapter.isDesktop(),
    isMobile: platformAdapter.isMobile(),
    isWeb: platformAdapter.isWeb(),
    adapter: platformAdapter
  };
}

export function usePlatformFeatures() {
  const { adapter } = usePlatform();
  
  const openFile = async () => {
    return await adapter.openFile();
  };
  
  const showNotification = async (title: string, body: string) => {
    return await adapter.showNotification(title, body);
  };
  
  const getConfig = async (key: string) => {
    return await adapter.getConfig(key);
  };
  
  const setConfig = async (key: string, value: any) => {
    return await adapter.setConfig(key, value);
  };
  
  return {
    openFile,
    showNotification,
    getConfig,
    setConfig
  };
}
```

---

## 📦 六、构建和部署

### 6.1 构建脚本

**scripts/build-all.sh**:
```bash
#!/bin/bash

echo "🚀 Building all platforms..."

# 构建Web
echo "📦 Building Web..."
cd packages/web
npm run build
cd ../..

# 构建Desktop (Electron)
echo "🖥️ Building Desktop..."
cd packages/desktop
npm run build
npm run dist
cd ../..

# 构建iOS (需要在macOS上)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "📱 Building iOS..."
    cd packages/mobile/ios
    xcodebuild -scheme APITable -configuration Release archive
    cd ../../..
fi

# 构建Android
echo "🤖 Building Android..."
cd packages/mobile/android
./gradlew assembleRelease
cd ../../..

echo "✅ All platforms built successfully!"
```

### 6.2 版本管理

**scripts/version-bump.sh**:
```bash
#!/bin/bash

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "Usage: ./version-bump.sh <version>"
    exit 1
fi

echo "📝 Updating version to $VERSION"

# 更新package.json
find packages -name "package.json" -exec sed -i '' "s/\"version\": \".*\"/\"version\": \"$VERSION\"/" {} \;

# 更新iOS版本
sed -i '' "s/MARKETING_VERSION = .*/MARKETING_VERSION = $VERSION;/" packages/mobile/ios/APITable.xcodeproj/project.pbxproj

# 更新Android版本
VERSION_CODE=$(echo $VERSION | tr -d '.')
sed -i '' "s/versionCode .*/versionCode $VERSION_CODE/" packages/mobile/android/app/build.gradle
sed -i '' "s/versionName .*/versionName \"$VERSION\"/" packages/mobile/android/app/build.gradle

echo "✅ Version updated to $VERSION"
```

### 6.3 CI/CD配置

**.github/workflows/build.yml**:
```yaml
name: Multi-Platform Build

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  build-web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '16.15.0'
      
      - name: Install dependencies
        run: |
          cd packages/web
          npm install
      
      - name: Build
        run: |
          cd packages/web
          npm run build
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: web-build
          path: packages/web/out/

  build-desktop:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '16.15.0'
      
      - name: Install dependencies
        run: |
          cd packages/desktop
          npm install
      
      - name: Build
        run: |
          cd packages/desktop
          npm run build
          npm run dist
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: desktop-${{ matrix.os }}
          path: packages/desktop/dist/

  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: latest-stable
      
      - name: Build iOS
        run: |
          cd packages/mobile/ios
          xcodebuild -scheme APITable \
            -configuration Release \
            -archivePath build/APITable.xcarchive \
            archive

  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'
      
      - name: Build Android
        run: |
          cd packages/mobile/android
          ./gradlew assembleRelease
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: android-apk
          path: packages/mobile/android/app/build/outputs/apk/release/
```

---

## 📊 七、实施计划

### 7.1 时间表

| 阶段 | 任务 | 时间 | 人员 |
|------|------|------|------|
| **阶段1** | 项目架构设计和基础设施 | 1周 | 架构师 + 1人 |
| **阶段2** | 桌面端开发 (Electron) | 4-6周 | 2-3人 |
| **阶段3** | iOS开发 | 3-4周 | 1-2人 |
| **阶段4** | Android开发 | 3-4周 | 1-2人 |
| **阶段5** | 统一适配层和测试 | 2-3周 | 全员 |
| **阶段6** | 优化和发布 | 1-2周 | 全员 |

**总计**: 14-21周 (约3.5-5个月)

### 7.2 团队配置

- **架构师**: 1人
- **前端开发**: 2-3人
- **iOS开发**: 1-2人
- **Android开发**: 1-2人
- **测试工程师**: 1-2人
- **DevOps**: 1人

### 7.3 里程碑

- **M1**: 完成架构设计和基础设施 (第2周)
- **M2**: 完成桌面端Alpha版本 (第8周)
- **M3**: 完成iOS Beta版本 (第12周)
- **M4**: 完成Android Beta版本 (第16周)
- **M5**: 完成全平台测试和优化 (第19周)
- **M6**: 正式发布 (第21周)

---

## 🎯 八、风险评估与应对

### 8.1 技术风险

| 风险 | 影响 | 概率 | 应对措施 |
|------|------|------|----------|
| Electron性能问题 | 高 | 中 | 优化打包大小，使用懒加载 |
| WebView兼容性问题 | 中 | 高 | 提供降级方案，充分测试 |
| 原生功能集成困难 | 中 | 中 | 提前调研，预留时间 |
| 跨平台通信问题 | 高 | 低 | 设计完善的桥接协议 |

### 8.2 进度风险

| 风险 | 应对措施 |
|------|----------|
| 人员不足 | 提前招聘，外包辅助 |
| 需求变更 | 冻结核心需求，分版本迭代 |
| 技术难题 | 建立技术储备，寻求外部支持 |

### 8.3 质量风险

| 风险 | 应对措施 |
|------|----------|
| 测试覆盖不足 | 自动化测试，建立测试计划 |
| 用户体验差异 | 统一设计规范，充分用户测试 |
| 性能问题 | 性能监控，持续优化 |

---

## 📈 九、成功指标

### 9.1 技术指标

- ✅ Electron应用启动时间 < 3秒
- ✅ WebView首屏加载时间 < 2秒
- ✅ 应用包体积:
  - Electron: < 200MB
  - iOS: < 100MB
  - Android: < 80MB
- ✅ 内存占用:
  - Electron: < 500MB
  - iOS: < 300MB
  - Android: < 250MB

### 9.2 功能指标

- ✅ 核心功能100%覆盖
- ✅ 原生功能集成率 > 80%
- ✅ 跨平台一致性 > 95%
- ✅ 自动化测试覆盖率 > 70%

### 9.3 用户指标

- ✅ 用户满意度 > 4.5/5
- ✅ 崩溃率 < 0.1%
- ✅ 应用商店评分 > 4.0/5

---

## 🔧 十、后续优化

### 10.1 短期优化 (1-3个月)

1. **性能优化**
   - 代码分割和懒加载
   - 资源压缩和CDN加速
   - 缓存策略优化

2. **功能完善**
   - 离线功能支持
   - 数据同步优化
   - 推送通知完善

3. **用户体验**
   - 动画效果优化
   - 交互反馈完善
   - 无障碍功能

### 10.2 中期规划 (3-6个月)

1. **功能扩展**
   - 深色模式支持
   - 多语言完善
   - 插件系统

2. **性能提升**
   - WebAssembly集成
   - 原生模块优化
   - 数据库性能优化

3. **平台特性**
   - 平板适配
   - Apple Watch集成
   - Widget支持

### 10.3 长期规划 (6-12个月)

1. **技术演进**
   - 考虑React Native重构
   - 探索Flutter跨平台
   - 云端协作优化

2. **生态建设**
   - 开发者API
   - 第三方集成
   - 社区建设

---

## 📝 十一、总结

### 11.1 方案优势

1. **低改造成本**: 复用现有Web代码，开发成本较低
2. **快速上线**: 4-5个月即可完成全平台开发
3. **统一技术栈**: 降低维护成本和学习成本
4. **良好扩展性**: 为后续优化留有空间

### 11.2 注意事项

1. **保持代码一致性**: 严格遵循架构设计
2. **充分测试**: 确保各平台功能正常
3. **性能监控**: 持续关注应用性能
4. **用户反馈**: 及时响应用户需求

### 11.3 下一步行动

1. ✅ 成立项目组，明确分工
2. ✅ 搭建开发环境和CI/CD
3. ✅ 启动桌面端开发
4. ✅ 并行启动移动端开发
5. ✅ 建立测试和反馈机制

---

## 📚 附录

### A. 相关技术文档

- [Electron官方文档](https://www.electronjs.org/docs)
- [WKWebView开发指南](https://developer.apple.com/documentation/webkit/wkwebview)
- [Android WebView指南](https://developer.android.com/guide/webapps/webview)

### B. 参考项目

- [VSCode](https://github.com/microsoft/vscode) - Electron桌面端
- [Notion](https://www.notion.so/) - 多端一致性
- [Figma](https://www.figma.com/) - WebView移动端

### C. 工具推荐

- **开发工具**: 
  - VSCode / WebStorm
  - Xcode (iOS)
  - Android Studio (Android)
  
- **调试工具**:
  - Chrome DevTools
  - React DevTools
  - Electron DevTools

- **测试工具**:
  - Jest
  - Cypress
  - Detox (移动端)

---

**文档版本**: v1.0.0  
**最后更新**: 2025-10-03  
**维护者**: 技术团队

