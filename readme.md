# APITable 开源项目部署指南

## 项目简介

APITable是一种支持实时协作的可视化数据库产品，具有以下核心特征：
- **实时协作** - 支持多用户同时编辑
- **可视化** - 提供直观的数据操作界面
- **数据库** - 强大的数据存储和查询能力

## 源码信息

- **官方源码**: [https://github.com/apitable/apitable](https://github.com/apitable/apitable)
- **官方文档**: [https://apitable.getoutline.com/s/751b142b-866f-4174-a5f1-a2975f85ad41/doc/developer-quick-start-zofpBpXg9A](https://apitable.getoutline.com/s/751b142b-866f-4174-a5f1-a2975f85ad41/doc/developer-quick-start-zofpBpXg9A)

## 环境要求

### 必需软件及版本

| 软件 | 版本要求 | 说明 |
|------|----------|------|
| Git | 2.49.0+ | 版本控制 |
| Node.js | 16.15.0 | 使用nvm安装推荐 |
| pnpm | 8.15.9 | 包管理器 |
| Java | OpenJDK 17.0.15+ | 后端服务 |
| Python | 3.13+ | 构建工具 |
| Docker Desktop | 4.40.0+ | 容器化部署 |

> ⚠️ **重要**: Node.js和pnpm版本必须严格按照要求，否则`pnpm install`会报错

### 环境检查

```bash
# 检查各软件版本
node --version    # 应显示 v16.15.0
pnpm --version    # 应显示 8.15.9
java --version    # 应显示 OpenJDK 17.x
python3 --version # 应显示 Python 3.13.x
docker --version  # 应显示 Docker 24.x+
```

## 快速部署

### 1. 克隆项目

```bash
git clone https://github.com/apitable/apitable.git
cd apitable
```

### 2. 启动数据环境

```bash
make dataenv
```

此命令会：
- 创建数据存储目录：`data/mysql`、`data/minio/data`、`data/minio/config`、`data/redis`、`data/rabbitmq`
- 启动Docker容器：MySQL、MinIO、Redis、RabbitMQ、初始化数据库

### 3. 安装依赖并构建

```bash
make install
```

此命令会依次执行：
- `pnpm install && pnpm build:dst:pre` - 安装依赖并构建前端包
- `pnpm build:sr` - 构建服务端包
- `cd backend-server && ./gradlew build -x test --stacktrace` - 构建Java后端

### 4. 启动服务

```bash
make run
```

按提示选择启动服务：
- 输入 `1` - 启动 backend-server (Java后端)
- 输入 `2` - 启动 room-server (协同编辑)
- 输入 `3` - 启动 web-server (前端界面)
- 输入 `4` - 启动 databus-server (数据总线)

## 服务架构

### 核心服务

| 服务 | 端口 | 描述 | 技术栈 |
|------|------|------|--------|
| backend-server | 8081 | 后端API服务 | Java Spring Boot |
| room-server | - | 协同编辑服务 | Node.js + NestJS |
| web-server | - | 前端界面 | Next.js |
| databus-server | 8625 | 数据总线服务 | Docker容器 |

### 数据服务

| 服务 | 端口 | 描述 | 管理界面 |
|------|------|------|----------|
| MySQL | 3306 | 主数据库 | - |
| Redis | 6379 | 缓存服务 | - |
| RabbitMQ | 5672, 15672 | 消息队列 | http://localhost:15672 |
| MinIO | 9000-9001 | 对象存储 | http://localhost:9001 |

## 访问地址

- **后端API**: http://localhost:8081/api
- **前端界面**: 通过web-server访问
- **RabbitMQ管理**: http://localhost:15672
- **MinIO管理**: http://localhost:9001

## 项目结构

### 核心模块

1. **backend-server** - 后端服务模块
   - 提供所有数据请求接口
   - 使用MySQL、Redis、RabbitMQ中间件
   - 用户账号信息存储在`apitable_user`表

2. **room-server** - 协同编辑模块
   - 实现实时协作功能
   - 依赖databus-server

3. **web-server** - 前端模块
   - 基于Next.js构建
   - 使用文件路径路由模式
   - 仅4个页面使用SSR，其余为CSR

4. **databus-server** - 数据总线服务
   - 支持协同编辑功能
   - 通过Docker容器运行

### 技术特点

- **前端渲染**: 主要使用CSR(客户端渲染)，少量SSR(服务端渲染)
- **状态管理**: 通过axios发送网络请求调用后端接口
- **实时协作**: 基于WebSocket实现多用户协作

## 开发说明

### Next.js渲染机制

| 渲染模式 | 客户端数据请求 | getServerSideProps | 使用场景 |
|----------|----------------|-------------------|----------|
| SSG | 否 | 否 | 静态页面 |
| SSR | 否 | 是 | 动态页面 |
| CSR | 是 | - | 交互页面 |

### 开发流程

1. 在domain层定义领域模型和接口
2. 在infra层实现数据访问和外部服务调用
3. 在application层实现应用服务
4. 在web层添加API接口
5. 添加相应的单元测试

## 故障排除

### 常见问题

1. **Docker镜像拉取失败**
   ```bash
   # 配置国内镜像源
   # 编辑 ~/.docker/daemon.json
   {
     "registry-mirrors": [
       "https://docker.mirrors.ustc.edu.cn",
       "https://hub-mirror.c.163.com"
     ]
   }
   ```

2. **Node.js版本不匹配**
   ```bash
   # 使用nvm安装指定版本
   nvm install 16.15.0
   nvm use 16.15.0
   ```

3. **端口冲突**
   ```bash
   # 检查端口占用
   lsof -i :8081
   netstat -an | grep LISTEN
   ```

### 服务状态检查

```bash
# 检查进程状态
ps aux | grep -E "(java|node|nest)"

# 检查Docker容器
docker ps

# 检查端口监听
netstat -an | grep LISTEN | grep -E "(8081|3000|8080|8082)"
```

## 停止服务

```bash
# 停止所有Docker容器
docker compose down

# 停止进程服务
# 查找并终止相关进程
ps aux | grep -E "(java|node|nest)" | grep -v grep
kill -9 <PID>
```

## 贡献指南

1. Fork项目
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建Pull Request

## 许可证

本项目采用开源许可证，详情请查看 [LICENSE](LICENSE) 文件。

## 支持

如有问题，请：
1. 查看官方文档
2. 提交Issue
3. 参与社区讨论