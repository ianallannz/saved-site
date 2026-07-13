# Saved GP — USB Setup Scripts

Scripts to configure a freshly installed Bluefin laptop with the Saved GP
experience: custom panel, menu, wallpaper, GNOME extensions, and apps.

---

## USB folder structure

```
saved-usb/
├── 01-setup.sh            ← system-level setup (run as root)
├── 02-apply-to-user.sh    ← apply to an existing user (run as that user)
├── README.md              ← this file
├── assets/
│   ├── wallpaper.png      ← ADD YOUR WALLPAPER HERE
│   └── menu-icon.png      ← ADD YOUR MENU ICON HERE
└── extensions.tar.gz      ← OPTIONAL but recommended (see below)
```

---

## Before you start: prepare the USB

### 1. Add your asset files

Copy your wallpaper and menu icon into the `assets/` folder:

```
assets/wallpaper.png
assets/menu-icon.png
```

### 2. (Recommended) Export extensions from your reference laptop

This is the fastest, most reliable way to get extensions onto each laptop —
no internet download needed, no version compatibility guesswork.

On your **configured reference laptop**, open a terminal and run:

```bash
cd ~/.local/share/gnome-shell
tar czf ~/extensions.tar.gz extensions/
```

Copy `extensions.tar.gz` from your home folder to the USB root (next to
`01-setup.sh`). The setup script will find it and extract it automatically.

---

## Per-laptop process (takes ~15–30 min with internet, ~5 min offline)

### Step 1 — Complete Bluefin initial setup

Boot the laptop. Go through the GNOME Initial Setup wizard:
- Create an **admin account** (you'll use this to run the scripts)
- Connect to **Wi-Fi**
- Skip anything else you don't need yet

**If the laptop fails to boot into Bluefin**, you may need to set a custom
boot entry in the BIOS. Restart and enter the BIOS/UEFI firmware (typically
`F2`, `F10`, `Del`, or `Esc` during startup), then:

1. Navigate to **Advanced → Boot Options**
2. Enable **Customized Boot** and set the path to:
   ```
   \EFI\fedora\grubx64.efi
   ```
3. Move **Customized Boot** to the top of the boot order
4. Save and exit — the laptop should now boot into Bluefin

### Step 2 — Plug in the USB, open a terminal

Press `Ctrl+Alt+T` to open Ptyxis, or find Terminal in the apps.

### Step 3 — Run the system setup script

```bash
cd /run/media/admin/'USB DISK'
sudo bash 01-setup.sh
```

This will:
- Copy your wallpaper and menu icon to `/var/lib/saved/assets/`
- Write GNOME defaults to `/etc/dconf/db/local.d/00-saved-defaults`
- Stage extensions into `/etc/skel/.local/share/gnome-shell/extensions/`
- Install Flatpak apps system-wide from Flathub

**If offline:** The script skips Flatpak installs and extension downloads.
Re-run it once connected — it skips anything already done.

### Step 4 — Apply settings to the admin user

The dconf defaults and skel only apply automatically to **new** accounts.
Your admin account already exists, so run this while logged in as admin:

```bash
bash 02-apply-to-user.sh
```

Then **log out and log back in** (Wayland requires this).

### Step 5 — Create the education user accounts

Go to **Settings → Users → Add User** and create the student/staff accounts.

Each new user will automatically get:
- The Saved GP wallpaper and panel layout
- All the GNOME extensions pre-installed and enabled
- Access to all system-wide Flatpak apps

### Step 6 — Reboot and verify

Log in as one of the new accounts and check:
- [ ] Wallpaper shows correctly
- [ ] Dash-to-Panel is at the bottom with the right layout
- [ ] ArcMenu shows the Saved icon and "Menu" label
- [ ] Blur My Shell is active on the panel
- [ ] Brave, Chrome, and OnlyOffice are in the taskbar/favourites
- [ ] `Ctrl+Alt+T` opens the terminal

---

## Troubleshooting

### Extensions not showing for a new user

Extensions need to be both *installed* (files on disk) and *enabled* (in
dconf). Check both:

```bash
# Are the extension files there?
ls ~/.local/share/gnome-shell/extensions/

# Is the enabled list set?
dconf read /org/gnome/shell/enabled-extensions
```

If the extensions folder is empty, run `02-apply-to-user.sh` as that user.

### Wallpaper not applying

Check the file exists:
```bash
ls /var/lib/saved/assets/wallpaper.png
```

If missing, re-run `sudo bash 01-setup.sh` with `assets/wallpaper.png` on
the USB.

Set it manually for quick testing:
```bash
gsettings set org.gnome.desktop.background picture-uri \
    'file:///var/lib/saved/assets/wallpaper.png'
```

### dconf settings not taking effect

Recompile the system database:
```bash
sudo dconf update
```

Then log out and back in.

### An extension fails to download

Either add it to `extensions/` on the USB (copy the folder from your
reference laptop's `~/.local/share/gnome-shell/extensions/<uuid>/`), or
install it manually via Extension Manager once the laptop is set up.

### Flatpak install fails

Some apps (Brave, Chrome) occasionally have Flathub hiccups. Retry manually:
```bash
sudo flatpak install --system flathub com.brave.Browser
```

---

## Customising the app list

Edit the `APPS=(...)` section in `01-setup.sh` to add or remove apps for
the education context. Each line is a Flathub app ID.

To find an app ID: search on https://flathub.org and look at the URL, e.g.
`https://flathub.org/apps/org.gnome.Clocks` → ID is `org.gnome.Clocks`.

---

## The path to a proper blue-build image

Once the pilot is validated, this whole process can be encoded into a
[blue-build](https://blue-build.org/) recipe. The key ingredients:

- **dconf defaults** → `files/system/etc/dconf/db/local.d/`
- **Extensions** → `files/system/usr/share/gnome-shell/extensions/`
  *(on the custom image these go system-wide, not in skel)*
- **Assets** → `files/system/var/lib/saved/assets/`
- **Flatpaks** → listed in the recipe's `flatpak` module
- **Packages** → any system packages via the `rpm-ostree` module

The blue-build `recipe.yml` would replace both scripts entirely —
laptops arrive pre-configured from the image, zero manual steps needed.

---

## Files placed on the laptop by these scripts

| Path | What |
|------|------|
| `/var/lib/saved/assets/wallpaper.png` | Wallpaper (shared, all users) |
| `/var/lib/saved/assets/menu-icon.png` | ArcMenu icon (shared, all users) |
| `/etc/dconf/db/local.d/00-saved-defaults` | GNOME defaults for all users |
| `/etc/skel/.local/share/backgrounds/saved-wallpaper.png` | Wallpaper copy in new-user template |
| `/etc/skel/.local/share/gnome-shell/extensions/` | Extension files for new users |

---

*Saved GP v0.1 — for the pilot at the education centre*
