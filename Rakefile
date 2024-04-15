task :test_immix do
  test_list = "TESTS=\""
  File.open("mmtk_tests.txt") do |f|
    f.each_line do |l|
      next if l.start_with? '#'
      test_list << l.strip << " "
    end
  end
  test_list.strip! << "\""

  sh <<~EOM
    make -C ruby                 \
      test-all #{test_list}      \
      RUN_OPTS=--mmtk-plan=Immix \
      TESTOPTS=-v
  EOM
end
