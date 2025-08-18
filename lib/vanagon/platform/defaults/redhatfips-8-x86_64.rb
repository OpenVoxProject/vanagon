platform "redhatfips-8-x86_64" do |plat|
  plat.servicedir "/usr/lib/systemd/system"
  plat.defaultdir "/etc/sysconfig"
  plat.servicetype "systemd"

  packages = %w(
    autoconf
    automake
    cmake
    gcc-c++
    java-1.8.0-openjdk-devel
    libarchive
    libsepol-devel
    libselinux-devel
    openssl-devel
    pkgconfig
    readline-devel
    rpmdevtools
    rpm-build
    rsync
    swig
    systemtap-sdt-devel
    yum-utils
    zlib-devel
  )

  plat.provision_with "dnf install -y --allowerasing #{packages.join(' ')}"
  plat.install_build_dependencies_with "dnf install -y --allowerasing "
  plat.vmpooler_template "redhat-fips-8-x86_64"
  # NOTE: You must run the build on a FIPS-enabled Linux host in order for this platform to
  # build correctly with the Docker engine.
  plat.docker_image "almalinux:8"
  plat.docker_arch "linux/amd64"
end
