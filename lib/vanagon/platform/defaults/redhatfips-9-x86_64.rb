platform "redhatfips-9-x86_64" do |plat|
  plat.servicedir "/usr/lib/systemd/system"
  plat.defaultdir "/etc/sysconfig"
  plat.servicetype "systemd"

  packages = %w(
    autoconf
    automake
    cmake
    gcc-c++
    libarchive
    libselinux-devel
    libsepol-devel
    openssl-devel
    pkgconfig
    readline-devel
    rpm-build
    rpmdevtools
    rsync
    swig
    systemtap-sdt-devel
    which
    zlib-devel
  )

  plat.provision_with "dnf install -y yum-utils && dnf config-manager --set-enabled crb"
  plat.provision_with "dnf install -y --allowerasing #{packages.join(' ')}"
  plat.install_build_dependencies_with "dnf install -y --allowerasing "
  plat.docker_image "almalinux:9"
  plat.docker_arch "linux/amd64"
end
