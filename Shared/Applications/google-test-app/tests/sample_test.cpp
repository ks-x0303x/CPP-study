#include <gtest/gtest.h>

// 足し算のテスト
TEST(ArithmeticTest, Addition) {
    EXPECT_EQ(3 + 5, 8);
    EXPECT_EQ(-3 + 7, 4);
    EXPECT_EQ(1000000 + 500000, 1500000);
}

// 引き算のテスト
TEST(ArithmeticTest, Subtraction) {
    EXPECT_EQ(10 - 4, 6);
    EXPECT_EQ(-5 - (-3), -2);
    EXPECT_EQ(0 - 10, -10);
}

// 掛け算のテスト
TEST(ArithmeticTest, Multiplication) {
    EXPECT_EQ(3 * 4, 12);
    EXPECT_EQ(-2 * 6, -12);
    EXPECT_EQ(0 * 100, 0);
}

// 割り算のテスト
TEST(ArithmeticTest, Division) {
    EXPECT_EQ(8 / 2, 4);
    EXPECT_EQ(-9 / 3, -3);
    EXPECT_EQ(7 / 2, 3); // 整数の割り算は小数点以下が切り捨て

    // ゼロ除算のテスト（実行時エラーを避けるためコメントアウト）
    // EXPECT_ANY_THROW(10 / 0);
}

// 小数の四則演算テスト
TEST(ArithmeticTest, FloatingPointOperations) {
    EXPECT_DOUBLE_EQ(5.5 + 2.2, 7.7);
    EXPECT_DOUBLE_EQ(10.0 / 3.0, 10.0 / 3.0);
    EXPECT_NEAR(10.0 / 3.0, 3.333, 0.001); // 誤差許容範囲を考慮
}

// 例外処理（ゼロ除算）テスト
TEST(ArithmeticTest, DivisionByZero) {
    EXPECT_THROW({
        int a = 10;
        int b = 0;
        int c = a / b; // C++の整数演算ではゼロ除算でクラッシュする
        (void)c;
    }, std::exception);
}