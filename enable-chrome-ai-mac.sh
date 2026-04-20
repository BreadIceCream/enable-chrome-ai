#!/bin/bash

set -euo pipefail

COLOR_CYAN='\033[0;36m'
COLOR_BLUE='\033[0;34m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_RED='\033[0;31m'
COLOR_RESET='\033[0m'

write_info_log() {
    printf "%b[INFO] %s%b\n" "$COLOR_BLUE" "$1" "$COLOR_RESET"
}

write_success_log() {
    printf "%b[SUCCESS] %s%b\n" "$COLOR_GREEN" "$1" "$COLOR_RESET"
}

write_warn_log() {
    printf "%b[WARN] %s%b\n" "$COLOR_YELLOW" "$1" "$COLOR_RESET"
}

write_error_log() {
    printf "%b[ERROR] %s%b\n" "$COLOR_RED" "$1" "$COLOR_RESET" >&2
}

write_stage() {
    printf "\n%b=========================================================%b\n" "$COLOR_CYAN" "$COLOR_RESET"
    printf "%b          [ STAGE ] %s%b\n" "$COLOR_CYAN" "$1" "$COLOR_RESET"
    printf "%b=========================================================%b\n" "$COLOR_CYAN" "$COLOR_RESET"
}

confirm_chrome_stop() {
    local count
    count="$(pgrep -if 'Google Chrome|Chrome Beta|Chrome Canary|Chrome Dev' | wc -l | tr -d ' ')"

    if [ "$count" = "0" ]; then
        write_info_log "No running Chrome process was detected."
        return 0
    fi

    write_warn_log "Detected running Chrome processes: $count"
    printf "Terminate Chrome now? [y/n] "
    read -r answer

    if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
        write_warn_log "User chose not to stop Chrome. Exiting without changes."
        return 1
    fi

    write_info_log "Stopping Chrome processes..."
    pkill -if 'Google Chrome|Chrome Beta|Chrome Canary|Chrome Dev' || true
    sleep 2
    write_success_log "Chrome processes stopped."
    return 0
}

update_local_state_file() {
    local file_path="$1"
    local timestamp backup_path json_tmp summary_tmp
    local changed_fields=()
    local already_fields=()

    write_stage "PROCESSING FILE"
    write_info_log "Processing: $file_path"

    timestamp="$(date '+%Y%m%d%H%M%S')"
    backup_path="${file_path}.backup.${timestamp}"
    cp "$file_path" "$backup_path"
    write_info_log "Backup created: $backup_path"

    json_tmp="$(mktemp)"
    summary_tmp="$(mktemp)"

    osascript -l JavaScript - "$file_path" "$json_tmp" "$summary_tmp" <<'JXA'
ObjC.import('Foundation');

function readUtf8(path) {
    const nsPath = $(path).stringByStandardizingPath;
    const data = $.NSData.dataWithContentsOfFile(nsPath);
    if (!data) {
        throw new Error("Unable to read file: " + path);
    }
    const text = $.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding);
    if (!text) {
        throw new Error("Unable to decode UTF-8 file: " + path);
    }
    return ObjC.unwrap(text);
}

function writeUtf8(path, content) {
    const nsContent = $(content);
    const ok = nsContent.writeToFileAtomicallyEncodingError(
        $(path).stringByStandardizingPath,
        true,
        $.NSUTF8StringEncoding,
        null
    );
    if (!ok) {
        throw new Error("Unable to write file: " + path);
    }
}

function formatValueForLog(value) {
    if (value === null || typeof value === "undefined") {
        return "<null>";
    }
    if (typeof value === "string") {
        return "'" + value + "'";
    }
    if (value === true) {
        return "true";
    }
    if (value === false) {
        return "false";
    }
    return JSON.stringify(value);
}

function run(argv) {
    const srcPath = argv[0];
    const outPath = argv[1];
    const summaryPath = argv[2];

    const data = JSON.parse(readUtf8(srcPath));
    const changedFields = [];
    const alreadyFields = [];
    const glicChanged = Object.create(null);
    let glicAlreadyTrue = 0;

    const oldVariationsCountry = formatValueForLog(data.variations_country);
    if (data.variations_country !== "us") {
        data.variations_country = "us";
        changedFields.push("variations_country: " + oldVariationsCountry + " -> 'us'");
    } else {
        alreadyFields.push("variations_country already 'us'");
    }

    const currentConsistencyCountry = data.variations_permanent_consistency_country;
    const oldConsistencyCountry = currentConsistencyCountry === null || typeof currentConsistencyCountry === "undefined"
        ? "<null>"
        : JSON.stringify(currentConsistencyCountry);
    let consistencyCountryUpdated = false;

    if (currentConsistencyCountry === null || typeof currentConsistencyCountry === "undefined") {
        data.variations_permanent_consistency_country = [null, "us"];
        consistencyCountryUpdated = true;
    } else if (typeof currentConsistencyCountry === "string") {
        data.variations_permanent_consistency_country = [currentConsistencyCountry, "us"];
        consistencyCountryUpdated = true;
    } else if (Array.isArray(currentConsistencyCountry)) {
        const newConsistencyCountry = currentConsistencyCountry.slice();
        while (newConsistencyCountry.length < 2) {
            newConsistencyCountry.push(null);
        }
        if (newConsistencyCountry[1] !== "us") {
            newConsistencyCountry[1] = "us";
            data.variations_permanent_consistency_country = newConsistencyCountry;
            consistencyCountryUpdated = true;
        }
    } else {
        data.variations_permanent_consistency_country = [currentConsistencyCountry, "us"];
        consistencyCountryUpdated = true;
    }

    if (consistencyCountryUpdated) {
        changedFields.push(
            "variations_permanent_consistency_country: " +
            oldConsistencyCountry +
            " -> " +
            JSON.stringify(data.variations_permanent_consistency_country)
        );
    } else {
        alreadyFields.push(
            "variations_permanent_consistency_country already has country 'us' in slot 2"
        );
    }

    function walk(item) {
        if (Array.isArray(item)) {
            item.forEach(walk);
            return;
        }

        if (!item || typeof item !== "object") {
            return;
        }

        Object.keys(item).forEach(function (key) {
            const value = item[key];
            if (key === "is_glic_eligible") {
                const oldValueText = formatValueForLog(value);
                if (value !== true) {
                    item[key] = true;
                    glicChanged[oldValueText] = (glicChanged[oldValueText] || 0) + 1;
                } else {
                    glicAlreadyTrue += 1;
                }
            }
            walk(item[key]);
        });
    }

    walk(data);

    Object.keys(glicChanged).sort().forEach(function (oldValue) {
        changedFields.push(
            "is_glic_eligible: " + oldValue + " x" + glicChanged[oldValue] + " -> true"
        );
    });

    if (glicAlreadyTrue > 0) {
        alreadyFields.push("is_glic_eligible already true x" + glicAlreadyTrue);
    }

    writeUtf8(outPath, JSON.stringify(data, null, 2) + "\n");

    const summaryLines = [];
    alreadyFields.forEach(function (item) {
        summaryLines.push("ALREADY\t" + item);
    });
    changedFields.forEach(function (item) {
        summaryLines.push("CHANGED\t" + item);
    });
    writeUtf8(summaryPath, summaryLines.join("\n") + (summaryLines.length ? "\n" : ""));
}
JXA

    mv "$json_tmp" "$file_path"

    while IFS=$'\t' read -r kind message; do
        [ -n "${kind:-}" ] || continue
        if [ "$kind" = "ALREADY" ]; then
            already_fields+=("$message")
        elif [ "$kind" = "CHANGED" ]; then
            changed_fields+=("$message")
        fi
    done < "$summary_tmp"

    rm -f "$summary_tmp"

    write_info_log "Processing results as follows:"
    if [ "${#already_fields[@]}" -gt 0 ]; then
        write_info_log "Already compliant fields:"
        for field in "${already_fields[@]}"; do
            printf "  - %s\n" "$field"
        done
    else
        write_info_log "Already compliant fields: none"
    fi

    if [ "${#changed_fields[@]}" -gt 0 ]; then
        write_success_log "Changed fields:"
        for field in "${changed_fields[@]}"; do
            printf "  - %s\n" "$field"
        done
    else
        write_info_log "Changed fields: none. Target values were already present."
    fi

    write_success_log "Patch complete."
}

main() {
    local chrome_paths=()
    local found_paths=()
    local path

    printf "\n%b=========================================================%b\n" "$COLOR_CYAN" "$COLOR_RESET"
    printf "%b         Enable Chrome AI - Auto Config Tool%b\n" "$COLOR_CYAN" "$COLOR_RESET"
    printf "%b=========================================================%b\n\n" "$COLOR_CYAN" "$COLOR_RESET"

    if ! command -v osascript >/dev/null 2>&1; then
        write_error_log "osascript is required on macOS to patch the Local State JSON file."
        exit 1
    fi

    chrome_paths=(
        "$HOME/Library/Application Support/Google/Chrome/Local State"
        "$HOME/Library/Application Support/Google/Chrome Beta/Local State"
        "$HOME/Library/Application Support/Google/Chrome Canary/Local State"
        "$HOME/Library/Application Support/Google/Chrome Dev/Local State"
    )

    for path in "${chrome_paths[@]}"; do
        if [ -f "$path" ]; then
            found_paths+=("$path")
        fi
    done

    if [ "${#found_paths[@]}" -eq 0 ]; then
        write_error_log "Chrome Local State was not found. Make sure Chrome is installed and has been launched at least once."
        exit 1
    fi

    write_info_log "Found Chrome Local State paths: ${#found_paths[@]}"
    for path in "${found_paths[@]}"; do
        write_info_log " - $path"
    done

    write_stage "PROCESS CHECK"
    if ! confirm_chrome_stop; then
        exit 1
    fi

    write_stage "PATCH EXECUTION START"
    for path in "${found_paths[@]}"; do
        if ! update_local_state_file "$path"; then
            write_error_log "Failed to process $path"
        fi
    done
    write_stage "PATCH EXECUTION COMPLETE"

    write_stage "COMPLETED"
    write_success_log "All operations completed."

    printf "\n%b=========================================================%b\n" "$COLOR_CYAN" "$COLOR_RESET"
    printf "%b                      NEXT STEPS%b\n" "$COLOR_CYAN" "$COLOR_RESET"
    printf "%b=========================================================%b\n" "$COLOR_CYAN" "$COLOR_RESET"
    write_info_log "1. Restart Chrome and check Gemini in the sidebar or settings."
    write_info_log "   If not work, modify Chrome settings according to the guidelines in the README.md file."
    write_info_log "2. To restore, replace Local State with the generated .backup file."
    write_warn_log "   Each run creates a new .backup file. Keep the latest backup file and use it if you need to restore Local State."
}

main "$@"
