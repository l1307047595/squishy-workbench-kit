#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
捏捏提示词工作台 · 中转站生图脚本（Hermes 优化版）

用法:
    python scripts/generate.py --check                          # 零消耗探活（配置+网络，不出图不扣费）
    python scripts/generate.py --prompt-file prompts/x.txt --ref ref/x.png --name x_main
    python scripts/generate.py --prompt "英文提示词 //" --outdir outputs --name demo --size 1024x1024

相对原版（Freebuff/WorkBuddy 版）的优化:
    1. --prompt-file：长提示词从文件读取，绕开 PowerShell 引号/括号/换行转义大坑
    2. --check：不产生任何图像请求的探活模式（验证配置完整性 + 网络可达性）
    3. 429/502 内置重试：429 image_queue_full 按实测规律等 60s，502 等 8s（--retries 可调）
    4. 出图后自动核对：文件存在 + 字节数 + 真实分辨率（PIL），终结"命令没报错≠出图成功"
    5. edits 输出与底图同名导致 Errno 22 的坑：目标已存在时自动 _vN 递增，绝不覆盖底图
    6. 模型锁定：config.model_locked=true 时拒绝切换任何 -1k/-2k/-4k 变体（用户明令）
    7. --outdir 默认 outputs/（工作区内，交付卡片可直接引用；原版默认 Downloads 在工作区外）
    8. stdout 强制 UTF-8，Windows 控制台中文输出不再乱码

约定:
    - 提示词全英文，`//` 结尾（脚本会检查并警告）
    - --ref 可重复传多张参考图（本地路径或 http(s) URL）
    - api_key 只存 config/api.json，不进命令行、不出现在任何输出里
"""

import argparse
import base64
import json
import mimetypes
import sys
import time
from pathlib import Path

try:
    import requests
except ImportError:
    sys.exit("缺少 requests，请先 pip install requests")

try:
    from PIL import Image
    HAS_PIL = True
except ImportError:
    HAS_PIL = False

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_CONFIG = ROOT / "config" / "api.json"


def setup_utf8_stdout():
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            pass


def load_config(path: Path) -> dict:
    if not path.exists():
        sys.exit(f"[配置错误] 文件不存在: {path}")
    try:
        # utf-8-sig：兼容 PowerShell Set-Content -Encoding UTF8 写入的 BOM
        cfg = json.loads(path.read_text(encoding="utf-8-sig"))
    except json.JSONDecodeError as e:
        sys.exit(f"[配置错误] api.json 不是合法 JSON: {e}")
    for key in ("base_url", "api_key", "model"):
        if not cfg.get(key):
            sys.exit(f"[配置错误] 缺少字段: {key}")
    return cfg


def do_check(cfg: dict) -> int:
    """零消耗探活：不发起图像请求，只验证配置 + 网络可达 + key 格式。"""
    base = cfg["base_url"].rstrip("/")
    print(f"[check] base_url      = {base}")
    print(f"[check] model         = {cfg['model']} (locked={cfg.get('model_locked', False)})")
    print(f"[check] api_key       = ****{cfg['api_key'][-4:]} (len={len(cfg['api_key'])})")
    print(f"[check] default_size  = {cfg.get('default_size', '1024x1024')}")
    print(f"[check] timeout       = {cfg.get('timeout', 300)}s")
    # 轻量 GET /models：测连通 + 验 key（不产生图像请求，不计费）
    try:
        r = requests.get(base + "/models", timeout=15,
                         headers={"Authorization": f"Bearer {cfg['api_key']}"})
        print(f"[check] GET /models     = HTTP {r.status_code}")
    except requests.RequestException as e:
        print(f"[check] 网络不可达: {e}")
        return 1
    missing = [d for d in ("scripts", "config", "ref", "outputs", "prompts") if not (ROOT / d).exists()]
    print(f"[check] 目录结构        = {'完整' if not missing else '缺: ' + ', '.join(missing)}")
    if r.status_code != 200:
        print(f"[check] FAILED —— key/base_url 未被接受（HTTP {r.status_code}），先修 config")
        return 1
    if missing:
        print("[check] FAILED —— 目录缺项")
        return 1
    print("[check] OK —— 可以接单")
    return 0


def ensure_in_ws(p: Path, what: str) -> Path:
    """兵部#1/#2：读写路径收敛到工作区内（防提示注入诱导越界写启动目录/读敏感文件外传）。"""
    rp = p.resolve()
    if rp != ROOT and ROOT not in rp.parents:
        sys.exit(f"[拒绝] {what} 必须位于工作区内: {p}")
    return rp


def assert_public_url(u: str, what: str):
    """兵部#3/#4：本机拒抓回环/内网/元数据地址（防 --ref SSRF 与中转站响应 URL 二次 SSRF）。"""
    import ipaddress
    import socket
    from urllib.parse import urlparse
    host = urlparse(u).hostname or ""
    try:
        addrs = [i[4][0] for i in socket.getaddrinfo(host, None)]
    except socket.gaierror:
        sys.exit(f"[拒绝] {what} 主机解析失败: {host}")
    for a in addrs:
        if not ipaddress.ip_address(a).is_global:
            sys.exit(f"[拒绝] {what} 指向非公网地址: {host} ({a})")


def to_data_url(ref: str) -> str:
    if ref.startswith(("http://", "https://", "data:")):
        if ref.startswith("data:"):
            return ref
        assert_public_url(ref, "--ref URL")
        r = requests.get(ref, timeout=60)
        r.raise_for_status()
        mime = r.headers.get("Content-Type", "image/png").split(";")[0].strip()
        return "data:{};base64,{}".format(mime, base64.b64encode(r.content).decode())
    p = Path(ref)
    if not p.exists():
        sys.exit(f"[参数错误] 参考图不存在: {ref}")
    p = ensure_in_ws(p, "参考图")
    mime = mimetypes.guess_type(p.name)[0] or "image/png"
    return "data:{};base64,{}".format(mime, base64.b64encode(p.read_bytes()).decode())


def unique_target(outdir: Path, name: str, suffix: str, ext: str) -> Path:
    """目标文件已存在时自动 _v2/_v3... 递增，避免 edits 同名写入 Errno 22 与覆盖底图。"""
    out = outdir / f"{name}{suffix}.{ext}"
    v = 1
    while out.exists():
        v += 1
        out = outdir / f"{name}{suffix}_v{v}.{ext}"
    return out


def save_image(item: dict, outdir: Path, name: str, idx: int, total: int) -> Path:
    outdir.mkdir(parents=True, exist_ok=True)
    suffix = "" if total == 1 else f"-{idx + 1}"
    if item.get("b64_json"):
        raw = base64.b64decode(item["b64_json"])
        ext = "png"
        if raw[:3] == b"\xff\xd8\xff":
            ext = "jpg"
        elif raw[:4] == b"RIFF" and raw[8:12] == b"WEBP":
            ext = "webp"
        out = unique_target(outdir, name, suffix, ext)
        out.write_bytes(raw)
        return out
    if item.get("url"):
        assert_public_url(item["url"], "响应图片 URL")  # 兵部#4：不信任中转站响应里的地址
        r = requests.get(item["url"], timeout=120)
        r.raise_for_status()
        ctype = r.headers.get("Content-Type", "")
        ext = "jpg" if ("jpeg" in ctype or "jpg" in ctype) else ("webp" if "webp" in ctype else "png")
        out = unique_target(outdir, name, suffix, ext)
        out.write_bytes(r.content)
        return out
    raise RuntimeError("响应中既无 b64_json 也无 url: " + json.dumps(item)[:300])


def verify_output(p: Path, expect_size: str):
    """P4/F15 规则的程序化落实：文件存在 + 字节数 + 真实分辨率。"""
    if not p.exists():
        print(f"[核验失败] 文件不存在: {p}")
        return False
    size_kb = p.stat().st_size / 1024
    line = f"[核验] {p.name}  {size_kb:.0f}KB"
    ok = size_kb > 50  # 小于 50KB 基本是坏图
    if not ok:
        line += "  ⚠ 文件过小疑似坏图"
    if HAS_PIL:
        try:
            with Image.open(p) as im:
                w, h = im.size
            line += f"  分辨率 {w}x{h}"
            if expect_size and "x" in expect_size:
                try:
                    ew, eh = (int(x) for x in expect_size.lower().split("x"))
                    ar_req = ew / eh
                    ar_act = w / h
                    if abs(ar_act - ar_req) / ar_req > 0.08:
                        line += f"  ⚠ 宽高比偏离请求({expect_size})"
                        ok = False  # F15：中转站会静默忽略非方尺寸，此检查必须影响退出码
                except ValueError:
                    pass
        except Exception as e:
            line += f"  ⚠ 无法读取分辨率: {e}"
            ok = False
    print(line)
    return ok


def build_request(args, cfg):
    base_url = cfg["base_url"].rstrip("/")
    model = args.model or cfg["model"]
    size = args.size or cfg.get("default_size", "1024x1024")
    quality = args.quality or cfg.get("default_quality")
    headers = {"Authorization": f"Bearer {cfg['api_key']}"}

    if args.ref and args.endpoint == "edits":
        files = []
        for r in args.ref:  # 刑部#7：统一走存在性检查+工作区收敛，不抛裸 traceback
            p = Path(r)
            if not p.exists():
                sys.exit(f"[参数错误] 参考图不存在: {r}")
            p = ensure_in_ws(p, "参考图")
            key = "image" if len(args.ref) == 1 else "image[]"
            files.append((key, (p.name, p.read_bytes(), mimetypes.guess_type(p.name)[0] or "image/png")))
        data = {"model": model, "prompt": args.prompt_text, "n": str(args.n), "size": size}
        if quality:
            data["quality"] = quality
        return f"{base_url}/images/edits", headers, {"files": files, "data": data}, size

    payload = {"model": model, "prompt": args.prompt_text, "n": args.n, "size": size}
    if quality:
        payload["quality"] = quality
    if args.ref:
        payload["image"] = [to_data_url(r) for r in args.ref] if len(args.ref) > 1 else to_data_url(args.ref[0])
    return f"{base_url}/images/{args.endpoint}", {**headers, "Content-Type": "application/json"}, {"json": payload}, size


def main():
    setup_utf8_stdout()
    ap = argparse.ArgumentParser(description="中转站生图（OpenAI 兼容端点，Hermes 优化版）")
    src = ap.add_mutually_exclusive_group()
    src.add_argument("--prompt", help="英文提示词文本，// 结尾（短提示词用）")
    src.add_argument("--prompt-file", help="从 UTF-8 文件读取提示词（推荐，绕开 PowerShell 转义）")
    ap.add_argument("--outdir", default=str(ROOT / "outputs"), help="输出目录，默认工作区 outputs/")
    ap.add_argument("--name", default="image", help="文件名前缀（英文简称，无空格无括号）")
    ap.add_argument("--ref", action="append", default=[], help="参考图路径或 URL，可重复")
    ap.add_argument("--model", default=None, help="覆盖配置模型（model_locked=true 时禁止）")
    ap.add_argument("--size", default=None, help="尺寸，如 1024x1024 / 1536x1024")
    ap.add_argument("--quality", default=None, help="low / medium / high / auto")
    ap.add_argument("--n", type=int, default=1, help="生成张数，默认 1")
    ap.add_argument("--endpoint", default="generations", choices=["generations", "edits"])
    ap.add_argument("--config", default=str(DEFAULT_CONFIG))
    ap.add_argument("--retries", type=int, default=2, help="429/502 自动重试次数，默认 2；0 关闭")
    ap.add_argument("--retry-429-wait", type=int, default=60, help="429 重试等待秒数，实测 60s 有效")
    ap.add_argument("--retry-502-wait", type=int, default=8, help="502 重试等待秒数")
    ap.add_argument("--check", action="store_true", help="零消耗探活后退出（不发起图像请求）")
    ap.add_argument("--dry-run", action="store_true", help="只打印将要发送的请求概要，不实际提交")
    args = ap.parse_args()

    cfg = load_config(Path(args.config))
    if args.check:
        sys.exit(do_check(cfg))

    # 提示词来源
    if args.prompt_file:
        pf = Path(args.prompt_file)
        if not pf.exists():
            pf = ROOT / args.prompt_file
        if not pf.exists():
            sys.exit(f"[参数错误] 提示词文件不存在: {args.prompt_file}")
        args.prompt_text = pf.read_text(encoding="utf-8-sig").strip()  # 刑部#5：防 BOM 混入触发非ASCII误报
    elif args.prompt:
        args.prompt_text = args.prompt
    else:
        sys.exit("[参数错误] 必须提供 --prompt 或 --prompt-file（或 --check）")

    # 规则前置检查（只警告不阻断）
    if not args.prompt_text.rstrip().endswith("//"):
        print("[警告] 提示词未以 // 结尾（identity 规范）")
    if any(ord(c) > 127 for c in args.prompt_text):
        print("[警告] 提示词含非 ASCII 字符，规范要求全英文")
    # 禁词表 = identity.md 第七节全集（子串匹配：squish 一词覆盖 squishy/squishies/squishmallows/SQUISH 变体）
    banned = ["squish", "pop mart", "blind box", "mystery box", "mystery",
              "baby", "infant", "toddler", "1-4 years", "early education",
              "儿童", "孩童"]
    hits = [b for b in banned if b in args.prompt_text.lower()]
    if hits:
        print(f"[警告] 提示词含禁用词: {hits} —— 交付前必改（终审清单第七节；F3/F8 已因 SQUISH 变体复发 2 次）")
    # 模型锁定（用户明令：仅 gpt-image-2，禁一切变体）
    if args.model and cfg.get("model_locked") and args.model != cfg["model"]:
        sys.exit(f"[拒绝] 用户明令仅允许 {cfg['model']}，禁止切换变体（收到的 --model={args.model}）")
    # 文件名安全检查（P4 教训：括号/空格炸命令行；兵部#1：禁路径穿越字符）
    if any(c in args.name for c in ' ()[]<>|&;/\\*"?,') or ".." in args.name:
        sys.exit(f"[参数错误] --name 只允许字母/数字/下划线/连字符: {args.name!r}")

    url, headers, body_kw, size = build_request(args, cfg)
    mode = "edits-multipart" if args.ref and args.endpoint == "edits" else "json"
    print(f"[请求] {url}  [模式] {mode}")
    print(f"[模型] {cfg['model'] if not args.model else args.model}  [尺寸] {size}  [张数] {args.n}  [参考图] {len(args.ref)}")
    print(f"[提示词] {args.prompt_text[:120].replace(chr(10), ' ')} ...（共 {len(args.prompt_text)} 字符）")
    if args.dry_run:
        print("[dry-run] 未发送。")
        return

    timeout = int(cfg.get("timeout", 300))
    attempt = 0
    t0 = time.time()
    while True:
        # 刑部#8：send() 包装器内联（-4 行）；刑部#4：超时≠未送达，读超时不自动重发防二次扣费
        resp = None
        try:
            resp = requests.post(url, headers=headers, timeout=timeout, **body_kw)
        except requests.exceptions.ReadTimeout:
            sys.exit(f"[失败] 读超时（{timeout}s）—— 请求可能已入队计费，不自动重发；\n"
                     f"先到中转站控制台核对有无幽灵任务，再人工决定是否重试。")
        except requests.ConnectionError as e:
            print(f"[网络错误] 请求未送达，可安全重发: {e}")
        except requests.RequestException as e:
            sys.exit(f"[失败] 请求异常: {e}")
        if resp is not None and resp.status_code == 200:
            break
        code = resp.status_code if resp is not None else 0
        body = (resp.text[:300] if resp is not None else "")
        retryable = (code in (429, 502)) or (resp is None)
        attempt += 1
        if not retryable or attempt > args.retries:
            sys.exit(f"[失败] HTTP {code}\n{body}")
        wait = args.retry_429_wait if code == 429 else args.retry_502_wait
        print(f"[重试 {attempt}/{args.retries}] HTTP {code} —— {wait}s 后重试（勿连环轰炸）")
        time.sleep(wait)

    try:
        data = resp.json()
    except ValueError:
        sys.exit("[失败] 响应不是 JSON: " + resp.text[:500])

    items = data.get("data") or []
    if not items:
        sys.exit("[失败] 响应无 data 字段: " + json.dumps(data, ensure_ascii=False)[:500])

    outdir = Path(args.outdir)
    if not outdir.is_absolute():
        outdir = ROOT / outdir
    outdir = ensure_in_ws(outdir, "--outdir")  # 兵部#1：产物只能写进工作区

    saved, all_ok = [], True
    for i, item in enumerate(items):
        if "b64_json" not in item and "url" not in item:
            if item.get("revised_prompt"):
                print("[提示] 仅有 revised_prompt:", item["revised_prompt"][:200])
            continue
        p = save_image(item, outdir, args.name, i, len(items))
        saved.append(p)
        all_ok = verify_output(p, size) and all_ok

    if not saved:
        sys.exit("[失败] 未取得任何图片: " + json.dumps(data, ensure_ascii=False)[:600])

    print(f"[完成] 共 {len(saved)} 张，用时 {time.time() - t0:.1f}s（含重试等待）")
    for p in saved:
        print(f"[保存] {p}")
    sys.exit(0 if all_ok else 3)


if __name__ == "__main__":
    main()
