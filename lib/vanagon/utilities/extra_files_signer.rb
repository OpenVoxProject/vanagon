require 'open3'

class Vanagon
  module Utilities
    module ExtraFilesSigner
      class << self
        RED = "\033[31m".freeze
        GREEN = "\033[32m".freeze
        RESET = "\033[0m".freeze

        def run_command(cmd, silent: true, print_command: false, report_status: false)
          puts "#{GREEN}Running #{cmd}#{RESET}" if print_command
          output = ''
          Open3.popen2e(cmd) do |_stdin, stdout_stderr, thread|
            stdout_stderr.each do |line|
              puts line unless silent
              output += line
            end
            exitcode = thread.value.exitstatus
            unless exitcode.zero?
              err = "#{RED}Command failed! Command: #{cmd}, Exit code: #{exitcode}"
              # Print details if we were running silent
              err += "\nOutput:\n#{output}" if silent
              err += RESET
              abort err
            end
            puts "#{GREEN}Command finished with status #{exitcode}#{RESET}" if report_status
          end
          output.chomp
        end

        def local_commands(project, mktmp, source_dir)
          commands = []
          signing_script_path = File.join(run_command("#{mktmp} 2>/dev/null"), File.basename('sign_extra_file'))

          project.extra_files_to_sign.each do |file|
            commands += ["echo > #{signing_script_path}"]
            commands += project.signing_commands.map { |c| "echo '#{c.gsub('%{file}', file)}' >> #{signing_script_path}" }
            commands += ["/bin/bash #{signing_script_path}"]
          end

          commands
        rescue RuntimeError
          require 'vanagon/logger'
          VanagonLogger.error "Error signing extra files: #{project.extra_files_to_sign.join(',')}"
          raise if ENV['VANAGON_FORCE_SIGNING']
          []
        end

        def commands(project, mktemp, source_dir)
          tempdir = nil
          commands = []
          # Skip signing extra files if logging into the signing_host fails
          # This enables things like CI being able to sign the additional files,
          # but locally triggered builds by developers who don't have access to
          # the signing host just print a message and skip the signing.
          Vanagon::Utilities.retry_with_timeout(3, 5) do
            tempdir = Vanagon::Utilities::remote_ssh_command("#{project.signing_username}@#{project.signing_hostname}", "#{mktemp} 2>/dev/null", return_command_output: true)
          end

          remote_host = "#{project.signing_username}@#{project.signing_hostname}"
          remote_destination_directory = "#{remote_host}:#{tempdir}"
          remote_signing_script_path = File.join(tempdir, File.basename('sign_extra_file'))
          extra_flags = ''
          extra_flags = '--extended-attributes' if project.platform.is_macos?

          project.extra_files_to_sign.each do |file|
            remote_file_to_sign_path = File.join(tempdir, File.basename(file))
            local_source_path = File.join('$(tempdir)', source_dir, file)
            remote_source_path = "#{remote_host}:#{remote_file_to_sign_path}"
            local_destination_path = local_source_path

            commands << "#{Vanagon::Utilities.ssh_command} #{remote_host} \"echo > #{remote_signing_script_path}\""
            commands += project.signing_commands.map { |c| "#{Vanagon::Utilities.ssh_command} #{remote_host} \"echo '#{c.gsub('%{file}', remote_file_to_sign_path)}' >> #{remote_signing_script_path}\"" }
            commands += [
              "rsync -e '#{Vanagon::Utilities.ssh_command}' --verbose --recursive --hard-links --links --no-perms --no-owner --no-group #{extra_flags} #{local_source_path} #{remote_destination_directory}",
              "#{Vanagon::Utilities.ssh_command} #{remote_host} /bin/bash #{remote_signing_script_path}",
              "rsync -e '#{Vanagon::Utilities.ssh_command}' --verbose --recursive --hard-links --links --no-perms --no-owner --no-group #{extra_flags} #{remote_source_path} #{local_destination_path}"
            ]
          end

          commands
        rescue RuntimeError
          require 'vanagon/logger'
          VanagonLogger.error "Unable to connect to #{project.signing_username}@#{project.signing_hostname}, skipping signing extra files: #{project.extra_files_to_sign.join(',')}"
          raise if ENV['VANAGON_FORCE_SIGNING']
          []
        end
      end
    end
  end
end
