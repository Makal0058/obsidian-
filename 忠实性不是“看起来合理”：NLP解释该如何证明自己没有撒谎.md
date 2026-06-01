> [!info] 基本信息
> - **论文题目**：Towards Faithfully Interpretable NLP Systems: How Should We Define and Evaluate Faithfulness?
> - **中文题目**：走向忠实可解释的自然语言处理系统：如何定义和评估忠实性？
> - **期刊/会议**：ACL 2020
> - **年份**：2020
> - **Tag**： #可解释性 #NLP #Faithfulness #Plausibility #研究背景 #深度学习 #模型解释

---
```table-of-contents
```
---
# 一、研究背景（前人做到哪一步）

随着深度学习在NLP中的广泛应用，模型可解释性（interpretability / explainability）研究迅速兴起。已有大量工作尝试定义"什么是好的解释"，但普遍存在以下问题：

## 1.1 概念混用问题

前人工作大多以特定use-case驱动，对解释质量的定义是ad-hoc的，且往往将以下三个性质混为一谈而不加区分：$$\begin{cases} Readability（可读性）：解释是否易于人类理解 \\ Plausibility（似真性）：解释是否令人信服、是否符合人类直觉 \\ Faithfulness（忠实性）：解释是否准确反映模型的真实推理过程 \end{cases}$$

> [!note] 术语说明 这三个概念在文献中命名不统一。Plausibility 也被称为 "human-interpretability"、"persuasiveness"；Faithfulness 也被称为 "fidelity"、"transparency"、"robustness"、"descriptive accuracy" 等

---
## 1.2 Faithfulness 缺乏统一定义

尽管部分工作隐式或显式地评估了faithfulness，但全领域内**没有一致且正式的faithfulness定义**。不同论文各自引入ad-hoc的测试，彼此不兼容，难以找到共性

---
## 1.3 已有评估路线及其局限

前人尝试过以下几类评估方式，但均存在问题：

|评估路线|代表工作|局限性|
|---|---|---|
|人类判断解释质量|多数early工作|人类无法判断faithfulness，只能判断plausibility|
|HCI / IUI用户任务表现|Feng & Boyd-Graber (2019)|用户表现提升只说明plausibility与模型性能相关，与faithfulness无关|
|"天然可解释"模型（如attention）|Ghaeini et al. (2018)|天然可解释性只是claim，需要验证；近期工作已对attention的faithfulness提出质疑|
|二值化faithful/not faithful判定|大多数工作|门槛过高，几乎所有方法都会被反例推翻，陷入"不断证伪"的死循环|

---
## 1.4 "证伪文化"的流行

当前文献中存在一个明显趋势：用**反例（counter-example）证明某方法不faithful**，然后就此停止。论文指出这种做法是无建设性的（unproductive）——因为任何解释方法本质上都是对真实推理过程的**近似**，严格意义上完全忠实的解释，就像“独角兽”一样，几乎找不到

因此作者主张不要再追求**二元判断**：$\begin{cases} faithful（忠实） \\ not\ faithful（不忠实） \end{cases}$

而应该改成**灰度判断**： **在什么任务、什么模型、什么输入范围内，它有多大程度 faithful**

---
# 二、拟解决的问题（为什么现有方法不行）

## 2.1 核心矛盾：Faithfulness 与 Plausibility 被混为一谈

现有方法最根本的问题在于**没有将 faithfulness 与 plausibility 显式区分**，导致评估结论相互污染

两者定义上截然不同：$\begin{cases} Plausibility：解释是否令人信服（面向人类感知） \\ Faithfulness：解释是否准确反映模型的真实推理过程（面向模型内部） \end{cases}$

> [!warning] 关键风险
> 两者完全可以独立成立：一个解释可以非常令人信服（high plausibility）但完全不反映模型实际决策过程（low faithfulness），反之亦然
> 
> 典型例子：post-hoc 文本生成式解释（额外训练一个 generator 输出自然语言解释），plausibility 是主导目标，**没有任何 faithfulness 保证**。

**混淆的后果是灾难性的**。以累犯预测（recidivism prediction）为例：法官看到模型预测及其解释，并相信该解释反映了模型推理过程。若解释看起来合理但实为unfaithful，则会产生法律后果——这是最坏情形

---
## 2.1 现有评估方式的具体缺陷
### 2.1.1 用人类判断来评估 Faithfulness

**问题**：
- 人类根本无法判断一个解释是否 faithful：如果人类能理解模型，就不需要解释了
- 出于同样原因，也无法为此问题获取监督信号
- 人类判断本质上只能衡量 plausibility，而非 faithfulness
### 2.1.2 用人类标注的金标签（gold labels）来评估

**问题**：
- 评估方法依赖金标签，会引入人类对"模型应该怎么做"的先验
- 这将评估推向 plausibility 方向
- 应当能对**错误的模型预测**同样进行解释和评估，不能只评估正确预测
### 2.1.3 无条件信任"天然可解释"模型

**问题**：
- "inherently interpretable" 只是一个 claim，需要验证才能信任
- Attention mechanism 曾被认为天然可解释，但近期工作（Jain & Wallace 2019；Serrano & Smith 2019；Wiegreffe & Pinter 2019）对其 faithfulness 提出严重质疑
- 天然可解释模型的解释必须与 post-hoc 方法接受**同等标准**的 faithfulness 评估
### 2.1.4 用 HCI / IUI 场景下的用户任务表现来评估

**问题逻辑链**：

$$\text{用户表现提升} \;\not\Rightarrow\; \text{解释 faithful}$$

用户表现提升只说明：plausibility 与模型性能之间存在某种相关性。哪怕这个相关性极小，也会带来用户表现提升——与 faithfulness 完全无关

> [!example] 极端反例（论文虚构场景）
> 假设一个解释系统：
> - 模型预测**正确**时 → 解释随机高亮内容词（看起来合理）
> - 模型预测**错误**时 → 解释随机高亮标点符号（看起来可疑）
> 
> 用户会因为"正确预测时解释更好看"而表现更好。但解释完全不反映模型决策过程。→ **HCI评估通过，faithfulness为零**
### 2.1.5 用二值化标准（faithful / not faithful）来定性

**问题**：
- 几乎所有解释方法都能被反例推翻（proof by counter-example）
- 解释本质上是对真实推理过程的**近似**，必然损失信息
- 由鸽巢原理：输入空间足够大，必然存在解释与推理偏差的点
- 当前模型决策边界高度非线性、高维，adversarial / pathological 行为普遍存在
- 结果：领域陷入"不断证伪"的死循环，无建设性产出

> [!quote] 论文核心判断
> 严格意义上 faithful 的解释是一只"独角兽"——几乎不可能找到，继续用二值标准评估只会持续产出负面结论

---
## 2.2 问题总结：两个层次的缺失

| 层次 | 缺失内容 |
|---|---|
| **概念层** | Faithfulness 没有统一、正式的定义；与 plausibility 长期混用 |
| **评估层** | 没有合适的评估方法；现有方法要么测的是 plausibility，要么门槛过高导致一切方法都失败 |

这两个缺失共同导致：领域无法判断"一个解释方法在实践中是否足够 faithful 到有用"

---
# 三、创新点与贡献

## 3.1 贡献概览

本文是一篇 **opinion paper**，不提出新模型或新算法，核心贡献在于：

1. 对 faithfulness 的定义进行系统梳理，提炼出三条隐含假设
2. 提出评估 faithfulness 的具体操作准则
3. 呼吁放弃二值化 faithfulness 标准，转向更实用的"灰度"标准

---
## 3.2 创新点
### 3.2.1 提炼 Faithfulness 的三条隐含假设

现有工作对 faithfulness 的定义各自为政，本文通过文献梳理，将所有评估方法统一到**三条底层假设**之下，实现了对看似无关的评估方法的统一描述框架

1. **Assumption 1：The Model Assumption（模型假设）**

>[!note] 
>**两个模型做出相同预测，当且仅当它们使用了相同的推理过程**

**推论 1.1**：若一个解释系统对做出相同决策的两个模型给出不同解释，则该解释系统是 unfaithful 的

**推论 1.2**：若一个解释本身作为模型，其决策与被解释模型不同，则该解释是 unfaithful 的

>解释模型像是原模型的“翻译版”。如果原模型说：**A**，解释模型却说：**B**，那这个解释模型就不是在忠实翻译原模型，而是在讲自己的东西。所以这句话的核心是：**解释如果不能复现被解释模型的决策，就不能声称自己忠实解释了那个模型**

**对应评估方法**：

- **Fidelity**：当解释本身是可计算模型时（如决策树、规则列表），用解释模型能否模拟原模型决策的准确率来度量
- **Forward simulation**（Doshi-Velez & Kim 2017）：让人类仅凭输入+解释来模拟模型决策，不接触模型本身
- **对抗训练反例**（Wiegreffe & Pinter 2019）：训练能模仿原模型决策但给出不同解释的对抗模型，以此证伪 faithfulness

2. **Assumption 2：The Prediction Assumption（预测假设）**

>[!note] 
> **对于相似的输入，模型做出相似的决策，当且仅当其推理过程相似**

**推论 2**：若解释系统**对相似的输入和输出给出不同的解释**，则该系统是 unfaithful 的

**对应评估方法**：
- **输入扰动测试**（Kindermans et al. 2019）：对输入空间引入常数偏移，观察决策不变时解释是否也不变
- **Interpretability robustness**（Alvarez-Melis & Jaakkola 2018）：解释应对输入的小扰动保持不变
- **Explanation consistency**（Wolf et al. 2019）：解释相对于模型的一致性

> [!note] NLP中的局限
> 由于NLP输入是离散的，robustness 类方法在NLP场景中较难直接应用

3. **Assumption 3：The Linearity Assumption（线性假设）**

> [!note] 
> **输入的某些部分对模型推理比其他部分更重要，且不同部分的贡献相互独立**

**推论 3**：在特定条件下，热力图（heat-map）类解释可以是 faithful 的

>热力图解释只有在模型决策接近**各部分独立加权求和**时，才可能 faithful；如果模型依赖复杂交互、上下文、否定、多步推理，热力图就很容易不忠实。比如句子：这部电影不是很好。如果热力图只高亮 **“好”**，看起来像正面评价，但真正关键其实是：**不是 + 好**。这两个词组合起来才表达负面或弱正面。这时**每个词独立贡献**的假设就坏掉了

**对应评估方法**（以 attention map 为代表）：
- **Erasure（擦除法）**：擦除"最相关"部分 → 期望模型决策改变；擦除"最不相关"部分 → 期望模型决策不变（Arras et al. 2016；Feng et al. 2018；Serrano & Smith 2019）
- **Comprehensiveness & Sufficiency**（Yu et al. 2019；DeYoung et al. 2019）：作为 erasure 的形式化推广，分别度量移除高排名特征 / 仅保留高排名特征对模型的影响程度

> [!warning] 注意
> 本文作者明确指出**不一定背书**线性假设——它在近期工作中已受到合理质疑，但仍被部分文献所使用，故纳入框架
### 3.2.2 提出 Faithfulness 评估的操作准则

针对现有评估的系统性缺陷，本文给出五条具体准则：

| 准则                             | 核心内容                                                      |
| ------------------------------ | --------------------------------------------------------- |
| **显式声明评估目标**                   | 明确说明评估的是 faithfulness 还是 plausibility，不得混用                |
| **不得引入人类判断**                   | 人类判断只能衡量 plausibility；faithfulness 评估应完全排除人类主观判断          |
| **不得依赖金标签**                    | 金标签引入人类先验，会将评估推向 plausibility；应能评估错误预测的解释                 |
| **不信任天然可解释性声明**                | inherently interpretable 只是 claim，必须与 post-hoc 方法接受相同评估标准 |
| **不用 IUI 用户表现衡量 faithfulness** | 用户表现只反映 plausibility 与模型性能的相关性，与 faithfulness 无关          |
>金标签：人工标注的标准答案

>**不用 IUI 用户表现衡量 faithfulness**：**不能因为“用户用了这个解释后任务做得更好”，就说这个解释是 faithful 的 
>IUI** 是：**智能用户界面**，也就是模型辅助人类做决策的交互系统
>比如一个问答系统给用户答案，同时给解释。然后实验发现：用户看到解释后，答题准确率提高了。这只能说明：这个解释**对用户有帮助**，或者让用户更信任模型。但不能说明：这个解释真实反映了模型内部推理过程
### 3.2.3 呼吁从二值 Faithfulness 转向灰度标准

本文最具前瞻性的贡献是指出：**严格 faithful 是不可达的目标**，应以"在实践中足够 faithful 到有用"替代。

提出两个灰度化的具体方向：

#### 方向一：跨模型与任务的灰度（Across models and tasks）

某些模型或任务可能允许足够 faithful 的解释，即使在其他任务上不成立。

$$\text{Faithfulness degree} = f(\text{model}, \text{task})$$

> [!example]
> 某解释方法对情感分析任务可能足够 faithful，对问答任务则不然——基于各任务的句法与语义属性差异。

#### 方向二：跨输入空间的灰度（Across input space）

在输入空间的特定子空间（相似输入的邻域，甚至单个输入）上，若能以一定置信度判断该决策的解释是 faithful 的，则可限定范围使用

$$\text{Faithfulness degree} = g(\text{input subspace or instance})$$

> [!quote] 论文对社区的挑战性命题
> 必须开发出正式的 faithfulness 定义与评估方法，使我们能够判断一个方法**在实践中是否足够 faithful 以有用**——这是作者向领域提出的核心未解问题。

---

### 3.5 贡献总结

贡献一：概念澄清 └── 明确区分 faithfulness vs. plausibility └── 梳理三条隐含假设，统一现有评估框架

贡献二：评估准则 └── 五条操作性准则，指出现有评估的具体缺陷

贡献三：范式转变呼吁 └── 放弃二值标准 → 转向灰度 faithfulness └── 提出两个灰度化方向作为未来研究挑战

---
# 四、方法与模型
## 4.1 