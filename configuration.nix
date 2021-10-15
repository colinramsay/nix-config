# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{

  nixpkgs.overlays = [
    (self: super: {
      picom = super.picom.overrideAttrs (old: {
        src = builtins.fetchTarball {
          url = "https://github.com/ibhagwan/picom/archive/next.tar.gz";
        };
      });

    })
  ];

  # hardware.video.hidpi.enable = true;
  hardware.bluetooth.enable = true;

  time.timeZone = "Europe/London";

  security.polkit.enable = true;

  virtualisation.docker.enable = true;

  programs = {
    steam.enable = true;
    git.enable = true;
    dconf.enable = true;
    gnome-terminal.enable = true;

    zsh = {
      enable = true;
      shellAliases = {
        la = "ls -la";
        renix = "sudo nixos-rebuild switch";
      };
      ohMyZsh = {
        enable = true;
        plugins = [ "git" ];
        theme = "robbyrussell";
      };
    };
  };

  services = {
    blueman.enable = true;
    chrony.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
    xserver = {
      enable = true;

      desktopManager = { xterm.enable = false; };

      displayManager = {
        defaultSession = "none+i3";
        autoLogin.enable = true;
        autoLogin.user = "colinramsay";
      };

      windowManager.i3 = {
        package = pkgs.i3-gaps;
        enable = true;
        configFile = "/etc/nixos/cfg/etc/i3/config";
      };
    };
  };

  nixpkgs.config.allowUnfree = true;
  environment.pathsToLink = [ "/libexec" ];

  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
    <home-manager/nixos>
  ];

  # dont use systemd-boot as we want grub
  boot.loader.systemd-boot.enable = false;

  # don't fiddle with anything
  boot.loader.efi.canTouchEfiVariables = false;

  # go go grub - without this things go weird
  boot.loader.grub.enable = true;

  # dont install grub
  boot.loader.grub.device = "nodev";

  # networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  networking.interfaces.enp8s0.useDHCP = true;

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  users.mutableUsers = false;

  fileSystems."/arch" = {
    device = "/dev/disk/by-uuid/5ca8f695-2c35-48d0-a6d1-8162a8d73e0f";
    fsType = "ext4";
    mountPoint = "/mnt/arch";
  };

  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/d92e66d1-4eec-435d-8cd1-28bae1f3db95";
    fsType = "ext4";
    mountPoint = "/mnt/data";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.colinramsay = {
    home = "/home/colinramsay";
    shell = pkgs.zsh;
    hashedPassword =
      "$6$Nw.4veVXY/c$a1Xlq2mo.Mt3jfA7qh03csnhS5y7EAcRjl4mdxlVRjqoJ9JDqFgY/VFKAR5D13kZJyNItH9pFq8oknUcfzAX0.";
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ]; # Enable ‘sudo’ for the user.
  };

  fonts.fonts = with pkgs; [
    unifont
    jetbrains-mono
    (nerdfonts.override { fonts = [ "Overpass" ]; })
    siji
  ];
  home-manager.users.colinramsay = { pkgs, ... }: {
    xsession.pointerCursor = {
      package = pkgs.gnome3.adwaita-icon-theme;
      name = "Adwaita";
      size = 38;
    };

    xresources.properties = { "Xft.dpi" = 92; };

    home.file.".local/bin/spotlight.sh" = {
      executable = true;
      source = ./cfg/home/.local/bin/spotlight.sh;
    };
    home.file.".config/i3/config".source = ./cfg/etc/i3/config;
    home.file.".config/polybar/config".source =
      ./cfg/home/.config/polybar/config;
    home.file.".config/picom/picom.conf".source =
      ./cfg/home/.config/picom/picom.conf;

    # Xft.dpi: 96

    home.file.".config/polybar/launch.sh" = {
      text = ''
        # Terminate already running bar instances
        #kill $(ps aux | grep "polybar" | awk '{print $2}')
        # If all your bars have ipc enabled, you can also use 
        polybar-msg cmd quit

        # Launch Polybar, using default config location ~/.config/polybar/config
        polybar stats 2>&1 | tee -a /tmp/polybar.log & disown
        polybar tray 2>&1 | tee -a /tmp/polybar.log & disown
        polybar workspaces 2>&1 | tee -a /tmp/polybar.log & disown

        echo "Polybar launched..."
      '';
      executable = true;
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs;

    let
      polybar = pkgs.polybar.override {
        i3Support = true;
        i3GapsSupport = true;
      };
    in [
      remmina
      freerdp
      filezilla
      evince
      dbeaver
      jq
      hsetroot
      nixfmt
      picom
      polybar
      killall
      rofi
      signal-desktop
      docker-compose
      vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      xfce.thunar
      polkit_gnome
      wget
      firefox
      _1password-gui
      vscode
      pavucontrol
      gnome3.adwaita-icon-theme
      gnome.gnome-disk-utility
      heroku
    ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}

