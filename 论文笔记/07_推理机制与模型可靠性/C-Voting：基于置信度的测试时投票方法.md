> [!info] 基本信息
> - **论文题目**：C-VOTING: Confidence-Based Test-Time Voting Without Explicit Energy Functions
> - **中文题目**：C-Voting：一种不依赖显式能量函数的置信度测试时投票方法
> - **期刊/会议**：ICLR 
> - **年份**：2026
> - **主题**：#循环模型 #测试时推理 #推理扩展 #置信度估计 #轻量模型

---
```table-of-contents
```
---
# 一、研究背景（前人做到哪一步）
## 1.1 循环模型做推理：

前人已经证明循环模型（同一层反复迭代）在复杂推理任务上很有潜力，Universal Transformer、DEQ等工作奠基了这个框架。HRM和AKOrN是目前最强的两个，分别在Sudoku-extreme/Maze-hard和Sudoku-hard上达到SOTA

---
## 1.2 Test-time scaling：

LLM那边已经有self-consistency（多条chain-of-thought投票）、Tree of Thoughts等方法，核心思路都是**多采样+选最好的**。循环模型这边，增加迭代步数是一种scaling方式，但会饱和且无法并行

---
## 1.3 Voting策略：

AKOrN引入了E-voting——多随机初始化，选能量最低的轨迹，在Sudoku上带来约40%的准确率提升，效果显著。但问题是E-voting强依赖显式能量函数，而大多数有竞争力的模型（HRM、recurrent transformer）没有这个东西，直接堵死了这条路

---
## 1.4 前人留下的gap：

没有一个通用的、不依赖能量函数的voting策略，能跨模型使用。这篇论文就是填这个坑的

---
# 二、拟解决的问题（为什么现有方法不行）
## 2.1 现有方法的两个根本缺陷：
### 2.1.1 E-voting适用范围太窄

E-voting依赖显式能量函数，但大多数强模型（HRM、recurrent transformer）的迭代是残差结构$z_{t+1} = z_t + g(z_t)$ ，$g$是任意学出来的神经网络，不能写成某个标量的梯度，所以根本没有能量函数可用。这直接把E-voting锁死在AKOrN这一类特殊模型上

### 2.1.2 增加迭代步数这条路有天花板

加深递归是另一种test-time scaling方式，但性能会饱和——迭代到一定步数后再加也没用，而且无法并行，推理延迟线性增长

## 2.2 两个缺陷合起来的问题：
$$\begin{cases}想要voting → 只能用E-voting → 只能用AKOrN这类模型 \\想换更强的模型（HRM）→ 没有能量函数 → voting用不了，只能靠加步数 → 很快饱和 \end{cases}$$
也就是说，**现有方法里没有一个通用的、模型无关的voting策略**，导致test-time scaling的上限被模型架构绑死了。这篇论文要解决的就是这个绑定关系

---
# 三、创新点与贡献

## 3.1 提出C-voting

用模型输出的平均top-1概率作为置信度，选最高置信度的轨迹作为答案。不需要能量函数，任何从随机初始状态出发的循环模型都能用。这是核心贡献

---
## 3.2 证明C-voting比E-voting更好

在AKOrN上直接对比，C-voting在Sudoku-hard上比E-voting高4.9%。说明置信度是比能量更直接的代理指标，即使在能两种方法都能用的场景下，C-voting也是更优选择

---
## 3.3 设计了ItrSA++

为C-voting量身定制的轻量循环模型，约3M参数（HRM的1/9）。结构极简：随机初始化 → cross-attention混合输入 → 重复self-attention + SwiGLU → readout。配合C-voting在三个任务上全面超越HRM和AKOrN

---
## 3.4 揭示了C-voting的局限和机制

通过可视化分析指出：C-voting有效的前提是模型对错误预测的置信度低、对正确预测的置信度高。Maze-hard上提升有限，原因是模型对错误答案也很自信（miscalibrated），voting无法区分好坏轨迹。这个分析给后续研究指明了改进方向

---
# 四、方法与模型（框架图/公式/关键步骤）
## 4.1 C-voting 流程

1. 对同一道题，随机采 $K$ 个不同初始状态 $z_0^{(1)}, z_0^{(2)}, \ldots, z_0^{(K)}$
2. 每个初始状态各自跑完 $T$ 步迭代，得到 $K$ 条轨迹
3. 对每条轨迹计算置信度：$$C^{(k)} = \frac{1}{|L|}\sum_{l \in L} \max_j P_{j,l}(z_T^{(k)})$$4. 选置信度最高的轨迹作为答案：$$k^* = \arg\max_k C^{(k)}$$
---
## 4.2 ItrSA++ 结构

### 4.2.1 每步迭代做三件事，重复 $T$ 次：
1. 看题目：$$\tilde{z}_t = z_t + \text{CrossAttn}(z_t, x^{emb})$$当前想法$z_t$去看一眼题面$x^{emb}$，把题目信息吸收进来，更新成$\tilde{z}_t$
> 解题时瞄一眼已知条件

2. 内部推理：$$\bar{z}_{t,S} = \tilde{z}_t + \text{SelfAttn} \times S\text{次}$$吸收完题目信息后，隐状态内部各位置互相交流 $S$次——行跟列说话，列跟宫说话，检查约束关系
> 在脑子里把行列宫的限制梳理一遍

3. 深度加工：$$z_{t+1} = \bar{z}_{t,S} + \text{SwiGLU}(\bar{z}_{t,S})$$
做一次非线性变换，提炼出更有用的表示，准备下一轮迭代
> 把这一轮想到的东西消化吸收，准备下一轮再想

### 4.2.2 最后 readout：
$$\text{logit} = W_O \cdot \text{Norm}(z_T)$$

---
## 4.3 关键设计决策

- 初始状态随机采样，而非固定为0，这是 voting 多样性的来源
- cross-attention 每步都重新看题目，防止模型**忘记**输入
- 归一化方式用 RMSNorm，对性能影响显著
- 训练时用梯度截断（gradient truncation）稳定训练 

---
# 五、实验与结论（数据说明了什么、有什么局限性）
## 5.1 实验结论

### 5.1.1 C-voting vs E-voting（在AKOrN上）
- Sudoku-hard：C-voting 94.4% vs E-voting 89.5%，高4.9%
- Sudoku-extreme：C-voting同样更优
- 结论：置信度比能量更直接对应正确率，即使模型有能量函数也应该用C-voting

### 5.1.2 ItrSA++ vs HRM vs AKOrN

|任务|HRM|AKOrN|ItrSA++|
|---|---|---|---|
|Sudoku-hard|—|89.5%|94.4%|
|Sudoku-extreme|55.0%|—|95.2%|
|Maze-hard|74.5%|0%|78.6%|

3M参数打赢27M参数的HRM，参数量只有九分之一

### 5.1.3 K越大越好

随着随机样本数$K$增加，准确率持续提升，说明C-voting有稳定的scaling效果（投入越多，效果越好）

---
## 5.1 局限性

### 5.1.1 Maze上提升有限

根本原因是模型miscalibrated——对错误答案也很自信，置信度无法区分好坏轨迹。C-voting有效的前提是"错的不确定、对的确定"，Maze上这个前提不成立
### 5.1.2 HRM兼容性差

HRM原本用固定初始状态，强行引入随机初始化会破坏训练假设，导致隐状态不稳定，C-voting效果打折扣
### 5.1.3 计算量随K线性增长

样本数翻倍，计算量翻倍，推理成本不低
### 5.1.4 依赖模型calibration

理论保证建立在well-calibrated假设上，现实中不一定满足，是潜在的不稳定因素