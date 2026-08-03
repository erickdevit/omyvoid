use std::fs;
use std::io::Write;
use std::path::Path;
use std::process::{Command, Stdio};
use std::sync::mpsc::{self, Receiver, Sender};
use std::thread;
use std::time::{Duration, Instant};

use crate::storage::{validate_alongside_plan, StoragePlan};

const TARGET: &str = "/mnt";
const MAIN_REPOSITORY: &str = "https://repo-default.voidlinux.org/current";
const BLACKHOLE_REPOSITORY: &str = "https://mirror.black-hole.dev/x86_64";
const OMYVOID_REPOSITORY: &str = "https://packages.omyvoid.org/current";
const ESP_BYTES: u64 = 2 * 1024 * 1024 * 1024;

#[derive(Debug)]
pub enum InstallMessage {
    Progress { percent: u16, message: String },
    Error(String),
    Done,
}

#[derive(Clone)]
pub struct InstallConfig {
    pub storage: StoragePlan,
    pub encrypt: bool,
    pub luks_pass: String,
    pub hostname: String,
    pub username: String,
    pub password: String,
    pub root_password: String,
    pub language: String,
    pub locale: String,
    pub keymap: String,
    pub timezone: String,
    pub offline: bool,
}

impl std::fmt::Debug for InstallConfig {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("InstallConfig")
            .field("storage", &self.storage)
            .field("encrypt", &self.encrypt)
            .field("hostname", &self.hostname)
            .field("username", &self.username)
            .field("language", &self.language)
            .field("locale", &self.locale)
            .field("keymap", &self.keymap)
            .field("timezone", &self.timezone)
            .field("offline", &self.offline)
            .field("password", &"[REDACTED]")
            .field("root_password", &"[REDACTED]")
            .field("luks_pass", &"[REDACTED]")
            .finish()
    }
}

pub fn spawn_install(config: InstallConfig) -> Receiver<InstallMessage> {
    let (tx, rx) = mpsc::channel();
    thread::spawn(move || {
        if let Err(error) = run_install(&config, &tx) {
            let _ = tx.send(InstallMessage::Error(error));
        } else {
            let _ = tx.send(InstallMessage::Done);
        }
    });
    rx
}

fn progress(tx: &Sender<InstallMessage>, percent: u16, message: impl Into<String>) {
    let _ = tx.send(InstallMessage::Progress {
        percent,
        message: message.into(),
    });
}

fn command(args: &[&str]) -> Result<(), String> {
    let output = Command::new(args[0])
        .args(&args[1..])
        .output()
        .map_err(|error| format!("Failed to run '{}': {error}", args[0]))?;
    if output.status.success() {
        return Ok(());
    }
    let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
    Err(if stderr.is_empty() {
        format!("Command failed: {}", args.join(" "))
    } else {
        format!("Command failed: {}\n{stderr}", args.join(" "))
    })
}

fn command_stdin(args: &[&str], input: &[u8]) -> Result<(), String> {
    let mut child = Command::new(args[0])
        .args(&args[1..])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|error| format!("Failed to run '{}': {error}", args[0]))?;
    child
        .stdin
        .take()
        .ok_or_else(|| format!("Could not open stdin for {}", args[0]))?
        .write_all(input)
        .map_err(|error| format!("Could not write to {}: {error}", args[0]))?;
    let output = child
        .wait_with_output()
        .map_err(|error| format!("Could not wait for {}: {error}", args[0]))?;
    if output.status.success() {
        Ok(())
    } else {
        Err(format!(
            "Command failed: {}\n{}",
            args.join(" "),
            String::from_utf8_lossy(&output.stderr).trim()
        ))
    }
}

fn quiet_command(args: &[&str]) {
    let _ = Command::new(args[0])
        .args(&args[1..])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status();
}

fn output(args: &[&str]) -> Result<String, String> {
    let value = Command::new(args[0])
        .args(&args[1..])
        .output()
        .map_err(|error| format!("Failed to run '{}': {error}", args[0]))?;
    if !value.status.success() {
        return Err(format!("Command failed: {}", args.join(" ")));
    }
    Ok(String::from_utf8_lossy(&value.stdout).trim().to_string())
}

fn write_file(path: impl AsRef<Path>, content: impl AsRef<[u8]>) -> Result<(), String> {
    fs::write(path.as_ref(), content)
        .map_err(|error| format!("Failed to write {}: {error}", path.as_ref().display()))
}

fn partition_path(disk: &str, number: u32) -> String {
    let separator = if disk
        .chars()
        .last()
        .is_some_and(|value| value.is_ascii_digit())
    {
        "p"
    } else {
        ""
    };
    format!("{disk}{separator}{number}")
}

fn wait_for_device(path: &str) -> Result<(), String> {
    let deadline = Instant::now() + Duration::from_secs(10);
    while Instant::now() < deadline {
        if Path::new(path).exists() {
            return Ok(());
        }
        thread::sleep(Duration::from_millis(200));
    }
    Err(format!("Partition device did not appear: {path}"))
}

fn secure_boot_enabled() -> bool {
    fs::read_dir("/sys/firmware/efi/efivars")
        .ok()
        .into_iter()
        .flatten()
        .filter_map(Result::ok)
        .filter(|entry| {
            entry
                .file_name()
                .to_string_lossy()
                .starts_with("SecureBoot-")
        })
        .any(|entry| {
            fs::read(entry.path())
                .ok()
                .is_some_and(|data| data.get(4) == Some(&1))
        })
}

fn clean_target(disk: &str) {
    quiet_command(&["swapoff", "-a"]);
    if let Ok(mounts) = output(&["findmnt", "-rn", "-o", "TARGET,SOURCE"]) {
        let mut targets: Vec<&str> = mounts
            .lines()
            .filter_map(|line| {
                let mut fields = line.split_whitespace();
                let target = fields.next()?;
                let source = fields.next()?;
                source.starts_with(disk).then_some(target)
            })
            .collect();
        targets.sort_by_key(|target| std::cmp::Reverse(target.len()));
        for target in targets {
            quiet_command(&["umount", "-lf", target]);
        }
    }
    quiet_command(&["cryptsetup", "close", "omyvoid_crypt"]);
}

fn create_partitions(storage: &StoragePlan) -> Result<(String, String, Option<String>), String> {
    let disk = storage.disk();
    match storage {
        StoragePlan::EraseDisk { .. } => {
            clean_target(disk);
            command(&["sgdisk", "--zap-all", disk])?;
            command(&[
                "sgdisk",
                "-n",
                "1:0:+2G",
                "-t",
                "1:ef00",
                "-c",
                "1:OMYVOID_BOOT",
                "-n",
                "2:0:0",
                "-t",
                "2:8300",
                "-c",
                "2:OMYVOID_ROOT",
                disk,
            ])?;
            quiet_command(&["partprobe", disk]);
            quiet_command(&["udevadm", "settle"]);
            let boot = partition_path(disk, 1);
            let root = partition_path(disk, 2);
            wait_for_device(&boot)?;
            wait_for_device(&root)?;
            Ok((boot, root, None))
        }
        StoragePlan::AlongsideWindows {
            esp_uuid,
            boot_partition_number,
            root_partition_number,
            free_region,
            ..
        } => {
            validate_alongside_plan(storage)?;
            fs::create_dir_all("/run/omyvoid-installer").ok();
            command(&[
                "sgdisk",
                "--backup=/run/omyvoid-installer/partition-table.gpt",
                disk,
            ])?;
            let sector_size: u64 = output(&["blockdev", "--getss", disk])?
                .parse()
                .map_err(|_| "Could not determine disk sector size".to_string())?;
            let boot_sectors = ESP_BYTES / sector_size;
            let boot_end = free_region
                .start_sector
                .checked_add(boot_sectors)
                .and_then(|value| value.checked_sub(1))
                .ok_or_else(|| "Invalid free-space geometry".to_string())?;
            if boot_end >= free_region.end_sector {
                return Err(
                    "The selected free region cannot contain a 2 GiB boot partition".into(),
                );
            }
            let boot_range = format!(
                "{boot_partition_number}:{}:{boot_end}",
                free_region.start_sector
            );
            let boot_type = format!("{boot_partition_number}:ef00");
            let boot_label = format!("{boot_partition_number}:OMYVOID_BOOT");
            let root_range = format!(
                "{root_partition_number}:{}:{}",
                boot_end + 1,
                free_region.end_sector
            );
            let root_type = format!("{root_partition_number}:8300");
            let root_label = format!("{root_partition_number}:OMYVOID_ROOT");
            command(&[
                "sgdisk",
                "-n",
                &boot_range,
                "-t",
                &boot_type,
                "-c",
                &boot_label,
                "-n",
                &root_range,
                "-t",
                &root_type,
                "-c",
                &root_label,
                disk,
            ])?;
            quiet_command(&["partprobe", disk]);
            quiet_command(&["udevadm", "settle"]);
            let boot = partition_path(disk, *boot_partition_number);
            let root = partition_path(disk, *root_partition_number);
            if let Err(error) = wait_for_device(&boot).and_then(|_| wait_for_device(&root)) {
                let boot_number = boot_partition_number.to_string();
                let root_number = root_partition_number.to_string();
                quiet_command(&["sgdisk", "-d", &boot_number, "-d", &root_number, disk]);
                return Err(error);
            }
            Ok((boot, root, Some(esp_uuid.clone())))
        }
    }
}

fn create_filesystems(
    boot_partition: &str,
    root_partition: &str,
    encrypted: bool,
    passphrase: &str,
) -> Result<(String, Option<String>), String> {
    command(&[
        "mkfs.vfat",
        "-F",
        "32",
        "-n",
        "OMYVOID_BOOT",
        boot_partition,
    ])?;
    let (root_device, luks_uuid) = if encrypted {
        command_stdin(
            &[
                "cryptsetup",
                "luksFormat",
                "--batch-mode",
                "--type",
                "luks2",
                "--pbkdf",
                "argon2id",
                "--key-file",
                "-",
                root_partition,
            ],
            passphrase.as_bytes(),
        )?;
        command_stdin(
            &[
                "cryptsetup",
                "open",
                "--key-file",
                "-",
                root_partition,
                "omyvoid_crypt",
            ],
            passphrase.as_bytes(),
        )?;
        (
            "/dev/mapper/omyvoid_crypt".to_string(),
            Some(output(&["cryptsetup", "luksUUID", root_partition])?),
        )
    } else {
        (root_partition.to_string(), None)
    };
    command(&["mkfs.btrfs", "-f", "-L", "OMYVOID_ROOT", &root_device])?;
    Ok((root_device, luks_uuid))
}

fn mount_layout(root_device: &str, boot_partition: &str) -> Result<(), String> {
    fs::create_dir_all(TARGET).map_err(|error| format!("Could not create {TARGET}: {error}"))?;
    command(&["mount", "-o", "subvolid=5", root_device, TARGET])?;
    for subvolume in ["@", "@home", "@log", "@xbps", "@snapshots"] {
        command(&[
            "btrfs",
            "subvolume",
            "create",
            &format!("{TARGET}/{subvolume}"),
        ])?;
    }
    command(&["umount", TARGET])?;
    command(&[
        "mount",
        "-o",
        "subvol=@,noatime,compress=zstd",
        root_device,
        TARGET,
    ])?;
    for directory in ["home", "var/log", "var/cache/xbps", ".snapshots", "boot"] {
        fs::create_dir_all(format!("{TARGET}/{directory}"))
            .map_err(|error| format!("Could not create target directory {directory}: {error}"))?;
    }
    for (subvolume, mountpoint) in [
        ("@home", "home"),
        ("@log", "var/log"),
        ("@xbps", "var/cache/xbps"),
        ("@snapshots", ".snapshots"),
    ] {
        command(&[
            "mount",
            "-o",
            &format!("subvol={subvolume},noatime,compress=zstd"),
            root_device,
            &format!("{TARGET}/{mountpoint}"),
        ])?;
    }
    command(&["mount", boot_partition, &format!("{TARGET}/boot")])
}

struct TargetCleanup {
    encrypted: bool,
}

impl Drop for TargetCleanup {
    fn drop(&mut self) {
        for mountpoint in [
            "run",
            "sys",
            "proc",
            "dev",
            "boot",
            ".snapshots",
            "var/cache/xbps",
            "var/log",
            "home",
            "",
        ] {
            quiet_command(&["umount", "-R", "-l", &format!("{TARGET}/{mountpoint}")]);
        }
        if self.encrypted {
            quiet_command(&["cryptsetup", "close", "omyvoid_crypt"]);
        }
    }
}

fn find_offline_repository() -> Option<String> {
    [
        "/run/omyvoid/repository",
        "/run/initramfs/live/repository",
        "/run/live/medium/repository",
        "/mnt/omyvoid/repository",
    ]
    .into_iter()
    .find(|path| Path::new(path).join("x86_64-repodata").exists())
    .map(str::to_string)
}

fn xbps_install(root: &str, repositories: &[String], packages: &[String]) -> Result<(), String> {
    let mut process = Command::new("xbps-install");
    process
        .env("XBPS_ARCH", "x86_64")
        .args(["-S", "-y", "-r", root]);
    for repository in repositories {
        process.args(["-R", repository]);
    }
    process.args(packages);
    let output = process
        .output()
        .map_err(|error| format!("Could not start xbps-install: {error}"))?;
    if output.status.success() {
        Ok(())
    } else {
        Err(format!(
            "XBPS installation failed:\n{}",
            String::from_utf8_lossy(&output.stderr).trim()
        ))
    }
}

fn repository_list(offline: bool) -> Result<Vec<String>, String> {
    if offline {
        return find_offline_repository()
            .map(|repository| vec![repository])
            .ok_or_else(|| "The ISO does not contain the signed offline XBPS repository".into());
    }
    Ok(vec![
        MAIN_REPOSITORY.to_string(),
        format!("{MAIN_REPOSITORY}/nonfree"),
        format!("{MAIN_REPOSITORY}/multilib"),
        format!("{MAIN_REPOSITORY}/multilib/nonfree"),
        BLACKHOLE_REPOSITORY.to_string(),
        std::env::var("OMYVOID_XBPS_REPOSITORY")
            .unwrap_or_else(|_| OMYVOID_REPOSITORY.to_string()),
    ])
}

fn packages_from_manifest() -> Result<Vec<String>, String> {
    let source = std::env::var("OMYVOID_PATH").unwrap_or_else(|_| "/opt/omyvoid".into());
    let manifest = fs::read_to_string(format!("{source}/install/omyvoid-base.packages"))
        .map_err(|error| format!("Could not read the Omyvoid package manifest: {error}"))?;
    Ok(manifest
        .lines()
        .map(str::trim)
        .filter(|line| !line.is_empty() && !line.starts_with('#'))
        .map(str::to_string)
        .collect())
}

fn write_xbps_repositories() -> Result<(), String> {
    fs::create_dir_all(format!("{TARGET}/etc/xbps.d"))
        .map_err(|error| format!("Could not create XBPS configuration: {error}"))?;
    write_file(
        format!("{TARGET}/etc/xbps.d/00-repository-main.conf"),
        format!(
            "repository={MAIN_REPOSITORY}\nrepository={MAIN_REPOSITORY}/nonfree\n\
       repository={MAIN_REPOSITORY}/multilib\nrepository={MAIN_REPOSITORY}/multilib/nonfree\n\
       repository={BLACKHOLE_REPOSITORY}\nrepository={OMYVOID_REPOSITORY}\n"
        ),
    )
}

fn copy_omyvoid_source() -> Result<(), String> {
    let source = std::env::var("OMYVOID_PATH").unwrap_or_else(|_| "/opt/omyvoid".into());
    if !Path::new(&source).is_dir() {
        return Err(format!("Omyvoid source directory was not found: {source}"));
    }
    fs::create_dir_all(format!("{TARGET}/opt/omyvoid"))
        .map_err(|error| format!("Could not create /opt/omyvoid: {error}"))?;
    command(&[
        "rsync",
        "-a",
        "--delete",
        "--exclude=.git/",
        "--exclude=build/",
        "--exclude=installer/target/",
        &format!("{source}/"),
        &format!("{TARGET}/opt/omyvoid/"),
    ])
}

fn mount_virtual_filesystems() -> Result<(), String> {
    for directory in ["dev", "proc", "sys", "run"] {
        fs::create_dir_all(format!("{TARGET}/{directory}")).ok();
    }
    command(&["mount", "--rbind", "/dev", &format!("{TARGET}/dev")])?;
    command(&["mount", "--make-rslave", &format!("{TARGET}/dev")])?;
    command(&["mount", "-t", "proc", "proc", &format!("{TARGET}/proc")])?;
    command(&["mount", "--rbind", "/sys", &format!("{TARGET}/sys")])?;
    command(&["mount", "--make-rslave", &format!("{TARGET}/sys")])?;
    command(&["mount", "--rbind", "/run", &format!("{TARGET}/run")])?;
    command(&["mount", "--make-rslave", &format!("{TARGET}/run")])?;
    let _ = fs::copy("/etc/resolv.conf", format!("{TARGET}/etc/resolv.conf"));
    Ok(())
}

fn chroot(args: &[&str]) -> Result<(), String> {
    let mut values = vec!["chroot", TARGET];
    values.extend_from_slice(args);
    command(&values)
}

fn chroot_stdin(args: &[&str], input: &[u8]) -> Result<(), String> {
    let mut values = vec!["chroot", TARGET];
    values.extend_from_slice(args);
    command_stdin(&values, input)
}

fn filesystem_uuid(device: &str) -> Result<String, String> {
    let uuid = output(&["blkid", "-s", "UUID", "-o", "value", device])?;
    if uuid.is_empty() {
        Err(format!("Could not determine filesystem UUID for {device}"))
    } else {
        Ok(uuid)
    }
}

fn fstab(root_uuid: &str, boot_uuid: &str) -> String {
    format!(
        "UUID={root_uuid} / btrfs noatime,compress=zstd,subvol=@ 0 0\n\
     UUID={root_uuid} /home btrfs noatime,compress=zstd,subvol=@home 0 0\n\
     UUID={root_uuid} /var/log btrfs noatime,compress=zstd,subvol=@log 0 0\n\
     UUID={root_uuid} /var/cache/xbps btrfs noatime,compress=zstd,subvol=@xbps 0 0\n\
     UUID={root_uuid} /.snapshots btrfs noatime,compress=zstd,subvol=@snapshots 0 0\n\
     UUID={boot_uuid} /boot vfat noatime,umask=0077 0 2\n"
    )
}

fn configure_identity(cfg: &InstallConfig, root_uuid: &str, boot_uuid: &str) -> Result<(), String> {
    fs::create_dir_all(format!("{TARGET}/etc/sudoers.d")).ok();
    write_file(format!("{TARGET}/etc/fstab"), fstab(root_uuid, boot_uuid))?;
    write_file(
        format!("{TARGET}/etc/hostname"),
        format!("{}\n", cfg.hostname),
    )?;
    write_file(
        format!("{TARGET}/etc/hosts"),
        format!(
            "127.0.0.1 localhost\n127.0.1.1 {}\n::1 localhost ip6-localhost ip6-loopback\n",
            cfg.hostname
        ),
    )?;
    write_file(
        format!("{TARGET}/etc/locale.conf"),
        format!("LANG={}\n", cfg.locale),
    )?;
    write_file(
        format!("{TARGET}/etc/vconsole.conf"),
        format!("KEYMAP={}\n", cfg.keymap),
    )?;
    write_file(
        format!("{TARGET}/etc/sudoers.d/10-omyvoid-wheel"),
        "%wheel ALL=(ALL:ALL) ALL\n",
    )?;
    command(&[
        "chmod",
        "0440",
        &format!("{TARGET}/etc/sudoers.d/10-omyvoid-wheel"),
    ])?;

    chroot(&[
        "ln",
        "-snf",
        &format!("/usr/share/zoneinfo/{}", cfg.timezone),
        "/etc/localtime",
    ])?;
    chroot(&[
        "sed",
        "-i",
        &format!("s/^#{} UTF-8/{} UTF-8/", cfg.locale, cfg.locale),
        "/etc/default/libc-locales",
    ])?;
    chroot(&["xbps-reconfigure", "-f", "glibc-locales"])?;
    chroot(&["useradd", "-m", "-s", "/bin/bash", &cfg.username])?;
    for group in [
        "wheel", "audio", "video", "input", "render", "kvm", "storage", "network", "docker",
    ] {
        let status = Command::new("chroot")
            .args([TARGET, "getent", "group", group])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status()
            .map_err(|error| format!("Could not inspect group {group}: {error}"))?;
        if status.success() {
            chroot(&["usermod", "-aG", group, &cfg.username])?;
        }
    }
    chroot_stdin(
        &["chpasswd"],
        format!(
            "{}:{}\nroot:{}\n",
            cfg.username, cfg.password, cfg.root_password
        )
        .as_bytes(),
    )?;

    let language_dir = format!("{TARGET}/home/{}/.config/omyvoid", cfg.username);
    fs::create_dir_all(&language_dir).ok();
    write_file(
        format!("{language_dir}/language"),
        format!("{}\n", cfg.language),
    )?;
    chroot(&[
        "chown",
        "-R",
        &format!("{}:{}", cfg.username, cfg.username),
        &format!("/home/{}", cfg.username),
    ])
}

fn configure_limine_source(
    root_uuid: &str,
    luks_uuid: Option<&str>,
    windows_uuid: Option<&str>,
) -> Result<(), String> {
    fs::create_dir_all(format!("{TARGET}/etc/default")).ok();
    write_file(
    format!("{TARGET}/etc/default/limine"),
    format!(
      "ESP_PATH=\"/boot\"\nOMYVOID_ROOT_SUBVOLUME=\"@\"\nOMYVOID_ROOT_UUID=\"{root_uuid}\"\n\
       OMYVOID_LUKS_UUID=\"{}\"\nOMYVOID_KERNEL_CMDLINE=\"rw quiet splash loglevel=3 rd.udev.log_level=3\"\n\
       OMYVOID_WINDOWS_EFI_UUID=\"{}\"\nOMYVOID_WINDOWS_EFI_PATH=\"/EFI/Microsoft/Boot/bootmgfw.efi\"\n\
       OMYVOID_KEEP_SNAPSHOTS=5\n",
      luks_uuid.unwrap_or_default(),
      windows_uuid.unwrap_or_default(),
    ),
  )
}

fn run_omyvoid_install(cfg: &InstallConfig) -> Result<(), String> {
    let home = format!("HOME=/home/{}", cfg.username);
    let user = format!("USER={}", cfg.username);
    let language = format!("OMYVOID_LANGUAGE={}", cfg.language);
    let target_user = format!("OMYVOID_TARGET_USER={}", cfg.username);
    let encrypted = format!("OMYVOID_ENCRYPTED_INSTALL={}", cfg.encrypt);
    chroot(&[
        "/usr/bin/env",
        "-i",
        &home,
        &user,
        &format!("LOGNAME={}", cfg.username),
        "SHELL=/bin/bash",
        "TERM=linux",
        "PATH=/opt/omyvoid/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
        "OMYVOID_PATH=/opt/omyvoid",
        "OMYVOID_INSTALL=/opt/omyvoid/install",
        "OMYVOID_INSTALL_LOG_FILE=/var/log/omyvoid-install.log",
        "OMYVOID_CHROOT_INSTALL=true",
        &language,
        &target_user,
        &encrypted,
        "/bin/bash",
        "-e",
        "-c",
        "cd /opt/omyvoid && ./install.sh",
    ])
}

fn run_install(cfg: &InstallConfig, tx: &Sender<InstallMessage>) -> Result<(), String> {
    if !Path::new("/sys/firmware/efi").is_dir() {
        return Err("Omyvoid requires UEFI boot mode".into());
    }
    if secure_boot_enabled() {
        return Err("Disable Secure Boot before installing Omyvoid".into());
    }

    let disk = cfg.storage.disk().to_string();
    progress(tx, 3, "Validating the selected GPT layout...");
    let (boot_partition, root_partition, windows_uuid) = create_partitions(&cfg.storage)?;
    let cleanup = TargetCleanup {
        encrypted: cfg.encrypt,
    };

    progress(tx, 12, "Creating FAT32 boot and Btrfs root filesystems...");
    let (root_device, luks_uuid) = create_filesystems(
        &boot_partition,
        &root_partition,
        cfg.encrypt,
        &cfg.luks_pass,
    )?;
    progress(tx, 20, "Creating the Omyvoid Btrfs subvolume layout...");
    mount_layout(&root_device, &boot_partition)?;

    progress(
        tx,
        30,
        if cfg.offline {
            "Installing Void from the ISO repository..."
        } else {
            "Installing Void from signed online repositories..."
        },
    );
    let repositories = repository_list(cfg.offline)?;
    xbps_install(
        TARGET,
        &repositories,
        &["base-system".into(), "linux".into()],
    )?;
    write_xbps_repositories()?;
    copy_omyvoid_source()?;
    let packages = packages_from_manifest()?;
    xbps_install(TARGET, &repositories, &packages)?;

    progress(
        tx,
        58,
        "Mounting the target runtime and writing system configuration...",
    );
    mount_virtual_filesystems()?;
    let root_uuid = filesystem_uuid(&root_device)?;
    let boot_uuid = filesystem_uuid(&boot_partition)?;
    configure_identity(cfg, &root_uuid, &boot_uuid)?;
    if let Some(uuid) = luks_uuid.as_deref() {
        write_file(
            format!("{TARGET}/etc/crypttab"),
            format!("omyvoid_crypt UUID={uuid} none luks,discard\n"),
        )?;
    }
    configure_limine_source(&root_uuid, luks_uuid.as_deref(), windows_uuid.as_deref())?;

    progress(
        tx,
        68,
        "Applying the Omyvoid desktop and runit configuration...",
    );
    run_omyvoid_install(cfg)?;
    chroot(&[
        "chown",
        "-R",
        &format!("{}:{}", cfg.username, cfg.username),
        &format!("/home/{}", cfg.username),
    ])?;

    if Path::new("/run/omyvoid-installer/partition-table.gpt").is_file() {
        fs::create_dir_all(format!("{TARGET}/var/log")).ok();
        let _ = fs::copy(
            "/run/omyvoid-installer/partition-table.gpt",
            format!("{TARGET}/var/log/omyvoid-partition-table.gpt"),
        );
    }

    progress(
        tx,
        86,
        "Reconfiguring Void kernels and generating Omyvoid UKIs...",
    );
    chroot(&["xbps-reconfigure", "-fa"])?;
    chroot(&["omyvoid", "boot", "repair"])?;
    chroot(&["omyvoid", "snapshot", "create"])?;

    progress(tx, 97, "Synchronizing data and unmounting the target...");
    command(&["sync"])?;
    drop(cleanup);
    progress(
        tx,
        100,
        format!("Omyvoid installation on {disk} is complete"),
    );
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn partition_paths_cover_nvme_and_scsi() {
        assert_eq!(partition_path("/dev/nvme0n1", 3), "/dev/nvme0n1p3");
        assert_eq!(partition_path("/dev/sda", 3), "/dev/sda3");
    }

    #[test]
    fn fstab_contains_every_required_subvolume() {
        let generated = fstab("ROOT", "BOOT");
        for expected in [
            "subvol=@",
            "subvol=@home",
            "subvol=@log",
            "subvol=@xbps",
            "subvol=@snapshots",
        ] {
            assert!(generated.contains(expected));
        }
        assert!(generated.contains("UUID=BOOT /boot vfat"));
        assert!(!generated.contains("swap"));
    }

    #[test]
    fn install_config_debug_redacts_secrets() {
        let config = InstallConfig {
            storage: StoragePlan::EraseDisk {
                disk: "/dev/test".into(),
            },
            encrypt: true,
            luks_pass: "luks-secret".into(),
            hostname: "omyvoid".into(),
            username: "void".into(),
            password: "user-secret".into(),
            root_password: "root-secret".into(),
            language: "en".into(),
            locale: "en_US.UTF-8".into(),
            keymap: "us".into(),
            timezone: "UTC".into(),
            offline: true,
        };
        let debug = format!("{config:?}");
        assert!(!debug.contains("luks-secret"));
        assert!(!debug.contains("user-secret"));
        assert!(!debug.contains("root-secret"));
    }
}
