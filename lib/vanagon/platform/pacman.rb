class Vanagon
  class Platform
    class Pacman < Vanagon::Platform
      def initialize(name)
        super(name)
        @make ||= '/usr/bin/make'
        @patch ||= '/usr/bin/patch'
        @tar ||= '/usr/bin/tar'
      end

      def generate_package(project)
        target_dir = project.repo ? output_dir(project.repo) : output_dir
        archive_name = package_name(project)

        [
          "mkdir -p output/#{target_dir}",
          "cp #{project.name}-#{project.version}.tar.gz output/#{target_dir}/#{archive_name}",
        ]
      end

      def generate_packaging_artifacts(_workdir, _name, _binding, _project)
        nil
      end

      def package_name(project)
        "#{project.name}-#{project.version}-#{@name}.tar.gz"
      end

      def install_build_dependencies(dependencies)
        "pacman -Syu --noconfirm --needed #{dependencies.join(' ')}"
      end
    end
  end
end
