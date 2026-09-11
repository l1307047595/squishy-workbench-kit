# squishy-workbench-kit

捏捏提示词工作台的分发包。**技能 + 规则库 + 生图脚本 + agent 入口**四件套一起发，任何一份缺失都会让技能变成空壳。

> **同事只看一份文档** → [`ONBOARDING.md`](ONBOARDING.md)（10 分钟一次性安装 + 日常更新 + 排错表）。
> 下面是维护者视角的完整说明。

## 这个包里有什么

| 目录 / 文件 | 内容 | 更新方式 |
|---|---|---|
| `skills/` | 两个 WorkBuddy 技能：`squishy-prompt-workbench`（接单主流程）、`prompt-workbench-audit`（工作区体检） | 目录联接，`git pull` 即时生效 |
| `rules/` | 仅 `identity.md`（身份铁律，首装种子）。`feedback.md` / `library.md` **不入仓库**，由 install.ps1 在工作区创建空文件，每人自己积累 | **不复制同步，永不覆盖** |
| `scripts/generate.py` | 生图脚本（重试 / 出图核验 / `_vN` 防覆盖 / 模型白名单 / 路径收敛） | 复制同步 |
| `AGENTS.md` | agent 进入工作区的第一入口（9 条铁律 + 命令 + 目录） | 复制同步 |
| `STATE.template.md` | 订单状态板模板（仅首次安装时铺一份） | **个人文件，之后永不覆盖** |
| `config/api.example.json` | 中转站配置模板，**key 留空** | 复制同步 |
| `install.ps1` / `update.ps1` | 一键安装 / 一键更新 | 复制同步 |
| `ONBOARDING.md` | 同事安装指南（发这一份给同事即可） | 复制同步 |

## 共享 vs 个人（重要）

| 类别 | 文件 | 会不会被更新覆盖 |
|---|---|---|
| **共享** | `scripts/*.py`、`AGENTS.md` | **会**，这就是"实时同步"的部分 |
| **个人** | `identity.md`、`feedback.md`、`library.md`、`memory/`、`STATE.md`、`ref/`、`prompts/`、`outputs/`、`config/api.json` | **永不覆盖**，完全归你自己 |

- **规则三件套（identity/feedback/library）是个人文件**：`identity.md` 首装带完整内容，`feedback.md` 与 `library.md` 首装为空文件，每个人的规则与案例自己从零积累；团队更新不会动它们。
- **每个人的每日记忆 `memory/*.md` 独立存在，团队更新不会动它。**
- 共享文件被覆盖前，若本地副本有改动，会自动备份到
  `%USERPROFILE%\.workbuddy\squishy-workbench-local-backup\<时间戳>\`，不会静默丢东西。
- 团队级新铁律 → 交给维护者改仓库里的 `AGENTS.md`（共享）并 push；个人经验直接写自己工作区的 `feedback.md` / `library.md`，不会被覆盖。

## 一次性安装

### 1. 装 git（没装过才需要）

```powershell
winget install --id Git.Git -e
```

### 2. 克隆仓库

```powershell
git clone https://github.com/l1307047595/squishy-workbench-kit.git D:\skills-repo
```

> **私有仓库**：clone 前需要维护者把你加为 Collaborator，否则报 401 / Repository not found。
> 内网或墙内连不上 GitHub 时，改用自己的镜像或公司 Git 地址。

### 3. 跑安装脚本

```powershell
cd D:\skills-repo
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

脚本做的事：

1. 建工作区 `D:\squishy-workbench\`（`ref/ prompts/ outputs/ config/ scripts/ memory/`）
2. 播种规则三件套（`identity.md` 带内容，`feedback.md`/`library.md` 空文件，**之后永不覆盖**）、铺 `scripts/*.py` 与 `AGENTS.md`，首次生成 `STATE.md`
3. 生成 `config/api.json` 模板（**key 你自己填**）
4. 在 `%USERPROFILE%\.workbuddy\skills\` 下建**目录联接**指向本仓库的 `skills/*`
   → 之后 `git pull` 一拉，技能立刻是新版，**永远不用重装**
5. 把工作区路径写进 `%USERPROFILE%\.workbuddy\squishy-workbench.json`
6. （可选）注册定时任务，每 30 分钟自动 `git pull` + 同步共享文件

自定义：

```powershell
.\install.ps1 -WorkbenchDir "E:\my-workbench" -ScheduleMinutes 15
.\install.ps1 -ScheduleMinutes 0      # 不建定时任务，手动更新
```

### 4. 填 key 并自检

```powershell
notepad D:\squishy-workbench\config\api.json
cd D:\squishy-workbench
python scripts\generate.py --check      # 零消耗探活，不出图不扣费
```

看到 `[check] OK —— 可以接单` 就成了。

## 日常更新

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File D:\skills-repo\update.ps1
```

`git pull` → 覆盖同步 `scripts/` `AGENTS.md`（覆盖前自动备份本地改动）→ 打印变更摘要。
`identity.md`、`feedback.md`、`library.md`、`memory/`、`STATE.md`、`ref/`、`prompts/`、`outputs/`、`config/api.json` **全程不动**。
装了定时任务的话这步是自动的。

## 出图怎么跑

```powershell
cd D:\squishy-workbench
python scripts\generate.py --prompt-file prompts\<前缀>_main.txt --ref ref\<前缀>_ref.png --name <前缀>_main

# 局部修改
python scripts\generate.py --prompt-file prompts\<前缀>_edit.txt --ref outputs\<图>.png --endpoint edits --name <前缀>_edit
```

**模型白名单**（`config.model_allowed` 强制，禁一切 `-1k/-2k/-4k` 分辨率变体）：

| 模型 | 用途 |
|---|---|
| `gpt-image-2` | 默认，常规套图，保真基线 |
| `gpt-image-2.5-flare` | 速度/批量：多张连出、快速试错 |
| `gpt-image-2.5-sunburst` | 精确编辑：edits 局部修改、高保真重做 |

新模型首用先出 1 张与默认模型对照目检；同任务内不混用。

## 安全约定

- `config/api.json` 含中转站 key，**已在 .gitignore 中**，永远不要提交或贴群
- 同事各用各的 key、各付各的费
- `outputs/` `ref/` `prompts/` 是个人产物，不进仓库
- 仓库私有：里面含价格、店铺、客户偏好等经营信息

## 常见问题

| 现象 | 处置 |
|---|---|
| `install.ps1` 报"未对文件进行数字签名" | 用带 `-ExecutionPolicy Bypass` 的完整命令 |
| 技能没生效 | 确认 `%USERPROFILE%\.workbuddy\skills\` 下是 Junction；不行重启 WorkBuddy |
| `python` 不是内部或外部命令 | 用 WorkBuddy 自带解释器 `%USERPROFILE%\.workbuddy\binaries\python\envs\default\Scripts\python.exe` |
| 定时任务注册失败（权限不足） | 跳过，改成每天手动跑一次 `update.ps1` |
| 429 `image_queue_full` | 上游饱和，脚本自动隔 60s 重试；别连环轰炸、别换模型绕 |
| 自己改过的共享文件被覆盖了 | 去 `%USERPROFILE%\.workbuddy\squishy-workbench-local-backup\<时间戳>\` 找回 |
| clone 报 401 / Repository not found | 让维护者把你加进 Collaborators |
