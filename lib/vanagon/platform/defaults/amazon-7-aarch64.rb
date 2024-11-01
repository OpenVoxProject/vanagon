platform "amazon-7-aarch64" do |plat|
  plat.servicedir "/usr/lib/systemd/system"
  plat.defaultdir "/etc/sysconfig"
  plat.servicetype "systemd"

  packages = %w(
    autoconf
    automake
    cmake3
    createrepo
    curl
    gcc
    gcc-c++
    libarchive
    libtool
    make
    rpm-libs
    rpm-build
    rsync
    systemd
    which
  )
  plat.provision_with("yum install -y --nogpgcheck  #{packages.join(' ')}")
  plat.install_build_dependencies_with "yum install --assumeyes"
  plat.vmpooler_template "amazon-7-arm64"
  plat.docker_image "amazonlinux:2"
  plat.docker_arch "linux/arm64"
end
