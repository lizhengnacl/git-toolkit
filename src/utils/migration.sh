#!/usr/bin/env bash

# 描述: 检查是否需要执行配置迁移
# 参数: 无
# 返回: 0 需要迁移，1 不需要迁移
check_migration_needed() {
  if [[ ! -f "$MIGRATION_MARKER_FILE" ]]; then
    return 0
  fi
  return 1
}

# 描述: 执行配置迁移
# 参数: 无
# 返回: 0 成功，非 0 失败
run_migration() {
  mkdir -p "$GIT_TOOLKIT_DIR"

  cat > "$MIGRATION_MARKER_FILE" <<EOF
MIGRATION_VERSION="${MIGRATION_VERSION}"
MIGRATION_TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
EOF

  log_info "Configuration migration to v${MIGRATION_VERSION} completed"
  return 0
}

# 描述: 回滚迁移（如果失败）
# 参数: 无
# 返回: 0 成功，非 0 失败
rollback_migration() {
  if [[ -f "$MIGRATION_MARKER_FILE" ]]; then
    rm -f "$MIGRATION_MARKER_FILE"
    log_info "Migration rolled back"
  fi
  return 0
}
