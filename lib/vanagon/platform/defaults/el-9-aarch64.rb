platform "el-9-aarch64" do |plat|
  plat.servicedir "/usr/lib/systemd/system"
  plat.defaultdir "/etc/sysconfig"
  plat.servicetype "systemd"

  packages = %w(
    autoconf
    automake
    cmake
    createrepo
    curl
    dnf-utils
    gcc
    gcc-c++
    libarchive
    libtool
    make
    rpm-build
    rpm-libs
    rsync
    systemd
    which
  )
  plat.provision_with "dnf install -y --allowerasing #{packages.join(' ')} && dnf config-manager --set-enabled crb"
  plat.install_build_dependencies_with "dnf install -y --allowerasing "
  plat.vmpooler_template "redhat-9-arm64"
  plat.docker_image "almalinux:9"
  plat.docker_arch "linux/arm64"
end
