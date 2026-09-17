platform 'el-9-ppc64le' do |plat|
  plat.servicedir '/usr/lib/systemd/system'
  plat.defaultdir '/etc/sysconfig'
  plat.servicetype 'systemd'

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
    libselinux-devel
    make
    patch
    perl-Getopt-Long
    readline-devel
    rpm-libs
    rpm-build
    rsync
    systemd
    systemtap-sdt-devel
    which
    zlib-devel
  )

  plat.provision_with("dnf install -y --allowerasing  #{packages.join(' ')} && dnf config-manager --set-enabled crb")
  plat.install_build_dependencies_with 'dnf install -y --allowerasing'
  plat.docker_image "almalinux:9"
  plat.docker_arch "linux/ppc64le"
end
