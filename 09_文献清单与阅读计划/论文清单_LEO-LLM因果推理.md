# 文献清单：LEO卫星网络 × LLM Agent × 因果推理

> 整理自方向调研的多轮检索。优先级说明：
> - 🔴 **P0 必精读**：与你主线（受限环境下 Agent 因果推理）直接相关，决定你的差异化卖点
> - 🟠 **P1 重点读**：方法可借鉴，或包含你必须知道的反方论点
> - 🟡 **P2 了解即可**：知道现状、补综述文献量用，快速浏览
>
> 阅读策略：每篇带三个问题去读——①它的场景和我的 LEO 场景差在哪？②它的方法假设在卫星上哪些不成立？③它怎么拿数据/做实验？

---

## 一、松尾研自己的工作（最高战略价值）

> 这是你申博的目标实验室，他们的母题是"Agent 能力在什么条件下失效、如何让它更可靠"。读这些不是为了引用，是为了**学会用他们的语言重新包装你的工作**。

| 优先级   | 标题                                                                                                   | 一句话                                             | 与你的关系                                        |
| ----- | ---------------------------------------------------------------------------------------------------- | ----------------------------------------------- | -------------------------------------------- |
| 🔴 P0 | **Lost in the Distance: LLMs Struggle to Capture Long-Distance Relational Knowledge** (NAACL 2025)   | 在两个相关元素间插入噪声，LLM 推理远距离关系的能力随噪声增大急剧下降，在因果推理任务上验证 | 松尾研亲手做的"因果推理可靠性"研究，和你方向最近，**精读后学会对齐他们的话语体系** |
| 🟠 P1 | **Exposing Limitations of LM Agents in Sequential-Task Compositions on the Web** (CompWoB, TMLR)     | Agent 基础任务 94% 成功率，组合任务掉到 24.9%                 | 母题同源：Agent 在复杂条件下的失效边界                       |
| 🟠 P1 | **AGENTiGraph: A Multi-Agent KG Framework for Interactive Domain-Specific LLM Chatbots** (CIKM 2025) | 多智能体 + 知识图谱，缓解幻觉/推理弱/事实不一致                      | 多 Agent + 结构化知识，与你的 RAG/Agent 综述呼应           |
| 🟡 P2 | **Answer When Needed, Forget When Not: In-Context Knowledge Unlearning** (ACL 2025 Findings)         | 测试时按上下文选择性遗忘信息                                  | 了解他们对"知识管理"的思路                               |

**链接**
- Lost in the Distance: https://weblab.t.u-tokyo.ac.jp/en/news/20250123/
- 实验室六大研究单元（World Models / Learning Algorithms / Robotics / LLM / Brain-inspired / Social Implementation）: https://weblab.t.u-tokyo.ac.jp/en/fundamental-research/
- 论文全列表: https://weblab.t.u-tokyo.ac.jp/en/research/publications/tags/llm-nlp/

---

## 二、因果推理 × 故障诊断（你的主线 = Idea 1）

> 这是你最该深耕的方向。结论：组合"LLM+因果+故障诊断"已经不新，但**没人做"Pearl 三层框架 + LEO 极端约束（数据稀缺、间歇连接、星上算力不足）"这个特定组合**。你的护城河在场景约束，不在方法本身。

| 优先级 | 标题 | 一句话 | 与你的关系 |
|--------|------|--------|-----------|
| 🔴 P0 | **CausaLM-Net: LLM-guided causal graph & state-space learning for fault diagnosis in cloud-native 5G base stations** (Expert Systems w/ Applications, 2026) | 语义推理 + 因果结构学习 + 动态图建模的统一诊断框架，在中国移动 5G 数据集验证 | **最接近的竞品**。看它怎么构因果图、怎么验证。你的差异：它做 5G 基站（数据充足、连接稳定），你做 LEO（数据稀缺、间歇） |
| 🔴 P0 | **Long Causal Chain-of-Thought (LC-CoT) for compound fault diagnosis: hypergraph-based Causal-LLM intervention reasoning** (2026) | 长因果思维链 + 干预条件奖励反馈，做复合故障的干预推理与闭环维护决策 | 看它的**干预推理（intervention）**怎么实现——正好对应 Pearl 第二层 |
| 🔴 P0 | **Intelligent Fault Diagnosis for Satellite Networks Using LLM Agents** (ICCAICE, ACM 2025) | CNN 返回中间结果给 LLM 生成结构化诊断报告，含因果分析 + 运维建议 | **离你最近的卫星场景论文**。重点看它**没做什么**——它没用 Pearl 三层、没处理数据稀缺，这就是你的空间 |
| 🟠 P1 | **Agentic Diagnostic Reasoning over Telecom and Datacenter Infrastructure** (2026) | 不学因果模型，让 LLM 通过结构化工具交互做"过程性因果推理" | ⚠️ **必读的反方论点**：实证表明因果推理 RCA 跨系统泛化差。你必须想好怎么回应这个质疑 |
| 🟠 P1 | **Reasoning Language Models for Root Cause Analysis in 5G Wireless Networks** (arXiv 2507.21974) | 两阶段：CoT 监督微调 + GRPO 强化学习提升诊断推理 | 看 RCA 的训练范式，传统 fault tree 的局限性论述可直接引用 |
| 🟡 P2 | **Why causal reasoning makes LLMs smarter at diagnosing system failures** (Okoone, 行业博客) | 因果 Agent 比反应式工具链更能找到根因 | 非学术，仅作直觉/动机佐证，**不要进参考文献** |

**链接**
- CausaLM-Net: https://www.sciencedirect.com/science/article/abs/pii/S0957417426008742
- LC-CoT: https://www.sciencedirect.com/science/article/abs/pii/S0278612526000725
- 卫星 LLM Agent 诊断: https://dl.acm.org/doi/10.1145/3804601.3804823
- Agentic Diagnostic Reasoning: https://arxiv.org/pdf/2601.07342
- 5G RCA: https://arxiv.org/pdf/2507.21974

---

## 三、结构化 / 抽象化 RAG（Idea 2 = 问题结构记忆，撞车最重）

> 结论：你最独特的"函子形式化"已被人在 RAG 里用了（CatRAG），"匹配问题结构而非表面相似"也已成热门。**不适合做主线**，但这些是你综述 RAG 章节的优质新文献。

| 优先级 | 标题 | 一句话 | 与你的关系 |
|--------|------|--------|-----------|
| 🟠 P1 | **CatRAG: Functor-Guided Structural Debiasing with Retrieval Augmentation** (2026) | 用函子（投影）在表示层做结构化去偏 + RAG 提供平衡证据 | ⚠️ **你的"函子"卖点被它占了**。读它确认重叠度，决定你的 Idea 2 还剩什么空间 |
| 🟡 P2 | **GroupRAG: Cognitively Inspired Group-Aware Retrieval via Knowledge-Driven Problem Structuring** (2026) | 识别问题内部潜在结构组，从多概念起点检索推理（MedQA 验证） | "显式建模问题结构"——和你的思路同源 |
| 🟡 P2 | **Structure-R1: Dynamically Leveraging Structural Knowledge via RL** (arXiv 2510.15191) | 用 RL 把检索内容转成结构化表示，动态生成适配查询的结构 | 结构化检索的方法参考 |
| 🟡 P2 | **SRAG: RAG with Structured Data Improves Vector Retrieval** (2026) | 用结构化元数据（主题、查询类型、KG 三元组）把检索转向结构/任务级对齐 | 轻量级实现思路，促进泛化 |
| 🟡 P2 | **ARoG: Abstraction Reasoning on Graph for Privacy-protected KGQA** (arXiv 2508.08785) | 关系中心 + 结构导向抽象，把实体抽象成高层概念 | 抽象表示构建方法 |
| 🟡 P2 | **RAG with Hierarchical Knowledge** (HiRAG, arXiv 2503.10150) | 知识图谱分层表示，解决语义相似实体的结构距离 + 局部/全局知识鸿沟 | GraphRAG 系列的改进，综述背景 |
| 🟡 P2 | **Hierarchical RAG: Multi-level Retrieval** (综述类) | 多层级结构化检索范式总览（树/社区/多分辨率图） | 综述写作时的 taxonomy 参考 |

**链接**
- CatRAG: https://arxiv.org/html/2603.21524
- GroupRAG: https://arxiv.org/pdf/2603.26807
- Structure-R1: https://arxiv.org/pdf/2510.15191
- SRAG: https://arxiv.org/pdf/2603.26670
- ARoG: https://arxiv.org/html/2508.08785v1
- HiRAG: https://arxiv.org/pdf/2503.10150

---

## 四、分布式 / 持续更新知识库（Idea 3 = gossip 传播）

> 结论：零件都成熟（gossip 是老技术、分布式 RAG 有人做），但"LEO + RAG + gossip 更新"的特定组合还较新。**可作备选主线**，但小心和 JPL 的星座持续决策线撞车。

| 优先级 | 标题 | 一句话 | 与你的关系 |
|--------|------|--------|-----------|
| 🟠 P1 | **Distributed Retrieval-Augmented Generation** (arXiv 2505.00443) | 分布式 RAG，指出集中式 RAG 的隐私/扩展性问题，快变知识维护成本高 | "快变知识维护成本高"论点和你卫星场景几乎一样（它做医疗） |
| 🟠 P1 | **Large-Scale Continual Scheduling for Dynamic Distributed Satellite Constellation** (NASA JPL, 2026) | 星上分布式控制做动态星座观测分配，在线 DDCOP 算法，强调计算/通信效率 | ⚠️ **JPL 在做星座分布式持续决策**，"星座+持续+分布式+ISL"framing 被占，注意区分 |
| 🟡 P2 | **Gossip-based Protocols for Large-scale Distributed Systems** (DSc 学位论文) | gossip 协议的系统性理论（push/pull、冗余消息优化、收敛性） | gossip 机制的理论基础 |
| 🟡 P2 | **Strengthening Gossip Protocols using Protocol-Dependent Knowledge** (arXiv 1907.12321) | 动态 gossip 的成功条件与协议设计 | 形式化背景，了解即可 |
| 🟡 P2 | Gossip 协议科普（GeeksforGeeks / DesignGurus） | gossip 在分布式数据库的传播机制 | 入门理解，**不进参考文献** |

**链接**
- Distributed RAG: https://arxiv.org/pdf/2505.00443
- JPL 星座持续调度: https://arxiv.org/pdf/2601.06188
- Gossip 学位论文: https://www.inf.u-szeged.hu/~jelasity/dr/doktori-mu.pdf

---

## 五、Agent 回滚 / 安全执行（Idea 4 = 回滚机制，已饱和）

> 结论：2026 年初一批工作把这块做到很深，"快照粒度""不可逆动作"都被解决/点破了。**不适合做主线**，综述里一句带过即可。

| 优先级 | 标题 | 一句话 | 与你的关系 |
|--------|------|--------|-----------|
| 🟡 P2 | **Crab: A Semantics-Aware Checkpoint/Restore Runtime for Agent Sandboxes** (arXiv 2604.28138) | eBPF 分类每轮 OS 副作用决定 checkpoint 粒度，恢复正确率 8%→100% | ⚠️ 你的"快照粒度怎么定"被它解决了 |
| 🟡 P2 | **ACRFence: Preventing Semantic Rollback Attacks in Agent Checkpoint-Restore** (arXiv 2603.20625) | checkpoint 能恢复本地状态，但无法撤销已对外部服务执行的动作 | ⚠️ 点破你回滚机制的致命盲区（卫星不可逆动作） |
| 🟡 P2 | **The Evolution of Tool Use in LLM Agents** (arXiv 2603.22862) | 给 Agent 引入事务语义，工具调用当有界工作流，补偿逻辑实现安全回滚 | 了解 SagaLLM/Atomix 等事务式回滚 |
| 🟡 P2 | **STRATUS: Multi-agent System for Autonomous ...** | 状态调和系统的回滚，承认复杂环境完美 undo 仍是挑战 | 工程现状参考 |
| 🟡 P2 | **All is Not Lost: LLM Recovery without Checkpoints** (arXiv 2506.15461) | 无 checkpoint 的容错训练恢复，训练时间提升 12%+ | 偏训练容错，关系较远 |

**链接**
- Crab: https://arxiv.org/html/2604.28138
- ACRFence: https://arxiv.org/html/2603.20625
- Tool Use Evolution: https://arxiv.org/html/2603.22862v1

---

## 六、多时间尺度 / LEO×LLM 系统（Idea 5 = 多时间尺度，红海 + 拖入通信）

> 结论：核心概念已被 DRL 那篇占了，且这个方向会把你拖回通信仿真。**放弃做主线，写进综述当背景。** 但这些正好补你综述被批的薄弱章节。

| 优先级 | 标题 | 一句话 | 与你的关系 |
|--------|------|--------|-----------|
| 🟠 P1 | **Collaborative Computing in NTN: A Multi-Time-Scale DRL Approach** (arXiv 2402.04865) | 多时间尺度 DRL 做 NTN 无线资源优化，明确处理星段/地段不同控制周期 | ⚠️ **你 Idea 5 的核心论点被它占了**（只是用 DRL 不是 LLM） |
| 🟡 P2 | **Communication-Efficient Collaborative LLM Inference over LEO Satellite Networks** (arXiv 2604.04654) | 把 LLM 切成子模型分布到多卫星，流水线并行降延迟 | 对应你综述 4.2.3 分割计算，新文献补充 |
| 🟡 P2 | **LLM-guided DRL for Multi-tier LEO Satellite Networks (FSO/RF)** (arXiv 2505.11978) | LLM 引导 DRL 调超参，处理时间耦合约束，DeepSeek 表现最佳 | LLM 辅助 DRL 的卫星应用 |
| 🟡 P2 | **LLM-Empowered Channel Prediction & Predictive Beamforming for LEO** (arXiv 2510.10561) | CSI 编码进文本嵌入空间，LLM 推理 + LoRA 微调，预测多时隙 CSI | 物理层 LLM 应用（注意：这反驳了你综述"LLM 天然不满足物理层"的绝对结论） |
| 🟡 P2 | **AI Reasoning for Wireless Communications and Networking: A Survey** (arXiv 2509.09193) | 无线通信 AI 推理综述，含 LEO SFC 重路由、GeNet 等案例 | 综述类，可对标你自己的综述结构 |

**链接**
- 多时间尺度 DRL: https://arxiv.org/pdf/2402.04865
- 协同 LLM 推理: https://arxiv.org/pdf/2604.04654
- LLM-guided DRL: https://arxiv.org/pdf/2505.11978
- 信道预测 LLM: https://arxiv.org/pdf/2510.10561
- 无线 AI 推理综述: https://arxiv.org/html/2509.09193

---

## 行动建议（优先级排序）

1. **先读第一组松尾研 + 第二组 P0 这 4 篇**（Lost in the Distance / CausaLM-Net / LC-CoT / 卫星 LLM Agent 诊断）。读完你就能回答两件事：主线到底怎么定位、怎么用松尾研的语言讲。

2. **务必读 Agentic Diagnostic Reasoning（反方论点）**。"因果模型泛化差"是你方向最大的潜在攻击，见导师前想好回应。

3. **第三~六组的 P2 文献**：不用精读，但建议全部补进你的综述参考文献——它们都是 2025-2026 的新工作，直接解决导师 AI 评审吐槽的"文献量少（仅 13 篇）+ 时效性差"。

4. **重新定位你的主线卖点**（基于全部检索结论）：
   > 不是"用 LLM 优化卫星故障诊断"（应用导向，松尾研不感兴趣），
   > 而是"**在数据稀缺、间歇连接、噪声干扰的极端环境下，LLM Agent 如何保持可靠的因果推理**，以 LEO 卫星星座作为天然具备这些约束的试验场景"（方法导向，对齐松尾研母题）。

---

*注：标 ⚠️ 的是撞车风险点或必须警惕的反方论点；标"不进参考文献"的是非学术来源，仅供建立直觉。文中数据与结论均来自检索到的论文摘要/正文片段，引用前请核对原文。*
