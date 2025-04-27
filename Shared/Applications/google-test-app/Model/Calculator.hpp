#pragma once

#include "ICalculator.hpp"

class Calculator : public ICalculator {
public:
    int add(int a, int b) override {
        return a + b;
    }

    int subtract(int a, int b) override {
        return a - b;
    }

    int multiply(int a, int b) override {
        return a * b;
    }

    int divide(int a, int b) override {
        if (b == 0) {
            throw std::runtime_error("Division by zero");
        }
        return a / b;
    }
};