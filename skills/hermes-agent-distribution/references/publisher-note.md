# 发布者说明

每个 Hermes agent distribution 仓库应**保留** `skills/hermes-agent-distribution/`，随 `distribution_owned: skills` 一并发布。

## 为什么

其他开发者安装你的 agent 时，只需：

1. 绑定 `hermes-agent-distribution` skill（或从已安装的任意 distribution 中获得该 skill）
2. 提供你的 Git 仓库地址

无需手写 install 命令或记住 profile 名称。优化后的 skill 含 `.env` 分组说明、验证步骤与安装完成报告模板，减少安装过程中的来回追问。

## 发布前检查

- [ ] `skills/hermes-agent-distribution/SKILL.md` 存在且未被 `.gitignore` 排除
- [ ] `distribution.yaml` 根目录含有效 `name:`、`source:`、`env_requires`
- [ ] `./publish.sh` 可正常推送

## 可选：publish 成功提示

`publish.sh` 末尾可输出：

```text
其他开发者安装：提供 Git 地址 + hermes-agent-distribution skill
或：hermes profile install <REMOTE> --alias -y
```

不要写死 `--name`；名称由 manifest 决定。

## 与 agent-distribution-sync 的关系

| Skill | 职责 |
|-------|------|
| `hermes-agent-distribution` | 首次安装 |
| `agent-distribution-sync` | 已安装后的双向同步 |

两个 skill 互补，发布者均应保留。
