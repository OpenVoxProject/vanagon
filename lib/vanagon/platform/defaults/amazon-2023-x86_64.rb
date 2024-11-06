platform "amazon-2023-x86_64" do |plat|
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
  plat.provision_with "dnf install -y --allowerasing #{packages.join(' ')}"
  plat.install_build_dependencies_with "dnf install -y --allowerasing "
  plat.vmpooler_template "amazon-2023-x86_64"
  plat.docker_image "amazonlinux:2023"
  plat.docker_arch "linux/amd64"
end
