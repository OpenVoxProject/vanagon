platform 'windows-msys2-x64' do |plat|
  plat.servicetype 'windows'

  packages = %w[
    autoconf
    git
    make
    patch
    mingw-w64-ucrt-x86_64-gcc
    mingw-w64-ucrt-x86_64-gdbm
    mingw-w64-ucrt-x86_64-zlib
    mingw-w64-ucrt-x86_64-gcc-libs
  ]

  # Story time:
  #
  # Windows can end up with multiple MSYS2 installations. This is common
  # on GitHub actions where the runner image comes with `C:/msys64/`
  # pre-installed, but inactive, and the `msys/setup-msys2` creates a new
  # installation under `D:/a/_temp/msys64/`.
  #
  # Thus: assume Vanagon is running in a MSYS2 shell which mounts the chosen
  # MSYS2 installation and sets PATH appropriately. "UNIX" paths in this shell,
  # like `/usr/bin/` should work fine, but fully-qualified Windows paths like
  # `C:/msys64/usr/bin/` might point to the "wrong" MSYS2 installation.
  plat.provision_with("/usr/bin/pacman -S --noconfirm --needed #{packages.join(' ')}")
  plat.install_build_dependencies_with '/usr/bin/pacman -S --noconfirm --needed'

  plat.make '/usr/bin/make'
  plat.patch 'TMP=/var/tmp /usr/bin/patch.exe --binary'

  plat.platform_triple 'x86_64-w64-mingw32'

  # Putting these here as a reminder where we use them elsewhere. DO NOT
  # use the full path, just the name of the executable without the extension.
  # Otherwise, autoconf gets confused.
  plat.environment 'CC', 'x86_64-w64-mingw32-gcc'

  plat.package_type 'msi'
  plat.output_dir 'windows'
end
