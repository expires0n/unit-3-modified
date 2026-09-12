# unit-3-modified

Hyprland + Quickshell rice (mor pastel **Pastel Dusk** temalı).
Kaynak: [samyns/Unit-3](https://github.com/samyns/Unit-3) — onun üstüne kişisel çatallama.

## Tek tık kurulum

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/expires0n/unit-3-modified/main/install.sh)
```

Script sorar, yedekler (`~/.config-backup-*`), kurar. `~/.config/hypr/user.conf` güncellemelerde **ezilmez**.

## Neler var (orijinalden farklar)

- **Tema**: Pastel Dusk — koyu mor zemin `#14101D`, lavanta yazı `#D8CDF5`, mor vurgu `#A78BFA`, pembe dokunuş `#F0A6D6`
- **Font**: Apple SF Pro Text + SF Mono (fontconfig varsayılanı)
- **İmleç**: macOS siyah (AUR: `apple_cursor`)
- **Başlat menüsü (SUPER)**: BOOKMARKS sekmesi (varsayılan açık), tümde-arama, gerçek ikonlar, nokta dokusu + kuzey yıldızı, koyu tema
- **Player**: sağ kenar hover ile açılır, fullscreen'de bulaşmaz, seek sırasında kapanmaz
- **Timer popup**: bardaki TMR'ye tıkla — preset/custom/kronometre (max 24h)
- **Bar**: GPU kullanımı (AMD sysfs), timer, pomodoro yerine TMR
- **Klavye**: TR Q, monitörler 75Hz çift ekran örneği `user.conf` içinde
- **Kısayollar**: `SUPER+Space` terminal, `SUPER+E` Dolphin, `SUPER+SHIFT+S` dondurmalı SS (panoya + Resimler), `SUPER+D/S` gizli sekmeler

## Kısayollar

| Tuş | İş |
|-----|-----|
| `SUPER` (dokun) | Başlat menüsü |
| `SUPER + Tab` | Kontrol merkezi |
| `SUPER + L` | Kilit |
| `SUPER + Space` | Terminal (kitty) |
| `SUPER + E` | Dolphin |
| `SUPER + P` | Duvar kağıdı seçici (kalıcı olur) |
| `SUPER + Enter` | (kaldırıldı — player hover ile) |
| `SUPER + Q` | Pencereyi kapat |
| `SUPER + F` | Büyüt (maximize) |
| `SUPER + SHIFT + F` | Tam ekran |
| `SUPER + S` | Spotify sekmesi |
| `SUPER + D` / `SUPER + M` | Gizli `magic` sekmesi |
| `SUPER + SHIFT + D` | Pencereyi magic'e gönder |
| `SUPER + SHIFT + S` | Dondurmalı alan SS (pano + Resimler) |
| `SUPER + 1..0` / `ALT + 1..0` | Masaüstü (bulunduğun monitörde) |
| `ALT + Tab` | Pencere döngüsü |

## Kurulum sonrası el işleri (opsiyonel)

**Otomatik giriş + Unit-3 kilidi** (Noctalia greeter yerine):
```fish
sudo cp /etc/greetd/config.toml /etc/greetd/config.toml.bak
printf '\n[initial_session]\ncommand = "uwsm start -e -D Hyprland hyprland.desktop"\nuser = "KULLANICI-ADIN"\n' | sudo tee -a /etc/greetd/config.toml > /dev/null
```
`KULLANICI-ADIN` yerine kullanıcı adını yaz (tırnaklar kalsın). Bozarsa: `Ctrl+Alt+F3` ile konsola geçip yedeği geri kopyala:
```fish
sudo cp /etc/greetd/config.toml.bak /etc/greetd/config.toml; and sudo reboot
```

**2. disk otomount (şifresiz)** — `/etc/fstab`:
```
UUID=DISK-UUID /mnt/870EVO ntfs3 rw,nofail,x-systemd.device-timeout=10,uid=1000,gid=1000,umask=000,windows_names 0 0
```

**Spicetify**: `sudo chmod -R a+wr /opt/spotify` sonra `spicetify backup apply`. Tema: `~/.config/spicetify/Themes/PastelDusk` (bu repoda YOK, kişisel) — renkler yukarıdaki palet.

**Oyun**: Steam başlatma seçeneği `gamemoderun mangohud %command%`, `sudo systemctl enable --now lactd`.

## Lisans

MIT — detay `LICENSE`. Orijinal emek [samyns](https://github.com/samyns/Unit-3)'e ait.
