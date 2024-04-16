require 'etc'

task :test_immix do
  nproc = Etc.nprocessors + 1
  sh <<~EOM
    make -j#{nproc} -C ruby      \
      test-all                   \
      RUN_OPTS=--mmtk-plan=Immix
  EOM
end
