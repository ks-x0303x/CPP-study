#pragma once
#include <memory>
#include "ICalculator.hpp"

class CalculatAddUseCase {
public:
    explicit CalculatAddUseCase(std::shared_ptr<ICalculator> calculator)
        : calculator_(std::move(calculator)) {}

    int execute(int a, int b) {
        return calculator_->add(a, b);
    }
private:
    std::shared_ptr<ICalculator> calculator_;
};