#include <gtest/gtest.h>

// メイン関数（テストエントリポイント）
int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}