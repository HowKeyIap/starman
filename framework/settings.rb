class Settings
  extend Utils

  @@settings = {}

  def self.settings
    @@settings
  end

  def self.install_root
    @@settings['install_root']
  end

  def self.cache_root
    @@settings['cache_root']
  end

  def self.link_root package = nil
    if package
      if package.has_label? :alone
        File.dirname(package.prefix) + '/link'
      elsif package.has_label? :common
        common_root
      elsif package.has_label? :compiler
        File.dirname(File.dirname(File.dirname(package.prefix)))
      else
        "#{Settings.install_root}/#{Settings.compiler_set}"
      end
    else
      "#{Settings.install_root}/#{Settings.compiler_set}"
    end
  end

  def self.common_root
    "#{install_root}/common"
  end

  def self.conf_file
    "#{Runtime.rc_root}/conf.yml"
  end

  def self.compiler_set
    CommandParser.args[:compiler_set] || @@settings['defaults']['compiler_set']
  end

  def self.compilers
    @@settings['compiler_sets'][compiler_set]
  end

  def self.c_compiler
    compilers['c']
  end

  def self.cxx_compiler
    compilers['cxx']
  end

  def self.fortran_compiler
    compilers['fortran']
  end

  def self.mpi_c_compiler
    compilers['mpi_c']
  end

  def self.mpi_cxx_compiler
    compilers['mpi_cxx']
  end

  def self.mpi_fortran_compiler
    compilers['mpi_fortran']
  end

  def self.nodes
    [@@settings['nodes']['master_node'], @@settings['nodes']['slave_nodes']].flatten.uniq
  end

  def self.master_node
    @@settings['nodes']['master_node']
  end

  def self.slave_nodes
    @@settings['nodes']['slave_nodes']
  end

  def self.init options = {}
    if File.file? conf_file
      @@settings = YAML.load(open(conf_file).read)
      if (not install_root or install_root == '<change_me>') and not options[:ignore_errors]
        CLI.error "#{CLI.red 'install_root'} is not set in #{CLI.blue conf_file}!"
      end
      if (not compiler_set or compiler_set == '<change_me>') and not options[:ignore_errors]
        CLI.error "#{CLI.red 'compiler_set'} is not set in #{CLI.blue conf_file}!"
      end
      set_compile_env
      if CommandParser.args[:verbose]
        CLI.notice "Use #{CLI.blue compiler_set} compilers."
        ['CC', 'CXX', 'FC', 'MPICC', 'MPICXX', 'MPIFC', 'MPIF90', 'MPIF77'].each do |env|
          CLI.notice "#{env} = #{CLI.blue ENV[env]}" if ENV[env]
        end
      end
    end
  end

  def self.write options = nil
    if options
      if File.file? conf_file and not options[:force]
        CLI.error "#{CLI.red conf_file} exists! Overwrite it by using --force option!"
      end
      @@settings['install_root'] = options[:install_root]
      @@settings['cache_root'] = options[:cache_root]
      if system_command? 'gcc' and system_command? 'g++'
        @@settings['defaults'] = { 'compiler_set' => 'gcc' }
        @@settings['compiler_sets'] = { 'gcc' => {} }
        @@settings['compiler_sets']['gcc']['c'] = `which gcc`.chomp
        @@settings['compiler_sets']['gcc']['cxx'] = `which g++`.chomp
        @@settings['compiler_sets']['gcc']['fortran'] = `which gfortran`.chomp if system_command? 'gfortran'
      end
    end
    begin
      write_file conf_file, @@settings.to_yaml
    rescue Errno::EACCES => e
      CLI.error "Failed to create runtime configuration directory at #{CLI.red Runtime.rc_root}!\n#{e}"
    end
    if not File.file? conf_file
      CLI.notice "Create runtime configuration directory #{CLI.blue Runtime.rc_root}."
      CLI.notice "Please edit #{CLI.blue conf_file} to suit your environment and come back."
    end
  end
end
