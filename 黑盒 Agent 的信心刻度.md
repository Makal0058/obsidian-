> [!info] 基本信息
> - **论文题目**：Efficient Non-Parametric Uncertainty Quantification for Black-Box Large Language Models and Decision Planning
> - **中文题目**：给黑盒大模型做低成本不确定性估计，并用于 Agent 的逐步决策规划
> - **期刊/会议**：ICML 
> - **年份**：2024
> - **主题**： #不确定性量化 #LLM决策规划 #黑盒LLM #Agent设计

---
```table-of-contents
```
---
# 一、研究背景（前人做到哪一步）

## 1.1 LLM 驱动的 step-by-step 决策规划

LLM 在 AI agent 决策规划领域已有广泛应用，覆盖机器人控制、工作流自动化、医疗等场景。核心范式是：以 LLM 为认知中枢，基于当前观测、历史记录和目标描述逐步生成动作

---
## 1.2 不确定性量化的必要性

LLM 存在 hallucination 问题——对错误输出过度自信。在决策规划场景中，早期的错误决策会级联影响后续步骤，危害尤为严重。不确定性量化是缓解这一问题的主要手段

---
## 1.3 前人方法的两条路线及其局限

### 1.3.1 白盒方法（需要访问模型内部）

- 利用 token logits 计算输出生成概率
- 做 out-of-distribution 检测
- 让 LLM 自我评估输出正确性

瓶颈：依赖 logits 或内部层输出，对 GPT-4 等闭源模型不可用
### 1.3.2 **黑盒方法**（仅用文本输出）

- 代表工作：Lin et al. (2023)——对同一输入多次采样，通过比较不同响应之间的相似度来估计输出概率 p(y∣x)p(y|x) p(y∣x)

瓶颈：

1. 多次推理开销大，调用商业 API 成本高

2. "响应相似度"本身定义模糊，引入额外不确定性

---
## 1.3 前人在 agent 设计上的局限

现有决策规划工作（RT-2、PaLM-E 等）每次推理只生成**单个** action，效率较低；且普遍缺乏系统性的不确定性感知机制，无法在模糊情况下主动向用户寻求澄清

---
## 1.4 本文切入点

在预算约束下使用黑盒 LLM，同时实现**高效**（单次推理）、**有统计保证**的不确定性量化，并在此基础上构建完整的交互式决策 agent

---
# 二、拟解决的问题（为什么现有方法不行）

## 2.1 现有方法的核心矛盾

决策规划场景对不确定性量化有实际需求，但现有两条路线都有硬伤，且硬伤方向相反：
### 2.1.1 白盒方法：能用但用不了

技术上是可行的——logits 信息丰富，置信度估计相对准确

问题是**访问权限**：GPT-4、Claude 这类最强的闭源模型根本不暴露 logits。工业界 agent 开发的现实是预算有限、倾向用最强的商业模型，白盒方法在这个场景下直接出局

---
### 2.1.2 黑盒方法：能用但太贵

以 Lin et al. (2023) 为代表：对同一输入多次采样，比较响应之间的语义相似度来估计 $p(y|x)$

两个具体问题：

1. **计算开销**：每次不确定性估计需要多次推理，调商业 API 按 token 计费，成本直接乘以采样次数。step-by-step 规划每一步都要估计，开销累积不可忽视

2. **相似度定义模糊**：用响应间相似度代理置信度，本身引入了新的不确定性——什么叫"两个回答相似"？语义相似还是字面相似？这个问题没有公认答案，整个估计链条的可靠性因此存疑

---
## 2.2 两个问题叠加的实际后果

在预算受限 + 使用黑盒 LLM 的场景下，现有方法要么不能用，要么用了太贵且不可靠。结果是：工业界 agent 开发实际上在**没有不确定性估计的情况下裸跑**，hallucination 风险完全暴露

---
## 2.3 本文的问题定位

用一次推理、不需要 logits、有统计解释性的方式估计置信度——三个约束同时满足，缺一不可。这就是 point-wise dependency + conformal prediction 这套方案的出发点

---
# 三、创新点与贡献

## 3.1 面向黑盒 LLM 的高效不确定性量化方法

### 3.1.1 技术路线

用辅助神经网络估计 $point-wise\ dependency\ r(x,y) = \frac{p(x,y)}{p(x)p(y)}$​，训练目标是 $relative\ predictive\ coding$（密度比拟合的稳定版本）。部署时单次推理出结果，不需要 logits，不需要多次采样
### 3.1.2 相比前人的增量在哪

|           | 白盒方法 | Lin et al. 黑盒 | 本文           |
| --------- | ---- | ------------- | ------------ |
| 需要 logits | ✓    | ✗             | ✗            |
| 单次推理      | ✓    | ✗             | ✓            |
| 统计解释性     | 弱    | 弱             | ✓（依赖强度有明确定义） |
| 相似度模糊性    | 无    | 有             | 无            |

**核心增量：** 在黑盒约束下，同时实现了单次推理和有统计解释性的置信度信号，两个条件之前没有工作同时满足
### 3.1.3 配合 conformal prediction

在 calibration 数据上标定阈值，给"真实动作落在候选集内"这件事提供概率保证（论文中 $\geq 80\%$ ）。把启发式的阈值选择变成了有统计背书的决策

---
## 3.2 完整的交互式决策 Agent 设计

### 3.2.1 相比前人 agent 工作的增量

前人工作（RT-2、PaLM-E 等）每次推理生成单个动作，本文的 fine-tuning 设计让模型**单次推理生成所有候选动作**，再由 estimator 过滤。推理次数从 $O(n)$  降到 $O(1)$ 
### 3.2.2 人机交互机制

不确定性估计直接驱动交互逻辑：

- 单个动作超过阈值 → 自动执行
- 多个动作超过阈值 → 请用户选择
- 无动作超过阈值 → 停止

把 hallucination 的处理从被动（事后检测）变成了主动（实时向用户寻求澄清），这个设计思路本身有参考价值

---
## 3.3 贡献的边界

两个贡献都有场景依赖性：动作空间必须是**结构化离散集合**，方法才能保持简洁。这既是论文设计干净的原因，也是推广到开放域任务时需要额外工作的地方

---
# 四、方法与模型

## 4.1 整体架构

三阶段流水线：数据收集 → 模型训练 → 部署。两个核心模块并行训练：决策 agent（Mistral-7B fine-tune）和 point-wise dependency 估计器（辅助神经网络）

---
## 4.2 决策 Agent

### 4.2.1 训练方式

Instruction fine-tuning，基座是 Mistral-7B-Instruct-v0.1，不使用 logits，纯黑盒
### 4.2.2 两阶段 fine-tuning 设计

第一阶段：只给用户请求，输出单个动作

```
[INST] You are a home assistant, and you receive a command: water the plants.
Please deploy your next action: [/INST]
<ACT> outdoor lights: on </ACT>
```

第二阶段：加入历史动作，输出下一个动作

```
[INST] You are a home assistant, and you receive a command: water the plants.
You deployed <ACT>outdoor lights: on</ACT>, <ACT>outdoor speaker: play laid-back music</ACT>.
Please deploy your next action: [/INST]
<ACT> smart sprinkler: on </ACT>
```
### 4.2.3 推理时的关键设计

自回归解码的副产品——训练时动作一个个生成，推理时**单次推理自动输出所有候选动作**，不需要多次调用

---
## 4.3 Point-wise Dependency 估计器

### 4.3.1 估计目标

$$r(a, x') = \frac{p(a, x')}{p(a)p(x')}$$

其中 $x'$ 是用户请求 + 历史动作的拼接，$a$ 是当前候选动作
### 4.3.2 网络结构

$$r^*_\theta(a, x') = \langle f^l_a \circ f^g_a \circ f^{llm}(a),\ f^l_x \circ f^g_x \circ f^{llm}(x') \rangle$$

- $f^{llm}$：Mistral-7B 提取 token 级别表示（共享，不更新）
- $f^g_a / f^g_x$：GRU，在序列维度上聚合
- $f^l_a / f^l_x$：全连接层，取 GRU 最后一个隐状态
- 最终内积得到标量

可训练参数只在 GRU 和 FC 层，LLM 部分冻结
### 4.3.3 训练目标

Relative predictive coding（密度比拟合的稳定版本）：

$$\sup_\theta\ \mathbb{E}_{P_{AX'}}[r^*_\theta(a,x')] - \alpha \mathbb{E}_{P_A P_{X'}}[r^*_\theta(a,x')] - \frac{\beta}{2}\mathbb{E}_{P_{AX'}}[r^{*2}_\theta] - \frac{\gamma}{2}\mathbb{E}_{P_A P_{X'}}[r^{*2}_\theta]$$

- $(a, x') \sim P_{AX'}$：正样本，真实配对
- $(a, x') \sim P_A P_{X'}$：负样本，随机配对
- 超参数固定：$\alpha=1.0,\ \beta=0.005,\ \gamma=0.1$

最终恢复：$r_\theta(a, x') = \frac{\gamma r^*_\theta(a,x') + \alpha}{1 - \beta r^*_\theta(a,x')}$

---
## 4.4 Conformal Prediction 标定阈值

在 calibration 数据上：

1. 定义 non-conformity score = $50 - r_\theta(a, x')$
2. 取 $1-\epsilon$（即80%）分位数，得到阈值 1.627
3. 统计保证：测试时真实动作落在 $\{a \mid r_\theta(a, x') \geq 1.627\}$ 内的概率 $\geq 80\%$

---
## 4.5 部署逻辑

```
用户输入请求
    ↓
LLM 单次推理，生成所有候选动作
    ↓
估计器计算每个候选的 r(a, x')
    ↓
与阈值比较
    ├── 多个超过阈值 → 展示给用户选择
    ├── 一个超过阈值 → 自动执行，追加到历史
    └── 无超过阈值  → 停止
```

循环直到停止条件触发

---
# 五、实验与结论（数据说明了什么、有什么局限性）
## 5.1 实验设置

**数据**：20k 条 (用户请求, 动作集合) 对，按 10:1:2 划分训练/校准/评估集。平均每条请求对应 3.1 个动作

**评估指标**：精确匹配（exact match），严格——"play soft sounds" ≠ "play soft music"。计算 mean precision、mean recall、F1

**三个实验问题**：
- Q1：step-by-step 规划 vs all-at-once 生成
- Q2：最优动作选择策略
- Q3：阈值高低对性能的影响

---
## 5.2 Q1 & Q2：规划方式的影响（Table 1，阈值统一为 1.0）

| 指标 | All-at-once | Step-by-step 随机选 | Step-by-step 选最大 |
|---|---|---|---|
| Mean Precision | 0.108 | 0.126 | 0.134 |
| Mean Recall | 0.200 | 0.193 | 0.212 |
| F1 | 0.140 | 0.152 | 0.164 |

**数据说明了什么**

Step-by-step 在 F1 上全面优于 all-at-once，原因是历史动作提供了额外上下文，类似 chain-of-thought 的增益——决策不是孤立的，前序动作约束了后续动作的合理范围

选 point-wise dependency 最大的动作优于随机选，说明 $r(a, x')$ 确实是真实动作的有效排序信号，不是噪声

---
## 5.3 Q3：阈值的影响（Table 2）

| | $t=0.0$ | $t=1.0$ | $t=1.627$ |
|---|---|---|---|
| **All-at-once** | | | |
| Mean Precision | 0.083 | 0.108 | 0.127 |
| Mean Recall | 0.235 | 0.200 | 0.167 |
| F1 | 0.127 | 0.140 | 0.144 |
| **Step-by-step 最大** | | | |
| Mean Precision | 0.123 | 0.134 | 0.139 |
| Mean Recall | 0.232 | 0.212 | 0.209 |
| F1 | 0.162 | 0.164 | 0.167 |

**数据说明了什么**

阈值升高 → precision 升、recall 降、F1 小幅升，规律符合预期。更重要的是 precision 的提升——说明 $r(a,x')$ 作为过滤器是有效的，高分动作确实更可能是真实动作

conformal prediction 给出的统计保证（$\geq 80\%$）与 exact match 指标之间**相关性弱**。论文自己承认这一点，原因是 exact match 太严格，语义正确但措辞不同的动作全算错

---
## 5.4 局限性

1. **评估指标太严格：** Exact match 无法区分语义正确和字面错误。实际性能可能被低估，但现有数字缺乏说服力。论文提到未来会加语义相似度评估和人类研究，但本文没做

2. **绝对数值偏低：** F1 最高只有 0.167，precision 最高 0.139。即使考虑 exact match 的严苛性，数字仍然不高。论文没有充分讨论这个问题。

3. **场景限制：** 动作空间是预定义的结构化离散集合，智能家居场景天然适配。换到开放域任务，整套方法的简洁性不再成立

4. **数据规模：** 20k 条数据是合成标注的，分布单一，泛化能力存疑。没有在其他数据集上验证

5. **没有人在环的实验：** Q2 的最优策略分析完全基于自动评估。论文承认缺少真实用户参与的人类研究，交互设计的实际有效性没有验证

---
## 5.5 总结

论文的核心结论成立：step-by-step 优于 all-at-once，$r(a,x')$ 是有效的排序信号，阈值升高提升 precision。但绝对性能数字偏低、评估体系单一、场景局限是三个明显的短板，限制了结论的普适性。