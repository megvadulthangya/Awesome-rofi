#!/bin/bash

# ------------------------------------------------------
#  Rofi témák telepítése - Többnyelvű verzió
# ------------------------------------------------------

# Nyelv érzékelése
detect_language() {
    if [[ "$LANG" =~ hu.* ]] || [[ "$LANGUAGE" =~ hu.* ]]; then
        echo "hu"
    else
        echo "en"
    fi
}

LANG=$(detect_language)

# Nyelvi stringek
if [ "$LANG" = "hu" ]; then
    MSG_INSTALLING="Rofi témák telepítése a megvadulthangya forkjából..."
    MSG_CHECKING_REPO="Repository állapot ellenőrzése..."
    MSG_CLONING_REPO="Repository klónozása a GitHubról..."
    MSG_CLONING_TO="Klónozás ide:"
    MSG_INSTALLING_FONTS="Betűtípusok telepítése (system-wide)..."
    MSG_UPDATING_FONT_CACHE="Betűtípus gyorsítótár frissítése..."
    MSG_BACKING_UP_CONFIG="Meglévő Rofi konfiguráció biztonsági mentése ide:"
    MSG_INSTALLING_THEMES="Rofi témák telepítése..."
    MSG_INSTALLING_SCRIPTS="Scriptek telepítése /usr/local/bin-be..."
    MSG_REMOVING_SCRIPTS_FOLDER="Scripts mappa eltávolítása a Rofi konfigurációból..."
    MSG_CLEANING_UP="Tisztítás..."
    MSG_SUCCESS="Rofi témák sikeresen telepítve!"
    MSG_ERROR_SUDO="HIBA: A scriptet sudo-val kell futtatni a system-wide betűtípus telepítéséhez!"
    MSG_ERROR_INSTALL="HIBA: A Rofi témák telepítése sikertelen."
    MSG_REPO_EXISTS="Repository már létezik, közvetlen telepítés a lokális fájlokból..."
    MSG_KEEPING_FILES="Klónozott repository fájlok megtartása..."
    MSG_SKIPPING_ROOT="Root felhasználó kihagyva (telepítés csak rendszeres felhasználók számára)..."
else
    MSG_INSTALLING="Installing Rofi themes from megvadulthangya fork..."
    MSG_CHECKING_REPO="Checking repository status..."
    MSG_CLONING_REPO="Cloning repository from GitHub..."
    MSG_CLONING_TO="Cloning to:"
    MSG_INSTALLING_FONTS="Installing fonts (system-wide)..."
    MSG_UPDATING_FONT_CACHE="Updating font cache..."
    MSG_BACKING_UP_CONFIG="Backing up existing Rofi configuration to:"
    MSG_INSTALLING_THEMES="Installing Rofi themes..."
    MSG_INSTALLING_SCRIPTS="Installing scripts to /usr/local/bin..."
    MSG_REMOVING_SCRIPTS_FOLDER="Removing scripts folder from Rofi configuration..."
    MSG_CLEANING_UP="Cleaning up..."
    MSG_SUCCESS="Rofi themes successfully installed!"
    MSG_ERROR_SUDO="ERROR: Script must be run with sudo for system-wide font installation!"
    MSG_ERROR_INSTALL="ERROR: Rofi themes installation failed."
    MSG_REPO_EXISTS="Repository exists, installing directly from local files..."
    MSG_KEEPING_FILES="Keeping cloned repository files..."
    MSG_SKIPPING_ROOT="Skipping root user (installation only for regular users)..."
fi

echo "[INFO] $MSG_INSTALLING"

# Sudo jogok ellenőrzése
if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] $MSG_ERROR_SUDO"
    exit 1
fi

# Repository állapot ellenőrzése
echo "[INFO] $MSG_CHECKING_REPO"

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_CLONE=false

# Ellenőrizzük, hogy a jelenlegi könyvtár klónozott repository-e
if [ -d "$CURRENT_DIR/.git" ] && \
   [ -d "$CURRENT_DIR/.github" ] && \
   [ -d "$CURRENT_DIR/files" ] && \
   [ -d "$CURRENT_DIR/fonts" ] && \
   [ -d "$CURRENT_DIR/previews" ] && \
   [ -f "$CURRENT_DIR/LICENSE" ] && \
   [ -f "$CURRENT_DIR/README.md" ] && \
   [ -f "$CURRENT_DIR/setup.sh" ]; then
    
    echo "[INFO] $MSG_REPO_EXISTS"
    WORK_DIR="$CURRENT_DIR"
    TEMP_CLONE=false
else
    echo "[INFO] $MSG_CLONING_REPO"
    WORK_DIR="/tmp/rofi-themes-$$"
    echo "[INFO] $MSG_CLONING_TO $WORK_DIR"
    git clone --depth=1 -b my-awesome-config https://github.com/megvadulthangya/awesome-rofi.git "$WORK_DIR"
    if [ $? -ne 0 ]; then
        echo "[ERROR] $MSG_ERROR_INSTALL"
        exit 1
    fi
    TEMP_CLONE=true
    cd "$WORK_DIR"
fi

# Betűtípusok telepítése (system-wide)
echo "[INFO] $MSG_INSTALLING_FONTS"
FONT_DIR="/usr/share/fonts/rofi-themes"
mkdir -p "$FONT_DIR"
cp -rf "$WORK_DIR/fonts/"* "$FONT_DIR" 2>/dev/null

# Betűtípus gyorsítótár frissítése
echo "[INFO] $MSG_UPDATING_FONT_CACHE"
fc-cache -f -v

# Rofi konfiguráció telepítése minden felhasználó számára
# /etc/skel-be másolás (új felhasználók számára)
if [ -d "/etc/skel" ]; then
    SKEL_ROFI_DIR="/etc/skel/.config/rofi"
    mkdir -p "$SKEL_ROFI_DIR"
    if [ -d "$SKEL_ROFI_DIR" ] && [ ! -L "$SKEL_ROFI_DIR" ]; then
        mv "$SKEL_ROFI_DIR" "${SKEL_ROFI_DIR}.bak"
    fi
    cp -rf "$WORK_DIR/files/"* "$SKEL_ROFI_DIR" 2>/dev/null
    # Scripts mappa eltávolítása a célból
    if [ -d "$SKEL_ROFI_DIR/scripts" ]; then
        rm -rf "$SKEL_ROFI_DIR/scripts"
    fi
fi

# Meglévő felhasználók számára
for USER_HOME in /home/*; do
    if [ -d "$USER_HOME" ] && [ "$(basename "$USER_HOME")" != "root" ]; then
        USER=$(basename "$USER_HOME")
        USER_ROFI_DIR="$USER_HOME/.config/rofi"
        
        if [ -d "$USER_ROFI_DIR" ]; then
            echo "[INFO] $MSG_BACKING_UP_CONFIG ${USER_ROFI_DIR}.bak"
            mv "$USER_ROFI_DIR" "${USER_ROFI_DIR}.bak"
        fi
        
        echo "[INFO] $MSG_INSTALLING_THEMES for user: $USER"
        mkdir -p "$USER_HOME/.config"
        cp -rf "$WORK_DIR/files/"* "$USER_ROFI_DIR" 2>/dev/null
        
        # Scripts mappa eltávolítása a célból
        if [ -d "$USER_ROFI_DIR/scripts" ]; then
            rm -rf "$USER_ROFI_DIR/scripts"
        fi
        
        # Jogok beállítása
        chown -R "$USER:$USER" "$USER_ROFI_DIR"
    fi
done

echo "[INFO] $MSG_SKIPPING_ROOT"

# Scriptek telepítése /usr/local/bin-be
if [ -d "$WORK_DIR/files/scripts" ]; then
    echo "[INFO] $MSG_INSTALLING_SCRIPTS"
    cp -rf "$WORK_DIR/files/scripts/"* "/usr/local/bin/" 2>/dev/null
    chmod +x /usr/local/bin/* 2>/dev/null
fi

# Tisztítás - CSAK ha ideiglenes klónozás történt
if [ "$TEMP_CLONE" = true ]; then
    echo "[INFO] $MSG_CLEANING_UP"
    rm -rf "$WORK_DIR"
else
    echo "[INFO] $MSG_KEEPING_FILES"
    # Klónozott repository esetén nem törlünk semmit a forrásból
fi

echo "[SUCCESS] $MSG_SUCCESS"
