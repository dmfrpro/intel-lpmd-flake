{ pkgs, ... }:

pkgs.stdenv.mkDerivation rec {
  pname = "intel-lpmd";
  version = "0.1.1";

  src = pkgs.fetchFromGitHub {
    owner = "dmfrpro";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-DNApZY0FDFeOzMITcIYnmZd6lnz/5+HFqaeu9/O2IRk=";
  };

  nativeBuildInputs = with pkgs; [
    pkg-config
    autoconf
    autoreconfHook
    automake
    gtk-doc
    gnused
  ];

  buildInputs = with pkgs; [
    glib
    dbus
    libxml2
    systemdLibs
    upower
    libnl
    man-db
    coreutils
  ];

  configureFlags = [
    "--with-dbus-sys-dir=$out/share/dbus-1/system-services/"
    "--without-systemdsystemunitdir"
    "--localstatedir=/var"
    "--sysconfdir=/etc"
  ];

  patchPhase = ''
    sed -i '30,34d' data/Makefile.am
  '';

  postInstall = ''
    mkdir -p $out/share/dbus-1/system.d
    cp -v data/org.freedesktop.intel_lpmd.conf $out/share/dbus-1/system.d/

    mkdir -p $out/share/xml
    cp -v data/*.xml $out/share/xml
  '';

  meta = {
    license = pkgs.lib.licenses.gpl2;
    homepage = "https://github.com/intel/intel-lpmd";
    sourceProvenance = [ pkgs.lib.sourceTypes.fromSource ];
    description = ''
      Intel Low Power Mode Daemon (lpmd) is a Linux daemon designed to
      optimize active idle power.
    '';
    platforms = [ "x86_64-linux" ];
  };
}
