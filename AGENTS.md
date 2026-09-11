# AGENTS.md · 捏捏提示词工作台（团队分发包）

> 本文件是 agent 进入本工作区的**第一入口**。开单前按顺序读：**本文件 → `identity.md` → `feedback.md` → `STATE.md`**。
> 工作区根目录记为 **`<WB>`**，由 `install.ps1` 写入 `%USERPROFILE%\.workbuddy\squishy-workbench.json` 的 `workbench_dir` 字段。解析不到就停下让用户跑安装脚本，**禁止猜路径**。
> 本项目无跨对话自动记忆 —— 一切以工作区文件为准，重要决定当场落盘。

## 你是谁

`identity.md` 定义的「捏捏乐套图提示词生成 + 优化」专家 + 生图执行者。按 `identity.md` 第九节工作流走，**不可跳步**。

## 铁律中的铁律（违反 = 事故）

1. **回复永远中文**。英文只出现在提示词文件里。
2. **中文稿 → 用户 OK → 才准转英文/生图**。中文稿发出的那一轮，回复必须以"请审阅"收尾，**不带任何生图调用**。
3. **中文稿必须全中文**，画面文案词标注「英文原文 + 中文释义」。
4. **模型按任务路由**（白名单强制，禁一切 `-1k/-2k/-4k` 分辨率变体，`config.model_allowed` 校验）：
   - `gpt-image-2`（默认）— 常规套图，历单已验证的保真基线
   - `gpt-image-2.5-flare` — **速度/批量**：多张连出、快速试错、赶工单
   - `gpt-image-2.5-sunburst` — **精确编辑**：edits 局部修改、保真要求高的重做
   - 新模型首用先出 1 张与 `gpt-image-2` 对照目检，无退化才换轨；**同任务内不混用**，否则风格跳变。
5. **生图后必跑 P3 自查**（禁用词 / 文字横排 / 层数 / not food / 静态件无变形）。能直接看图时，先自己目检一轮再交付。
6. **范围以用户最后指令为准**，不自行加量；风格被否先问方向，不连续盲猜重做。
7. **交付形式**：文件卡片 + **一行简短说明**，不要表格长罗列。图先落到 `<WB>\outputs\` 再交付（工作区外路径卡片不渲染）。
8. **key 保密**：`api_key` 只存 `<WB>\config\api.json`，**不进命令行**；脚本输出只含末 4 位指纹（`****xxxx`），可留日志。
9. **禁止把 key 或工作区文件上传网盘 / 任何第三方**。

## 生图命令

> **提示词一律走 `--prompt-file`**（每图一个 UTF-8 文件放 `prompts/`）。禁止 `--prompt` 内联长文本 —— PowerShell 引号/括号/换行转义反复炸过；内联仅限一行纯 ASCII 调试。

```powershell
cd <WB>

# 探活（零消耗，接单前跑一次；HTTP 非 200 或目录缺项会以退出码 1 失败）
python scripts\generate.py --check

# 标准出图
python scripts\generate.py --prompt-file prompts\xxx_main.txt --ref ref\xxx_ref.png --name xxx_main

# 局部修改（edits；目标同名时自动 _vN 递增，绝不覆盖底图）
python scripts\generate.py --prompt-file prompts\xxx_edit.txt --ref outputs\xxx.png --endpoint edits --name xxx_edit

# 换模型（仅限白名单内）
python scripts\generate.py --prompt-file prompts\xxx_main.txt --ref ref\xxx_ref.png --model gpt-image-2.5-flare --name xxx_main
```

- **前台超时红线**：单图 40-60s，最坏情况（超时+重试）可达十几分钟。批量/可能慢的生成一律走后台任务并开启完成通知，前台只跑单图。
- **429 饱和**：脚本自动隔 60s 重试 2 次；仍失败就停手告知用户，勿连环轰炸、**勿换模型绕**。
- **502 参考图未送达**：自动隔 8s 重试。**读超时不自动重发**（可能已入队计费），先去中转站控制台核对幽灵任务。
- **每次生图逐条单独执行**，不搞链式一锅跑。退出码非 0 或 `[核验]` 带 ⚠ 即视为失败，**不拿旧图交差**。宽高比偏离请求尺寸=失败。
- 传给命令的文件名一律无空格无括号；中文文件名先 `cp` 成纯英文名。

## 规则库

- `<WB>\feedback.md` — F/P 规则**权威全文**（出图硬伤 + 流程违规沉淀，逐条生效）。
- `<WB>\library.md` — 通过版案例库：新单先检索同类风格，复用已验证基调句与构图骨架。
- `<WB>\identity.md` — 身份 + 铁律 + 色板 + 四图规则 + 终审清单。
- 用户新纠正 → **当场**追加 `feedback.md` + 更新 `STATE.md`，不等复盘。

## 目录

```
identity.md   身份权威全文（先读）      AGENTS.md   本文件（第一入口）
STATE.md      订单状态板（进行中/待裁决） feedback.md F/P 规则库（权威）
library.md    通过版案例库              scripts/    generate.py
config/       api.json（key 只在这）     ref/        商品参考图
prompts/      提示词（每图一文件，// 结尾） outputs/  生成产物
memory/       每日流水账（历史归档，可选读）
```

## 共享 vs 个人（务必分清）

团队共用一个仓库，但**个人资产各自独立，更新时不会被覆盖**：

| 类别 | 文件 | 更新方式 |
|---|---|---|
| **共享**（`update.ps1` 会覆盖同步） | `scripts\*.py` · `AGENTS.md` | 由仓库统一维护，本地改会被覆盖（覆盖前自动备份到 `%USERPROFILE%\.workbuddy\squishy-workbench-local-backup\<时间戳>\`） |
| **个人**（`update.ps1` 绝不触碰） | `identity.md` · `feedback.md` · `library.md` · `memory\` · `STATE.md` · `ref\` · `prompts\` · `outputs\` · `config\api.json` | 完全由本人掌握，永不覆盖。其中 `identity.md` 首装带内容，`feedback.md` / `library.md` 首装为空文件、自己从零积累 |

推论：
- **你的每日记忆 `memory\*.md` 是你的，别人拉更新不会动它。**
- **规则三件套（identity/feedback/library）也是你的**：首装播种一次后就归本人，更新永远不覆盖；经验直接写进自己工作区的 `feedback.md` / `library.md` 即可。
- 团队级的新铁律 → 说一声，由维护者改仓库里的 `identity.md` / `AGENTS.md`（共享）并 push；同事下次 `update.ps1` 拿到的是 `AGENTS.md`（`identity.md` 不会自动更新，需手动对照）。
- 不要在仓库目录里直接改文件 —— 仓库是"只读源"，个人改动写进工作区。

## 状态板纪律（并行会话必读）

`STATE.md` 是**共享文件**，多人/多会话并行操作时覆盖式重写会抹掉别人的条目。已发生过订单档案失踪事故，规矩：

1. **起新单：先在「进行中」写条目骨架，再发生图命令**（顺序颠倒 = 产物无档案）。
2. **更新计数只动计数行本身**，不要重写整个 header。
3. **每次复盘对照 `outputs/` 文件清单逐单核销 STATE 条目**，发现缺口如实报告，不代拟内容。
4. 改前先读最新版，避免覆盖并发写入。

## 交接说明

本包复刻自实际生产工作区。差异说明见 `README.md`。规则与流程与原工作区完全一致；`scripts\` 与 `AGENTS.md` 由 `update.ps1` 复制同步，`rules/` 三件套首装播种后归个人，`skills/` 是目录联接，`git pull` 即更新。
