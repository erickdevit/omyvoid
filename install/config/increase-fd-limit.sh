# Raise file descriptor limits for developer tools and desktop sessions.
sudo mkdir -p /etc/security/limits.d
sudo tee /etc/security/limits.d/99-omyvoid-nofile.conf >/dev/null <<'EOF'
* soft nofile 65536
* hard nofile 524288
root soft nofile 65536
root hard nofile 524288
EOF
