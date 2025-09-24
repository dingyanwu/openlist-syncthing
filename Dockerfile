# 使用官方基础镜像（已含 aria2）
FROM openlistteam/openlist:latest-lite-aria2

# 从 syncthing 官方镜像拷贝 syncthing 二进制到 /bin/syncthing
COPY --from=syncthing/syncthing:latest /bin/syncthing /bin/syncthing

# 创建数据目录
RUN mkdir -p /data/openlist /data/syncthing

  

# ===== 创建 openlist 服务 =====
# 目录：/opt/service/start/openlist
RUN echo '#!/bin/sh' > /opt/service/start/openlist/run && \
    echo 'exec /opt/openlist/openlist --data /data/openlist server' >> /opt/service/start/openlist/run && \
    chmod +x /opt/service/start/openlist/run

# ===== 创建 syncthing 服务 =====
# 目录：/opt/service/start/syncthing
RUN mkdir -p /opt/service/start/syncthing && \
    echo '#!/bin/sh' > /opt/service/start/syncthing/run && \
    echo 'exec /bin/syncthing serve -H /data/syncthing' >> /opt/service/start/syncthing/run && \
    chmod +x /opt/service/start/syncthing/run

# ===== 可选：从 /opt/service/stop/aria2 拷贝到 /opt/service/start/aria2（如果存在）=====
# 检查上游镜像是否有 /opt/service/stop/aria2，有则拷贝到 start/
RUN if [ -d /opt/service/stop/aria2 ]; then \
      cp -a /opt/service/stop/aria2 /opt/service/start/aria2 2>/dev/null; \
    fi

# 暴露端口
EXPOSE 5244 8384 22000 21027/udp

# ===== 入口点脚本：全部逻辑写在这里（不依赖外部文件） =====
# 使用 RUN echo 构造一个完整的 entrypoint.sh 脚本，然后 COPY 到 /entrypoint.sh 并设置权限
RUN echo '#!/bin/sh' > /entrypoint.sh && \
    echo 'umask ${UMASK}' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo 'if [ "$1" = "version" ]; then' >> /entrypoint.sh && \
    echo '  ./openlist version' >> /entrypoint.sh && \
    echo 'else' >> /entrypoint.sh && \
    echo '  chown -R ${PUID}:${PGID} /opt' >> /entrypoint.sh && \
    echo '' >> /entrypoint.sh && \
    echo '  exec su-exec ${PUID}:${PGID} runsvdir /opt/service/start' >> /entrypoint.sh && \
    echo 'fi' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

# 容器启动时运行入口点

ENTRYPOINT ["/entrypoint.sh"]

