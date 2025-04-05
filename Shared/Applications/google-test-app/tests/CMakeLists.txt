# add_executable(sample_test sample_test.cpp)
# target_link_libraries(sample_test gtest gtest_main pthread)

add_executable(test_runner
    main.cpp
    mock_test.cpp
    sample_test.cpp
    )

target_link_libraries(test_runner gtest gmock pthread)

# CTestを使うためにテストを追加
# add_test(NAME SampleTest COMMAND sample_test)

