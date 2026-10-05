platform "archlinux-rolling-x86_64" do |plat|
  plat.servicedir "/usr/lib/systemd/system"
  plat.defaultdir "/etc/default"
  plat.servicetype "systemd"

  packages = %w(
    autoconf
    automake
    cmake
    curl
    gcc
    libarchive
    libtool
    make
    rsync
    systemd
    which
  )
  plat.provision_with "pacman -Syu --noconfirm --needed #{packages.join(' ')}"
  plat.install_build_dependencies_with "pacman -Syu --noconfirm --needed"
  plat.docker_image "archlinux:base-devel"
  plat.docker_arch "linux/amd64"
end
