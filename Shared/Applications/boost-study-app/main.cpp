        // main.cpp
        #include <boost/asio.hpp>
        #include <iostream>
        #include <memory>
        #include <thread>
        #include <atomic>
        #include <string>


        int main() {
            // Boost Asioのio_contextオブジェクトを作成
            auto p_io_context = std::make_shared<boost::asio::io_context>();
            // 非同期のタスクを実行
            boost::asio::post(*p_io_context, []() {
                std::cout << "Hello from Boost Asio!" << std::endl;
            });
            auto running = true;
            std::thread worker_thread([p_io_context, &running](){
                while (true)
                {
                    std::string input_text;
                    std::cout << "キー入力をしてください。" << std::endl;
                    std::getline(std::cin, input_text);
                    if (input_text == "exit")
                    { // プログラム終了条件
                        running = false;   // ワーカースレッドのループを停止
                        p_io_context->stop(); // io_contextを終了
                        break;
                    }

                    // 非同期のタスクを実行
                    boost::asio::post(*p_io_context, []() {
                        std::cout << "Hello from Boost Asio!" << std::endl;
                    });
                }
            });

            std::cout << "タスク受付" << std::endl;
            while (running)
            {
                // io_contextでタスクを実行
                p_io_context->run();
                std::this_thread::sleep_for(std::chrono::milliseconds(1000));
            }
            
            return 0;
        }
