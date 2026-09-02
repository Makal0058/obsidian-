> [!info] 基本信息
> - **论文题目**：Search-on-Graph: Iterative Informed Navigation for Large Language Model Reasoning on Knowledge Graphs
> - **中文题目**：图上搜索：让大模型在知识图谱中边观察边推理地导航
> - **期刊/会议**：arXiv:2510.08825
> - **年份**：2025 年 10 月
> - **Tag**： #KGQA #图导航 #LLM推理 #迭代单跳检索 #免微调 #图序列化 #位置锚定

---
```table-of-contents
```
---
# 一、研究背景（前人做到哪一步）

## 1.1 核心痛点：LLM 在知识密集型多跳推理上不可靠

LLM 虽具备强大推理能力，但面对知识密集型、多跳问题时存在三大固有缺陷：

- **幻觉**：在不确定时生成看似合理但事实错误的陈述
- **参数化知识过时**：内部知识滞后于现实世界变化
- **缺乏长尾事实**：难以掌握专业领域的稀有知识

在多跳推理场景中，每一步都依赖准确的知识检索，**错误会沿推理链累积放大**，进一步削弱可靠性

---
## 1.2 解决思路：用知识图谱（KG）增强 LLM

知识图谱通过**带类型的边（typed edges）**建模实体间的事实关系，提供结构化的关系证据，天然支持多跳推理，且可随知识演化高效更新。但 KGQA 本身面临两大挑战：

- **规模巨大**：Freebase（19 亿三元组）、Wikidata（160 亿且持续演化）
- **schema 异构**：不同知识库的 schema 差异大，难以开发通用方法

---
## 1.3 三类现有方法及其局限
### 1.3.1 语义解析方法（Semantic Parsing）

将自然语言问题转化为可执行逻辑形式（SPARQL、S-expression 等）后再查询

| 代表工作 | 思路 |
|---|---|
| RNG-KBQA (2021) | KG 路径搜索枚举候选逻辑形式 + 排序生成 |
| DecAF (2022) | 将 KB 线性化为文本，联合解码逻辑形式与答案 |
| ChatKBQA (2023) | generate-then-retrieve，LLM 生成候选后做短语级 grounding |
| CoG (2025) | 参数化输出 fact-aware 查询，再通过 KG 对齐纠正幻觉实体 |
| DARA / Rule-KBQA / HTML | 任务分解 + grounding / 规则引导 / 层次多任务学习 |

> [!warning] 局限
> 需**预先生成完整逻辑形式或查询计划**，要求大量 schema 知识，迁移性差；**当假设的 schema 元素在真实 KG 中不存在时会直接失败**
### 1.3.2 子图检索方法（Subgraph Retrieval）

先在主题实体周围检索相关子图，再在子图上推理

| 代表工作 | 思路 |
|---|---|
| GRAFT-Net (2018) | 融合 KB 实体与 Wikipedia 文本的异构子图 + 图网络 |
| PullNet (2019) | 用 graph CNN 迭代决定"拉取"哪些节点 |
| UniKGQA (2022) | 沿 KG 边做问题-关系分数传播，统一检索与推理 |
| G-Retriever (2024) | 将子图选择建模为 Prize-Collecting Steiner Tree |
| Paths-over-Graph (2025) | 多跳路径扩展 + 图约简剪枝 |

> [!warning] 局限
> 存在根本性权衡——**子图大则召回高但噪声多，子图小则可能漏掉关键边**；且答案质量完全依赖检索完整性，**构建阶段被过滤掉的关键关系无法由推理模块恢复**。此外许多方法用独立 embedding 模块做相似度选择，但语义表示可能误导（如"Inception 导演获得了什么奖"会引入无关的电影元数据）
### 1.3.3 Agentic LLM 方法

通过 LLM agent 与 KG 交互式探索

| 代表工作 | 思路 |
|---|---|
| Think-on-Graph (2023) | 迭代 beam search，维护 top-N 部分路径并剪枝 |
| Plan-on-Graph (2024) | 问题分解为子目标 + 轨迹记忆 + 反思机制 |
| EffiQA (2024) | LLM 全局规划 + 轻量模型探索 |
| FiDeLiS / ReKnoS / iQUEST | Path-RAG + 演绎 beam search / 超关系双向推理 / 迭代分解 + GNN |

> [!warning] 局限
> 常引入**复杂的多组件架构**（规划、记忆、剪枝各需独立模块）；最关键的是，**并行路径探索（beam search）会指数级扩张搜索空间，用大量无关信息淹没 LLM**

---
## 1.4 研究空缺（Gap）

三类方法的共同问题可归结为：**都在"预先猜测"而非"实地观察"**——
- 语义解析：盲目假设 schema 存在
- 子图检索：依赖相似度启发式
- Agentic：并行盲目扩张

> [!note] SoG 的切入点
> 强调**观察优先于推测（precedence of observation over speculation）**：LLM 应先系统性地观察每个实体处**实际可用**的关系连接，再基于问题做出有依据的导航决策，而非盲目规划路径或依赖语义相似度

---
# 二、拟解决的问题（为什么现有方法不行）

> [!abstract] 一句话
> 三类现有方法的失败，**根源是同一个**：都在「未观察就行动」——在不知道真实可用关系的情况下做决策。SoG 要解决的核心问题，就是把「推测驱动」换成「观察驱动」
## 2.1 语义解析：预设 schema 与真实 KG 不符 → 脆性失败

语义解析方法必须**在查询前一次性生成完整的逻辑形式**（SPARQL / S-expression）。这要求：

- LLM 预先掌握目标 KG 的完整 schema 知识
- 假设的关系/属性名在真实 KG 中确实存在

> [!failure] 失败模式
> 一旦**预设的 schema 元素在真实 KG 中缺失**，整条查询直接报废（planning-based failure mode）。而真实 KG（Freebase 用 CVT 复合值类型、Wikidata 用 qualifiers）schema 高度异构，预设几乎必然出错。其可迁移性因此很差

---
## 2.2 子图检索：检索-推理解耦带来的不可恢复损失

子图检索是「先框定一块子图，再在子图上推理」，但这个先后顺序本身埋了雷：
### 2.2.1 失败模式一：召回-噪声的两难权衡
> [!failure] 
> - 子图**大** → 召回高，但混入大量无关三元组，噪声淹没相关信息
> - 子图**小** → 噪声低，但可能漏掉关键边
> 没有一个尺寸能同时兼顾
### 2.2.2 失败模式二：损失不可逆
> [!failure] 
> 答案质量**完全依赖检索完整性**——构建子图阶段被过滤掉的关键关系，**下游推理模块再聪明也无法找回**。检索一旦出错，推理无力回天
### 2.2.3 失败模式三：语义相似度会误导
> [!failure] 
> 许多方法用独立 embedding 模块按语义相似度选子图。但相似 ≠ 相关：
> 问「Inception 的导演获得了什么奖」时，相似度检索器会把大量**无关的电影元数据**一并拉进来，而真正需要的只是「导演→奖项」这一条关系路径

---
## 2.3 Agentic LLM：架构臃肿 + 搜索空间指数爆炸

Agentic 方法（ToG、PoG 等）确实能做交互式探索、避免一次性完整查询，但代价高昂：
### 2.3.1 失败模式一：多组件架构复杂
> [!failure] 
> 通常需要为**规划、记忆、剪枝**分别配置独立模块，工程复杂度和维护成本高
### 2.3.2 失败模式二：并行探索的指数爆炸（最致命）
> [!failure] 
> 用 **beam search 并行维护多条路径** → 搜索空间随跳数**指数级扩张** → 海量无关信息**淹没 LLM 的上下文**。这恰恰把「让 LLM 专注推理」的初衷反噬了

---
## 2.4 三者的共性根因 + SoG 的针对性主张

| 方法 | 错误的「推测」 | 真实后果 |
|---|---|---|
| 语义解析 | 盲目假设 schema 存在 | 关系缺失即崩溃 |
| 子图检索 | 依赖语义相似度启发式 | 漏边不可恢复、噪声大 |
| Agentic | 并行盲目扩张路径 | 上下文被无关信息淹没 |

> [!success] SoG 拟解决的问题，落到三个具体设计目标
> 1. **不预设 schema**：在每个实体处先观察**实际存在**的 1-hop 关系，再决定下一跳 → 天然适配异构 schema，规避 planning-based 失败
> 2. **不并行扩张**：每跳**只选一条关系**做单跳导航，避免 beam search 的搜索空间爆炸与噪声累积
> 3. **不上重型架构**：用**单个 LLM + 单个 SEARCH 函数**完成全部遍历，去掉规划/记忆/剪枝等独立模块
>
> 论文的更深主张：**许多所谓"LLM 在结构化推理上的局限"，其实源于我们呈现问题的方式，而非模型本身能力的根本不足。** 把任务设计对齐到 LLM 的强项——基于局部上下文做迭代观察与决策——就能在不堆架构的前提下超越复杂方法

---
# 三、创新点与贡献

> [!abstract] 一句话
> 用**一个 LLM + 一个 SEARCH 函数**，把 KGQA 从「预先规划/并行扩张」简化为「迭代式单跳观察-导航」，在六个基准上免微调达到 SOTA。核心哲学：**观察优先于推测（observe-then-navigate）**
## 3.1 范式创新：observe-then-navigate（最核心）

颠覆了「先规划路径 / 先检索子图 / 并行 beam search」的传统思路，提出**先观察、再导航**的迭代原则：

> [!success] 关键洞察
> 在每一跳，LLM 先检视当前实体**实际可用**的关系，**再**决定下一跳。导航决策**扎根于问题特定的推理**，而非盲目路径规划或语义相似度启发式

这一范式直接拔除了前述三类方法的病根：
- 不预设 schema → 规避 planning-based 失败
- 不并行扩张 → 规避搜索空间指数爆炸与噪声累积

---
## 3.2 方法创新：单个 SEARCH 函数 + 三项关键设计

整个框架的架构简洁性来自三个刻意的设计决策：

| #   | 设计              | 作用                                      |
| --- | --------------- | --------------------------------------- |
| 1   | **紧凑结果格式的探索函数** | 用空间高效的 markdown 表格返回 1-hop 邻居，节省上下文长度   |
| 2   | **动态过滤机制**      | 遇到高度数节点时，只返回去重后的关系类型（unique properties） |
| 3   | **系统化设计的提示**    | few-shot exemplar 示范有效的推理-导航过程          |

> [!note] SEARCH 函数签名
> `search(entity, direction, properties?)`
> - `entity`：目标实体 ID（如 `m.07_m2`）
> - `direction`：`outgoing` / `incoming`（支持双向遍历）
> - `properties`（可选）：用于聚焦检索的关系过滤
>
> 这是 LLM **唯一**的 KG 探索接口

**高度数节点的两段式处理（Algorithm 1）**

> [!tip] 把不可解问题拆成两个可管理步骤
> 1. **属性发现**：邻居数 > k（=50）且未指定 properties 时，只返回去重关系类型，让 LLM 先「扫一眼」可用关系而不撑爆上下文
> 2. **定向检索**：LLM 用 `properties` 参数做第二次精准调用，只取相关关系
> 3. 即便过滤后仍超 p（=1000），截断至前 p 条以保证落入上下文窗口

----
## 3.3 分析贡献：系统拆解关键设计选择

论文对多个设计因素做了消融分析，并量化其影响：

- **few-shot 数量**：IO→0-shot（带工具定义）跳升最大；1-shot 再涨一波；**3-shot 后基本饱和**
- **Thinking vs Instruct 模型**：Thinking 全面胜出，多跳任务差距最大 → SoG 的天花板取决于模型本身的结构化推理能力
- **输出格式**（见下表）

| 格式 | 平均总 token | 平均轮次 | EM |
|---|---|---|---|
| JSON | 12047.3 | 3.06 | 76.5 |
| Markdown | 7981.8 | 3.05 | 74.5 |
| **Markdown + Property Filter（本文）** | **5622.5** | 3.93 | **78.0** |

> [!success] 反直觉结论
> Markdown + 属性过滤**虽多了一轮交互，却同时实现了最低 token 与最高准确率**——稠密邻域中避免冗余信息既省成本又帮 LLM 更有效定位相关路径

---
## 3.4 实验贡献：六基准免微调 SOTA

> [!success] 主结果
> 在 Freebase（SimpleQA / WebQSP / CWQ / GrailQA）与 Wikidata（QALD-9 / QALD-10）六个基准上，仅用现成 LLM、**无任何任务特定微调**即达到 SOTA 或高度竞争性结果。
> - **SoG + GPT-4o** 在 6 个数据集中有 5 个超越所有先前系统（CWQ 仅落后 Generate-on-Graph 0.1%）
> - **Wikidata 上提升尤为显著**：QALD-9 +16.6%、QALD-10 +16.7%（vs IO Prompting）
> - 在单跳（SimpleQA）与多跳任务上**表现一致**，不像 ToG/EffiQA/ReKnoS/KnowPath 只在多跳上相对强

## 3.5 论文主张的 contributions（原文三条）

> [!quote] Main Contributions
> 1. 提出通用 KGQA 框架 **SoG**：单 LLM + 迭代 1-hop SEARCH 函数，可靠导航多样图 schema
> 2. 分析多个设计选择（函数输出格式、关系过滤、few-shot 示例、模型选择），展示精心设计如何提升整体性能与效率
> 3. 大量实验证明 SoG 的简单、即插即用设计在六个广泛使用的 KGQA 基准上达到 SOTA

---
## 3.6 更深层的立场（值得单独记一笔）

> [!important] 元层面贡献
> SoG 证明了：**许多被认为是「LLM 结构化推理的固有局限」，其实源于我们呈现问题的方式，而非模型能力的根本缺陷。** 把任务设计对齐到 LLM 的强项（基于局部上下文的迭代观察与决策），无需复杂架构、专用模块或大量 scaffolding 即可超越前人
>
> 这一立场与 [[Graph-Intervention Faithfulness]] 工作形成有趣张力：SoG 强调「呈现方式」决定性能（尤其强制显式输出导航路径），恰好可能对应你 Pilot 中「JSON-CoT 显著压制 endpoint anchoring」的发现——即 SoG 之所以 work，部分得益于它强制了「显式路径输出」这种位置锚定的解药

---
# 四、方法与模型

> [!abstract] 核心
> SoG = **单个 LLM** + **单个 SEARCH 函数** + **few-shot 提示**。LLM 通过 tool call 反复调用 SEARCH 做 1-hop 探索，遵循「观察-导航」循环，直到抽取出最终答案。整个过程**无微调、即插即用**，对任何支持 tool calling 的 LLM 通用

## 4.1 预备定义（Preliminaries）

> [!note] 知识图谱
> $$G = \{(e, r, e') \mid e, e' \in E,\ r \in R\}$$
> 每个三元组 $(e, r, e')$ 编码头实体 $e$ 与尾实体 $e'$ 间的事实关系 $r$。实体由唯一 ID 标识（如 Freebase 中 `m.07_m2` = 梵高），并附带文本标签与语义类型
>
> 实体 $e$ 的邻域同时包含出边与入边关系：
> $$R_e = \{r \mid (e, r, e') \in G\} \cup \{r \mid (e', r, e) \in G\}$$
> 这种**双向连通性**使遍历可沿关系边任一方向进行

> [!note] 推理路径
> 长度为 $k$、从 $e_0$ 到 $e_k$ 的推理路径：
> $$P = [(e_0, r_1, e_1), (e_1, r_2, e_2), \dots, (e_{k-1}, r_k, e_k)]$$
> 相邻三元组共享实体，构成连通遍历；中间实体 $e_1, \dots, e_{k-1}$ 充当「踏脚石」
>
> **示例**：Vincent van Gogh $\xrightarrow{\text{place of birth}}$ Zundert $\xrightarrow{\text{contained by}}$ Netherlands $\xrightarrow{\text{capital}}$ Amsterdam（3-hop）

> [!note] KGQA 任务定义
> 给定自然语言问题 $q$、知识图谱 $G$、主题实体 $T_q \subseteq E$，目标是找出答案实体 $A_q \subseteq E$。沿用前人设定（ToG / PoG），**使用数据集提供的 gold entity 标注**，即问题中的实体已链接到 KG ID，从而**跳过 entity linking 环节**

---
## 4.2 SEARCH 函数（唯一接口）

> [!tip] 函数签名
> `search(entity, direction, properties?)`
>
> | 参数 | 含义 |
> |---|---|
> | `entity` | 目标实体 ID（如 `m.07_m2`） |
> | `direction` | `outgoing`（实体作主语）/ `incoming`（实体作宾语） |
> | `properties`（可选） | 指定属性以聚焦检索 |

函数返回**空间高效的 markdown 表格**，并在表头**前缀行数**，让 LLM 立刻获知结果规模。每行四列：

> [!example] SEARCH 返回示例：`search("Vincent van Gogh", "outgoing")`
> `594 rows:`（前缀行数告知结果规模）
>
> | property | propertyLabel | value | valueLabel |
> |---|---|---|---|
> | people.person.profession | Profession | m.0n1h | Artist |
> | visual_art.visual_artist.art_forms | Art forms | m.05qdh | Painting |
> | people.person.place_of_birth | Place of birth | m.0vlxv | Zundert |
> | people.person.date_of_birth | Date of birth | 1853-03-30 | - |
> | ... | ... | ... | ... |

> [!info] 设计要点
> 四列 = property ID + property label + value ID + value label，**同时提供机器可读标识符与人类可读标签**

---
## 4.3 高度数节点处理（Algorithm 1：自适应邻域检索）

KG 中常有度数极高的节点（国家、名人、大型组织），naive 地取全部邻居会撑爆上下文并引入噪声。SoG 用**两段式过滤**解决：

> [!example] Algorithm 1 — Adaptive Neighbourhood Retrieval
> ```
> Input:  entity_id, direction, properties; thresholds k, p
> Output: 1-hop neighbours in markdown table
> 
> R ← GET_ALL_NEIGHBOURS(entity_id, direction, properties)
> if |R| > k and properties is empty then
>     U ← EXTRACT_UNIQUE_PROPERTIES(R)
>     return FORMAT_AS_TABLE(U)          # 只返回去重关系类型
> if |R| > p then
>     R ← R[0:p]                         # 截断至前 p 条
> return FORMAT_AS_TABLE(R)
> ```

工作流程：
### 4.3.1 属性发现

邻居数 $|R| > k$ 且未指定 `properties` 时，只返回去重后的关系类型（unique properties），让 LLM 先「扫一眼」可用关系而不溢出上下文
> [!example] 高度数节点的属性发现：`search("Netherlands", "outgoing")`
> 高度数节点（$|R| > k=50$）且未指定 `properties` → 只返回去重关系类型：
>
> | property | propertyLabel |
> |---|---|
> | location.country.form_of_government | Form of government |
> | location.country.official_language | Official language |
> | location.country.capital | Capital |
> | ... | ... |
>
> 注意此处**只有两列**（property + propertyLabel），与普通 SEARCH 返回的四列不同——这正是「属性发现」阶段的标志：先survey关系类型，再定向检索。
### 4.3.2 定向检索

LLM 用 `properties` 参数做**第二次精准调用**，只取相关关系
### 4.3.3 兜底截断

即便过滤后仍 $|R| > p$，截断至前 $p$ 条以保证落入上下文窗口

> [!success] 效果
> 把高度数节点导航从「不可解问题」转化为**两个可管理步骤：属性发现 → 选择性检索**。

---
## 4.4 SoG 提示设计（Few-shot Prompting）

为每个数据集**手工构造 5 个多样化导航 exemplar**，覆盖三个关键环节：

| 环节 | 内容 |
|---|---|
| **Initial exploration** | 根据问题焦点策略性地做第一次 SEARCH 调用 |
| **Iterative traversal** | 分析返回的邻居、选定相关关系、链式调用 SEARCH 构造推理路径 |
| **Answer extraction** | 识别完成条件，从推理链中抽取最终答案 |

> [!info] exemplar 覆盖的推理模式
> 单跳检索、多跳遍历、约束验证（constraint verification）、聚合（aggregation）。均派生自训练集问题

> [!important] 可解释性
> 每一步导航都通过 tool call **显式记录**，因此所有推理轨迹**完全可解释**

## 4.5 完整工作流（以 Figure 1 为例）

> [!example] 「What is the capital of Vincent van Gogh's birth country?」
> 1. `search("Vincent van Gogh", "outgoing")` → 收到 markdown 表，思考：Zundert 是城市，需要国家
> 2. `search("Zundert", "outgoing")` → 发现 "Contained by" → Netherlands
> 3. `search("Netherlands", "outgoing")` → 结果太多（高度数节点），先看到属性列表
> 4. `search("Netherlands", "outgoing", ["capital"])` → 定向取到 Capital → **Amsterdam**
> 5. 思考：找到答案 → **Answer: Amsterdam**
>
> 路径：Van Gogh $\to$ Zundert（place of birth）$\to$ Netherlands（contained by）$\to$ Amsterdam（capital）
>
> 注：若在另一个 KG 中梵高直接连到 Netherlands，LLM 会自动采用更短路径 —— 体现 **schema-agnostic** 的自适应性

---
## 4.6 模型与超参

> [!note] 评测模型（全部 off-the-shelf，无微调）
> | 模型 | 类型 | 设置 |
> |---|---|---|
> | Qwen3-30B-A3B-Thinking-2507 | 开源 | temp=0.6, top_p=0.95, top_k=20, min_p=0 |
> | Qwen3-235B-A22B-Thinking-2507-FP8 | 开源 | 同上 |
> | GPT-4o | 闭源 | OpenAI API |
>
> **关键超参**：高度数阈值 $k = 50$，最大结果规模 $p = 1000$（平衡信息完整性与上下文窗口约束）。
> **要求**：任何支持 tool calling 的 LLM 均可即插即用。

---
# 五、实验与结论（数据说明了什么、有什么局限性）

## 5.1 实验设置

> [!note] 数据集（6 个，跨两大 KG）
> | KG | 数据集 | 特点 |
> |---|---|---|
> | Freebase | SimpleQA | 单跳 |
> | Freebase | WebQSP | 多跳 |
> | Freebase | CWQ (ComplexWebQuestions) | 多跳、约束复杂 |
> | Freebase | GrailQA | 多跳、考泛化 |
> | Wikidata | QALD-9 | 多跳 |
> | Wikidata | QALD-10 | 多跳 |
>
> SimpleQA / GrailQA 用 ToG 同款 1000 样本子集（控成本 + 可直接对比），其余用全量测试集

> [!info] 评测指标 & 基线
> - **指标**：精确匹配准确率 Hits@1（exact match）
> - **23 个基线**：分子图检索 / LLM baseline / agentic LLM 三组
> - 语义解析方法**被排除**（依赖任务特定微调，与本文 training-free 范式正交）
> - 超参：$k=50$，$p=1000$

---
## 5.2 主结果（Table 1）

> [!success] 六基准全部 SOTA 或高度竞争
> | 数据集 | 最佳 SoG 配置 | 准确率 | 提升（vs 前最佳） |
> |---|---|---|---|
> | SimpleQA | Qwen3-235B | **86.4** | +9.9% |
> | WebQSP | GPT-4o | **91.3** | +0.3% |
> | CWQ | Qwen3-235B | **77.1** | +1.9% |
> | GrailQA | GPT-4o | **86.9** | +2.2% |
> | QALD-9 | Qwen3-235B | **82.5** | **+16.6%** |
> | QALD-10 | Qwen3-235B | **79.8** | **+16.7%** |
>
> - **SoG + GPT-4o** 在 6 个数据集中 5 个超越所有先前系统（CWQ 仅落后 Generate-on-Graph 0.1%）
> - **SoG + Qwen3-235B** 在 4/6 上刷新最佳，WebQSP / GrailQA 仅以 0.7% / 0.8% 微弱落后

## 5.3 数据说明了什么（4 个核心结论）
### 5.3.1 结论一：observe-then-navigate 的简单设计能匹配甚至超越复杂架构

> [!important] 
> 仅用现成 LLM、无任何微调即达 SOTA，证明**许多 LLM 结构化推理的「局限」源于问题呈现方式，而非模型能力本身**
### 5.3.2 结论二：schema-agnostic 设计成立

> [!important] 
> Freebase 用 CVT 复合值类型、Wikidata 用 qualifiers，结构迥异；SoG **无需修改**即适配两者，Wikidata 上 +16% 的大幅提升正是 schema 通用性的有力证据
### 5.3.3 结论三：单跳 / 多跳上表现一致（区别于同类方法）

> [!important] 
> SoG 在单跳（SimpleQA）和多跳任务上都强，而 ToG / EffiQA / ReKnoS / KnowPath 只在多跳上相对突出
> **机制解释**：每跳只选一条关系而非并行探索多路径，避免了噪声累积——这种噪声本会在简单问题上反而拖累性能
### 5.3.4 结论四（消融）：三个设计因素决定成败

> [!important] 
>
> **(1) Few-shot 数量**（Figure 2）
> - IO → 0-shot（带工具定义）：**跳升最大**，说明 LLM 一旦理解 SEARCH 接口就能做结构化导航
> - 0 → 1-shot：再涨一波，单个示范即惠及所有复杂度
> - **3-shot 后饱和**，少量多样 exemplar 已足够
>
> **(2) Thinking vs Instruct 模型**
> - Thinking 变体全面胜出，**多跳任务差距最大**
> - 说明 SoG 的性能天花板取决于模型**底层的结构化推理能力**——Thinking 模型基于推理而非问题语义/模式匹配来做导航选择
>
> **(3) 输出格式 + 过滤**（Table 2，SimpleQA 20% 样本，Qwen3-30B-Thinking）
> 
> | 格式 | 平均总 token | 平均轮次 | EM |
> |---|---|---|---|
> | JSON | 12047.3 | 3.06 | 76.5 |
> | Markdown | 7981.8 | 3.05 | 74.5 |
> | **Markdown + Property Filter（本文）** | **5622.5** | 3.93 | **78.0** |
>
> 反直觉：属性过滤**虽多一轮交互，却同时实现最低 token + 最高准确率**——稠密邻域避免冗余既省成本，又帮 LLM 更准定位路径

---
## 5.4 论文结论（Conclusion 原意）

> [!quote] 三个有效图导航的依赖因素
> 1. 给 LLM 提供每个实体处**实际可用**的关系
> 2. 使用能有效利用导航示范的**推理优化模型**
> 3. 设计平衡信息完整性与计算效率的**输出格式**
>
> SoG 的简单性与通用性（无需任务特定训练、跨 schema 无缝适配），验证了**以观察为中心的方法是 LLM 结构化推理的一个有前景方向**

---
## 5.5 局限性（论文未设独立 Limitations 节，以下为推断 + 可借鉴角度）
### 5.5.1 方法层面的潜在局限

> [!warning] 
> - **依赖 gold entity 标注**：实验全程使用数据集提供的实体链接，**跳过了 entity linking**。真实部署中 entity linking 本身就是误差源，论文未评估端到端鲁棒性
> - **天花板受限于模型推理能力**：消融已自证 Instruct 模型表现明显劣于 Thinking——SoG 不能「拯救」弱推理模型，对小模型/弱推理场景的可迁移性存疑
> - **单路径导航的脆性**：每跳只选一条关系，效率高但**没有回溯 / 容错机制**。一旦某跳选错关系，无并行路径兜底（这正是它砍掉 beam search 换来的代价）。论文未报告失败案例分析或错误传播率
> - **高度数节点的截断风险**：$|R| > p=1000$ 时直接截断「前 p 条」，若正确答案恰在被截断部分则不可恢复——截断顺序的影响未被分析
> - **few-shot 需手工构造**：每个数据集 5 个 exemplar 均人工编写，跨新领域/新 KG 的零样本可迁移性未验证
> - **评测仅 Hits@1**：对多答案问题、聚合类问题的覆盖度（recall / F1）未充分报告
### 5.5.2 整体定位
> [!tip] 
> SoG 是一篇「**做减法做到极致**」的方法论论文——证明了简单 + 观察驱动能打过复杂架构。它的强是工程与范式上的强；它的弱（faithfulness 未验证、单路径无容错、依赖 gold linking）恰好是后续工作（包括你的诊断框架）可以撬动的缝隙

---
# 六、关联课题需求（该文献的方法能否解决我的实验痛点、其缺陷是否可通过我的方案弥补）

> [!abstract] 结论先行（两句话）
> SoG **不能直接解决**我的实验痛点——它是「如何让 LLM 在图上正确导航」的**方法论**，而我的 GIF 是「它到底是不是真在跟图走」的**诊断框架**，二者目标正交。但 SoG 是我框架一个**极佳的真实世界 testbed**，且我的方案恰好能戳中它一处**从未被验证的核心假设**。需要警惕的是：二者的位置锚定机理并非 1:1 对应，直接套用会失真
## 6.1 SoG 能否解决我的实验痛点？——基本不能，但提供了样本

| 我的痛点 | SoG 是否解决 | 说明 |
|---|---|---|
| 区分「真图推理」vs「序列化位置启发式」 | ❌ 否 | SoG 全程**默认**模型在跟图走，从未验证；它解决的是导航策略，不是 faithfulness |
| 构造反事实图 G1/G2 做位置控制 | ❌ 否 | SoG 用真实 KG + gold answer，无反事实/decoy 结构 |
| 量化「图推理虚胖」（GFI） | ❌ 否 | SoG 只报 Hits@1，无 Raw GIS / PC-GIS 之类的敏感性拆解 |
| 提供可被诊断的真实 KGQA 方法 | ✅ 是 | SoG 把图序列化为带行号 markdown 表，是现成的位置控制实验场 |

> [!note] 定位
> SoG 不是我的「工具」，而是我的**研究对象 / 应用 case**。它越是成功（六基准 SOTA），就越值得问一句：**它的成功有多少来自真图推理，多少来自提示形式的副作用？**

---
## 6.2 SoG 的缺陷能否被我的方案弥补？——这是最强的钩子

> [!danger] 核心缺陷：faithfulness 完全未验证
> SoG 有两个设计，**恰好同时落在我 Pilot 结论的两端**：
> 1. **图序列化为 markdown 表**：每次 SEARCH 返回的行，其 `property` / `value` 的**出现顺序**就是位置信号 → 对应我的「序列化位置」自变量
> 2. **强制显式输出导航路径**（Thinking + tool call 链）：对应我 Pilot 里的 **JSON-CoT 设置**
>
> 而我的 Pilot 已证：
> - Direct answer-only：Raw GIS=100% 但 PC-GIS=0%、GFI=100%、decoy-last EAR=100%（表面跟图，实则纯终点位置锚定）
> - JSON-CoT：PC-GIS↑95%、GFI↓5%、decoy-last EAR↓0%（强制输出路径**压制**了位置锚定）
>
> **推论**：SoG 之所以 work，很可能**部分得益于它强制了显式路径输出这一「位置锚定的解药」，而非模型真的在做图结构推理。** 我的框架能把这个隐藏归因**显式诊断出来**——这正是 GIF 对 SoG 的诊断价值

> [!success] 我的方案能补上 SoG 的三处空白
> 1. **归因拆解**：用 Raw GIS vs PC-GIS 拆开 SoG 的 Hits@1，回答「准确率里有多少是图推理虚胖」
> 2. **失败模式分类**：SoG 砍掉了 beam search、单路径无容错，但从不报错误分析。我的 Trace-only Compliance / Endpoint Anchoring / Hop-level Drift 分类能定位它**在哪种结构上虚假跟随**
> 3. **提示形式的因果证据**：SoG 的消融只比了 JSON vs Markdown 的 **token/准确率**，没碰 faithfulness。我可以补上「输出格式 × 位置锚定」这一维，把 SoG 的 Table 2 提升为因果性结论

---
## 6.3 但必须诚实：类比在三处会断裂（防止过度自洽）

> [!warning] 机理差异，直接套用会失真
> - **agentic vs static**：我的 GIF 是**静态**呈现整张图让模型读；SoG 是**主动**导航——模型自己决定请求哪些行、每跳只选一条关系。SoG 的「最后出现节点」由路径构造**天然就是答案节点**，所以 EAR 在 SoG 里的语义和我的静态 decoy-last 不同，不能直接搬
> - **反事实结构缺失**：我的核心是 G1/G2 双反事实图 + decoy 边。SoG 跑在真实 KG 上，没有 gold path 唯一性的符号程序验证，也没有诱饵节点。要在 SoG 上测，我得**自己往它的 SEARCH 返回表里注入位置控制版本和 decoy 行**——这是额外工程
> - **多跳 vs 单步答案**：我的 Pilot 是 4-hop 随机符号图、一次性给图。SoG 是迭代单跳，位置锚定可能**逐跳累积或逐跳重置**，需要新指标（比如逐跳 EAR）才能刻画，不能直接用现成 GFI

---
## 6.4 可操作的对接方式（如果真要用 SoG 做实验）

> [!tip] 把 SoG 的 SEARCH 表格当成位置控制载体
> - **改造点**：在 SoG 的 SEARCH 返回中，对**目标关系所在行**做我的四种位置版本（endpoint-first / middle / last / decoy-last），其余保持不变
> - **新指标**：定义**逐跳 GFI**——在每一跳的关系选择上测 Raw vs 位置控制后的敏感性，刻画位置锚定是否随 hop 累积
> - **对照**：SoG 的 Thinking vs Instruct 消融可直接复用为我的「推理能力 × faithfulness」交叉维度——Pilot 已暗示 CoT 压制锚定，Thinking 模型是否锚定更轻？这是一个现成可验证的假设
> - **风险**：SoG agentic 特性使「模型自己跳过含 decoy 的行」成为混淆变量，需控制（如强制单次调用、禁用二次过滤）

---
## 6.5 一句话给自己

> [!important]
> **SoG 不解决我的问题，但它是我问题的最佳反面教材**：一篇「做减法到极致、六基准 SOTA」的方法论，恰恰**把 faithfulness 当成不证自明的前提**。我的 GIF 价值不在于打败 SoG，而在于揭示——SoG 的强，可能有一部分是「提示形式压制了位置锚定」的副产品，而非论文宣称的「LLM 本就能做结构化图推理」。这正好是我论文 Intro / Related Work 里区分 **「真图跟随」vs「序列化锚定」** 的一个有力 motivating example

