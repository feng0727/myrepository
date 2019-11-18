# maven-archetype


模块说明

•uyun-common
通用模块，主要用于存放实体类以及工具类
 任何模块都可进行依赖，但其本身应尽量减少依赖

•uyun-service-interface
服务接口，共享于服务提供者和服务消费者
 作为抽象层被两者所依赖


•uyun-dao
  提供db mybatis 访问


•uyun-service
服务提供者，用于提供消费者接口实现
 存放主要业务逻辑


•uyun-web
服务消费者，提供前端Restful接口
 通过dubbo远程RPC调用提供方暴露的服务


依赖环境

•Redis

其中有使用到Redis作为数据缓存，可通过Docker快速搭建Redis环境
使用公司内部镜像
docker pull registry.cn-hangzhou.aliyuncs.com/uyun/redis-sentinel:3.0.7

docker run -dp 6379:6379 -p 26379:26379 --name redis --restart always -e REDIS_HOST=<server-ip> -e REDIS_PORT=6379 registry.cn-hangzhou.aliyuncs.com/uyun/redis-sentinel:3.0.7
注意其中<server-ip>需要设置宿主机的ip

•Zookeeper

使用Zookeeper作为Dubbo的服务注册中心，通过Docker快速搭建Zookeeper开发环境
拉取镜像
docker pull registry.aliyuncs.com/daydayup/zookeeper

启动容器
docker run -d -p 2181:2181 --name=zookeeper --restart always registry.aliyuncs.com/daydayup/zookeeper

•MySQL

数据持久化需要依赖MySQL数据库，这里直接使用官方的镜像即可
拉取官方镜像
docker pull mysql

启动容器并设置root密码
docker run -dp 3306:3306 --name mysql -e MYSQL_ROOT_PASSWORD=root mysql

