> [!info] 基本信息
> - **论文题目**：Follow the Path: Reasoning over Knowledge Graph Paths to Improve Large Language Model Factuality
> - **中文题目**：顺着知识图谱路径推理：提升大语言模型事实性的路径约束方法
> - **期刊/会议**：ACL Findings 2026
> - **年份**：2026
> - **Tag**： #知识图谱 #KG-grounding #推理蒸馏 #reasoning-trace #test-time-scaling #多跳问答 #事实性 #factuality #SFT微调 #小模型 

---
```table-of-contents
```
---
# 一、研究背景（前人做到哪一步）

> [!abstract] 一句话定位
> LLM 的 reasoning（"thinking"）在 STEM/数学/代码上已被证明能提升性能，但**能否提升事实性（factuality），尤其是复杂多跳问答 mQA**，仍是开放问题。前人主要在「推理时检索」这条路上做 KG grounding，本文把它挪到了「离线造数据」这一步
## 1.1 三条已有技术脉络
### 1.1.1 脉络 A：长 CoT / 测试时扩展（Test-Time Scaling）

> [!note] 
> - 长链推理：CoT、反思、回溯、自洽性 self-consistency（Wei et al. 2022、Wang et al. 2023）
> - 测试时扩展两种范式：
>   - **并行扩展（parallel）**：Best-of-$N$，生成 $N$ 个候选提升命中概率（Brown et al. 2024 "Large Language Monkeys"）
>   - **顺序扩展（sequential）**：CoT + 迭代修正、self-refine（Madaan et al. 2023）
> - 关键限制：并行扩展的实际效果**受限于选择机制（verifier / majority voting）**，而 verifier 的天花板又被 generation recall 卡住——模型生成不出正确答案，verifier 再强也选不出来
> - 代表：s1（Muennighoff et al. 2025），本文 **fs1 = factual s1** 直接继承其框架。
### 1.1.2  脉络 B：KG 增强的推理（Graph-enhanced Reasoning）

> [!note] 
> 前人用知识图谱提升事实性，主要分三类，**全部集中在推理时（inference-time）**：
> - **语义解析**：把自然语言问题转成形式化 KG 查询（Lan & Jiang 2020；Ye et al. 2022）
> - **GNN 联合表示**：QA-GNN 把 QA context 和 KG 拼成联合图做消息传递（Yasunaga et al. 2021）
> - **KG-RAG / 路径推理**：
>   - RoG：生成 KG-grounded 的 relation path 作为忠实路径让模型 follow（Luo et al. 2024）
>   - ToG：agent 在图上迭代 beam search，探索-剪枝-推理（Sun et al. 2024）
>   - G-Retriever：先检索连通子图（树优化），再基于子图生成答案（He et al. 2024）
>   - GNN-RAG（Mavromatis & Karypis 2025）：**与本文最接近**——用 GNN 找候选答案节点，再取最短路径 verbalize 给 LLM 推理
>   - Paths-over-Graph（Tan et al. 2025）：同样用 KG path 引导推理
### 1.1.3  脉络 C：长文本事实性（Long-Form Factuality）

> [!note] 
> - 已有 SAFE、SimpleQA 等事实性数据集（Wei et al. 2024），但**缺乏对结构化知识子图的显式 grounding**
> - Tian et al. 2024：用自动生成的偏好排序微调，优先选事实一致的输出

---
## 1.2 前人止步于此的关键空白（Research Gap）

> [!warning] 本文要补的洞
> 上述 KG 方法**几乎都是 inference-time retrieval 机制**（迭代 beam search、子图优化），即"每次回答都要现场查图"。它们提升的是**单次回答时的外部支撑**，没有改善模型**自身（intrinsic）的推理能力**
>
> $$\text{前人：} \quad \text{问题} \xrightarrow{\text{推理时查 KG}} \text{答案}$$
> $$\text{本文：} \quad \text{KG path} \xrightarrow{\text{离线一次性造数据}} \text{SFT} \Rightarrow \text{模型"学会"更factual地thinking}$$

**注：**
inference-time retrieval（推理时检索）机制：**模型每次回答问题的当下，临时去外部知识源（这里是知识图谱 KG）里现查相关信息，把查到的内容塞进上下文，再生成答案**

> [!question] 由此引出的 RQ
> **To what extent does grounding the reasoning processes of LLMs in KG paths enhance their factual accuracy for mQA?**
> （把 LLM 的推理过程锚定在 KG 路径上，能在多大程度上提升多跳问答的事实准确率？）

---
## 1.3 与本文方法的对照锚点

| 维度 | 前人主流（RoG / ToG / G-Retriever / GNN-RAG） | 本文 fs1 |
|---|---|---|
| KG 介入时机 | 推理时（inference-time retrieval） | **离线、一次性**（造训练数据） |
| 改善对象 | 单次回答的外部支撑 | **模型 intrinsic 推理技能** |
| 产物 | 检索流程 / 子图 | 3.9K 条 KG-grounded reasoning traces + SFT 模型 |
| 评测视角 | top-1 / 检索质量 | **pass@k 上界**（隔离生成能力，不混入 verifier） |

---
# 二、拟解决的问题（为什么现有方法不行）

> [!abstract] 一句话
> 现有方法在两条路上各有死穴：**推理范式**（CoT / thinking / 并行采样）不保证事实正确，**KG 增强**则停留在推理时检索、没改善模型自身的推理能力。fs1 要解决的是「如何让模型把 *factual* 的思考方式内化进参数」
## 2.1 问题的根源：reasoning ≠ factual reasoning

> [!warning] 核心矛盾
> 长链推理（thinking）在数学/逻辑上有效，是因为这些任务的中间步骤**可自洽验证**（算对了就是对了）。但 mQA 的中间步骤依赖**外部世界事实**，模型推得再"流畅"也可能基于错误的参数化记忆
>
> 论文原话点破要害：从大模型蒸馏来的 reasoning trace —— **"we have no guarantee that these reasoning traces from the large reasoning models are factually correct."**

> [!example] 反面实例（论文 Figure 9，QwQ-32B 的 rt trace）
> 问"东欧主流宗教信徒中谁会去斯里兰卡 Batticaloa 的圣玛丽大教堂"，模型整段推理**看起来逻辑严密**（讨论东正教 vs 天主教、东仪天主教、侨民社区……），最终蒙对 "Roman Catholics"。但这是**流畅的猜测**而非事实锚定的推理——这正是 rt（纯蒸馏 trace）的隐患：**对的答案，错的（或无据的）过程**

---
## 2.2 逐一拆解：现有四类方法为什么不行
### 2.2.1 Instruction-tuned 直答 / Zero-shot

> [!note] 
> 无中间推理，多跳问题直接崩。Figure 1 里直接答 "Paris"——错
> **死穴**：没有把分散在多处的证据"串"起来的过程。
### 2.2.2 Chain-of-Thought（CoT）

> [!note] 
> 有 step-by-step，但步骤本身**没有事实约束**，照样能一本正经地推向错误答案（Figure 1 "Vienna"）
> **死穴**：推理结构 ≠ 推理内容正确。Table 4 也显示 CoT 在 3+ hop 难题上相对增益最低
### 2.2.3 原始 Thinking trace（rt，从 R1/QwQ 蒸馏）

> [!note] 
> 引入了大模型的"思考"能力，但蒸馏来的 trace **事实正确率本身就不高**
> **量化证据（Table 1）**：rt 的 LLM-as-Judge 准确率仅 **0.49**，且 trace 更长（~990 subwords）——**又长又不准**，等于把大模型的"幻觉式思考"也一并蒸馏进了小模型
### 2.2.4 KG 增强方法（RoG / ToG / G-Retriever / GNN-RAG）

> [!note] 
> 这是最接近"对"的一类，但全部是**推理时检索机制**：
> - 每次回答都要现场跑 beam search（ToG）或子图优化（G-Retriever）→ **推理开销大、依赖外部 KG 在线可用**
> - 提升的是"这一次回答"的外部支撑，**模型自身的推理技能没变** → 撤掉检索就打回原形
> **死穴**：治标不治本——是"给模型递小抄"，不是"让模型学会"

---
## 2.3 由此凝练出的待解问题
### 2.3.1 拟解决的问题（三层递进）

> [!question] 
> 1. **factuality 缺口**：能否让 thinking 过程本身变得 **factual**，而不只是 **fluent** ？
> 2. **internalization 缺口**：能否把 KG 的事实约束从「推理时外挂」变成「训练时内化进参数」，从而无需在线检索？
> 3. **可验证性缺口**：能否提供一个**不被 verifier 质量污染**的评测，纯粹度量"模型生成正确推理的能力"？
### 2.3.2 fs1 的应对（与上面三层一一对应）

> [!success] 
> 1. 用 KG 最短路径 steer 蒸馏出的 trace → trace 准确率 0.49 → **0.65**，且更短（990 → 767 subwords）：**更准 + 更简洁**（Table 1）
> 2. 把 KG grounding 当作**离线一次性造数据**，再 SFT → 推理时不再需要 KG（区别于 RoG/ToG）
> 3. 用 **pass@k 上界**评测，刻意不引入 selection 机制 → 隔离"生成能力"，避免 verifier recall 瓶颈污染结论
### 2.3.3 这套方案自身埋下的限制（伏笔，承接后文实验）

> [!warning] 
> 既然事实约束被"固化"进参数，方法本质上**只对参数知识不足的小模型有效**；大模型（7B+）参数里已有足够事实，KG 指引反而可能干扰 → 这正是 Table 4 中 7B/32B 在 SimpleQA、WebQSP 上**负增益**的伏笔 $$\text{离线固化的代价：缺乏推理时的动态判断} \Rightarrow \text{无法按问题难度自适应是否依赖 KG}$$

---
# 三、创新点与贡献

> [!abstract] 一句话
> 把 KG grounding 从「推理时检索」搬到「离线造数据」，用 KG 最短路径 steer 出又准又短的 reasoning trace，再 SFT 内化进模型——并用 pass@k 上界 + 多维 ablation 严谨证明"提升源自 KG 而非别的"
## 3.1 核心创新（机制层定位）

> [!success] 创新点：offline, one-time KG grounding for *intrinsic* reasoning
> 不是给模型递小抄（inference-time retrieval），而是**用 KG 把训练数据"洗"干净**，让模型学会更 factual 的思考方式
> - 论文原话：KG 作为 *"a one-time, offline process to create higher-quality training data, which induces the model to 'think' more effectively."*
> - 与最接近的 GNN-RAG（Mavromatis & Karypis 2025）的根本区别：后者推理时取最短路径 verbalize 给 LLM；fs1 把路径用在**训练前**，推理时不碰 KG

> [!note] 数据构造的两个小巧思
> 1. **最小跳约束作为隐式语义过滤**：先找 1-hop，有就停；否则 2-hop、3-hop……——短路径在 KG 里更可能是直接、有意义的关系，自动滤掉噪声
> 2. **三元组线性化**："subject, relation, object" 格式注入 prompt，保留 KG 结构方向，兼顾可解释性。多条能导向同一答案的路径 → 反映推理多样性

---
## 3.2 三大可量化贡献（对应论文 Contributions 1-3）
### 3.2.1 贡献 ①：并行采样下的显著提升

> [!success] 
> fs1-tuned **Qwen2.5-32B** 在 pass@16 下事实准确率提升 **6–14 个绝对百分点**
> - CWQ：+16 abs. pts @ k=16；SimpleQA：~+6 abs. pts（Figure 5）
> - 评测刻意用 **pass@k 上界**，隔离"生成能力"，不被 verifier recall 污染
### 3.2.2 贡献 ②：定位"在哪类问题上有效"（多维切片分析）

> [!success] 
> 取 SimpleQA 的元数据按 **hop 数 / answer type / domain** 切片（Figure 7）：
> - **难题更受益**：1-2 hop 增益低，**3+ hop 反超**所有基线 → KG path 帮的是复杂多跳
> - **数值类答案最受益**：number、date、misc 类型相对提升最大
> - **domain**：video games、geography、politics、music 上 fs1 最好；art/history 反而 rt 更好，sports 是 CoT 更好
### 3.2.3 贡献 ③：跨尺度（360M–32B）单次推理分析
> [!success] 
> pass@1 下 **小模型增益最大、大模型递减甚至负增益**（Table 4）：
> - 0.5B fs1 在 WebQSP **+74.6%**；CWQ 0.135 → 0.209
> - 1.5B 起在 4/6 数据集**退化**；32B 在 SimpleQA **-10.3%**、WebQSP **-7.2%**
> - 作者假设：大模型参数知识已足够，对 KG 显式指引依赖更低
### 3.2.4 贡献 ④：开源资源
> [!success] 
> 公开 **3.4K rt + 3.9K fs1** reasoning traces（源自 QwQ-32B & Deepseek-R1）+ 代码 + 模型（MIT，`github.com/jjzha/fs1`），为 process-level verification / factuality reward model 提供素材

---
## 3.3 两个关键 ablation（创新的"防御性"贡献）
### 3.3.1 排除数据泄漏

> [!check] 
> CWQ_train vs 各 benchmark 的 cos sim > 0.9 重叠计数极低、几乎无 exact match、平均 cos sim ≤ 0.15 → **提升不来自训练集泄漏**（Figure 6）
### 3.3.1 排除"teacher 更强"这个 confounder（最关键）

> [!check] 
> 用同一批问题、分别取 QwQ-32B 和 R1-685B 的 fs1 子集训练 Qwen2.5-32B → pass@k **几乎完全一致**（Table 3，如 pass@16 均为 71.95）$$\Rightarrow \text{提升源自 KG path 注入，而非 teacher 模型强弱}$$**这是全文最值得抄的实验设计**：预判并消解最致命的替代解释

---
## 3.4 贡献的边界（诚实之处 = 也是软肋）

> [!warning] 自曝的天花板
> - "6–14 pts" 只在 **pass@16 并行采样**下成立；pass@1 故事弱很多
> - 方法本质是**"救小模型"**，不是"普遍提升 factuality"——标题/abstract 写得偏大
> - 离线固化 ⇒ **缺乏推理时的动态判断**，无法按难度自适应是否依赖 KG（承接 二、拟解决的问题（为什么现有方法不行） 的伏笔）

---
# 四、方法与模型

> [!abstract] 一句话
> 整条 pipeline：从大模型蒸馏推理 trace（rt）→ 用 KG 最短路径 steer 出更 factual 的 trace（fs1）→ 标准 SFT 微调小模型 → pass@k 评测。核心是"离线一次性把 KG 事实约束洗进训练数据"
## 4.1 数据来源（CWQ）

> [!note] 训练问题集
> - 用 **ComplexWebQuestions (CWQ)** dev set，共 **3,519** 题（专为复杂多跳设计，基于 Freebase 自动生成 SPARQL → 转自然语言 → 人工 paraphrase）
> - 用 CWQ 是因为它每题都自带 **gold answer 实体** + 可对齐到 KG 的问题实体——这是后面抽 KG 路径的前提

---
## 4.2 rt：蒸馏原始推理 trace

> [!note] 步骤
> 1. 直接拿问题问两个 teacher：**QwQ-32B** 和 **Deepseek-R1 (685B)**
> 2. 抓取 `<think>...</think>` 包裹的推理过程，强制最终答案放进 `\boxed{}`
> 3. **只保留最终答案正确**的 trace → 得到 **3.4K 条 rt**
>
> > [!warning] rt 的隐患（承接 过程也被蒸馏上去了吗 的澄清）
> > "答案对就保留"会把**蒙对答案、但过程瞎猜/无据**的 trace 一并收进来 → trace 事实准确率仅 0.49

---
## 4.3 fs1：用 KG 路径 steer trace（核心创新）
### 4.3.1 路径抽取流程

> [!success] 
> 1. **实体对齐**：CWQ 的 Freebase 实体 → 对齐到 Wikidata 实体（用 `wdt:P646`，见 SPARQL）
> 2. **最小跳路径抽取**（隐式语义过滤）： $$\text{先找 1-hop;\ 有则停;\ 否则 2-hop} \to \text{3-hop} \to \cdots$$
>    短路径 = 更可能是直接、有意义的关系，自动滤噪
> 3. **多实体处理**：
>    - 每个问题实体分别与答案实体查（individually）
>    - 所有问题实体联合与答案实体查（jointly，捕获多实体路径）
>    - 多 gold answer 时，每个 Q–A 组合分别查
> 4. **线性化**：用标准三元组 `subject, relation, object` 格式（保留 KG 语义方向），多条能导向同一答案的路径全部保留 → 反映推理多样性
### 4.3.2 fs1 Prompt 结构（Figure 2）

> [!example] 
> ```
> <Question>
> While answering the question, make use of the following
> linearised graph as an inspiration in your reasoning,
> not as the only answer:
>   1994 NBA Finals, winner, Houston Rockets
>   Houston Rockets, owned by, Leslie Alexander
>   ...
> Put your final answer within \boxed{}.
> ```
> **关键措辞**："as an inspiration, not as the only answer" —— KG 是引导而非硬约束，让模型仍走自然推理但锚定在事实上
### 4.3.3 fs1 vs rt 的数据质量（Table 1）

> [!check] 
> | 指标 | rt | fs1 |
> |---|---|---|
> | Exact Match | 0.51 | **0.67** |
> | Sem. Match | 0.52 | **0.60** |
> | LLM-as-Judge | 0.49 | **0.65** |
> | 样本数 | 3,434 | **3,886** |
> | 平均 trace 长度 | 990 | **767**（更短） |
> 结论：**更准 + 更多 + 更简洁**

---
## 4.4 训练（SFT）

> [!note] 配置（沿用 s1 / Muennighoff et al. 2025）
> - 微调 **6 个 Qwen2.5-Instruct**（0.5B → 32B），分别在 rt 和 fs1 上训
> - 只用最终答案正确的 trace
> - 超参：5 epochs、seq len 8192、batch 16、lr $1\times10^{-5}$（cosine，5% warmup）、weight decay $1\times10^{-4}$
> - 标准 SFT 损失（自回归交叉熵）：
>   $$\mathcal{L}_{\text{SFT}}(\theta) = -\frac{1}{T}\sum_{t=1}^{T}\log p_\theta\!\left(y_t^{*} \mid x, y_{<t}\right)$$

---
## 4.5 推理与模型清单

> [!note] 推理设置
> - 原始 instruct 模型：$T=0.7$, top_p $=0.8$；微调后模型：$T=0.6$, top_p $=0.95$
> - 推理引擎：**vLLM 0.9.3**；硬件：LUMI 超算（AMD MI250x），约 **6,500 GPU-hours**，~276 kg CO₂

> [!note] 涉及的模型全景
> - **Teachers（造数据）**：QwQ-32B、Deepseek-R1 (685B)
> - **被微调的 students**：Qwen2.5 {0.5, 1.5, 3, 7, 14, 32}B；额外加 SmolLM2-{360M, 1.7B}（跨家族对照）→ 共 **8 个模型**
> - **Baselines**：Qwen2.5-72B-Instruct、QwQ-32B、Deepseek-R1、o3-mini
> - **LLM-as-Judge**：主用 **Llama-3.3-70B-Instruct**（与 gpt-4o-mini 对比，几乎无差异）

---
## 4.6 评测协议

> [!note] 四种 setup × 六个 benchmark
> - Setups：(1) zero-shot 直答 (2) zero-shot CoT (3) rt-tuned (4) fs1-tuned
> - Benchmarks（共 **23.9K** 题）：CWQ、ExaQT（时序 QA）、GrailQA、SimpleQA、Mintaka（多语，取英文）、WebQSP
> - 指标 **pass@k**，$k\in\{1,2,4,8,16\}$：
>   $$\text{pass@}k = \mathbb{E}_{\text{problems}}\!\left[1 - \frac{\binom{n-c}{k}}{\binom{n}{k}}\right]$$
>   $n$=每题生成数，$c$=正确数
>
> > [!tip] 为什么刻意用 pass@k 上界（方法论亮点）
> > 不引入 selection 机制（majority vote / verifier），是为了**隔离"生成 + 知识激发能力"**，避免 verifier 的 recall 瓶颈污染结论——"verifier 选不出模型没生成的正确答案"。fs1 扩大了正确推理路径的池子，正是解决这个 recall 瓶颈

---
# 五、实验与结论（数据说明了什么、有什么局限性）

> [!abstract] 一句话
> 并行采样下 fs1 在 32B 上提升 6–14 个绝对点；切片分析锁定"复杂多跳 + 数值答案"最受益；跨尺度分析揭示"救小模型、大模型递减甚至负增益"。结论诚实，但也因此自曝了泛化边界
## 5.1 主结果：并行采样（pass@k 上界，Qwen2.5-32B）

> [!success] 发现 A：parallel scaling × fs1 最优（Figure 5）
> 随 $k$ 增大，所有设置的 pass@k 都升，但 **fs1 升得最猛**：
> - CWQ：+16 abs. pts @ k=16
> - SimpleQA：~+6 abs. pts @ k=16
> $$\Rightarrow \text{fs1 扩大了"正确推理路径池",直接抬高 pass@k 上界}$$
> **数据说明**：fs1 的价值在"提升生成正确答案的概率"，而非"选出正确答案"——这与它刻意用 pass@k 上界、不引入 verifier 的设计自洽

---
## 5.2 多维切片：fs1 到底在哪类问题上有效（Figure 7，pass@16 相对提升）

> [!check] 发现 B：难题、数值答案最受益
> | 切片维度 | fs1 表现 |
> |---|---|
> | **hop 数** | 1-2 hop 增益低；**3+ hop 反超所有基线** ← 核心卖点 |
> | **answer type** | **number / date / misc 最受益**；person 类一般 |
> | **domain** | fs1 强：video games、geography、politics、music；rt 强：art、history；CoT 强：sports |
> **数据说明**：KG path 真正帮的是"需要串联多步事实"的复杂题——这与"事实锚定"的动机吻合，是全文最有说服力的一致性证据

---
## 5.3 跨尺度单次推理（Table 4，pass@1）

> [!warning] 发现 C：救小模型，大模型递减/负增益
> - **0.5B**：fs1 全面提升，WebQSP **+74.6%**，CWQ 0.135 → 0.209
> - **1.5B**：fs1 在 **4/6** 数据集**退化**（ExaQT -4.7%、WebQSP -1.1%）
> - **7B**：SimpleQA **-24.3%**、WebQSP **-15.2%**
> - **32B**：SimpleQA **-10.3%**、WebQSP **-7.2%**
> - 跨家族：Qwen2.5-0.5B fs1 稳定提升，但 SmolLM2-360M 在 GrailQA **-15.9%**（家族不一致）
> $$\text{作者假设：大模型参数知识已足够} \Rightarrow \text{对 KG 显式指引依赖更低,甚至被干扰}$$
> **数据说明**：这不是"普遍提升 factuality"的方法，而是**"参数知识不足时的补丁"**

---
## 5.4 两个防御性 ablation（排除替代解释）

> [!check] 发现 D：排除数据泄漏（§5.1, Figure 6）
> CWQ_train vs benchmark 的 cos sim>0.9 重叠极少、几乎无 exact match、平均 cos sim ≤ 0.15 → 提升**非来自泄漏**

> [!check] 发现 E：排除"teacher 更强"（§5.2, Table 3）★最关键
> 同问题、QwQ-32B 子集 vs R1-685B 子集分别训 32B → pass@k **几乎完全相同**（pass@16 均 71.95）。
> $$\Rightarrow \text{提升源自 KG path,而非 teacher 强弱} \quad (\text{这是全文最该抄的实验设计})$$

---
## 5.5 总体结论

> [!summary] 论文主张
> 把推理 trace 锚定在 KG 路径上、并训练模型内化它，能在复杂开放域 QA 上带来事实性的实质提升——尤其是**并行采样 + 复杂多跳 + 小模型**三个条件叠加时。开源 3.4K rt + 3.9K fs1 traces，供 process-level verification / factuality reward model 后续研究

---
## 5.6 局限性（论文自述 + 我的批判补充）
### 5.6.1 论文明确承认的局限
> [!failure] 
> 1. **不保证中间过程完全正确**：KG 条件只是"提高"trace 准确率，非保证
> 2. **pass@k 是上界**：实际落地需额外 selection 机制（majority vote / verifier）→ 真实性能会打折
> 3. **评测数据偏旧、仅英文**：无法排除测试集已进入某些 LLM 的预/后训练
> 4. **实体答案评测难**：靠 LLM-as-Judge 缓解，但 judge 本身有固有局限
### 5.6.1 我的补充
> [!danger] 
> 1. **标题/abstract 言过其实**：主打 "6–14 pts" 只在 **pass@16** 成立，pass@1 下大模型大量负增益——"提升 factuality" 的普适性叙事站不住
> 2. **方法的天花板是结构性的**：离线固化 KG ⇒ **缺乏推理时动态判断**，无法按问题难度自适应是否依赖 KG。大模型负增益不是 bug，是"硬塞外部约束干扰已有参数知识"的必然结果
> 3. **依赖 gold answer 才能抽路径**：CWQ 自带答案实体才能抽最短路径——这在**没有 gold answer 的真实开放域**不可复现，限制了方法迁移性

