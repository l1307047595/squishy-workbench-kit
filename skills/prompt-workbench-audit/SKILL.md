---
name: prompt-workbench-audit
description: 提示词工作台「工作区体检」技能——只读巡检一个生图工作区，输出资产盘点、订单链路缺口、记忆断档、命名/规则不一致与风险项。当用户说"分析当前工作区""工作区体检""盘一下这个工作区""巡检工作台""有没有没做完的单""上次干到哪了""体检/盘点/审计 workspace"时使用。适用于捏捏(squishy)、美妆(beauty)、Temu 全类目等所有 prompt workbench 型工作区。只读不落盘，不改动任何业务文件。
---

# 提示词工作台 · 工作区体检

## 概述

对一个「提示词 + 出图 + 规则库」型工作区做**只读体检**，回答三件事：**有什么资产 / 哪一单没做完 / 哪些东西已经不一致了**。
本技能只做诊断，不做修复；修复动作须单独征得用户同意。

## 目标工作区定位（开工前必先解析）

优先用用户本回合指定的目录；没指定时按下述顺序找：

1. 读 `%USERPROFILE%\.workbuddy\squishy-workbench.json`（**UTF-8 带 BOM，用 `utf-8-sig` 读**）→ 取 `workbench_dir`
2. 读不到 → 看当前工作目录是否本身就是 workbench（有 `ref/` `prompts/` `outputs/` 三件套）
3. 都找不到 → **停止**，问用户要目录。禁止乱猜、禁止扫描全盘

约定：下文 `<WB>` = 待体检的工作区根目录。**全程只读**。

## 工作区的标准结构

体检前先确认目标目录符合此形态，不符合说明不是 workbench 型工作区：

| 路径 | 角色 |
|---|---|
| `<WB>\ref\` | 参考图（商品基准） |
| `<WB>\prompts\` | 中文稿 `*_draft_cn.md` + 英文提示词 `*.txt` |
| `<WB>\outputs\` | 出图产物 |
| `<WB>\config\api.json` | 中转站配置（含 key，**读结构时必须脱敏**） |
| `<WB>\scripts\` | 生图脚本（`generate_hermes.py`） |
| `<WB>\identity.md` `feedback.md` `library.md` | 规则库三件套 |
| `<WB>\.workbuddy\memory\` | 每日日志 `YYYY-MM-DD.md` + `MEMORY.md` |

## Process（6 步，全程只读）

### 步骤 1 · 结构与体量盘点

统计 `ref/` `prompts/` `outputs/` `scripts/` 文件数与总字节，记录根目录规则库大小与修改时间。输出成一张表。

```powershell
$wb = "<WB>"
Get-ChildItem $wb -Force | Select-Object Mode, Length, LastWriteTime, Name
foreach ($d in @("ref","prompts","outputs","scripts")) {
  $c = @(Get-ChildItem (Join-Path $wb $d) -File -ErrorAction SilentlyContinue)
  "{0,-9} {1,5} files  {2,9:N1} MB" -f $d, $c.Count, (($c | Measure-Object Length -Sum).Sum / 1MB)
}
```

### 步骤 2 · 订单链路完整性（**核心，最常查出问题的一步**）

一单的完整链路是四段：`ref 参考图 → prompts\*_draft_cn.md 中文稿 → prompts\*.txt 英文提示词 → outputs 出图`。
用文件名前缀做关联（如 `funbox44` ↔ `funbox44_ref.png` / `funbox44_draft_cn.md` / `funbox44_main.txt` / `funbox44_*.png`）。

| 观察到的状态 | 判定 | 含义 |
|---|---|---|
| 有 ref，无中文稿 | **待开工** | 新单只上传了参考图就没往下走 |
| 有中文稿 + 提示词，出图缺 | **未完成** | 中途中断，或按"先出主图再批量"惯例只出了 1 张 |
| 有 4 张出图 | **已完成** | 再核对 `library.md` 里是否已入库 |
| 有 ref，且其时间晚于所有 prompts/outputs | 最新一单 | 优先向用户确认是否开单 |

```powershell
$wb = "<WB>"
$prefixes = Get-ChildItem (Join-Path $wb "ref") -File | ForEach-Object { ($_.Name -replace '_(ref|.*)$','') } | Sort-Object -Unique
foreach ($p in $prefixes) {
  $cn = @(Get-ChildItem (Join-Path $wb "prompts") -File -ErrorAction SilentlyContinue | Where-Object Name -like "$p*")
  $im = @(Get-ChildItem (Join-Path $wb "outputs") -File -ErrorAction SilentlyContinue | Where-Object Name -like "$p*")
  "{0,-12} prompts={1,2}  outputs={2,2}" -f $p, $cn.Count, $im.Count
}
```

### 步骤 3 · 命名规范一致性

读 `<WB>\feedback.md` 最新命名条款（当前规则：交付图必须为 `*月*日第*个任务的<主图/宣传图1/宣传图2/实际使用图>.png`）。
统计 `outputs\` 中符合新规的文件数与旧英文 slug 数 → 报告新旧混存比例。

```powershell
$o = Join-Path "<WB>" "outputs"
$new = @(Get-ChildItem $o -File | Where-Object Name -match '月.*任务')
$old = @(Get-ChildItem $o -File | Where-Object Name -notmatch '月.*任务')
$ver = @(Get-ChildItem $o -File | Where-Object Name -match '_v\d')
"new-naming=$($new.Count)  old-slug=$($old.Count)  versioned-copies=$($ver.Count)"
```

### 步骤 4 · 记忆连续性

比对 `.workbuddy\memory\` 内日志日期集合 vs 全库文件 mtime 的日期集合。
**有文件改动但无当日日志 = 记忆断档**，是最高价值发现之一（跨会话会丢上下文）。

```powershell
$wb = "<WB>"
Get-ChildItem (Join-Path $wb ".workbuddy\memory") -File | Select-Object Name, LastWriteTime
Get-ChildItem $wb -Recurse -File |
  Where-Object { $_.FullName -notmatch '\\\.git\\' -and $_.LastWriteTime -gt (Get-Date).AddDays(-3) } |
  Sort-Object LastWriteTime | Select-Object LastWriteTime, FullName
```

### 步骤 5 · 规则库与外部同步积压

- `feedback.md` / `library.md` 的 mtime 是否与最近一单同步更新（异常单没沉淀规则 = 下次必再犯）。
- 若工作区有云盘镜像目录（如项目盘 `docs/`），比对同步时间 → 报告积压天数。同步动作本身**需用户确认**。
- 若工作区由本 kit 安装：`rules/` 是 `update.ps1` 复制同步的，检查仓库 commit 时间 vs 工作区规则文件时间，判断同事端是否落后。

### 步骤 6 · 风险项扫描

逐项检查并如实报告，不粉饰：

- 无 `.git` → 规则库与产物裸奔，误删不可恢复
- 废弃版（`*_v1..vN`、未授权版、弃用风格）与通过版混放同一目录
- `scripts\` 内存在硬编码绝对路径 + 单一任务名的一次性脚本（无复用价值，属技术债）
- 环境文档与实际运行方式不一致（如仍写沙箱恢复流程，实际已常驻本机）
- `config\api.json` 之外的文件里出现 key（安全风险）

## 输出格式（固定三段，缺一不可）

1. **资产盘点表** — 表格：位置 / 内容 / 规模。
2. **问题清单（按优先级编号）** — 每条含「现象 + 证据（文件路径/时间戳）+ 影响」。未完成订单排第一。
3. **建议下一步** — 每条都是可执行动作，涉及删改/同步/生成的必须标注「需你确认」。

末尾给一行总判断（工作区健康度一句话）。

**可视化为可选加分项**：结构复杂时用一张 SVG 图呈现「资源资产 / 标准流程 / 当前状态」三层，文字结论仍走正文。

## 常见误判

| 误判 | 纠正 |
|---|---|
| 看 `outputs\` 文件数多就认为推进正常 | 必须核对最后一张的 mtime 与最新 ref 的先后关系 |
| 有同名文件就当这一单做完了 | 核对是 1 张还是 4 张；主角单常按「先主图、后批量」分段做 |
| 靠文件名猜哪张是通过版 | 以 `library.md` 记录为准；`_vN` 高编号 ≠ 通过版 |
| 只做结构盘点就下结论 | 订单链路 + 记忆断档才是体检的价值来源 |
| 体检过程中顺手清理旧文件 | **禁止**。巡检只读；任何移动/删除先列清单再要确认 |
| 把技能目录联接当成复制品去"修" | Junction 是正常安装形态，不要动 |

## Red Flags

- 输出里出现 key、token 等真实凭据
- 未核对四段链路就宣称"没有未完成任务"
- 在用户未确认的情况下移动 / 重命名 / 删除 `outputs\` 与 `ref\` 内文件
- 用中文文件名（含括号空格）直接进命令行前未加引号或先改纯英文名
- 报告只写"一切正常"——默认预期是**能查出问题**，查不出要说明为什么
- 把"命令没报错"当作"出图成功"（必须核对文件存在 + 时间戳 + 分辨率）

## 设计约定

- 本技能**只读**：不调用生图脚本、不消耗积分、不改动业务文件。
- 中文文件名 `9月10日第1个任务的主图.png` 是合法产物，不要当成乱码。
- 规则一致性以 `<WB>\feedback.md` 最新条款为准，**不在本技能内复制规则全文**，避免与规则库产生第二份真相。
- 体检结束后，若用户同意补记日志，再写 `<WB>\.workbuddy\memory\YYYY-MM-DD.md`（追加，不覆盖）。

## 安全说明

本技能不含脚本文件、不联网、不读取凭据实值（配置查看强制脱敏），全部动作为本机只读查询。
