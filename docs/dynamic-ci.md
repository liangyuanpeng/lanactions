# 动态 CI 配置指南

这个项目使用动态 CI 配置来根据不同的条件智能地运行测试和构建任务。

## 工作原理

1. **Setup Job**: 分析输入参数、代码变更和配置文件，生成动态的 job matrix
2. **Dynamic Jobs**: 根据生成的 matrix 运行相应的任务
3. **智能检测**: 根据变更的文件类型自动调整测试策略

## 使用方式

### 手动触发

在 GitHub Actions 页面手动触发 workflow 时，可以设置以下参数：

- `ghevent`: 预定义的配置档案
  - `minimal`: 最小化测试（仅构建）
  - `standard`: 标准测试（默认）
  - `full`: 完整测试（包括多版本、多数据库）
  - `security`: 安全扫描

- `customParam`: 自定义参数
  - `arm-only`: 仅在 ARM 架构上运行
  - `java21-only`: 仅使用 Java 21
  - `skip-e2e`: 跳过端到端测试
  - `add-security`: 添加安全扫描

### 自动检测

当代码发生变更时，系统会自动检测变更类型并调整测试策略：

- **Go 文件变更**: 添加 Go 测试，启用 e2e 测试
- **Java 文件变更**: 添加 Java 测试，启用多版本测试和 e2e 测试
- **配置文件变更**: 添加配置验证测试
- **Docker 文件变更**: 添加 Docker 构建和镜像扫描

## 配置文件

### `config/ci-matrix.json`

定义了不同的测试档案和变更检测规则：

```json
{
  "profiles": {
    "minimal": { ... },
    "standard": { ... },
    "full": { ... }
  },
  "change_detection": {
    "go_files": { ... },
    "java_files": { ... }
  }
}
```

### 自定义配置

你可以修改 `config/ci-matrix.json` 来：

1. 添加新的测试档案
2. 调整现有档案的配置
3. 修改变更检测规则
4. 添加新的文件类型检测

## 示例

### 最小化测试
```bash
# 手动触发
ghevent: minimal
```

### 完整测试
```bash
# 手动触发
ghevent: full
```

### 仅 ARM 架构测试
```bash
# 手动触发
ghevent: standard
customParam: arm-only
```

### 添加安全扫描
```bash
# 手动触发
customParam: add-security
```

## 扩展

要添加新的动态行为：

1. 修改 `config/ci-matrix.json` 添加新的配置
2. 更新 `scripts/smart-ci-matrix.sh` 添加新的逻辑
3. 在 workflow 中添加相应的 job 定义

## 调试

查看 setup job 的日志来了解生成的配置：

```
🚀 Smart CI Matrix Generator
Event: standard
Custom Param: 

✅ Using profile: standard
📋 Base configuration loaded
🔍 Detecting code changes...
📝 Changed files detected:
main.go
go.mod

✨ Detected go_files changes

🎯 Final CI Configuration:
📦 Basic jobs: ["build","e2e","go-test"]
🔧 CI matrix: {"java_version":["17"],"profile":["default"],"runasos":["ubuntu-latest","ubuntu-24.04-arm"]}
🔄 Always jobs: ["watcher","deployer"]

✅ Configuration generated successfully!
```