#!/bin/bash

# ==========================================
# Freqtrade Research Pipeline (Final Fix)
# 修复：加载 config_backtest.json 覆盖动态选币逻辑
# ==========================================

STRATEGY="NostalgiaForInfinityNext"
CONFIG="user_data/config.json"
CONFIG_BACKTEST="user_data/config_backtest.json" # 新增补丁路径
TIMEFRAME="5m"
DAYS=90
EPOCHS=100
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_DIR="user_data/research_results/${STRATEGY}_${TIMESTAMP}"

# 53 个蓝筹样本
TEST_PAIRS="BTC/USDT ETH/USDT SOL/USDT BNB/USDT XRP/USDT DOGE/USDT ADA/USDT AVAX/USDT LINK/USDT DOT/USDT MATIC/USDT LTC/USDT SHIB/USDT TRX/USDT UNI/USDT ATOM/USDT XLM/USDT ETC/USDT FIL/USDT APT/USDT ARB/USDT OP/USDT NEAR/USDT QNT/USDT LDO/USDT HBAR/USDT VET/USDT ICP/USDT GRT/USDT FTM/USDT SAND/USDT MANA/USDT AAVE/USDT EGLD/USDT THETA/USDT AXS/USDT XTZ/USDT EOS/USDT FLOW/USDT IMX/USDT KCS/USDT CRV/USDT MKR/USDT SNX/USDT ZEC/USDT RUNE/USDT CHZ/USDT COMP/USDT GALA/USDT ENJ/USDT BAT/USDT MINA/USDT DASH/USDT 1INCH/USDT KAVA/USDT XMR/USDT HOT/USDT IOTA/USDT NEO/USDT"

set -e

echo "-----------------------------------------------------"
echo "🚀 启动最终版研究流水线 - ${TIMESTAMP}"
echo "-----------------------------------------------------"

mkdir -p "${OUTPUT_DIR}"

# --- 1. 下载数据 (无需补丁) ---
echo ""
echo "📥 [Step 1/3] 检查数据完整性..."
docker-compose run --rm freqtrade download-data \
    --config "${CONFIG}" \
    --days "${DAYS}" \
    --timeframe "${TIMEFRAME}" \
    --exchange binance \
    --pairs ${TEST_PAIRS}

# --- 2. 基准回测 (加载双 Config) ---
echo ""
echo "📊 [Step 2/3] 执行基准回测..."
echo "逻辑：同时加载主配置和回测补丁，解决 VolumePairList 报错。"
docker-compose run --rm freqtrade backtesting \
    --config "${CONFIG}" \
    --config "${CONFIG_BACKTEST}" \
    --strategy "${STRATEGY}" \
    --timeframe "${TIMEFRAME}" \
    --timerange "$(date -d "${DAYS} days ago" +%Y%m%d)-" \
    --pairs ${TEST_PAIRS} \
    --export trades \
    --export-filename "${OUTPUT_DIR}/baseline_results.json"

echo "✅ 基准回测完成。"

# --- 3. 参数挖掘 (加载双 Config) ---
echo ""
echo "⛏️ [Step 3/3] 启动参数挖掘 (Hyperopt)..."
docker-compose run --rm freqtrade hyperopt \
    --config "${CONFIG}" \
    --config "${CONFIG_BACKTEST}" \
    --strategy "${STRATEGY}" \
    --hyperopt-loss SharpeHyperOptLoss \
    --spaces roi stoploss \
    -e "${EPOCHS}" \
    --timerange "$(date -d "${DAYS} days ago" +%Y%m%d)-" \
    --pairs ${TEST_PAIRS} \
    --print-all \
    --no-color > "${OUTPUT_DIR}/hyperopt_output.txt"

echo "-----------------------------------------------------"
echo "✅ 全流程结束！请查看: ${OUTPUT_DIR}/hyperopt_output.txt"
echo "-----------------------------------------------------"