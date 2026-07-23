> [!info] 基本信息
> - **论文题目**：GraphReason: Enhancing Reasoning Capabilities of Large Language Models through A Graph-Based Verification Approach
> - **中文题目**：GraphReason：用图结构验证提升大语言模型推理能力
> - **期刊/会议**：ACL 2024  NLRSE Workshop
> - **年份**：2024
> - **Tag**：    #LLM推理增强 #图神经网络 #思维链 #验证器 #自洽性 #数学推理 #图分类 #GNN #大语言模型 #推理图 #输出验证 #上下文学习 #多路径推理 #GPT #数学文字题

---
```table-of-contents
```
---
# 一、研究背景（前人做到哪一步）

## 1.1 问题定义

LLM 的推理能力（尤其是多步推理）是核心能力之一，典型任务是**数学文字题（Math Word Problems, MWP）**，要求模型分解复杂问题为多个子步骤逐步求解

---
## 1.2 已有方法的演进路线

### 1.2.1 阶段一：微调范式（Fine-tuning Based）

早期工作以 seq2seq 微调为主，通过特殊预训练或数据增强注入推理能力：

| 方法 | 思路 |
|---|---|
| Cobbe et al. (2021) | 训练 verifier 对微调模型采样的解法排序 |
| Yoran et al. (2022) / Wang et al. (2022) | 用人工模板生成训练样本，增强模型推理能力 |
| Pi et al. (2022) | 在程序执行数据上持续预训练，注入推理能力 |
| Xie & Sun (2019) | 树结构解码器生成方程树 |
| Zhang et al. (2020) | 图卷积网络提取数量关系 |
| Li et al. (2022) | 对比学习挖掘 MWP 规律 |

> [!warning] 局限性
> 微调范式依赖大量标注数据，泛化能力受限；Valmeekam et al. (2023) 指出多步推理仍是语言模型的普遍弱点
### 1.2.2  阶段二：大模型 Prompting（Prompting-Based，无需训练）

随着 LLM 规模增大，**推理能力内嵌于模型权重**，只需合适的 prompt 即可激活：

| 方法 | 思路 | 效果 |
|---|---|---|
| **Chain-of-Thought (CoT)**（Wei et al., 2022） | few-shot prompt 中包含逐步推理过程 | GSM8K: 18% → 57% |
| **Zero-shot CoT**（Kojima et al., 2023） | "Let's think step by step" 触发推理 | — |
| **In-context Learning**（Lampinen et al., 2022） | 提供带解释的示例，引导模型模拟 | — |
| **Least-to-Most Prompting**（Zhou et al., 2023） | 将复杂问题分解为子问题，逐步解决 | — |
| **DIVERSE**（Li et al., 2023） | 多样化 prompt 采样，增加输出多样性 | — |
### 1.2.3  输出验证（Output Verification，无需 LLM 额外训练）

核心思想：让 LLM **多次生成推理路径**，再设计 verifier 对结果进行评估和筛选

$$LLM 多次采样 \to 多条推理路径 \to Verifier 打分/投票 \to 最终答案$$

| 方法 | 机制 | 局限 |
|---|---|---|
| **Self-Consistency**（Wang et al., 2023） | 多次采样 + 多数投票（majority voting） | 每条路径独立处理，忽略路径间关联 |
| **Simple Verifier**（Cobbe et al., 2021） | verifier 对单条路径打分，选最高分 | 同上，路径间无交互 |
| **Voting Verifier**（Li et al., 2023） | 投票 + verifier 分数联合决策 | 同上 |
| **DIVERSE / Step-aware Voting Verifier**（Li et al., 2023） | 在每个步骤层面打分，而非仅看整条路径 | 假设过于简单：仅认为不同路径的步骤独立错误，无法建模步骤间的复杂逻辑关系；StrategyQA 上表现退步 |

> [!note] 关键 Gap（本文出发点）
> 现有 verifier 方法均**将每条推理路径视为独立实体**，未考虑**不同路径的中间步骤之间可能存在的逻辑关联**
>
> 一旦将路径拆解到步骤层级，来自不同路径的相同中间步骤本质上共享推理逻辑，应被统一建模
>
> → 本文提出 **GraphReason**：将同一问题的多条推理路径构建为**推理图（Reasoning Graph）**，相同中间步骤合并为同一节点，用 GNN 捕捉步骤间的逻辑关系

---
## 1.3 基准性能参照

以 GPT-3.5-turbo + 5-shot CoT 为例（GSM8K 数据集）：

| 方法 | GSM8K |
|---|---|
| Greedy Decode | 72.7% |
| Self-Consistency (Voting) | 82.3% |
| Voting Verifier | 85.4% |
| DIVERSE (Step-aware) | 85.0% |
| **GraphReason（本文）** | **85.7%** |

Fine-tuning SOTA（供参考）：57%（GSM8K）

---
# 二、拟解决的问题（为什么现有方法不行）

## 2.1 现有方法的核心缺陷

所有前序 verifier 方法共享同一个根本假设：**每条推理路径是独立的个体（independent entity）**

这一假设导致以下问题：

| 方法                           | 具体缺陷                                             |
| ---------------------------- | ------------------------------------------------ |
| Self-Consistency（多数投票）       | 只统计最终答案的出现频次，完全忽略推理过程                            |
| Simple Verifier              | 对单条路径整体打分，路径之间零交互                                |
| Voting Verifier              | 投票与 verifier 分数叠加，仍是路径级别的独立评估                    |
| Step-aware Verifier（DIVERSE） | 下沉到步骤级别打分，但步骤仍被视为属于各自路径，**不同路径的相同步骤未被识别为同一逻辑单元** |

---
## 2.2 被忽略的关键结构

当 LLM 对同一问题生成多条推理路径时，这些路径天然具有以下结构特征：

- **共享起点**：所有路径从同一问题出发
- **收敛终点**：答案相同的路径最终汇聚于同一结论
- **中间步骤存在重叠**：不同路径中语义/表达式相同的中间步骤，实质上是**同一推理节点**，但被现有方法重复计算、割裂处理

> [!example] 直观例子
> 路径 $S_1$ 的 Step2 与路径 $S_2$ 的 Step2 若表达式完全相同，
> 则它们在逻辑上是**同一推理步骤**，应合并为单一节点统一建模，
> 而非作为两个独立 token 序列分别打分。

---
## 2.3 Step-aware 方法为何不够

DIVERSE 看似已下探到步骤层级，但其本质假设是：**不正确路径中的某些步骤仍可能是正确的**

这一假设过于简单（**overly simplistic**），无法描述**跨路径步骤之间的复杂逻辑关系**

实验结果也印证了这一点：

- StrategyQA（常识推理）上 Step-aware 反而比 Voting Verifier **下降**
- 原因：常识推理任务无法提供每步的金标准标注（gold label），步骤级监督信号本身就是伪标签，噪声大

---
## 2.4 问题的本质表述

> [!note] 核心问题
> 现有 verifier 方法将 LLM 对同一问题的所有输出视为**一组互相独立的文本序列**，
> 而非一个**具有内在逻辑拓扑结构的整体**
>
> 这导致验证过程无法利用**跨路径的步骤共现关系**和**推理逻辑的图结构信息**，
> 从而在复杂推理场景（路径分叉多、中间步骤重叠度高）下存在系统性的信息损失
> 
> 注：verifier 方法——先让大模型生成多个答案/多条推理过程，然后再用一个“检查器”给这些候选答案打分，最后选最可信的那个

---
## 2.5 本文的解法方向

将问题重新建模为：
$$\text{多条独立路径的集合} \xrightarrow{\text{本文}} \text{一张有向推理图（Reasoning Graph）}$$

- 相同中间步骤 → 合并为**同一图节点**
- 步骤间的顺序依赖 → 编码为**有向边**
- 图的整体结构 → 用 **GNN（GIN）** 进行分类，判断该答案组是否正确

这样，跨路径的逻辑关联得以被显式建模，而非被平均或忽略

---
# 三、创新点与贡献

## 3.1 核心创新：推理图视角（首创）

> [!tip] 第一性原理
> 本文是**首个从图视角对 LLM 推理逻辑进行建模**的工作
> 将"多条推理路径的集合"重新定义为一张有向图，使得此前被所有 verifier 方法忽略的**跨路径步骤关联**得以被显式捕捉

---
## 3.2 方法创新拆解
### 3.2.1 创新点一：推理图构建（Reasoning Graph Construction）

- 将同一问题下、**最终答案相同**的多条推理路径合并为一张图
- 核心操作：**相同算术表达式的中间步骤 → 合并为同一节点**
- 图结构：统一起点（问题节点）+ 统一终点（答案节点）+ 中间步骤节点
- 意义：首次将"路径集合"这一无结构对象转化为**可被 GNN 处理的拓扑结构**
### 3.2.2 创新点二：节点特征设计（Node Feature Engineering）

每个步骤节点的特征向量 $\mathbf{V} \in \mathbb{R}^5$：

$$\mathbf{V} = [\text{score}^{\text{mean}},\ \text{score}^{\text{max}},\ \text{score}^{\text{min}},\ \text{score}^{\text{num}},\ \text{in\_degree}]$$

- 前四维来自 **Base Verifier** 的语义打分（均值/最大/最小/数量）
- 第五维为图结构信息（入度）
- 设计动机：语义信息与结构信息难以同时建模，故分工明确——Base Verifier 负责语义，GNN 负责结构
### 3.2.3 创新点三：双输入 GNN 验证器（Integrated Verifier）

$$G = [h_G,\ \text{score}_A] \in \mathbb{R}^6$$

- $h_G$：GIN 经 3 层传播后的图级表示（sum readout）
- $\text{score}_A$：同答案组内所有解的 Base Verifier 分数之和
- 两者拼接后送入线性分类器，输出该答案组是否正确的概率
- 意义：**图结构逻辑 + 整体语义置信度** 联合决策，优于任一单独使用
### 3.2.4 创新点四：即插即用设计（Plug-and-play）

- GraphReason **不修改原始 LLM**，作为外挂 verifier 存在
- 与任意 LLM（GPT-3.5、GPT-4、PaLM-2）兼容
- 训练数据与目标 LLM 解耦（训练集来自 GPT-3.5，测试可用于 GPT-4）

---
## 3.3 贡献总结

| 贡献维度 | 具体内容 |
|---|---|
| **方法创新** | 首个基于图结构的 LLM 推理验证框架 GraphReason |
| **基准建设** | 在 GSM8K / SVAMP / ASDiv-a / StrategyQA 上统一复现所有 verifier，提供公平对比基线 |
| **实验验证** | 在全部四个数据集上超越现有 verifier SOTA；消融实验验证各组件有效性 |
| **局限分析** | 明确指出计算开销、标注数据依赖、非算术推理任务泛化三个限制方向 |

---
## 3.4 与前人方法的本质差异（一句话）

> [!quote] 定位
> Self-Consistency 看**答案频次**，Step-aware Verifier 看**步骤质量**，GraphReason 看**推理路径之间的拓扑逻辑**——三者建模粒度依次递进，本文处于目前的最细粒度

---
# 四、方法与模型
## 4.1 框架总览

GraphReason 分为**训练阶段**与**预测阶段**，整体流程如下：
$$\begin{cases} 训练阶段： LLM 多次采样 \to 按最终答案分组 \to 构建推理图 \to GNN 分类器训练  \\ 预测阶段： LLM 多次采样 \to 按最终答案分组 \to 构建推理图 \to 训练好的\ Verifier\ 打分 \to argmax \to 最终答案 \end{cases}$$


> [!note] 设计原则
> GraphReason 作为**外挂插件**，不修改原始 LLM 参数，仅在输出层对候选答案组进行图结构验证


---
## 4.2 Step 1：Prompt 设计与多样化采样
### 4.2.1 基础 Prompt 结构

采用 CoT + In-context Learning 组合：

$$\text{Prompt} = [C;\ Q]$$

$$C = [(Q_1, S_1, A_1);\ (Q_2, S_2, A_2);\ \ldots;\ (Q_k, S_k, A_k)]$$

- $k = 5$：5 个 few-shot 示例，来自 GSM8K 训练集
- 每个示例包含问题、逐步推理过程、最终答案
### 4.2.2 多样化采样策略

为增加推理路径的覆盖度，采用双层采样：

$$N = N_1 \times N_2 = 10 \times 3 = 30 \text{ 条路径/问题}$$

- $N_1 = 10$：对同一 prompt，温度采样 10 次（sampling decoding）
- $N_2 = 3$：使用 3 套不同的 few-shot exemplars 构造不同 prompt
- 目的：同时增加**单 prompt 内的随机性**与**跨 prompt 的多样性**

---
### 4.3 Step 2：推理图构建（Reasoning Graph Construction）
### 4.3.1 分组

将 $N$ 条生成路径按**最终答案**分组：

$$\mathbf{S} = \{S_{A_1}, S_{A_2}, \ldots, S_{A_n}\}$$

每组 $S_{A_i}$ 包含所有得出答案 $A_i$ 的路径，每组单独构建一张推理图 $G_{A_i}$
### 4.3.2 图的节点定义

- **起始节点**：问题节点（所有路径共享）
- **终止节点**：答案节点（同组路径共享）
- **中间节点**：推理步骤节点

> [!important] 核心操作：步骤合并
> 比较任意两条路径的每个中间步骤，
> 若**算术表达式完全相同**，则合并为**同一图节点**；
> 若不同，则保留为独立节点。
>
> 合并标准：仅比较步骤中的**算术表达式部分**，忽略自然语言文本，
> 以简化图构建并减少噪声。
### 4.3.3 图构建算法（Algorithm 1 逻辑）

```python
# 伪代码
node2id = {}
edges = []

# 第一遍：建立步骤到节点 ID 的映射（去重）
for path in S_Ai:
    for step in path:
        if step not in node2id:
            node2id[step] = new_node_id

# 第二遍：建立有向边（step_t-1 → step_t）
for path in S_Ai:
    for step_t-1, step_t in consecutive_pairs(path):
        edge = (node2id[step_t-1], node2id[step_t])
        if edge not in edges:
            edges.append(edge)

G_Ai = Graph(node2id, edges)
```

---
## 4.4 Step 3：节点特征构造

每个步骤节点 $V_i$ 的特征向量：

$$\mathbf{V}_i = [\text{score}_i^{\text{mean}},\ \text{score}_i^{\text{max}},\ \text{score}_i^{\text{min}},\ \text{score}_i^{\text{num}},\ \text{in\_degree}_i] \in \mathbb{R}^5$$

| 特征维度 | 来源 | 含义 |
|---|---|---|
| $\text{score}^{\text{mean}}$ | Base Verifier | 经过该节点的所有路径分数均值 |
| $\text{score}^{\text{max}}$ | Base Verifier | 最高路径分数 |
| $\text{score}^{\text{min}}$ | Base Verifier | 最低路径分数 |
| $\text{score}^{\text{num}}$ | Base Verifier | 经过该节点的路径数量 |
| $\text{in\_degree}$ | 图结构 | 节点入度（反映该步骤被多少前驱步骤指向）|

**Base Verifier**

- 独立训练的二分类器（基于 BERT-base-uncased）
- 任务：判断单条推理路径是否正确，输出 $\text{score} \in (0, 1)$
- 步骤分数 = 所属路径的分数（步骤级分数与路径级分数相同）
- 作用：将语义信息编码进节点特征，弥补 GNN 难以直接建模语义的不足

---
## 4.5 Step 4：GNN 验证器（Graph Verifier）
### 4.5.1 图级表示

采用 **GIN（Graph Isomorphism Network）** 进行节点特征传播：

$$h_v^{(k)} = \text{MLP}^{(k)}\left((1 + \varepsilon^{(k)}) \cdot h_v^{(k-1)} + \sum_{u \in \mathcal{N}(v)} h_u^{(k-1)}\right)$$

- $k = 3$：3 层 GIN
- $\varepsilon$：可学习参数
- $\mathcal{N}(v)$：节点 $v$ 的邻居集合

Sum Readout 得到图级表示：

$$h_G = \sum_{v \in G} h_v^{(k)} \in \mathbb{R}^5$$
### 4.5.2 融合分数

同答案组内所有路径的 Base Verifier 分数求和：

$$\text{score}_A = \sum_{i \in S_A} \text{score}_i$$
### 4.5.3 最终图表示

$$G = [h_G,\ \text{score}_A] \in \mathbb{R}^6$$
### 4.5.4 训练目标

二分类（答案是否正确），BCE Loss：

$$\mathcal{L} = \sum_{i=1}^{n} \mathcal{L}_{\text{BCE}}(\text{label}_i,\ f(G_i))$$

其中 $f(\cdot)$ 为线性分类器，$n$ 为当前问题的候选答案组数量

---
### 4.6 Step 5：答案选择（预测阶段）

$$\hat{y} = \text{Answer}\left[\arg\max_i\ \text{score}_i\right]$$

选取验证器打分最高的推理图对应的答案作为最终预测结果

---
## 4.7 训练配置

| 超参数 | 设置 |
|---|---|
| 基础 LLM | GPT-3.5-turbo，温度 $t=1$ |
| 采样次数 | $N_1=10,\ N_2=3$，共 30 条路径/问题 |
| Few-shot 数量 | $k=5$ |
| Base Verifier | BERT-base-uncased，微调 |
| GNN 层数 | 3 层 GIN |
| 优化器 | AdamW |
| 学习率 | 线性分类器 $4\times10^{-2}$，GNN 层 $4\times10^{-3}$ |
| 激活函数 | ReLU |
| Batch size | 2（每步验证多张推理图，故较小）|
| 训练数据规模 | GSM8K 训练集 1000 条 |

---
# 五、实验与结论（数据说明了什么、有什么局限性）

## 5.1 实验设置
### 5.1.1 数据集

| 数据集 | 类型 | 测试集大小 | 说明 |
|---|---|---|---|
| GSM8K | 算术推理 | 1319 | 唯一提供 CoT 金标准示例的数据集，exemplar 来源 |
| SVAMP | 算术推理 | 1000 | 难度适中，结构变化丰富 |
| ASDiv-a | 算术推理（子集） | 1218 | 仅含算术运算，题目相对简单 |
| StrategyQA | 常识推理 | 300（测试）/ 700（训练）| 需隐式多步推理，无金标准 CoT |

> [!note] 跨数据集迁移设置
> 训练数据**仅来自 GSM8K**，在 SVAMP 和 ASDiv-a 上直接测试，同时验证了方法的**迁移学习与泛化能力**
### 5.1.2 评估指标

- **Accuracy**：最终答案是否与标准答案完全一致
### 5.1.3 公平性保证

- 所有 verifier（包括 baseline）使用**完全相同的 LLM 输出**进行验证
- 相同随机种子、相同硬件环境、相近超参数设置

---
## 5.2 主实验结果
### 5.2.1 与各 Baseline 对比（GPT-3.5-turbo）

| 方法 | GSM8K | SVAMP | ASDiv-a | StrategyQA |
|---|---|---|---|---|
| Fine-tuning SOTA | 57.0 | 57.4 | 75.3 | 73.9 |
| Greedy Decode | 72.7 | 78.7 | 93.0 | 65.0 |
| Self-Consistency (Voting) | 82.3 | 82.9 | 95.6 | 66.0 |
| Simple Verifier | 66.9 | 73.1 | 92.8 | 69.3 |
| Voting Verifier | 85.4 | 84.8 | 96.9 | 70.7 |
| DIVERSE (Step-aware) | 85.0 | 85.1 | 96.8 | 66.9 |
| **GraphReason（本文）** | **85.7** | **85.4** | **97.0** | **71.2** |
### 5.2.2 数据说明了什么

> [!success] 结论一：显著超越 Greedy Decode 基线
> GSM8K 上从 72.7% 提升至 85.7%，**绝对提升 +13.0%**，证明 verifier 机制对 LLM 推理能力有实质性增强

> [!success] 结论二：在全部四个数据集上达到 SOTA
> 相较于前序最优 verifier（Voting Verifier / DIVERSE）：
> - GSM8K：+0.3%（85.4% → 85.7%）
> - SVAMP：+0.3%（85.1% → 85.4%）
> - ASDiv-a：+0.1%（96.9% → 97.0%）
> - StrategyQA：+0.5%（70.7% → 71.2%）
>
> 图结构建模带来持续稳定的提升。

> [!warning] 结论三：Step-aware 方法的反常现象
> DIVERSE 在 StrategyQA 上（66.9%）反而低于 Voting Verifier（70.7%），原因：常识推理任务无法提供每步金标准标注，步骤级伪标签引入噪声，假设本身在此场景下失效。GraphReason 无此问题，依然保持最优

> [!info] 结论四：ASDiv-a 提升幅度最小
> 该数据集题目较简单，多数问题无需复杂图结构推理即可解决，图方法的优势在**复杂推理场景**下更显著

---
### 5.3 消融实验

| 配置 | GSM8K | △ | SVAMP | △ | ASDiv-a | △ |
|---|---|---|---|---|---|---|
| 完整 GraphReason | 85.7 | — | 85.4 | — | 97.0 | — |
| 去掉 Base Verifier 语义特征 | 81.2 | -4.5 | 83.1 | -2.3 | 94.3 | -2.7 |
| 去掉分数求和（score sum） | 82.8 | -2.9 | 83.2 | -2.2 | 95.6 | -1.4 |
| 去掉推理图结构 | 85.4 | -0.3 | 84.8 | -0.6 | 96.9 | -0.1 |
**数据说明了什么:**

> [!success] 语义特征最关键
> 去掉 Base Verifier 语义特征后下降最大（GSM8K -4.5%），说明当前方法对语义信息的依赖仍然较强，图结构信息是**在语义基础上的增量收益**，而非替代

> [!success] 图结构有效但提升有限
> 去掉推理图结构后仅下降 0.1%～0.6%，原因：语义信息与结构信息**未能同步联合建模**，存在训练 gap；图分类任务本身复杂度较高，训练数据中噪声较多，限制了图结构的充分发挥

> [!note] 三个组件缺一不可
> 任意移除一个组件均导致性能下降，证明完整框架设计的合理性

---
### 5.4 跨 LLM 泛化实验

| 方法 | GPT-3.5-turbo | GPT-4 | PaLM-2 |
|---|---|---|---|
| Greedy Decode | 72.7 | 87.0 | 53.0 |
| Voting | 82.3 | 94.0 | 71.0 |
| Simple Verifier | 66.9 | 89.0 | 36.0 |
| Voting Verifier | 85.4 | 97.0 | 77.0 |
| DIVERSE | 85.0 | 97.0 | 75.0 |
| **GraphReason** | **85.7** | 94.0 | **78.0** |

> [!warning] GPT-4 上的异常
> GraphReason 在 GPT-4 上（94.0%）低于 Voting Verifier（97.0%），原因：verifier 训练数据来自 GPT-3.5-turbo，GPT-4 的推理模式与 GPT-3.5 存在分布偏移，跨模型迁移能力有待提升

> [!success] PaLM-2 上仍保持最优
> GraphReason（78.0%）超过 Voting Verifier（77.0%），说明在推理模式差异不太极端的情况下，图结构方法具备一定泛化性

---
## 5.5 局限性
### 5.5.1 局限一：计算开销大

- 依赖 GPT-3.5 级别的 LLM 进行大量采样（30 条路径/问题）
- 推理成本与时间显著高于微调小模型方案
### 5.5.2 局限二：依赖带标注的 CoT 数据

- GraphReason 训练需要带推理路径标注的数据
- 当前使用 LLM 输出作为伪标注，引入较多噪声
- 若能提供人工标注的推理图，性能有望大幅提升
### 5.5.3 局限三：非算术推理任务泛化困难

- 图构建的合并操作依赖**明确的算术表达式匹配**
- 在常识推理、归纳推理等任务中，"相似步骤"的识别本身就是难题
- 当前方法对推理步骤结构化程度要求较高
### 5.5.4 局限四：跨 LLM 迁移能力不稳定

- Verifier 训练数据与目标 LLM 绑定，不同 LLM 的推理模式差异会导致性能下降
- GPT-4 实验已暴露此问题

---
## 5.6 结论总结

> [!abstract] 一句话结论
> GraphReason 通过将 LLM 多条推理路径建模为推理图，首次从**图结构视角**捕捉跨路径的步骤逻辑关联，在不修改 LLM 的前提下，在算术推理和常识推理任务上均达到 verifier 方法的 SOTA，但图结构收益的充分释放仍受限于**语义- 结构联合建模能力**与**训练数据质量**