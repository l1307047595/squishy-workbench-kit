# squishy-workbench-kit

捏捏提示词工作台的分发包。**技能 + 规则库 + 生图脚本**三件套一起发，任何一份缺失都会让技能变成空壳。

## 这个包里有什么

| 目录 | 内容 | 是否随 git 更新 |
|---|---|---|
| `skills/` | 两个 WorkBuddy 技能：`squishy-prompt-workbench`（接单主流程）、`prompt-workbench-audit`（工作区体检） | 是 |
| `rules/` | `identity.md`（身份铁律）、`feedback.md`（F/P 规则沉淀）、`library.md`（通过版案例库） | 是 |
| `scripts/` | `generate_hermes.py`（中转站生图脚本，含重试/核验/禁变体锁） | 是 |
| `config/api.example.json` | 中转站配置模板，**key 留空** | 是 |
| `install.ps1` / `update.ps1` | 一键安装 / 一键更新 | 是 |
| `config/api.json` | 你自己的 key（每人自备，**禁止提交**） | 否，已 gitignore |
| 工作区 `ref/ prompts/ outputs/` | 你自己的参考图与产出 | 否，不在仓库里 |

## 一次性安装

### 1. 装 git（没装过才需要）

```powershell
winget install --id Git.Git -e
```

### 2. 克隆仓库

```powershell
git clone <仓库地址> D:\skills-repo
```

> 内网/墙内连不上 GitHub 时，用你们公司自建 Git 或 Gitee 的地址；本机已配置 github 镜像重定向的话直接 clone 原地址即可。

### 3. 跑安装脚本

```powershell
cd D:\skills-repo
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

脚本做的事：

1. 建工作区 `D:\squishy-workbench\`（含 `ref/ prompts/ outputs/ config/ scripts/`，以及 `.workbuddy\memory\`）
2. 把 `rules/` 与 `scripts/` 铺进工作区
3. 生成 `config/api.json` 模板（**你要自己填 key**）
4. 在 `%USERPROFILE%\.workbuddy\skills\` 下建**目录联接**指向本仓库的 `skills\*` → 之后 `git pull` 一拉，技能立刻是新版
5. 把工作区路径写进 `%USERPROFILE%\.workbuddy\squishy-workbench.json`
6. （可选）注册定时任务，每 30 分钟自动 `git pull` + 同步规则库 → 做到"你改完、同事自动跟上"

自定义路径：

```powershell
.\install.ps1 -WorkbenchDir "E:\my-workbench" -ScheduleMinutes 15
.\install.ps1 -ScheduleMinutes 0      # 不建定时任务，手动更新
```

### 4. 填 key 并自检

```powershell
notepad D:\squishy-workbench\config\api.json
cd D:\squishy-workbench
python scripts\generate_hermes.py --check      # 零消耗探活，不出图不扣费
```

看到 `[check] OK —— 可以接单` 就成了。

## 日常更新

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File D:\skills-repo\update.ps1
```

做三件事：`git pull` → 覆盖同步 `rules/` 与 `scripts/` → 打印本次变更摘要。
装了定时任务的话这步是自动的，你什么都不用做。

## 出图怎么跑

```powershell
cd D:\squishy-workbench
python scripts\generate_hermes.py --prompt-file prompts\<前缀>_main.txt --ref ref\<前缀>_ref.png --endpoint edits --name <前缀>_main --size 1024x1024
```

参数与故障处置见 `skills\squishy-prompt-workbench\SKILL.md`。

## 安全约定（重要）

- `config/api.json` 含中转站 key，**已在 .gitignore 中**，永远不要提交，也不要贴进群里
- 同事各用各的 key、各付各的费
- `outputs/` 里的出图是个人产物，不进仓库
- 仓库是**私有的**：里面含价格、店铺、客户偏好等经营信息

## 常见问题

| 现象 | 处置 |
|---|---|
| `install.ps1` 报"无法加载文件，未对文件进行数字签名" | 用上面带 `-ExecutionPolicy Bypass` 的完整命令 |
| 技能没生效 | 确认 `%USERPROFILE%\.workbuddy\skills\` 下有对应目录且是 Junction；不行就重启 WorkBuddy |
| `python` 不是内部或外部命令 | 改用 WorkBuddy 自带解释器：`C:\Users\<你>\.workbuddy\binaries\python\envs\default\Scripts\python.exe` |
| 定时任务注册失败（权限不足） | 跳过即可，改为每天手动跑一次 `update.ps1` |
| 429 `image_queue_full` | 上游饱和，脚本会自动等 60s 重试；别连环轰炸、别换模型绕 |
| 同事拉到的规则库没更新 | 跑 `update.ps1`（`rules/` 是复制同步，不是链接） |
