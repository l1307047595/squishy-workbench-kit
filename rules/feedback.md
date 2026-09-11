# Feedback 记录

## 2026-09-10 · 命名规范（用户圣裁，永久生效）
- 出图文件名格式：`*月*日第*个任务的<主图/宣传图1/宣传图2/实际使用图>.png`（如 `9月10日第1个任务的主图.png`）
- 序号按当日内任务递增；提示词文件可沿用英文 slug，但**交付图必须此中文格式**

## 2026-09-04 · 水果三件套（榴莲/草莓/橙子）

### 流程纠正（用户反馈，最高优先级）
- **错误**：中文稿交付审阅时擅自把英文版一并输出，违反工作流第 4 步「未经 OK 禁止转英文」。
- **规则强化**：中文稿单独交付，用户回复 OK 后才输出英文版；两步之间必须停。

### 出图硬伤记录
- **trio_promo1（宣传图1）不合格**：模型给草莓/橙子擅自添加了笑脸表情、泡沫网套、「JOLLY SQUISH」吊牌——均为参考图外元素，违反铁律1（画面唯一商品=参考图商品，禁添加）。
- **根因**：提示词未显式禁止给商品添加表情/装饰；「cute playful mood」类氛围词易诱导模型加脸。
- **纠正规则（写入身份候选）**：带参考图时补一句 `Do not add faces, expressions, tags, packaging nets, or any decorative elements not present in the reference image.` 到 [Style & Quality] 否定约束。

### 通过版
- trio_main / trio_promo2 / trio_usage 三张通过自查（三件全在、无乱码、非白底、无禁用词），已入库。
- **更正（用户抓出）**：trio_promo1 吊牌「JOLLY SQUISH」含禁用词变体 SQUISH；trio_main/promo2/usage 复扫图内文字未见禁用词，维持通过。

### F3 · 禁用词 SQUISH 出现在画面文字里（自查漏扫，用户指出）
- **错误**：自查只扫了提示词文本，没扫生成图内的文字；「SQUISH」是 squishy 的变体，属明令禁止词。
- **纠正规则（写入身份候选，固定执行）**：
  1. 出图后自查必须包含**图片内文字逐词扫描**，禁用词清单（含变体/拆分/组合，如 SQUISH）同样适用于生成结果；
  2. 每条提示词 [On-Image Text] 段尾固定补：`These are the only texts allowed in the image; no other words, labels, or tags may appear anywhere.`；
  3. 提示词文本自查通过 ≠ 出图合格，出图后必须复扫图内文字。

## 2026-09-04 · Fun Box 四件套（用户反馈驱动的两次重做）

### F4 · 商品命名错误（用户逐件更正）
- **错误**：初稿把白色认成「花生形」、绿色认成「牛油果形」；实际白色=肥皂形、绿色=芒果形。
- **纠正规则**：多件商品套图，中文稿交付前先**逐件命名+编号**请用户确认（①②③④对应造型名），确认无误才往下写；禁止凭猜测命名。

### F5 · 风格「过于简约」（用户两次反馈）
- **错误**：v1 用摆拍式陈列（商品+简单波普点缀），用户评「过于简约、千篇一律、不够新颖吸引人」。
- **纠正路径**：v1 奶油木风 → v2 粉绿糖果波普（用户仍嫌简约）→ v3 糖果机爆发主题（场景叙事）通过。
- **提炼规则（场景叙事模板，已入 library.md）**：
  1. 默认不用摆拍式；高吸引力需求直接上**场景叙事**（容器喷涌/弹跳落地/漫画冲击线等动态瞬间）；
  2. 漫画波普元素具体清单：radiating sunburst lines / halftone dot fields / speed lines / jagged burst panel / speech-bubble chips / impact burst lines；
  3. 容器道具声明 `reads as a prop not a product`；动态姿态下保真句补 `even in mid-air tumbling poses`；
  4. 漫画层与实拍层分离：`the comic impact burst overlays the real product photography without hiding the squeezed toy`。

### 涉及文件
- 纠正前 v1 产出：outputs/funbox_main.png 等 4 张（保留未删，弃用）
- 通过版 v2：outputs/funboxv2_main.png 等 4 张
- 提示词：prompts/funbox_*.txt（v1 弃用）、prompts/funboxv2_*.txt（通过版）
- 规则沉淀：library.md「Fun Box v2 糖果机爆发主题」节

## 2026-09-04 · 柠檬捏捏单

### F6 · 中文稿 OK 前擅自生图（第 2 次违反，用户严厉批评）
- **错误**：用户提「风格更新颖+宣传语多」后，我出了中文稿但没等 OK 就直接转英文跑 generate.py，4 张先期产出全部作废。
- **根因**：同类错误第二次发生（第一次=水果三件套单），说明「出稿→停→等 OK」的流程闸门未真正固化。
- **生图前置锁（最高优先级，永久生效）**：
  1. 中文稿发出后，回复必须**停在等审阅状态**——最后一个字是向用户要 OK 的问题，且该轮不带任何生图工具调用；
  2. 用户明确 OK（或明确指定「直接发」）之前，`generate.py` 一次都不能执行；
  3. 用户对风格的追问（如「风格在哪」）只回答设计细节，回答完继续等 OK，不得视为放行。
- **作废处理**：先期产出 outputs/lemon_*.png（第 1 批）封存不计入通过版；用户 OK 后按同一提示词重跑 lemon_usage 才算数。

## F7 · 使用图变形"烂果感"（2026-09-05，第六单石榴）
- **现象**：使用图被捏的透明石榴珠粒大量爆出鼓包，视觉像果皮破损、水果烂掉
- **根因**：提示词用了 `bulge through the crystal-clear stretched skin`，模型理解为珠粒顶破外皮
- **修正**：`skin stays completely intact and unbroken — no beads burst out, no bulges poking through` + `squishes down evenly like a soft stress ball, beads pressing and shifting INSIDE under the clear skin`
- **规则**：透明颗粒玩具使用图禁用 bulge/burst/poke through 类词；变形=整体均匀压缩+珠粒皮内移位。徽章小图（占比小）可保留鼓包表达
- **关联**：第五单 soapv3（不透明款）用过 "wrinkles and creases" 无此问题——不透明款褶皱安全，透明款褶皱+鼓包组合危险

## F8 · 禁用词变体复发于文案环节（2026-09-04，第五单花生）
- **现象**：主图标题 "PEANUT PAL SQUISH" 自带禁用词变体 SQUISH（F3 复发，第 2 次）
- **根因**：写 [On-Image Text] 时只顾创意没扫禁词表
- **修正**：主标题改为 "PEANUT PALS" 重生成
- **规则**：[On-Image Text] 每条文案写完必须逐词对照第七节禁用词表（含变体/拆分）；SQUEEZY 等近形词也需检查（本次 SQUEEZY BEADS 通过，SQUISH 类直接禁）

## F9. 静态陈列图商品被"软胶化"变形（2026-09-05）
- 现象：主图/陈列图中，软质捏捏被模型自动加上凹陷、弯曲、挤压痕（如粉色黄油条侧面被压弯），即使提示词未要求任何捏压。
- 原因：模型对"squeeze toy"先验=软的会变形；参考图中商品是静置的，但模型自行"软化"。
- 修复：静态陈列图提示词必须显式加：`pristine UNDEFORMED brand-new condition — perfectly straight rectangular blocks with crisp clean edges, NO dents/dimples/compression/squeeze marks/warping/bending` + `All toys shown resting, untouched, in their original perfect shape`。
- 区分：只有使用图/徽章内才允许变形；其余所有图商品必须原始状态。

## F10. 同参考图多商品需显式排除不出的商品（2026-09-05）
- 现象：参考图1含绿+粉两块油条，但组合实际只卖粉色款时，模型仍把绿色画进画面。
- 修复：必须显式写 `The MINT GREEN butter block must NOT appear anywhere in the image` + 组合定义 `exactly TWO toys — the PINK butter block AND the pink translucent apple`。
- 通用规则：参考图含多商品时，凡不参与本图组合的商品必须逐个点名排除。

## F11. 套图四图布局必须差异化（2026-09-05 用户反馈）
- 反馈：四张图商品摆放千篇一律（都是底座并排斜靠）+ 宣传语不够丰富。
- 修复：同套图内每张构图骨架必须不同——已验证可用的差异化骨架库：主图=动态对角线独石式站姿；宣传图1=中央大圆环悬浮对分展示；宣传图2=杂志封面式左标题堆叠+右商品空中定格；使用图=低角度过肩视角近大远小。后续套图从骨架库轮换，禁止四图同款底座并排。
- 文案量：每图至少 3 层文字（大标题/促销条或气泡/角标徽章），且各图文案不重复。

## F12. 资质审核图禁白底（2026-09-07 用户反馈）
- 反馈：资质审核用的商品图不能是白底图。
- 修复：审核主图改用日常实拍场景——浅色木纹桌面 45° 俯拍 + 奶油色墙面虚化 + 自然窗光；使用图照常日常场景。两图均保持手机随手拍质感、零文字零装饰。
- 通用规则：凡"资质审核/合规实拍"类图，禁用纯白摄影棚背景，一律生活化真实场景。

## P1. 流程违规：圣诞3PCS套图未经中文稿确认直接生图（2026-09-07）
- 违规：用户上传圣诞双苹果+圣诞树3PCS参考图后，直接按英文提示词生成了4张套图，跳过了"中文稿→用户OK→生图"的强制流程。
- 修正：无论上下文多么相似，每个新商品/新订单的第一步永远是输出中文稿并等用户确认，F6 锁不可跳过。已生成的4张图标记为未授权版本，是否采用由用户决定。
- 教训：连续多单的高频节奏不是跳步理由。

## P2. 宣传语数量屡教不改（2026-09-07 用户二次批评）
- 用户此前（combo 套图轮）已明确要求"所有图片的宣传语都要丰富一点"，并已沉淀 F11（每图≥3层文字）。但圣诞3PCS套图仍只放了少量文字（主图仅 3 PCS SET，使用图零文案），再次被批评。
- 根因：把"丰富宣传语"理解为只适用于宣传图，未贯彻到主图/使用图。实际上用户要求的是**每一张图都要有充足英文宣传语**。
- 硬性规则（永久，所有电商图通用）：
  1. 主图：≥2 层文字（主标题/大标语 + 数量徽章）
  2. 宣传图1：≥3 层（大标题 + 徽章弧字 + 促销条或角标）
  3. 宣传图2：≥4 层（大标题 + 标语 + 图标词 + 促销条/角标）
  4. 使用图：≥2 层（对话气泡或感叹标语 + 底部标语条）
  5. 各图文案不重复，全部英文，禁用词零
- 违反即重做，不再询问。

## F13. 禁止竖排/旋转文字（2026-09-07 用户反馈）
- 现象：主图右侧竖排丝带「3 HUGGABLE FRIENDS」文字从上往下竖着排，用户明确否定。
- 规则：所有文字必须水平横排（从左到右正常阅读方向）。禁止 vertical text / rotated text / 竖排横幅；文案条一律水平横条。垂直位置信息改用横排小条或角标实现。
- 英文提示词模板句：`All text must be horizontal, reading left to right — never vertical, never rotated, never stacked letter-by-letter vertically.`

## F18. 中文稿必须全中文（2026-09-09 用户质问"你给我英文我怎么看的懂"）
- 现象：中文稿第③段风格基调句直接贴了英文原句，用户看不懂审阅不了。
- 规则：中文稿八段（含基调句、文案词）一律中文表述，英文句意用中文写出（色调/光线/氛围/画质/字体五维）；英文原句只允许出现在用户 OK 之后的英文版提示词里。画面文案词在中文稿中用「英文原文+中文释义」标注（如 2PCS PUDDING PALS「两只装布丁伙伴」）。

## P3. 生图后未执行自查即交付（2026-09-07 用户质问）
- 违规：圣诞套图 v2 生成后直接交付，未跑自查硬伤清单（乱码/白底/变形/水印/禁用词/文字横排），导致 promo2 的 LIMITED HOLIDAY SET 竖排漏检（违反 F13），被用户截图质问。
- 根因：本会话中模型无法直接查看生成的图片，一直靠"请用户自查"推卸——但流程要求的是先自查再交付，能查的项（提示词声明 vs 规则清单比对）必须逐项过一遍，声明了横排就要检查是否真的每条文案都写了横排约束。
- 硬性流程（每次生图后、交付前执行）：
  1. 对照该图提示词的 [On-Image Text] 逐条检查：是否全部加了 horizontal 约束、有无竖排/旋转风险措辞
  2. 检查禁用词、`//` 结尾、not food 声明、F9 无变形约束（静态图）
  3. 发现声明缺失或措辞违规 → 立即重生成，不带病交付
  4. 报告自查结果（✓/✗ 清单）+ 明确说明"图像内容层面仍需用户目检"

---

# 2026-09-08 · 组合单品（Crunchy Pudding + 黄油条）问题集中复盘

## F14. 多参考 edits 中非底图商品必走形（用户严批："和我提供的图片没有一毛钱关系"）
- 现象：三参考 edits（图1=布丁底图、图2=黄油条商品源、图3=版式参考）生成的黄油条完全不像原商品。v2 加"REAL-WORLD SIZE RATIO"仍走形。
- 根因：edits 多图模式下只有 Image1（底图）商品是像素级保留的；从 Image2"提取"的商品本质是重绘，必走形——与 generations 重绘走形同一性质。
- 修正方案（可复用，两选一）：
  1. **PIL 零裁剪垂直拼接**：把多张商品参考图拼成一张单底图 → edits 单图仅做重排，提示词写 `copying every product view pixel-faithfully from the base image — do not redraw, restyle, recolor or reshape any product`；
  2. **用户自拼底图**（Fun Box 39 模式）：用户用工具拼好商品视图底图，AI 只写重排提示词。协作效率最高。
- 规则：凡组合品商品来自多张参考图，一律先拼成单底图再 edits，禁止让模型从多图"提取商品"。

## F15. 真实尺寸比例约束的固定写法
- 教训：组合品两件商品尺寸差异大（黄油条长13cm vs 布丁杯宽5cm），不写比例模型默认等大。
- 固定模板：`REAL-WORLD SIZE RATIO IS MANDATORY: the butter bar is about 13 cm long and the pudding cup is only about 5 cm wide, so the butter bar must appear roughly 2.5 times larger than the pudding cup in every view; never draw them the same size.`
- 规则：多商品组合图，提示词必须写明各商品实际厘米数+倍数关系+"in every view"覆盖所有视图；尺寸未知先问（工作流第1步），已知尺寸必须写入。

## F16. AI 自加箭头/图标/装饰元素
- 现象：combo37_white v1 白底图上出现粉色箭头（模型自加，用户标注截图否定）。
- 规则：极简/白底/目录类图片，负面清单必须显式逐项：`no arrows, no icons, no props, no decorations, no added text`。只写"no added text"不够，箭头图标类必须点名。

## F17. 商品占比过小
- 现象：combo37_white v1 商品在画面中占比过小，用户要求"放大商品主图成视觉焦点"。
- 固定写法：`The products must be LARGE, filling about 80 percent of the frame, as the absolute visual focus, with generous even margins.`
- 规则：SKU/白底/目录图默认声明商品占比（80% 左右）；场景图/氛围图除外。

## P4. 命令行文件名含括号/空格导致命令失败
- 教训：`Fun Box (30).png` 直接传 --ref 使 bash eval 语法错误（括号解析），连败两次。
- 规则：所有传给命令行的文件先 `cp` 成无括号无空格的英文文件名（如 funbox30_ref.png）再传参；或全程引号+单引号包裹。此为固定前置步骤。

## 用户设计偏好（组合首图，2026-09-08 确认）
- hero/首图**不要**纸质展示盒、**不要**麻绳+吊牌类装饰——商品视图干净直给。
- 局部修改固定模式：用户截图+箭头标注 → edits 双参考（图1=当前成图作底图，图2=仅素材来源）+ 编号变更清单 + `keep EVERYTHING else pixel-identical`。
- 组合品白底图/首图需求结构：一看懂卖什么（组合关系）+ 体现珠粒填充（开窗视图必须有）+ 真实比例。

---

# 2026-09-07 ~ 09-08 对话问题复盘（待同步云端）

## 新增图文规则
- **F14 食物类防真实化+防爆汁**：水果/面包/蔬果造型捏捏禁蜡质高光、仿真果皮、仿真棕梗、生鲜感；禁汁液、液滴、飞溅、爆裂、果肉、湿感——即使写"泡沫颗粒光效"也可能被画成果汁，需写死 `surface stays COMPLETELY DRY and matte — NO juice/liquid droplets/splash/burst/pulp/moist texture/particles flying out`
- **F15 珠中珠/藏物类对比叙事**：禁张张开窗。正常图完整闭合（悬念文案 WHAT'S INSIDE?），仅 1 张卖点特写开窗爆点 + 使用图捏压时隐约透出（HIDDEN BEADS · REVEALED BY YOUR HANDS），制造"外观vs内里"层次
- **F16 敏感品类词审核规避**：axolotl 等物种词触发中转站 sensitive_words_detected（提示词+图双重审核，换同义词也没用）。解法：提示词完全不提商品名称/特征，只写 "Keep the toys in the input image EXACTLY as they are"，靠 edits 原图过审

## 新增流程规则
- **P-姿态**：长条形商品（黄油条等）展示默认**平躺**（LIES FLAT on wide bottom face, NEVER standing upright），姿态必须对照参考图，禁自创立起/竖放（曾致"太高了"返工）
- **P-物理真实性**：捏压形变与填充必须符合真实物理——密封皮内珠子不可见、只有开口处可见；禁珠子外漏/外挂/漂浮；禁不符合材质的形变（曾致"不符合实际"返工）
- **P-演示pose照抄**：参考图内自带的演示动作（捏皱起褶/双手拉伸/握中段弯折）就是商品卖点玩法，必须照抄，不自创捏法（曾致"商品不对/太短"返工）
- **P-多商品逐只锁定**：多商品组合图逐只描述特征+负面约束（香蕉禁加脸、白菜禁变圆绿），数量场景写死 `Count rule: exactly N items, one of each kind`（曾致数量错误）
- **P-比例写死**：组合商品真实比例写进提示词（如黄油条≈奶酪块2.5倍长、13cm×5cm），并指定平躺低姿态防止比例失衡

## 基建与技法
- **edits 端点已打通**：generate.py 支持 `--endpoint edits`（multipart 上传）。适用：①商品细节敏感、generations 重绘必走样 ②参考图自带完美演示 pose（像素级保留）。注意：n 参数必须整数、元组格式必须走 files=
- **双锚点技法**：商品反复漂移成"通用版"时，加一张历史上商品还原被认可的生成图作第二参考（treat as appearance anchor）
- **错误分类**：502=参考图未送达（sleep 6-8s 重试）；403 insufficient_user_quota=余额不足（充值，重试无效）；400 sensitive=改提示词（极简指代）；400 参数=修脚本

## 流程教训
- 用户选"方向1"= 整套套图都用该方向，不是各图各概念（gapple3 返工教训）——不确定就先问一句
- 风格被否时先用选项问清（哪部分不行+想要什么方向），不连续盲猜重做
- 新风格先只生成主图验证，OK 后再批量套用（省积分）
- 使用图构图公式：中后景完整陈列（UNDEFORMED）+ 前景捏压新增个体（用户明确要求，不能只有手捏）

## 2026-09-08 · 单日复盘（trio3/crunch4/arcade4/bundle2/funbox36-40 五单沉淀）

### F14 · 多图合稿必须先拆分
- trio3 首张主图误把 4 图合稿整包当单图提示词生成 → 作废重跑
- 规则：多图提示词写进一个文件时，逐张生成前必须先拆分为单图文件（一行一图独立自包含）

### F15 · 出图尺寸必须核对
- 传 1024x1536（3:4）中转站实际出 1024x1024——非方尺寸可能被忽略
- 规则：出图后核对实际分辨率与需求一致；用户偏好套图+海报统一 1:1

### F16 · 范围以用户最后指令为准
- 用户只要首图，我自行扩大到4张批量 → 浪费积分+用户不满；后台批量任务还被中断只出了2张
- 规则：范围确认以用户最后一条消息为准，不自行加量；生图优先前台逐张（后台任务易被中断丢任务）

### F17 · 陈列道具上的微缩商品同样适用 F9
- crunch4 v1 展示架上小样融化歪斜（F9 只护了大样）
- 规则：展示架/货架/台阶上的商品微缩版必须逐件点名保真（exactly the same shape as reference + NO melting/sagging/warping）；首图"大特写环绕"构图加「全件完整不出画」

### F18 · 手捏徽章防穿模四件套
- arcade4 promo1 徽章内手指与花生互相穿插+手压住弧形字
- 规则：手捏徽章固定声明四条——①手指只从外侧包握挤压（never poke through/merge/intersect）②手物整体留在徽章圆内不压边 ③徽章文字完整可见不被遮挡 ④被捏商品≥1/3面积不缩小

### F19 · 被捏个体=密封正常品（捏品无窗）
- bundle2 用户纠正：被捏的商品不能带开口/开窗填充展示
- 规则：填充展示（开口/开窗）只属于陈列个体；被捏演示个体一律用无开口无窗的密封正常版

### F20 · 珠粒填充双品套图"四件制"
- bundle2 用户二次纠正：所有图不能只有填充展示商品，必须有普通商品展示
- 规则：此类套图每图固定四件=填充展示版×2 + 密封普通版×2（被捏个体占普通版位）

### F21 · 多商品同框比例锁（参照物锚定）
- bundle2 比例两轮失真：v4 悬浮布丁画超大；v4→用户给定 油条13cm/布丁宽5cm
- 规则：①多商品同框先问清各品尺寸，注入 REAL-WORLD SCALE（双层约束=具体数字+禁止句 oversized...is wrong）②悬浮/夸张构图用「参照物锚定」：站台实拍对先定标，悬浮件声明 floating only lifts and tilts, never enlarges ③已知尺寸存档：油条13cm长、布丁宽5cm、捏捏5cm、白幽灵15cm

### F22 · 风格基准指向要确认
- funbox40 用户说"参考刚刚生成的图片"，我猜成 funbox36_cute_arcade，实际指 bundle2_main_v5 → 猜错重生成浪费积分
- 规则：「刚生成的图/这张」类指向=字面最近一张产出；有多张候选时先问一句再动手

### P4 · 生图后必须核对文件存在
- 一轮 v5 生成命令静默失败无产物无报错，差点拿旧版交差
- 规则：每次 generate.py 后 ls 核对目标文件存在+时间戳；不拿"命令没报错"当"出图成功"

## 2026-09-08 · 黄油条+黄油块 2PCS（键盘主题）单沉淀

### F23 · 提示词禁描述商品外观/填充物（用户严批："弱智，商品图直接被改了"）
- 现象：v2 提示词描述了方块颜色（cream-yellow）、凹点纹理、开口端积木填充等 → 模型反而改了商品外观
- 用户指令（永久规则）：**提示词不描述商品外观和填充物，一切让模型从参考图里自己拿**（图片里有的不需要文字复述）
- 允许保留的最小识别集：身份指代词（the long bar / the small cube）+ 计数规则（exactly TWO toys）+ 比例锁（13cm vs 5cm，这是布局约束非外观描述）
- 颜色漂移补救：发现被改色时，加「指向参考图」的锚句（keep the exact same colors as in the reference image — do not recolor），而非文字描述颜色本身
- 印刷锁定写法：Any print or text on the toys stays exactly as in the reference（不引用印刷内容原文）
- 双手问题（铁律复发）：徽章捏压必须显式写 a SINGLE adult hand, only ONE hand, never two hands

### F24 · 静默失败双发
- 链式命令（&&+sleep）整条执行后 stdout 全空且只出 1 张——链式生图不可靠
- 规则：生图命令逐条单独执行、逐条 ls 核对；不搞多张链式一锅跑

## P5 修补止损规则（2026-09-09）
- 像素级 PIL 修补（抠图贴回/覆盖）超过 2 轮仍不收敛（错位/露缝/咬字），立即停手，改为带硬锁词重新生成；磨修补不如重出。
