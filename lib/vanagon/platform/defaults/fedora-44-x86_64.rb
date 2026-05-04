platform 'fedora-44-x86_64' do |plat|
    plat.servicedir '/usr/lib/systemd/system'
    plat.defaultdir '/etc/sysconfig'
    plat.servicetype 'systemd'
    plat.dist 'fc44'
  
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
    plat.vmpooler_template 'fedora-44-x86_64'
    plat.docker_image 'fedora:44'
    plat.docker_arch 'linux/amd64'
  end
