{ pkgs, ... }:

pkgs.stdenv.mkDerivation rec {
  pname = "intel-lpmd";
  version = "unstable-20260608";

  src = pkgs.fetchFromGitHub {
    owner = "intel";
    repo = pname;
    rev = "c44813f5ecdb13048a7942567fe8a81710200229";
    sha256 = "sha256-+9tvIZfNhqoHw8d90H9ZvL3yo7M+vlxIJwo2K0/1/9w=";
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
    "--with-dbus-sys-dir=${placeholder "out"}/share/dbus-1/system-services/"
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
