# Enable Chrome AI Whole Process

[中文](README.md) | [English](README.en.md)

Used to enable and troubleshoot `Ask Gemini` / `Gemini Live in Chrome (GLIC)` in local Chrome, with a complete end-to-end setup guide.

✨ This repository includes:

- **Step-by-step instructions**
- **Windows script: [enable-chrome-ai.ps1](enable-chrome-ai.ps1)**
- **macOS script: [enable-chrome-ai-mac.sh](enable-chrome-ai-mac.sh)**

✅ **No third-party libraries or extra dependencies are required. The scripts run directly with built-in system capabilities.**

Suitable for:

- Chrome is already installed, but `Ask Gemini` is still not visible
- You want to modify `Local State` automatically with a script
- You have already changed flags, but the feature still does not appear

## Recommended Usage

1. Follow the "Steps" section below in order.
2. Prefer using the scripts to modify `Local State`.
3. Restart Chrome and check whether `Ask Gemini` appears.
4. If it still does not work, see "Troubleshooting" at the end.

## Steps

Note in advance: in my environment, several conditions **do not affect GLIC functionality** (such as region settings, VPN nodes, etc.). For details, see [Troubleshooting](#troubleshooting). You can just follow the steps below first.

### 1. Enable Chrome Experimental Flags

In the address bar, open `chrome://flags`, search for `glic` (Gemini Live in Chrome), set all related options to `Enabled`, and then restart the browser.

>You can selectively enable related options according to the descriptions shown in `chrome://flags`.
>In my environment, Chrome 147.0.7727.102 had only the following options left at the default state:
>
>- Glic Default To Last Active Conversation
>- Glic Reset Multi-Instance Enablement By Tier
>- Glic Force G1 Status for Multi-Instance
>- Glic guest URL presets
>- Glic disable actor safety checks
>
> All other related options were set to `Enabled`.

### 2. Modify the Local State File

The configuration values in the Local State file can also affect whether GLIC takes effect.

#### Use the Script

Download the script from this repository and run it locally. It will automatically modify the relevant configuration values in the Local State file, so you do not need to edit anything by hand.

- Windows: download and run [enable-chrome-ai.ps1](enable-chrome-ai.ps1).
- macOS: download and run [enable-chrome-ai-mac.sh](enable-chrome-ai-mac.sh).

⬇️ Option 1: Download and run the script directly without Git (recommended)

- Windows PowerShell:

  ```powershell
  Invoke-WebRequest -Uri "https://raw.githubusercontent.com/BreadIceCream/enable-chrome-ai/main/enable-chrome-ai.ps1" -OutFile "enable-chrome-ai.ps1"
  powershell -ExecutionPolicy Bypass -File .\enable-chrome-ai.ps1
  ```

- macOS Bash:

  ```bash
  curl -L "https://raw.githubusercontent.com/BreadIceCream/enable-chrome-ai/main/enable-chrome-ai-mac.sh" -o enable-chrome-ai-mac.sh
  chmod +x ./enable-chrome-ai-mac.sh
  ./enable-chrome-ai-mac.sh
  ```

📦 Option 2: Use `git clone` (Git required)

- Windows PowerShell:

  ```powershell
  git clone https://github.com/BreadIceCream/enable-chrome-ai.git
  cd enable-chrome-ai
  powershell -ExecutionPolicy Bypass -File .\enable-chrome-ai.ps1
  ```

- macOS Bash:

  ```bash
  git clone https://github.com/BreadIceCream/enable-chrome-ai.git
  cd enable-chrome-ai
  chmod +x ./enable-chrome-ai-mac.sh
  ./enable-chrome-ai-mac.sh
  ```

Script output example:

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

Script notes and safety:

- The scripts only modify relevant configuration values in Chrome's Local State file and do not affect the system or other applications.
- The scripts ask whether to close Chrome processes and do not force-close them without confirmation.
- The scripts automatically back up the Local State file to avoid accidental issues.
- Each run creates a new `.backup.<timestamp>` file. It is recommended to keep the latest backup and use it first for restoration.
- The scripts currently handle the following fields:
  - `variations_country`: set to `us`
  - `variations_permanent_consistency_country`: only modify the 2nd value to `us`, while keeping the 1st value unchanged
  - `is_glic_eligible`: recursively find and set to `true`

#### Manual Modification

If you do not want to use the scripts, you can also modify the Local State file manually:

1. Fully exit Chrome.
If Chrome is still running, your manual changes may be overwritten. It is recommended to close all Chrome windows first and confirm that no Chrome background processes remain.

2. Locate the Local State file.

   - Default Windows path:
     `C:\Users\your-username\AppData\Local\Google\Chrome\User Data\Local State`

   - Default macOS path:
     `~/Library/Application Support/Google/Chrome/Local State`

   > If you are using Chrome Beta, Dev, Canary, or other channels, the directory name may differ, but the file name is still `Local State`.

3. Manually back up the original file first, so you can restore it directly if anything goes wrong. For example:

   - `Local State.backup.manual`
   - or `Local State.backup.20260420`

4. Open the `Local State` file with a text editor. VS Code, Sublime Text, Notepad++, and similar editors that can handle large JSON files are recommended. Do not use editors that may insert rich-text formatting automatically.

5. Search for and modify the following fields:

   - `variations_country`: change it to

     ```json
     "variations_country": "us"
     ```

   - `variations_permanent_consistency_country`: change the 2nd value to `us`. Note: only change the 2nd value. The 1st value is usually a version number and should not be modified.

     ```json
     "variations_permanent_consistency_country": ["147.0.7727.102","us"]
     ```

   - `is_glic_eligible`: search for all `is_glic_eligible` entries and change all of them to `true`.

     ```json
     "is_glic_eligible": true
     ```

6. Save the file. Keep the JSON format valid. Do not remove commas, quotes, or brackets. If the editor reports a format error, fix it before saving.
7. Restart Chrome. After startup, check `chrome://flags` again and then continue with the language setting step below.
    If Chrome behaves abnormally after the modification, restore the backup file. Close Chrome, then replace `Local State` with the backup you created.

### 3. Change Chrome Language Settings

Open `chrome://settings` in the address bar, or click the three-dot menu in the top-right corner to enter Settings.

Find the language settings, set `English (United States)` as the preferred language, check "Display Google Chrome in this language", and then restart Chrome.
>You do not need to remove other languages. Just make sure that `English (United States)` has "Display Google Chrome in this language" enabled.

At this point, you will most likely be able to see and use `Ask Gemini` in Chrome. If it still does not work, then you may need to check the region associated with your Google account.

### 4. Check the Region Associated with Your Google Account

>TIPS: This step is usually not necessary. If all previous steps were completed correctly, it should generally already work. If it still does not work, you can check whether the region associated with your Google account is the United States.

Sign in to your Google account and visit `policies.google.com/terms`, then check whether the "Country version" is shown as "United States". If it is not the United States, it may affect GLIC functionality. You can search for "how to change the region associated with a Google account" and try updating it yourself.

## Troubleshooting

If it still does not work after completing all steps, check the following first:

1. Close Chrome again, reopen `Local State`, and confirm that the following fields still have the expected values:
   - `variations_country = "us"`
   - the 2nd value of `variations_permanent_consistency_country` is `"us"`
   - `is_glic_eligible = true`

2. If the fields have reverted to their previous values, Chrome or some sync/policy mechanism may have overwritten the local changes. In that case:
   - fully exit Chrome before running the script again
   - confirm that no background processes remain
   - restart Chrome and test again

3. If the field values are correct but the entry still does not appear, check these first:
   - Chrome version
   - language settings
   - whether `chrome://flags` actually took effect after restart

Note that if Chrome has been updated, it may reset some fields or overwrite modifications. It is recommended to check whether the relevant fields in `Local State` are still the target values after each Chrome update, or just re-run the script.

ℹ️ The following usually **do not directly affect** functionality:

- your Google account region is not the United States
- your system country/region is not the United States
- Chrome still keeps other languages
- your VPN node is not in the United States

## Recovery

1. Fully exit Chrome.
2. Find the latest `.backup` file you kept.
3. Replace the current `Local State` file with that backup.
4. Restart Chrome.

It is recommended to restore using the latest generated backup file first.

🔁 You can restore directly with the following commands. Replace the example backup file name with the actual `.backup.<timestamp>` file you kept:

- Windows PowerShell:

  ```powershell
  $localState = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State"
  # Replace with the actual backup file name
  $backup = "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State.backup.20260420"
  Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue
  Copy-Item -Path $backup -Destination $localState -Force
  ```

- macOS Bash:

  ```bash
  LOCAL_STATE="$HOME/Library/Application Support/Google/Chrome/Local State"
  # Replace with the actual backup file name
  BACKUP="$HOME/Library/Application Support/Google/Chrome/Local State.backup.20260420"
  pkill -if 'Google Chrome' || true
  cp "$BACKUP" "$LOCAL_STATE"
  ```

## Acknowledgements

🙏 This repository referenced and learned from the following projects when organizing ideas and implementation approaches:

- [tianlelyd/enable-chrome-ai](https://github.com/tianlelyd/enable-chrome-ai)
- [lcandy2/enable-chrome-ai](https://github.com/lcandy2/enable-chrome-ai)

Thanks to the original authors for their ideas, testing experience, and implementation inspiration.

## Disclaimer

This repository is based on currently visible configuration and practical testing, and is intended only for learning and troubleshooting reference.

- It does not guarantee effectiveness for all Chrome versions and environments
- Google may change fields, flags, or policies in later versions
- Please make sure you understand what the scripts do and how backups work before using them
