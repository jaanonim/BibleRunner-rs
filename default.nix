{ lib
, pkg-config
, dbus
, rustPlatform
, makeDesktopItem
, ...
}:
let
  inherit (builtins) fromTOML readFile head match length elemAt;

  cargoToml = fromTOML (readFile ./Cargo.toml);
  inherit (cargoToml) package;
  inherit (package) name version description authors;
  inherit (package.metadata.krunner) service path;

  primaryAuthor =
    if (authors != [ ])
    then match "(.+) (:?<(.*)>)" (head authors)
    else [ ];
in
rustPlatform.buildRustPackage rec {
  inherit version;
  pname = name;

  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ dbus ];

  desktopItem = makeDesktopItem {
    name = "plasma-runner-${name}";
    desktopName = "BibleRunner";
    type = "Service";
    icon = name;
    comment = description;

    extraConfig =
      {
        X-KDE-PluginInfo-Name = name;
        X-KDE-PluginInfo-Version = version;
        X-KDE-PluginInfo-EnabledByDefault = "true";
        X-KDE-ServiceTypes = "Plasma/Runner";
        X-Plasma-API = "DBus";
        X-Plasma-DBusRunner-Service = service;
        X-Plasma-DBusRunner-Path = path;
      }
      // lib.optionalAttrs (length meta.license >= 1) {
        X-KDE-PluginInfo-License = (head meta.license).spdxId;
      }
      // lib.optionalAttrs (length primaryAuthor >= 1) {
        X-KDE-PluginInfo-Author = head primaryAuthor;
      }
      // lib.optionalAttrs (length primaryAuthor >= 3) {
        X-KDE-PluginInfo-Email = elemAt primaryAuthor 2;
      };
  };

  postInstall = ''
    mkdir -p $out/share/icons
    cp ./resources/${name}.png $out/share/icons/${name}.png

    mkdir -p $out/share/krunner/dbusplugins
    cp $desktopItem/share/applications/* $out/share/krunner/dbusplugins

    mkdir -p $out/share/dbus-1/services
    cat<<EOF > $out/share/dbus-1/services/plasma-runner-${name}.service
    [D-BUS Service]
    Name=${service}
    Exec=$out/bin/${name}
    EOF
  '';

  meta = with lib; {
    inherit description;

    homepage = package.repository;
    license = with licenses; [ mit ];
  };
}
