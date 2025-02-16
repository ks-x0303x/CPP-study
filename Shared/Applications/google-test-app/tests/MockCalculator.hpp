#pragma once
#include "ICalculator.hpp"
#include <gmock/gmock.h>


class MockCalculator : public ICalculator {
public:
    MOCK_METHOD(int, add, (int a, int b), (override));
    MOCK_METHOD(int, subtract, (int a, int b), (override));
    MOCK_METHOD(int, multiply, (int a, int b), (override));
    MOCK_METHOD(int, divide, (int a, int b), (override));
};