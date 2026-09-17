platform 'el-8-ppc64le' do |plat|
  plat.servicedir '/usr/lib/systemd/system'
  plat.defaultdir '/etc/sysconfig'
  plat.servicetype 'systemd'

  packages = %w(
    autoconf
    automake
    cmake
    createrepo
    curl
    gcc
    gcc-c++
    libarchive
    libselinux-devel
    make
    patch
    perl-Getopt-Long
    readline-devel
    rpm-build
    rpm-libs
    rsync
    swig
    systemd
    systemtap-sdt-devel
    which
    zlib-devel
  )

  plat.provision_with("dnf install -y --allowerasing  #{packages.join(' ')}")
  plat.install_build_dependencies_with 'dnf install -y --allowerasing'
  plat.docker_image "almalinux:8"
  plat.docker_arch "linux/ppc64le"
end
