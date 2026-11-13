<p align="center">
  <a href="./README.md">English</a> | <a href="./README.zh-CN.md">简体中文</a>
</p>

# ❌️ Defender Remover / Defender Disabler

<a href="https://github.com/ionuttbara/windows-defender-remover">
    <picture>
        <source media="(prefers-color-scheme: dark)" srcset="./site-res/new_darkmode.png">
        <img alt="Defender Remover" src="./site-res/new_lightmode.png">
    </picture>
</a>

## 项目模块

有关各子组件的详细信息，请查看：

* **[💿 ISO 制作工具](./ISO_Maker/README.md)** — 创建一个已禁用 Defender 的自定义 Windows ISO。
* **[🛡️ 移除 Defender 引擎](./script/Remove_Defender/README.md)** — 移除杀毒核心与服务。
* **[🖥️ 移除Defender应用](./script/Remove_SecurityComp/README.md)** — 移除 Windows 安全中心界面。

---

## ❓️ 这个应用做什么？

此应用会移除／禁用 Windows Defender，包括 Windows 安全应用、Windows 基于虚拟化的安全（VBS）、Windows SmartScreen、Windows 安全服务、Windows Web 威胁服务、Windows 文件虚拟化（UAC）、Microsoft Defender 应用防护（App Guard）、Microsoft 驱动程序阻止列表、系统缓解措施，以及 Windows 10 或更高版本“设置”应用中的 Windows Defender 页面。


## ❓️ 会移除哪些组件？

### 移除安全组件
    此脚本会移除／禁用以下安全组件：
        - 对 Windows 安全中心的支持，包括运行 Windows 安全应用所需的 Windows 安全中心服务（wscsvc）、Windows 安全服务（SgrmBroker、Sgrm 驱动）。
        - 虚拟化支持。
            - 虚拟机监控程序启动（这修复了基于虚拟化的安全被禁用的问题；如果你使用 Hyper-V 和/或 WSL（适用于 Linux 的 Windows 子系统）、WSA（适用于 Android 的 Windows 子系统），它会自动启用）
            - LUA（禁用文件虚拟化和用户账户控制，这会让所有应用以管理员权限运行（同时修复旧应用的错误））
            - Exploit Guard（与漏洞利用相关）
            - Windows Smart Control
            - 篡改防护（Tamper Protection）（适用于 Windows 11 21H2 或更早版本）
        - SecHealthUI（Windows 安全 UWP 应用）
        - SmartScreen
        - Pluton 支持与 Pluton 服务支持
        - 系统缓解措施
          - “服务缓解措施”（Services Mitigations）（可在 admx.help 上搜索更多信息，这是一项策略）
          - Spectre 与 Meltdown 缓解措施（可让老旧的 Intel CPU 获得 +30% 的性能提升）
        - “设置”应用中的 Windows 安全部分。

### 移除杀毒组件
    此脚本会强制移除以下杀毒组件：
      - Windows Defender 定义更新列表（因为 Defender 已被移除，这将禁用其定义的更新）
      - Windows Defender SpyNet 遥测
      - 杀毒服务
      - Windows Defender 杀毒过滤驱动和 Windows Defender rootkit 扫描驱动
      - 杀毒扫描任务
      - Shell 关联（右键菜单）
      - 从 Windows 安全应用中隐藏“病毒与威胁防护”部分。

## 📃 使用说明

> [!NOTE]
> 建议在运行脚本前创建系统还原点。（如果你不知道自己在做什么的话）

1. 从 [Releases](https://github.com/ionuttbara/windows-defender-remover/releases) 下载打包好的脚本
2. 以管理员身份运行 “.exe”
3. 按照显示的说明操作

或者

你可以使用 git

```
git clone https://github.com/ionuttbara/windows-defender-remover.git
script/Script_Run.cmd
```


或者

你可以下载完整源代码
1. 从 [Releases](https://github.com/jbara2002/windows-defender-remover/releases) 下载源代码。
2. 从最新版本中选择 **Source Code(.zip)** 文件并下载。
3. 将文件解压到一个文件夹，然后运行 Script_Run.bat。

![cli](https://github.com/drunkwinter/windows-defender-remover/assets/38593134/46007191-0a65-43c2-b451-a993ff90e00e)

如果你遇到任何问题，可以提交一个 [issue](https://github.com/ionuttbara/windows-defender-remover/issues)。

## 📃 脚本自动化

你可以通过参数来移除 Defender。

#### 移除

```PowerShell
# Removal
Defender.Remover.exe /r <# or /R #>
```


## 禁用或移除 Windows Defender *应用防护策略（Application Guard Policies）*（高级）

如果你在打开某个应用时遇到问题（*极为罕见*）并收到 “The app can not run because Device Guard” 或 “Windows Defender Application Guard Blocked this app” 的消息，你需要从不同位置移除 4 个同名文件。


- 在 EFI 分区中

```PowerShell
Remove-Item -LiteralPath "$((Get-Partition | ? IsSystem).AccessPaths[0])Microsoft\Boot\WiSiPolicy.p7b"
```

- 在 Code Integrity 文件夹中

```PowerShell
Remove-Item -LiteralPath "$env:windir\System32\CodeIntegrity\WiSiPolicy.p7b"
```

- 在 Windows 文件夹中

```PowerShell
Remove-Item -LiteralPath "$env:windir\Boot\EFI\wisipolicy.p7b"
```

- 在 WinSxS 文件夹中

```PowerShell
Remove-Item -Path "$env:windir\WinSxS" -Include *winsipolicy.p7b* -Recurse
```

## 创建一个已禁用 Windows Defender 和服务的 ISO

你可以创建一个已禁用 Windows Defender 和安全服务的 ISO。这很简单，下面这个文件可以帮到你。
规则如下：
1. 挂载 ISO 并将其解压到某个位置。
2. 打开 **sources** 文件夹并创建 **$OEM$** 文件夹。（在 OOBE 阶段运行 DefenderRemover 部分时需要它）。
3. 打开 **$OEM$** 文件夹并创建名为 **$$** 的文件夹。
4. 打开 **$$** 文件夹并创建名为 **Panther** 的文件夹。
5. 打开 **Panther** 文件夹。
   显示的路径类似于
    **%解压后的 ISO 位置%\sources\$OEM$\$$\Panther\**
6. 从仓库 ISO_Maker 文件夹中下载 unnatended.xml 文件，并将其放入 Panther 文件夹。
7. 将其保存为可启动 ISO。（目前脚本还无法自动完成这一步，但在下一个版本中会支持）。
    

## ❓ 常见问题
#### ⭕ 如何在不下载脚本的情况下从电脑移除 Windows 安全中心／Windows 安全应用？
将此代码粘贴到一个 powershell 文件中，然后**以管理员身份运行**。
```
$remove_appx = @("SecHealthUI"); $provisioned = get-appxprovisionedpackage -online; $appxpackage = get-appxpackage -allusers; $eol = @()
$store = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore'
$users = @('S-1-5-18'); if (test-path $store) {$users += $((dir $store -ea 0 |where {$_ -like '*S-1-5-21*'}).PSChildName)}
foreach ($choice in $remove_appx) { if ('' -eq $choice.Trim()) {continue}
  foreach ($appx in $($provisioned |where {$_.PackageName -like "*$choice*"})) {
    $next = !1; foreach ($no in $skip) {if ($appx.PackageName -like "*$no*") {$next = !0}} ; if ($next) {continue}
    $PackageName = $appx.PackageName; $PackageFamilyName = ($appxpackage |where {$_.Name -eq $appx.DisplayName}).PackageFamilyName 
    ni "$store\Deprovisioned\$PackageFamilyName" -force >''; $PackageFamilyName  
    foreach ($sid in $users) {ni "$store\EndOfLife\$sid\$PackageName" -force >''} ; $eol += $PackageName
    dism /online /set-nonremovableapppolicy /packagefamily:$PackageFamilyName /nonremovable:0 >''
    remove-appxprovisionedpackage -packagename $PackageName -online -allusers >''
  }
  foreach ($appx in $($appxpackage |where {$_.PackageFullName -like "*$choice*"})) {
    $next = !1; foreach ($no in $skip) {if ($appx.PackageFullName -like "*$no*") {$next = !0}} ; if ($next) {continue}
    $PackageFullName = $appx.PackageFullName; 
    ni "$store\Deprovisioned\$appx.PackageFamilyName" -force >''; $PackageFullName
    foreach ($sid in $users) {ni "$store\EndOfLife\$sid\$PackageFullName" -force >''} ; $eol += $PackageFullName
    dism /online /set-nonremovableapppolicy /packagefamily:$PackageFamilyName /nonremovable:0 >''
    remove-appxpackage -package $PackageFullName -allusers >''
  }
}
```

#### ⭕ 为什么下载的可执行文件会被标记为病毒？

这是误报。

一些安全应用会因为 “.exe” 文件的生成方式,签名而将此应用标记为病毒。通过 **git** 或源代码 .zip 下载的则会被判定为无病毒。
从 Defender 12.6.x 开始，有些版本会被视为病毒，有些则不会（这是我这边的一个 bug，所以请不要为此提交报告）。

#### ⭕ 为什么 Windows 更新后补丁就不起作用了？

Windows 更新包含一个 ```Intelligence Update```，它会阻止某些操作并修改 Windows Defender／安全策略。
如果脚本对你不奏效，请检查你是否安装了 Windows 安全智能更新（Security Intelligence Update）。如果安装了，请禁用篡改防护，然后重新运行脚本。

#### ⭕ 如何在不从 release 下载可执行文件的情况下使用包移除器？

用 PowerRun 从 cmd 运行所需的 “.bat” 文件（将其拖到可执行文件上）。你需要重启才能使更改生效。

#### ⭕ 如果移除脚本不起作用，如何禁用 VBS

用此命令禁用并重启。

```
bcdedit /set hypervisorlaunchtype off
```
此后你将无法使用虚拟机。  

#### ⭕  为什么 VBS 在 Windows 11 上会一直保持启用？

默认情况下，脚本会禁用 VBS 以提升系统性能。使 VBS 保持启用的因素是 Windows 虚拟化。  
    
Windows 虚拟化所使用的应用和功能：  

- 适用于 **Android**/**Linux** 的 Windows 子系统 — HyperV 虚拟机
- <a href="https://apps.microsoft.com/detail/9n0tn65p5bf6?hl=en-US&gl=US" target="_blank">Microsoft Emulator</a>（可在 Microsoft Store 中找到的 Windows 10X 模拟器）
- Visual Studio 中的 Android Studio 集成，或其他模拟器（适用于安装了 2025 年 3 月更新或更新版本的 Windows 10 22H2）

如果你打开前面提到的那些应用中的任意一个，VBS 将在无需用户干预的情况下被启用。运行虚拟机引擎需要它。如果你不使用任何虚拟机，可以在<a href="https://github.com/ionuttbara/windows-defender-remover/issues" target="_blank">此处</a>提交 Issue。
