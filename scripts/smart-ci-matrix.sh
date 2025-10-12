#!/bin/bash

# 智能 CI matrix 生成器
# 结合配置文件、输入参数和代码变更检测

set -e

GHEVENT="${1:-standard}"
CUSTOM_PARAM="${2:-}"
CONFIG_FILE="config/ci-matrix.json"

echo "🚀 Smart CI Matrix Generator"
echo "Event: $GHEVENT"
echo "Custom Param: $CUSTOM_PARAM"

# 检查配置文件是否存在
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Configuration file not found: $CONFIG_FILE"
  exit 1
fi

# 从配置文件读取基础配置
if jq -e ".profiles.\"$GHEVENT\"" "$CONFIG_FILE" > /dev/null; then
  echo "✅ Using profile: $GHEVENT"
  BASIC_JOBS=$(jq -r ".profiles.\"$GHEVENT\".basic_jobs | @json" "$CONFIG_FILE")
  CI_MATRIX=$(jq -r ".profiles.\"$GHEVENT\".ci_matrix | @json" "$CONFIG_FILE")
  ALWAYS_JOBS=$(jq -r ".profiles.\"$GHEVENT\".always_jobs | @json" "$CONFIG_FILE")
else
  echo "⚠️  Profile '$GHEVENT' not found, using 'standard'"
  BASIC_JOBS=$(jq -r '.profiles.standard.basic_jobs | @json' "$CONFIG_FILE")
  CI_MATRIX=$(jq -r '.profiles.standard.ci_matrix | @json' "$CONFIG_FILE")
  ALWAYS_JOBS=$(jq -r '.profiles.standard.always_jobs | @json' "$CONFIG_FILE")
fi

echo "📋 Base configuration loaded"

# 如果是 PR 或 push 事件，检测代码变更
if [[ "$GITHUB_EVENT_NAME" == "pull_request" || "$GITHUB_EVENT_NAME" == "push" ]]; then
  echo "🔍 Detecting code changes..."
  
  # 获取变更文件列表
  if [[ "$GITHUB_EVENT_NAME" == "pull_request" ]]; then
    CHANGED_FILES=$(git diff --name-only origin/${{ github.event.pull_request.base.ref }}...HEAD || echo "")
  else
    CHANGED_FILES=$(git diff --name-only HEAD~1 HEAD || echo "")
  fi
  
  if [[ -n "$CHANGED_FILES" ]]; then
    echo "📝 Changed files detected:"
    echo "$CHANGED_FILES"
    
    # 检查每种文件类型的变更
    while IFS= read -r change_type; do
      patterns=$(jq -r ".change_detection.\"$change_type\".patterns[]" "$CONFIG_FILE" 2>/dev/null || continue)
      
      # 检查是否有匹配的文件变更
      has_changes=false
      while IFS= read -r pattern; do
        if echo "$CHANGED_FILES" | grep -q "$pattern"; then
          has_changes=true
          break
        fi
      done <<< "$patterns"
      
      if [[ "$has_changes" == "true" ]]; then
        echo "✨ Detected $change_type changes"
        
        # 添加额外的 jobs
        add_jobs=$(jq -r ".change_detection.\"$change_type\".add_jobs[]?" "$CONFIG_FILE" 2>/dev/null || echo "")
        if [[ -n "$add_jobs" ]]; then
          while IFS= read -r job; do
            [[ -n "$job" ]] && BASIC_JOBS=$(echo "$BASIC_JOBS" | jq --arg job "$job" '. + [$job] | unique')
          done <<< "$add_jobs"
        fi
        
        # 添加 always jobs
        add_always_jobs=$(jq -r ".change_detection.\"$change_type\".add_always_jobs[]?" "$CONFIG_FILE" 2>/dev/null || echo "")
        if [[ -n "$add_always_jobs" ]]; then
          while IFS= read -r job; do
            [[ -n "$job" ]] && ALWAYS_JOBS=$(echo "$ALWAYS_JOBS" | jq --arg job "$job" '. + [$job] | unique')
          done <<< "$add_always_jobs"
        fi
        
        # 启用多 Java 版本测试
        enable_multi_java=$(jq -r ".change_detection.\"$change_type\".enable_multi_java?" "$CONFIG_FILE" 2>/dev/null)
        if [[ "$enable_multi_java" == "true" ]]; then
          CI_MATRIX=$(echo "$CI_MATRIX" | jq '.java_version = ["17", "21"]')
        fi
        
        # 启用 e2e 测试
        enable_e2e=$(jq -r ".change_detection.\"$change_type\".enable_e2e?" "$CONFIG_FILE" 2>/dev/null)
        if [[ "$enable_e2e" == "true" ]]; then
          BASIC_JOBS=$(echo "$BASIC_JOBS" | jq '. + ["e2e"] | unique')
        fi
      fi
    done <<< $(jq -r '.change_detection | keys[]' "$CONFIG_FILE")
  fi
fi

# 处理自定义参数
if [[ -n "$CUSTOM_PARAM" ]]; then
  echo "🎛️  Applying custom parameter: $CUSTOM_PARAM"
  case "$CUSTOM_PARAM" in
    "arm-only")
      CI_MATRIX=$(echo "$CI_MATRIX" | jq '.runasos = ["ubuntu-24.04-arm"]')
      ;;
    "java21-only")
      CI_MATRIX=$(echo "$CI_MATRIX" | jq '.java_version = ["21"]')
      ;;
    "skip-e2e")
      BASIC_JOBS=$(echo "$BASIC_JOBS" | jq 'map(select(. != "e2e"))')
      ;;
    "add-security")
      BASIC_JOBS=$(echo "$BASIC_JOBS" | jq '. + ["security-scan"] | unique')
      ALWAYS_JOBS=$(echo "$ALWAYS_JOBS" | jq '. + ["security-report"] | unique')
      ;;
  esac
fi

echo ""
echo "🎯 Final CI Configuration:"
echo "📦 Basic jobs: $BASIC_JOBS"
echo "🔧 CI matrix: $CI_MATRIX"
echo "🔄 Always jobs: $ALWAYS_JOBS"

# 输出到 GitHub Actions
echo "matrix=$BASIC_JOBS" >> $GITHUB_OUTPUT
echo "ci-matrix=$CI_MATRIX" >> $GITHUB_OUTPUT
echo "always-jobs=$ALWAYS_JOBS" >> $GITHUB_OUTPUT

echo ""
echo "✅ Configuration generated successfully!"