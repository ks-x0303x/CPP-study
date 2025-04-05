#include <iostream>
#include <string>
#include <boost/utility/string_view.hpp>
#include <Hypodermic/ContainerBuilder.h>

class IService
{
    public:
        virtual void excute() const = 0;
        virtual ~IService(){std::cout << "Delete Base" << std::endl;}
};

class ControlService : public IService
{
    public:
        virtual ~ControlService() override {std::cout << "Delete ControlService" << std::endl;}

        void excute() const override 
        {
            std::cout << "this is ControlService." << std::endl;
        }
};

class ApplicationService : public IService
{
    public:
        virtual ~ApplicationService() {std::cout << "Delete ApplicationService" << std::endl;}
        void excute() const override
        {
            std::cout << "this is ApplicationService." << std::endl;
        }
};

class Hoge1 
{
    public:
        explicit Hoge1(){
            std::cout << "Create Hoge1" << std::endl;
            this->name = "Init name";
        }
        ~Hoge1(){std::cout << "Delete Hoge1" << std::endl;}
        std::string name;
};

class Hoge2
{
    public:
        explicit Hoge2(const std::shared_ptr<Hoge1> &hoge)
            {
                hoge_ = hoge;
                std::cout << "Create Hoge2" << std::endl;
            }
        ~Hoge2(){std::cout << "Delete Hoge2" << std::endl;}

    private:
        std::shared_ptr<Hoge1> hoge_;
};

void InstanceExample()
{
    // インスタンス生成の時
    // newを使用しない場合、実態が生成され、関数のスコープを抜けたときにメモリ解放される。
    auto hoge1_1 = Hoge1();
    // newを使用する場合、実態のポインタが生成され、関数のスコープを抜けたときにメモリ解放されない。
    auto hoge1_2 = new Hoge1;
}

void HypodermicExample()
{
    std::shared_ptr<Hypodermic::ContainerBuilder>builder = std::make_shared<Hypodermic::ContainerBuilder>();
    //auto builder = Hypodermic::ContainerBuilder();

    builder->registerType<ControlService>().named<IService>("Control");
    builder->registerType<ApplicationService>().named<IService>("Application").singleInstance();
    //builder->registerType<Hoge1>();
    //builder->registerType<Hoge2>();
    builder->registerInstanceFactory([&](Hypodermic::ComponentContext&)
    {
        auto hoge = std::make_shared<Hoge1>();
        return std::make_shared<Hoge2>(hoge);
    })
    .singleInstance();
    

    auto container = builder->build();
    auto service1 = container->resolveNamed<IService>("Control");
    auto service2 = container->resolveNamed<IService>("Application");
    //auto hoge1 = container->resolve<Hoge1>();
    auto hoge2 = container->resolve<Hoge2>();
    auto hoge2_temp = container->resolve<Hoge2>();
    
    service1->excute();
    service2->excute();
}


class Info
{
    public:
    Info(const std::string name)
    : name_(name)
    {

    }

    boost::string_view getName(){return name_;}

    private:
    const std::string& name_;
};

class Model
{
    public:
    Info GetInfo()
    {
        auto text = "hoge";
        auto info = Info(text);
        std::cout << info.getName() << std::endl;
        return Info(text);
    }

};

class Controller
{
    public:
    void Process()
    {
        auto model = Model();
        auto info = model.GetInfo();
        std::cout << info.getName() << std::endl;
    }
};

void SharedPtrExample()
{
    std::cout << "// 観点： 通常のshared_ptrの生成直後の参照カウント" << std::endl;
    std::shared_ptr<Hoge1> hoge1_1 = std::make_shared<Hoge1>();
    hoge1_1->name = "hoge1";
    std::cout << "hoge1_1 count = " << hoge1_1.use_count() << std::endl;
    std::cout << "hoge1_1.name = " << hoge1_1->name << std::endl;

    std::cout << "観点： 参照（&）のshared_ptrに代入したときの参照カウント" << std::endl;
    std::shared_ptr<Hoge1>& hoge1_2 = hoge1_1;
    std::cout << "hoge1_1 count = " << hoge1_1.use_count() << std::endl;
    std::cout << "hoge1_2.name = " << hoge1_2->name << std::endl;

    std::cout << "観点： 通常のshared_ptrに代入したときの参照カウント" << std::endl;
    auto hoge1_3 = hoge1_1;
    std::cout << "hoge1_1 count = " << hoge1_1.use_count() << std::endl;
    std::cout << "hoge1_3.name = " << hoge1_3->name << std::endl;

    std::cout << "観点： 通常のshared_ptrに再代入したときの元shared_ptrの参照カウント" << std::endl;
    hoge1_3 = std::make_shared<Hoge1>();
    std::cout << "hoge1_1 count = " << hoge1_1.use_count() << std::endl;
    
    std::cout << "観点： shared_ptrの指す変数を変更した後の、違うshared_ptrの変更の値" << std::endl;
    hoge1_3->name = "cange hoge1";
    std::cout << "hoge1_.1name = " << hoge1_1->name << std::endl;

    std::cout << "観点： const 参照（&）のshared_ptrの生成直後の参照カウント" << std::endl;
    const std::shared_ptr<Hoge1>& hoge1_4 = hoge1_2;
    std::cout << "hoge1_1 count = " << hoge1_1.use_count() << std::endl;
    std::cout << "hoge1_4.name = " << hoge1_4->name << std::endl;

    std::cout << "観点： shared_ptrの指す変数を変更した後の、違うshared_ptrの変更の値 すべて確認" << std::endl;
    hoge1_4->name = "hogehoge";

    std::cout << "hoge1_1.name = " << hoge1_1->name << std::endl;
    std::cout << "hoge1_2.name = " << hoge1_2->name << std::endl;
    std::cout << "hoge1_3.name = " << hoge1_3->name << std::endl;
    std::cout << "hoge1_4.name = " << hoge1_4->name << std::endl;
    

    // これはエラーになる。constに対する再代入。
    // hoge1_4 = std::make_shared<Hoge1>();


}

int main() {
    std::cout << "HypodermicExample----------->" << std::endl;
    HypodermicExample();
    std::cout << "HypodermicExample-----------<" << std::endl;

    std::cout << "InstanceExample----------->" << std::endl;
    InstanceExample();
    std::cout << "InstanceExample-----------<" << std::endl;

    std::cout << "SharedPtrExample----------->" << std::endl;
    SharedPtrExample();
    std::cout << "SharedPtrExample-----------<" << std::endl;

    auto controller = Controller();
    controller.Process();
    // 必要ならヘッダーファイル内の関数や定義を使用
    return 0;
}