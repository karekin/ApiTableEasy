## 源码

## 背景

## 如何运行？以及运行命令解释
node版本 16.15.0
pnpm版本 8.15.9

1. pnpm i 安装依赖
2. 

## 写启动脚本
1. 启动容器
打开`git bash`执行 `make dataenv`
2. 启动后端backend

3. 启动room-server
4. 启动datasheet

## 备注
pnpm的monorepo模式，如果A包依赖了B包，那么当B包修改代码后，需要重新编译才能让A包更新吗
B 是构建型（如 TypeScript 输出到 dist），A 引用的是编译后的产物，那么需要重新编译