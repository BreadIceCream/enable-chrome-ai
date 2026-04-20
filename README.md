# Enable Chrome AI Whole Process

[中文](README.md) | [English](README.en.md)

用于在本地 Chrome 中启用和排查 `Ask Gemini` / `Gemini Live in Chrome (GLIC)`，提供全流程操作步骤说明。

✨ 仓库包含：

- **操作步骤说明**
- **Windows 脚本：[enable-chrome-ai.ps1](enable-chrome-ai.ps1)**
- **macOS 脚本：[enable-chrome-ai-mac.sh](enable-chrome-ai-mac.sh)**

✅ **无需安装任何第三方库或额外依赖，直接使用系统自带能力即可运行脚本。**

适合：

- 已安装 Chrome，但还看不到 `Ask Gemini`
- 想通过脚本自动修改 `Local State`
- 已改过 flags，但功能仍未出现

## 推荐使用方式

1. 按照下方“操作步骤”依次完成。
2. 优先使用脚本修改 `Local State`。
3. 重启 Chrome 后检查 `Ask Gemini` 是否出现。
4. 若仍未生效，再看文末“故障排查”。

## 操作步骤

提前说明：在我的环境下，有几个情况并**不会影响Glic功能**（如国家地区、VPN节点等），详细请查看[故障排查](#故障排查)。你只需先按照以下步骤进行设置。

### 1. 更改Chrome的实验性功能开关

在地址栏输入 `chrome://flags`，搜索 `glic`（即Gemini live in Chrome），将所有相关的选项设置为 `Enabled`，然后重启浏览器。

>可以参考 `chrome://flags` 中的描述选择性地开启相关选项。
>我的环境是 Chrome 147.0.7727.102，只有以下几个选项设置为默认Default:
>
>- Glic Default To Last Active Conversation
>- Glic Reset Multi-Instance Enablement By Tier
>- Glic Force G1 Status for Multi-Instance
>- Glic guest URL presets
>- Glic disable actor safety checks
>
> 其他相关选项都设置为 Enabled。

### 2. 修改Local State文件

Local State文件中的配置项也会影响Glic是否生效。

#### 使用脚本

下载仓库中的脚本到本地，运行脚本，它会自动修改 Local State 文件中的相关配置项，你无需任何手动操作。

- Windows：下载 [enable-chrome-ai.ps1](enable-chrome-ai.ps1) 脚本，并运行。
- MacOS：下载 [enable-chrome-ai-mac.sh](enable-chrome-ai-mac.sh) 脚本，并运行。

⬇️ 方式一：不使用 Git，直接下载脚本并运行（推荐）

- Windows PowerShell：

  ```powershell
  Invoke-WebRequest -Uri "https://raw.githubusercontent.com/BreadIceCream/enable-chrome-ai/main/enable-chrome-ai.ps1" -OutFile "enable-chrome-ai.ps1"
  powershell -ExecutionPolicy Bypass -File .\enable-chrome-ai.ps1
  ```

- macOS Bash：

  ```bash
  curl -L "https://raw.githubusercontent.com/BreadIceCream/enable-chrome-ai/main/enable-chrome-ai-mac.sh" -o enable-chrome-ai-mac.sh
  chmod +x ./enable-chrome-ai-mac.sh
  ./enable-chrome-ai-mac.sh
  ```

📦 方式二：使用 `git clone`（需安装git）

- Windows PowerShell：

  ```powershell
  git clone https://github.com/BreadIceCream/enable-chrome-ai.git
  cd enable-chrome-ai
  powershell -ExecutionPolicy Bypass -File .\enable-chrome-ai.ps1
  ```

- macOS Bash：

  ```bash
  git clone https://github.com/BreadIceCream/enable-chrome-ai.git
  cd enable-chrome-ai
  chmod +x ./enable-chrome-ai-mac.sh
  ./enable-chrome-ai-mac.sh
  ```

脚本输出示例：

```powershell
=========================================================
         Enable Chrome AI - Auto Config Tool
=========================================================

[INFO] Found Chrome Local State paths: 1
[INFO]  - C:\Users\xxx\AppData\Local\Google\Chrome\User Data\Local State

=========================================================
          [ STAGE ] PROCESS CHECK
=========================================================
[WARN] Detected running Chrome processes: 22
Terminate Chrome now? [y/n]: y
[INFO] Stopping Chrome processes...
[SUCCESS] Chrome processes stopped.

=========================================================
          [ STAGE ] PROCESSING FILE
=========================================================
[INFO] Processing: C:\Users\xxx\AppData\Local\Google\Chrome\User Data\Local State
[INFO] Backup created: C:\Users\xxx\AppData\Local\Google\Chrome\User Data\Local State.backup.20260420105208
[INFO] Processing results as follows:
[INFO] Already compliant fields:
  - variations_country already 'us'
  - variations_permanent_consistency_country already has country 'us' in slot 2
  - is_glic_eligible already true x2
[INFO] Changed fields: none. Target values were already present.
[SUCCESS] Patch complete.

=========================================================
          [ STAGE ] COMPLETED
=========================================================
[SUCCESS] All operations completed.

=========================================================
                      NEXT STEPS
=========================================================
[INFO] 1. Restart Chrome and check Gemini in the sidebar or settings.
[INFO]    If not work, modify Chrome settings according to the guidelines in the README.md file.
[INFO] 2. To restore, replace Local State with the generated .backup file.
[WARN]    Each run creates a new .backup file. Keep the latest backup file and use it if you need to restore Local State.
```

脚本说明和安全性：

- 脚本仅修改 Chrome 的 Local State 文件中的相关配置项，不会对系统或其他应用造成任何影响。
- 脚本会询问是否关闭 Chrome 进程，不会强制关闭。
- 脚本会自动备份 Local State 文件，以防止意外情况发生。
- 每次运行脚本都会新建一个 `.backup.<时间戳>` 备份文件。建议保留最新生成的备份文件，恢复时优先使用它。
- 脚本当前会处理的字段如下：
  - `variations_country`：设置为 `us`
  - `variations_permanent_consistency_country`：只修改第 2 个值为 `us`，第 1 个值保持原样不变
  - `is_glic_eligible`：递归查找并设置为 `true`

#### 手动修改

若你不想使用脚本，也可以手动修改Local State文件，操作如下：

1. 完全退出 Chrome。
如果 Chrome 仍在运行，手动修改后的内容可能会被覆盖。建议先关闭所有 Chrome 窗口，再确认后台没有残留的 Chrome 进程。

2. 找到 Local State 文件。

   - Windows 默认路径：
     `C:\Users\你的用户名\AppData\Local\Google\Chrome\User Data\Local State`

   - macOS 默认路径：
     `~/Library/Application Support/Google/Chrome/Local State`

   > 如果你使用的是 Chrome Beta、Dev、Canary 等版本，对应目录名称会不同，但文件名仍然是 `Local State`。

3. 先手动备份一份原文件，这样即使修改出错，也可以直接用备份文件恢复。例如复制为：

   - `Local State.backup.manual`
   - 或 `Local State.backup.20260420`

4. 用文本编辑器打开 `Local State` 文件。推荐使用 VS Code、Sublime Text、Notepad++ 等支持大 JSON 文件的编辑器，不建议使用会自动插入富文本格式的编辑器。

5. 搜索并修改以下字段：

   - `variations_country`：修改为

     ```json
     "variations_country": "us"
     ```

   - `variations_permanent_consistency_country`：将第2个值修改为 `us`。注意：只改第 2 个值，第 1 个值通常是版本号，不要改动。

     ```json
     "variations_permanent_consistency_country": ["147.0.7727.102","us"]
     ```

   - `is_glic_eligible`：搜索所有 `is_glic_eligible`，将它们的值统一改为 `true`。

     ```json
     "is_glic_eligible": true
     ```

6. 保存文件。保存时保持 JSON 格式合法，不要删掉逗号、引号或括号。如果编辑器提示格式错误，先修正再保存。
7. 重新启动 Chrome。启动后重新检查 `chrome://flags` 和下一步的语言设置。
    如果修改后 Chrome 异常，使用备份文件恢复。关闭 Chrome 后，用你刚才备份的文件替换 `Local State` 即可。

### 3. 更改Chrome语言设置

在地址栏输入 `chrome://settings`，或者点击右上角的三个点，进入设置页面。

找到“语言”设置，将“英语（美国）”设置为首选语言，并勾选“以此语言显示Chrome界面内容”，然后重启浏览器。
>你无需删除其他语言，只需确保“英语（美国）”勾选了“以此语言显示Chrome界面内容”。

到此为止，你大概率能够在Chrome中看到并使用 `Ask Gemini` 了。如仍然不行，则需要检查谷歌账号的关联地区。

### 4. 检查谷歌账号的关联地区

>TIPS：这一步通常不需要，如果前面步骤都正确完成了，基本上就能使用了。若仍然无法使用，可以检查一下谷歌账号的关联地区是否为美国。

登录你的谷歌账号，访问 `policies.google.com/terms`，检查“国家/地区版本”是否显示为“美国”。如果不是美国，可能会影响Glic的功能。可以自行搜索“如何更改谷歌账号的关联地区”来尝试修改。

## 故障排查

如果完成全部步骤后仍无法使用，可重点检查：

1. 再次关闭 Chrome，重新打开 `Local State`，确认以下字段是否仍然是目标值：
   - `variations_country = "us"`
   - `variations_permanent_consistency_country` 的第 2 个值为 `"us"`
   - `is_glic_eligible = true`

2. 如果字段已经恢复成旧值，说明 Chrome 或其他同步/策略机制覆盖了本地修改。此时建议：
   - 先完全退出 Chrome 再运行脚本
   - 确认没有残留后台进程
   - 再重新启动 Chrome 测试

3. 如果字段值正确，但界面仍没有入口，优先排查：
   - Chrome 版本
   - 语言设置
   - `chrome://flags` 是否真正重启后生效

ℹ️ 以下情况通常**不会直接影响**功能：

- Google 账号地区不是美国
- 电脑系统国家与地区不是美国
- Chrome 语言中保留了其他语言
- VPN 节点不在美国

## 恢复方法

1. 完全退出 Chrome。
2. 找到你保留的最新 `.backup` 文件。
3. 用该备份文件替换当前的 `Local State` 文件。
4. 重新启动 Chrome。

建议优先使用最新生成的备份文件恢复。

🔁 可直接使用以下命令恢复，将示例中的备份文件名替换为你实际保留的 `.backup.<时间戳>` 文件即可：

- Windows PowerShell：

  ```powershell
  $localState = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"
  # 替换为实际的备份文件名
  $backup = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State.backup.20260420"
  Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue
  Copy-Item -Path $backup -Destination $localState -Force
  ```

- macOS Bash：

  ```bash
  LOCAL_STATE="$HOME/Library/Application Support/Google/Chrome/Local State"
  # 替换为实际的备份文件名
  BACKUP="$HOME/Library/Application Support/Google/Chrome/Local State.backup.20260420"
  pkill -if 'Google Chrome' || true
  cp "$BACKUP" "$LOCAL_STATE"
  ```

## 致谢

🙏 本仓库在整理思路和实现方案时，参考并借鉴了以下项目：

- [tianlelyd/enable-chrome-ai](https://github.com/tianlelyd/enable-chrome-ai)
- [lcandy2/enable-chrome-ai](https://github.com/lcandy2/enable-chrome-ai)

感谢原作者提供的思路、测试经验和实现启发。

## 免责声明

本仓库内容基于当前可见配置和实际测试整理，仅供学习和排查参考。

- 不保证对所有 Chrome 版本和环境都有效
- Google 后续可能调整字段、开关或策略
- 请在理解脚本作用和备份机制后再执行
