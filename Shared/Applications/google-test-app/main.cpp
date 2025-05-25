#include <iostream>
#include <memory>
#include <thread>
#include <chrono>
#include "Calculator.hpp"
#include "CalculatAddUseCase.hpp"

int main()
{
    std::cout << "main start up" << std::endl;
    std::shared_ptr<ICalculator> calculator = std::make_shared<Calculator>();
    CalculatAddUseCase useCase(calculator);
    while (true)
    {
        std::cout << "main loop" << std::endl;
        int result = useCase.execute(3, 5);
        std::cout << "Result of addition: " << result << std::endl;
        std::this_thread::sleep_for(std::chrono::seconds(1));
    }
    
    std::cout << "main shut down" << std::endl;

    return 0;
}