# Configure Docker daemon and limit log size to avoid filling Btrfs.
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json >/dev/null <<'EOF'
{
    "log-driver": "json-file",
    "log-opts": { "max-size": "10m", "max-file": "5" }
}
EOF

chrootable_runit_enable docker

# Give this user privileged Docker access
docker_user=${OMYVOID_TARGET_USER:-${SUDO_USER:-${USER:-}}}
if [[ -n $docker_user && $docker_user != "root" ]]; then
  sudo usermod -aG docker "$docker_user"
fi
