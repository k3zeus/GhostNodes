#!/bin/bash
# Nodenation Mock Test Runner for WSL
# Mocks destructive commands to safely test the menu logic in WSL

mkdir -p /tmp/mock_bin
export PATH="/tmp/mock_bin:$PATH"

# Mock sudo
cat << 'EOF' > /tmp/mock_bin/sudo
#!/bin/bash
echo "[MOCK SUDO] $@"
exec "$@"
EOF

# Mock apt-get
cat << 'EOF' > /tmp/mock_bin/apt-get
#!/bin/bash
echo "[MOCK APT] $@"
exit 0
EOF

# Mock adduser
cat << 'EOF' > /tmp/mock_bin/adduser
#!/bin/bash
echo "[MOCK ADDUSER] $@"
#!/bin/bash
echo "[MOCK CHPASSWD] Password changed"
exit 0
EOF

# Mock systemctl
cat << 'EOF' > /tmp/mock_bin/systemctl
#!/bin/bash
echo "[MOCK SYSTEMCTL] $@"
exit 0
EOF

# Mock chown
cat << 'EOF' > /tmp/mock_bin/chown
#!/bin/bash
echo "[MOCK CHOWN] $@"
exit 0
EOF

chmod +x /tmp/mock_bin/*

# Remove EUID check from a copy of the script so it doesn't abort
cp nodenation nodenation_test.sh
sed -i 's/if \[ "$EUID" -ne 0 \]; then/if false; then/' nodenation_test.sh

# Remove the TTY hijack block
sed -i '/if \[ ! -t 0 \]; then/,/fi/d' nodenation_test.sh

echo "Mock environment ready. Running nodenation..."

# We will simulate keystrokes: '2' (Satoshi Menu) -> 'q' (Quit)
cat << 'INPUT' > input_sequence.txt
2
q
INPUT

bash nodenation_test.sh < input_sequence.txt > test_output.log 2>&1
echo "Test finished. Output:"
cat test_output.log
