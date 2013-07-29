# Copyright (c) 2013 MaestroDev.  All rights reserved.
require 'maestro_plugin'
require 'maestro_shell'

module MaestroDev
  module Plugin
    class AntWorker < Maestro::MaestroWorker

      def execute
        validate_parameters

        Maestro.log.info "Inputs: tasks = #{@tasks}"
        Maestro.log.debug "Using Ant version #{@ant_version}" if !@ant_version.empty?

        shell = Maestro::Util::Shell.new
        command = create_command
        shell.create_script(command)

        write_output("\nRunning command:\n----------\n#{command.chomp}\n----------\n")
        exit_code = shell.run_script_with_delegate(self, :on_output)

        raise PluginError, "Ant run failed" unless exit_code.success?
      end

      def on_output(text)
        write_output(text, :buffer => true)
      end

      ###########
      # PRIVATE #
      ###########
      private
      
      # because we want to be able to string stuff together with &&
      # can't really test the executable.
      def valid_executable?
        Maestro::Util::Shell.run_command("#{@ant_executable} -version")[0].success?
      end

      def get_version
        result = Maestro::Util::Shell.run_command("#{@ant_executable} -version")
        result[1].split(" ")[3] if result[0].success?
      end

      def validate_parameters
        errors = []

        @ant_executable = get_field('ant_executable', 'ant')
        @ant_version = get_field('ant_version', '')
        @path = get_field('path') || get_field('scm_path')
        @propertyfile = get_field('propertyfile', '')
        @tasks = get_field('tasks', '')
        @environment = get_field('environment', '')
        @env = @environment.empty? ? "" : "#{Maestro::Util::Shell::ENV_EXPORT_COMMAND} #{@environment.gsub(/(&&|[;&])\s*$/, '')} && "

        valid = valid_executable?

        if valid
          if !@ant_version.empty?
            version = get_version
            errors << "ant is the wrong version: #{version}. Expected: #{@ant_version}" if version != @ant_version
          end
        else
          errors << "ant is not installed"
        end

        errors << "missing field path" if @path.nil?
        errors << "file in field path does not exist: #{@path}" if !@path.nil? && !File.exist?(@path)
        errors << "property file not found: #{@propertyfile}" if !@propertyfile.empty? && !File.exists?(@propertyfile)

        if !errors.empty?
          raise ConfigError, "Configuration errors: #{errors.join(', ')}"
        end
      end

      def process_tasks_field
        if is_json(@tasks)
          @tasks = JSON.parse(@tasks) if @tasks.is_a? String
        end

        if @tasks.class == Array
          @tasks = @tasks.join(' ')
        end
      end

      def create_command
        process_tasks_field
        propertyfile_param = @propertyfile.empty? ? '' : "-propertyfile #{@propertyfile}"
        shell_command = "#{@env}cd #{@path} && #{@ant_executable} -q #{propertyfile_param} #{@tasks}"
        set_field('command', shell_command)
        Maestro.log.debug("Running #{shell_command}")
        shell_command
      end

    end
  end
end
