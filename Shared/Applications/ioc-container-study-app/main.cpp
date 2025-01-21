#include <stdio.h>
#include <Hypodermic/ContainerBuilder.h>

int main() {
    auto builder = Hypodermic::ContainerBuilder();
    printf("Using header-only library in test project with testlib subdir!\n");
    // 必要ならヘッダーファイル内の関数や定義を使用
    return 0;
}