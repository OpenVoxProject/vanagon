platform 'fedora-45-aarch64' do |plat|
    plat.servicedir '/usr/lib/systemd/system'
    plat.defaultdir '/etc/sysconfig'
    plat.servicetype 'systemd'
    plat.dist 'fc45'
  
    packages = %w(
      autoconf
      automake
      binutils
      bzip2-devel
      cmake
      curl
      gcc
      gcc-c++
      libselinux-devel
      libsepol
      libsepol-devel
      make
      perl-lib
      perl-FindBin
      pkgconfig
      readline-devel
      rpmdevtools
      rsync
      swig
      systemtap-sdt-devel
      systemtap-sdt-dtrace
      systemd
      which
      zlib-devel
    )
    plat.provision_with("/usr/bin/dnf install -y --best --allowerasing #{packages.join(' ')}")
  
    plat.install_build_dependencies_with '/usr/bin/dnf install -y --best --allowerasing'
    plat.vmpooler_template 'fedora-45-aarch64'
    plat.docker_image 'fedora:45'
    plat.docker_arch 'linux/arm64'
  end
