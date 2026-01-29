FROM freqtradeorg/freqtrade:2024.10

# 切换到 root 安装系统级依赖
USER root
# 安装策略必须的 Python 库
RUN pip install --no-cache-dir pandas-ta finta technical

# 切换回机器人用户
USER ftuser