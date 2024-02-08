{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      blue-bubbles = pkgs.flutter.buildFlutterApplication rec {
        pname = "bluebubbles-app";
        version = "1.12.7+61";
        targetFlutterPlatform = "linux";
        
        src = ./.;

        gitHashes = {
          desktop_webview_auth = "sha256-knLo1ERnMXXaDgUJwNR+xRcrsH2YRA3VpCcBwCCOiVg=";
          firebase_dart = "sha256-jq4Y5ApGPrXcLN3gwC9NuGN/EQkl5u64iMzL8KG02Sc=";
          geolocator = "sha256-B46t4gI34dLy8NY04dyzrmVwBwzhYkt9hivSl8OsJqs=";
          geolocator_linux = "sha256-B46t4gI34dLy8NY04dyzrmVwBwzhYkt9hivSl8OsJqs=";
          geolocator_windows = "sha256-B46t4gI34dLy8NY04dyzrmVwBwzhYkt9hivSl8OsJqs=";
          local_notifier = "sha256-AeQzRYqTaXZypG3/DzyOeYLbBXB1WKr18QJC5ivmpkM=";
          permission_handler_windows = "sha256-X2zfT78M01jTH+Q9DbrvzK7FFm306zwLTlsFS7qEX2k=";
          qr_flutter = "sha256-QkPbX15YPjrfvTjFoCjFXCFBpsrabDC2AcZ8u+eVMLk=";
          pdf = "sha256-IHQOUCk5W9kTgoCgmoB+bEhLcWR3DIMjLqoOtHwALbI=";
        };

        autoPubspecLock = "${src}/pubspec.lock";
        vendorHash = "";

        postPatch = let
          PDFIUM_VERSION = "5200";
          PDFIUM_ARCH = "x64";
          pdfium = pkgs.fetchurl {
            url = "https://github.com/bblanchon/pdfium-binaries/releases/download/chromium/${PDFIUM_VERSION}/pdfium-linux-${PDFIUM_ARCH}.tgz";
            hash = "sha256-Dmjn8MdhmltKkUMfrVFtZlzFLww0HXAbIarXGmxtQdk=";
          };

          OBJECTBOX_VERSION = "2.2.1";
          OBJECTBOX_ARCH = "x64";
          objectbox = "https://github.com/objectbox/objectbox-c/releases/download/v${OBJECTBOX_VERSION}/objectbox-linux-${OBJECTBOX_ARCH}.tar.gz";
        in ''
          awk '/MIMALLOC_LIB/ { print; print "set(PDFIUM_URL \"file://${pdfium}\")"; next }1' linux/CMakeLists.txt > tmp_cmake
          mv tmp_cmake linux/CMakeLists.txt
          awk '/MIMALLOC_LIB/ { print; print "FetchContent_SetPopulated(objectbox-download SOURCE_DIR ${objectbox})"; next }1' linux/CMakeLists.txt > tmp_cmake
          mv tmp_cmake linux/CMakeLists.txt
        '';
        
        # https://github.com/media-kit/media-kit/blob/63c6ebe8366db7ecfbd13ab9ce76b11dd86dae48/libs/linux/media_kit_libs_linux/linux/CMakeLists.txt#L58
        # This dependency expects to have the source archive of mimalloc, this specific source archive.
        postConfigure = let
          mimalloc-src = pkgs.fetchurl {
            url = "https://github.com/microsoft/mimalloc/archive/refs/tags/v2.1.2.tar.gz";
            hash = "sha256-Kxv/b3F/lyXHC/jXnkeG2hPeiicAWeS6C90mKue+Rus=";
          };
        in ''
          mkdir -p build/linux/x64/release
          cp ${mimalloc-src} build/linux/x64/release/mimalloc-2.1.2.tar.gz
        '';
        
        buildInputs = with pkgs; [
          webkitgtk_4_1
          libnotify
        ];
      };
    in {
      packages = {
        default = blue-bubbles;
      };
    });
}
