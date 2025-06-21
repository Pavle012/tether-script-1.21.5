#!/bin/bash

status() {
    echo "⦿ $1"
}

run_quietly() {
    output=$("$@" 2>&1) || {
        echo "Error running command: $1"
        echo "$output"
        return 1
    }
}

setup() {
if [ -d "$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu" ]; then
  echo "Ubuntu is installed."
else
  pkg install -y proot-distro && proot-distro install ubuntu
fi

UPDATED_FLAG="$PREFIX/var/lib/proot-distro/ubuntu-updated.flag"

if [ ! -f "$UPDATED_FLAG" ]; then
  proot-distro login ubuntu -- bash -c "apt update && apt upgrade -y"
  touch "$UPDATED_FLAG"
fi

proot-distro login ubuntu -- bash -c "apt install -y curl git micro"

    status "Setting up Minecraft server environment..."
    
    mkdir -p ~/tether
    cd ~/tether
    
    status "Downloading Paper server jar..."
    run_quietly curl -s -OL 
https://api.papermc.io/v2/projects/paper/versions/1.21.5/builds/114/downloads/paper-1.21.5-114.jar

    status "Downloading Java Runtime Environment..."
    run_quietly curl -s -OL https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.6%2B7/OpenJDK21U-jre_aarch64_linux_hotspot_21.0.6_7.tar.gz

    status "Extracting Java Runtime Environment..."
    run_quietly tar -xzf OpenJDK21U-jre_aarch64_linux_hotspot_21.0.6_7.tar.gz

    status "Cleaning up temporary files..."
    run_quietly rm -f OpenJDK21U-jre_aarch64_linux_hotspot_21.0.6_7.tar.gz

    status "Installing proot-distro..."
    run_quietly pkg install proot-distro -y >/dev/null 2>&1

    status "Installing Ubuntu environment (this may take a while)..."
    run_quietly proot-distro install ubuntu >/dev/null 2>&1

    # Create eula.txt file and accept it
    status "Accepting Minecraft EULA..."
    echo "eula=true" > eula.txt

    create_run_script

    add_to_path
    
    status "Setup complete!"
}

create_run_script() {
    status "Creating server startup script..."
    
    cat > ~/tether/run.sh << 'EOF'
#!/bin/bash

status() {
    echo "⦿ $1"
}

if [ "$(basename "$(pwd)")" != "tether" ]; then
    cd ~/tether || { echo "Error: Could not find tether directory"; exit 1; }
fi

status "Starting Minecraft server..."
proot-distro login ubuntu --bind ~/tether:/root -- bash -c 'cd /root && ./jdk-21.0.6+7-jre/bin/java -Xmx3G -jar  paper-1.21.5-114.jar nogui'
EOF

    chmod +x ~/tether/run.sh
}

add_to_path() {
    status "Adding tether command to system PATH..."
    
    cat > "$PREFIX/bin/tether" << 'EOF'
#!/bin/bash

status() {
    echo "⦿ $1"
}

RUN_SCRIPT="$HOME/tether/run.sh"

if [ ! -f "$RUN_SCRIPT" ]; then
    echo "Error: Minecraft server is not set up properly."
    echo "Please run the setup script again."
    exit 1
fi

"$RUN_SCRIPT"
EOF
    
    chmod +x "$PREFIX/bin/tether"
    
    status "You can now start your server by typing 'tether' anywhere in Termux"
}

# Main execution
clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "                      TETHER"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if tether directory exists
if [ -d ~/tether ]; then
    # If run.sh doesn't exist, create it
    if [ ! -f ~/tether/run.sh ]; then
        create_run_script
    fi
    
    # Check if tether command exists in PATH
    if [ ! -f "$PREFIX/bin/tether" ]; then
        add_to_path
    else
        status "Server is already set up"
    fi
    
    status "Type 'tether' to start your Minecraft server"
else
    # First time setup
    setup
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
