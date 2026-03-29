#include "Calculator.hpp"
#include <gtest/gtest.h>
#include <gmock/gmock.h>

using ::testing::Return;

// テスト観点 : 
// Add      : 足し算
// Subtract : 引き算
// Multiply : 掛け算
// Divide   : 割り算

TEST(CalculatorTest, Add) {
    Calculator calculator;
    EXPECT_EQ(calculator.add(3, 5), 8);
    EXPECT_EQ(calculator.add(-3, 7), 4);
    EXPECT_EQ(calculator.add(1000000, 500000), 1500000);
    EXPECT_EQ(calculator.add(0, 0), 0);
}

TEST(CalculatorTest, Subtract) {
    Calculator calculator;
    EXPECT_EQ(calculator.subtract(10, 4), 6);
    EXPECT_EQ(calculator.subtract(-5, -3), -2);
    EXPECT_EQ(calculator.subtract(0, 10), -10);
}

TEST(CalculatorTest, Multiply) {
    Calculator calculator;
    EXPECT_EQ(calculator.multiply(3, 4), 12);
    EXPECT_EQ(calculator.multiply(-2, 6), -12);
    EXPECT_EQ(calculator.multiply(0, 100), 0);
}

TEST(CalculatorTest, Divide) {
    Calculator calculator;
    EXPECT_EQ(calculator.divide(8, 2), 4);
    EXPECT_EQ(calculator.divide(-9, 3), -3);
    EXPECT_EQ(calculator.divide(7, 2), 3); // 整数の割り算は小数点以下が切り捨て

    // ゼロ除算のテスト
    EXPECT_THROW(calculator.divide(10, 0), std::runtime_error);
}