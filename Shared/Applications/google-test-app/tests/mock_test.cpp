#include "MockCalculator.hpp"
#include <gtest/gtest.h>
#include <gmock/gmock.h>

using ::testing::Return;

TEST(CalculatorTest, AdditionTest) {
    MockCalculator mockCalc;

    // add(3, 5) が呼ばれたときに 8 を返す
    EXPECT_CALL(mockCalc, add(3, 5)).WillOnce(Return(8));

    // 実際にモックを使う
    EXPECT_EQ(mockCalc.add(3, 5), 8);
}

TEST(CalculatorTest, DivisionByZeroTest) {
    MockCalculator mockCalc;

    // divide(10, 0) のとき例外を投げるように設定
    EXPECT_CALL(mockCalc, divide(10, 0)).WillOnce(::testing::Throw(std::runtime_error("Divide by zero")));

    // 例外が発生することを確認
    EXPECT_THROW(mockCalc.divide(10, 0), std::runtime_error);
}