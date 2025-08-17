## 源码

[apitable官方开源地址](https://github.com/apitable/apitable)

[apitable官方文档](https://apitable.getoutline.com/s/751b142b-866f-4174-a5f1-a2975f85ad41/doc/developer-quick-start-zofpBpXg9A)

[ApiTableEasy地址](https://github.com/shenjipo/ApiTableEasy)

## 背景

`apitable`官方的代码无法直接在windows平台上运行，需要修改一些文件，且官方的项目中包含了很多`多维表格协同编辑`运行时不必要的代码，例如ai相关的组件，影响对于最核心部分代码的研究，因此，从官方的文档中抽取了`多维表格协同编辑`最核心的部分，并修改了必要的配置(具体修改内容参考[APITable开源项目学习](http://101.133.143.249/Blog/#/PreviewPc/PreviewBlog/762ab400-3a20-4af3-ab62-74106f4deda1))，使得新的项目`ApiTableEasy`能够在widnows平台上一键快速启动，方面研究核心业务逻辑

## ApitableEasy介绍

`ApitableEasy`项目包含三个模块

* backend-server 使用java编写，主要提供除协同编辑之外的后端服务
* room-server 使用nest.js编写，提供协同编辑后端服务
* datasheet-server 使用next.js编写，提供多维表格的web页面

### 如何启动

启动之前需要准备如下环境

* node16.15.0
* pnpm 8.15.9
* java openjdk 17.0.15
* python 3.13
* Docker Desktop 4.40.0

注意node和pnpm版本必须按照官方指定的版本，不然执行`pnpm i`的时候会报错

此外还要修改本机的**C:\Windows\System32\drivers\etc\hosts**文件，新增如下内容，配置域名解析

> 127.0.0.1       mysql
> 127.0.0.1       rabbitmq
> 127.0.0.1       redis
> 127.0.0.1       room-server
> 127.0.0.1       backend-server

按照顺序执行命令

1. 安装依赖 `pnpm i`
2. 编译部分子项目 `pnpm run build:pre`和`pnpm run build:dst`
3. 启动容器部署几个数据库并且初始化数据表，打开`git bash`，执行`make dataenv`
4. 启动`backend-server`，打开`git bash`，执行`make run`，输入1
5. 启动`room-server`，打开`git bash`，执行`make run`，输入2
6. 启动`datasheet-server`，打开`git bash`，执行`make run`，输入3

### 启动成功示例

启动成功后，打开localhost:3000，会看到`login`页面，登录成功后，会自动跳转到`workench`路由

login页面

![4690a3c6b095e106f468e8856d410dd2ab.png](http://101.133.143.249/blog-api/getImage/4690a3c6b095e106f468e8856d410dd2ab.png)

workench页面

![7a861e34419c4cf34f46bb12e00af415.png](http://101.133.143.249/blog-api/getImage/7a861e34419c4cf34f46bb12e00af415.png)

### apitable协同编辑实现原理

## 其他知识点

pnpm的monorepo模式，如果A包依赖了B包，那么当B包修改代码后，需要重新编译才能让A包更新吗
B 是构建型（如 TypeScript 输出到 dist），A 引用的是编译后的产物，那么需要重新编译
