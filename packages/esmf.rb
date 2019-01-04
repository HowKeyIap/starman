class Esmf < Package
  url 'http://www.earthsystemmodeling.org/esmf_releases/public/ESMF_7_1_0r/esmf_7_1_0r_src.tar.gz'
  sha256 'ae9a5edb8d40ae97a35cbd4bd00b77061f995c77c43d36334dbb95c18b00a889'
  version '7.1.0'

  option 'use-mkl', 'Use MKL for LAPACK dependency.'
  option 'use-pnetcdf', 'Use Parallel-NetCDF dependency.'
  option 'mpi-type', 'Set MPI type.', type: :string, choices: ['mpich', 'mpich2', 'mpich3', 'lam', 'openmpi', 'intelmpi']

  if use_mkl?
    CLI.notice 'Use MKL for LAPACK.'
  else
    depends_on :lapack
  end
  depends_on :netcdf
  depends_on :pnetcdf if use_pnetcdf?

  def install
    ENV['ESMF_DIR'] = pwd
    ENV['ESMF_BOPT'] = 'O'
    ENV['ESMF_OPTLEVEL'] = '2'
    if CompilerSet.c.vendor == :gcc and CompilerSet.fortran.vendor == :gcc
      CLI.error "ESMF needs gfortran with version >= 4.3!" if CompilerSet.fortran.version <= '4.3'
      ENV['ESMF_COMPILER'] = 'gfortran'
    elsif CompilerSet.c.vendor == :gcc and CompilerSet.fortran.vendor == :intel
      ENV['ESMF_COMPILER'] = 'intelgcc'
    elsif CompilerSet.c.vendor == :intel and CompilerSet.fortran.vendor == :intel
      ENV['ESMF_COMPILER'] = 'intel'
    else
      CLI.error "Unsupported compiler set!"
    end
    ENV['ESMF_INSTALL_PREFIX'] = prefix
    if use_mkl?
      ENV['ESMF_LAPACK'] = 'mkl'
    else
      ENV['ESMF_LAPACK'] = 'system'
      ENV['ESMF_LAPACK_LIBPATH'] = Lapack.link_lib
      ENV['ESMF_LAPACK_LIBS'] = '-llapck -lblas'
    end
    ENV['ESMF_NETCDF'] = 'nc-config'
    ENV['ESMF_PNETCDF'] = 'pnetcdf-config' if use_pnetcdf?
    ENV['ESMF_PIO'] = 'internal'
    if mpi_type
      ENV['ESMF_COMM'] = mpi_type.to_s
    elsif ENV['MPICXX'] =~ /mpiicpc$/ or ENV['MPIFC'] =~ /mpiifort$/
      ENV['ESMF_COMM'] = 'intelmpi'
    else
      CLI.error "You should set #{CLI.blue '--mpi-type'} option!"
    end
    run 'make'
    run 'make', 'tests' if not skip_test?
    run 'make', 'install'
  end
end