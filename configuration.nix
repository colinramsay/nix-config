# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  nix = {
    autoOptimiseStore = true;
    package = pkgs.nixUnstable;
    extraOptions = ''
      keep-outputs = false
      keep-derivations = false
      experimental-features = nix-command flakes
    '';
   };

   programs.ssh.extraConfig = ''
    PubkeyAcceptedAlgorithms +ssh-rsa
    HostkeyAlgorithms +ssh-rsa
   '';

  boot.supportedFilesystems = [ "ntfs" ];

  # go go grub
  boot.loader.grub.enable = true;

  # dont install grub to a device as its already installed
  boot.loader.grub.device = "nodev";
  
  # find windows
  boot.loader.grub.useOSProber = true;
  
  # remove nixos splash image
  boot.loader.grub.splashImage = null;

  # needed?
  boot.loader.grub.efiSupport = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelParams = [
    # This allows the keychron 6 function keys to work w/ fn2 pressed
    "hid_apple.fnmode=0"

    # https://wiki.archlinux.org/title/silent_boot
    # doesn't entirely work due to:
    # https://github.com/NixOS/nixpkgs/issues/32555
    "quiet"
    "loglevel=3"
    "rd.systemd.show_status=auto"
    "rd.udev.log_level=3"
  ];

  nixpkgs.overlays = [
    (self: super: {
      picom = super.picom.overrideAttrs (old: {
        src = super.fetchFromGitHub {
          owner = "ibhagwan";
          repo = "picom";
          rev = "c4107bb6cc17773fdc6c48bb2e475ef957513c7a";
          sha256 = "1hVFBGo4Ieke2T9PqMur1w4D0bz/L3FAvfujY9Zergw=";
        };
      });

    })
  ];

  # hardware.video.hidpi.enable = true;
  hardware.bluetooth.enable = true;

  time.timeZone = "Europe/London";

  security.polkit.enable = true;

  virtualisation.docker.enable = true;

  virtualisation.virtualbox.host.enable = false;
  virtualisation.virtualbox.host.enableExtensionPack = false;

  programs = {
    steam.enable = true;
    dconf.enable = true;
    gnome-terminal.enable = false;
  };

  services = {
    # usb drive support
    gvfs = {
      enable = true;
      package = pkgs.gnome3.gvfs;
    };

    blueman.enable = true;
    chrony.enable = true; # time server
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
    xserver = {
      enable = true;
      xkbModel  = "macbook78";      
      layout = "gb";

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
    #<home-manager/nixos>
  ];

  # networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.networkmanager.enable = true;
  networking.interfaces.enp8s0.useDHCP = true;

networking.firewall.allowedTCPPortRanges = [{from = 1714; to = 1764;}];
networking.firewall.allowedUDPPortRanges = [{from = 1714; to = 1764;}];


  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";
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

  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/51b8764a-92e2-4cee-91d8-7d1d4d57fe7d";
    mountPoint = "/mnt/data";
    options = [ "nofail" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/B6DD-2E6C";
    mountPoint = "/boot";
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
    #google-fonts
    unifont
    jetbrains-mono
    (nerdfonts.override { fonts = [ "Overpass" ]; })
    siji
  ];
  home-manager.users.colinramsay = { pkgs, ... }: {

    programs.zsh = {
      enable = true;
      # profileExtra = ''
        #export PATH="$HOME/.config/Code/User/globalStorage/ms-vscode-remote.remote-containers/cli-bin:$PATH";
      #'';
      shellAliases = {
        dc = "$HOME/.config/Code/User/globalStorage/ms-vscode-remote.remote-containers/cli-bin/devcontainer open";
        win = "sudo grub-reboot \"$(grep -i windows /boot/grub/grub.cfg|cut -d\"'\" -f2)\" && sudo reboot";
        la = "ls -la";
        edix = "cd /etc/nixos; code .; cd -";
        renix = "cd /etc/nixos; sudo nixos-rebuild --flake .# switch; cd -";
        upnix = "cd /etc/nixos; sudo nix flake update && sudo nixos-rebuild --flake .# switch; cd -";
      };
       oh-my-zsh = {
        enable = true;
        plugins = [ "git" ];
        theme = "robbyrussell";
      };
    };

    services.dunst = {
      enable = true;
      iconTheme.package = pkgs.gnome3.adwaita-icon-theme;
      iconTheme.name = "Adwaita";
      settings = {
        global = {
          geometry = "0x4-25+25";
          indicate_hidden = "yes";
          shrink = "no";
          transparency = 15;
          notification_height = 0;
          separator_height = 1;
          padding = 8;
          browser = "xdg-open";
          horizontal_padding = 10;
          frame_width = 0;
          frame_color = "#282a36";
          separator_color = "frame";
          sort = "yes";
          idle_threshold = 30;
          font = "Monospace 10";
          line_height = 0;
          dmenu = "/run/current-system/sw/bin/rofi -dmenu";
          markup = "full";
          format = "%s %p\\n%b";
          alignment = "left";
          vertical_alignment = "center";
          show_age_threshold = 60;
          word_wrap = "yes";
          ellipsize = "middle";
          ignore_newline = "no";
          stack_duplicates = true;
          hide_duplicate_count = false;
          show_indicators = "yes";
          icon_position = "left";
          min_icon_size = 0;
          max_icon_size = 64;
          sticky_history = "yes";
          history_length = 20;
          always_run_script = true;
          title = "Dunst";
          class = "Dunst";
          startup_notification = false;
          verbosity = "mesg";
          corner_radius = 0;
          ignore_dbusclose = false;
          force_xinerama = false;
          mouse_left_click = "close_current";
          mouse_middle_click = "do_action";
          mouse_right_click = "close_all";
        };
        urgency_low = {
          background = "#282a36";
          foreground = "#6272a4";
          timeout = 15;
        };

        urgency_normal = {
            background = "#282a36";
            foreground = "#bd93f9";
            timeout = 45;
        };
        urgency_critical = {
            background = "#001042";
            foreground = "#f8f8f2";
            timeout = 0;
        };
      };
    };
    services.flameshot.enable = true;

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
      gsimplecal
      blender
      gnumake
      bottles # wine gui
      ncdu
      alsaUtils
      slack
      jump
      spotify
      nix-index
      _1password-gui
      _1password
      alot
      calibre
      dbeaver
      discord
      docker-compose
      evince
      feh
      filezilla
      firefox
      flameshot
      freerdp
      git
      grub2 # grub-reboot
      gnome.gnome-disk-utility
      gnome3.adwaita-icon-theme
      heroku
      hsetroot
      jq
      killall
      libreoffice
      lieer
      nixfmt
      notmuch
      openvpn
      pavucontrol
      playerctl
      picom
      polkit_gnome
      polybar
      remmina
      rofi
      signal-desktop
      vim
      vlc
      vscode
      ungoogled-chromium
      w3m
      wget
      (xfce.thunar.override { thunarPlugins = with pkgs; [ xfce.thunar-volman xfce.thunar-archive-plugin ]; })
      xfce.xfconf
      xfce.exo
      zoom-us
      xorg.xev
      unzip
      kitty
      xdotool
      legendary-gl
      wineWowPackages.stable
      #(winetricks.override { wine = wineWowPackages.staging; })
      v4l-utils # webcam tweaks
    ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}

