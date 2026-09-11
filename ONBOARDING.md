# 同事安装指南（10 分钟一次性）

捏捏提示词工作台分发包。装完之后：**技能自动跟着仓库更新，你自己的订单/参考图/记忆永远不被覆盖。**

---

## 0. 前置条件

| 项 | 要求 |
|---|---|
| 系统 | Windows 10/11 |
| 权限 | 能给 GitHub 仓库授权；注册计划任务需要**管理员**（可选） |
| 软件 | Git、Python 3.13（`python --version` 能跑通） |
| WorkBuddy | 已安装并登录 |
| 仓库权限 | **必须先被加为 Collaborator**（仓库是私有的）——把 GitHub 用户名发给老大添加 |

---

## 1. 拿到仓库权限

把 **GitHub 用户名**发给仓库所有者，被加为 `l1307047595/squishy-workbench-kit` 的 **Collaborator**（Write 权限即可）。

> 没加之前 `git clone` 会直接 404，这是权限问题不是仓库不存在。

---

## 2. 克隆仓库

```powershell
git clone https://github.com/l1307047595/squishy-workbench-kit.git D:\skills-repo
cd D:\skills-repo
```

首次克隆会弹浏览器授权，登录自己的 GitHub 账号点同意即可（一次性，之后免密）。

---

## 3. 一键安装

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

默认把你的工作区建在 `D:\squishy-workbench`。想换盘/换目录：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -WorkbenchDir "E:\my-workbench" -ScheduleMinutes 15
```

`-ScheduleMinutes 0` = 不注册自动更新计划任务（需管理员权限才能注册成功）。

### install.ps1 干了些啥

1. 建工作区目录树：`ref/ prompts/ outputs/ config/ scripts/ memory/`
2. 把 `rules/*.md`、`scripts/*.py`、`AGENTS.md`、`STATE.md`（模板播种）复制进工作区
3. 生成 `config\api.json`（模板形态，**key 是空的，要自己填**）
4. 在 `%USERPROFILE%\.workbuddy\skills\` 下建**目录联接**指向仓库的 `skills\*`
   → 这一步是「实时更新」的关键：`git pull` 一拉，技能当场生效，**不用重装**
5. 写 `%USERPROFILE%\.workbuddy\squishy-workbench.json`（本机路径映射，技能靠它找到你的工作区）
6. 可选：注册计划任务，每 N 分钟自动 `git pull` + 同步规则

> 如果本机 `skills\` 下已有**同名真实文件夹**，install 会先把它改名成 `xxx.bak-时间戳` 再建联接，不会删你东西。

---

## 4. 填自己的 API key（必须）

编辑工作区里的 `config\api.json`，把 `api_key` 换成**你自己的**：

```json
{
  "base_url": "https://direct-api.cangyuansuanli.cn/v1",
  "api_key": "sk-你的key",
  "model": "gpt-image-2",
  "model_locked": true
}
```

> key 不进 git、不外传。每人自备。

---

## 5. 零成本自检

```powershell
cd D:\squishy-workbench
python scripts\generate.py --check
```

返回探活成功即链路通（`--check` 不产生任何扣费）。

---

## 6. 让 WorkBuddy 认到技能

**首次安装后重启一次 WorkBuddy**（让它刷新技能列表）。之后更新不需要重启。

验证：随便说一句「写捏捏生图提示词」或「体检一下工作区」，能触发技能即成功。

---

## 7. 日常更新（两种方式）

**手动（推荐，可控）**

```powershell
cd D:\skills-repo
git pull
powershell -NoProfile -ExecutionPolicy Bypass -File .\update.ps1
```

**自动**：第 3 步带了 `-ScheduleMinutes` 且注册成功的话，后台每 N 分钟自动跑一次，什么都不用管。

### update.ps1 会动什么 / 不会动什么

| 会同步（共享） | **绝不触碰（你自己的）** |
|---|---|
| `rules/*.md`（identity/feedback/library） | `memory/`（你的日志） |
| `scripts/*.py` | `STATE.md`（你的订单状态板） |
| `AGENTS.md` | `ref/` `prompts/` `outputs/`（你的素材与成品） |
| | `config/api.json`（你的 key） |

- 覆盖共享文件前会做 SHA256 比对：**你本地改过** → 先备份到
  `%USERPROFILE%\.workbuddy\squishy-workbench-local-backup\<时间戳>\`，再覆盖。
- `git pull` 失败（断网/无远端）只**警告不中断**，用本地仓库内容继续同步。

---

## 常见问题

| 现象 | 原因 / 处理 |
|---|---|
| `git clone` 404 | 还没被加 Collaborator，或账号不对 |
| install 报 `no skill folders` | 克隆不完整，重新 clone |
| 技能不触发 | 重启一次 WorkBuddy；确认 `%USERPROFILE%\.workbuddy\skills\<技能名>` 是**联接**（`Get-Item` 看 `LinkType=Junction`） |
| 生图报 401/无 key | 忘了第 4 步，填 `config\api.json` |
| `update.ps1` 里 `git pull` 失败 | 无妨，会继续同步本地仓库内容；查网络或凭证 |
| 计划任务注册失败 | 没用管理员跑；改用手动更新，或管理员权限重跑 install |
| 规则文件被覆盖了 | 说明你没改过它；如果你改过，先去 `squishy-workbench-local-backup\` 找备份 |
