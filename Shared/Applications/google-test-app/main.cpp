#include <iostream>
#include "Calculator.hpp"
#include "CalculatAddUseCase.hpp"

int main()
{
    std::cout << "main start up" << std::endl;
    std::shared_ptr<ICalculator> calculator = std::make_shared<Calculator>();
    CalculatAddUseCase useCase(calculator);
    int result = useCase.execute(3, 5);
    std::cout << "Result of addition: " << result << std::endl;
    std::cout << "main shut down" << std::endl;

    return 0;
}