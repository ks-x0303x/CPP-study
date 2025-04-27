#include <gtest/gtest.h>
#include <gmock/gmock.h>

using ::testing::Return;
using ::testing::_;

#include "MockCalculator.hpp"

#include "CalculatAddUseCase.hpp"

// テスト観点   :
// Execute    : 正常系

TEST(CalculatAddUseCaseTest, Execute) {
    // Mockオブジェクトを作成
    auto mockCalculator = std::shared_ptr<MockCalculator>();
    

    // 期待される動作を定義
    EXPECT_CALL(*mockCalculator, add(3, 5))
        .Times(1)
        .WillOnce(Return(8));

    // UseCaseを作成
    CalculatAddUseCase useCase(mockCalculator);

    // 実行
    int result = useCase.execute(3, 5);

    // 結果を検証
    EXPECT_EQ(result, 8);
}