> [!info] 基本信息
> - **论文题目**：Parallel Test-Time Scaling for Latent Reasoning Models
> - **中文题目**：面向潜在推理模型的并行测试时扩展
> - **期刊/会议**：ACL 2026（Long Papers）
> - **作者**：Runyang You, Yongqi Li, Meng Liu, Wenjie Wang, Liqiang Nie, Wenjie Li
> - **Tag**：#潜在推理 #测试时扩展 #并行推理 #随机采样 #潜在奖励模型 #思维链
```table-of-contents
```
# 一、研究背景（前人做到哪一步）
## 1.1 Test-Time Scaling 已成为提升推理能力的重要方法

Test-Time Scaling（TTS）通过在**推理阶段投入更多计算资源**来提升模型性能，而不需要重新训练模型。现有 TTS 主要沿两个方向发展：

1. **Sequential Scaling**：让单条推理链变得更长。
2. **Parallel Scaling**：同时生成多条推理轨迹，再通过 Majority Voting、Best-of-N 或搜索等方法进行聚合。

其中，并行 TTS 已经在传统 token-based reasoning 中被广泛使用。
## 1.2 Token-based CoT 天然适合并行采样

在传统 Chain-of-Thought 中，模型每一步都会输出一个 token 概率分布，因此可以直接利用 **top-k、nucleus sampling 等随机采样方法**生成多条不同的推理轨迹。

生成多条轨迹后，还可以利用：

- Majority Voting
- Best-of-N
- Guided Search

注：
- Majority Voting：大家投票  
- Best-of-N：找裁判挑最好的一条
- Guided Search：生成过程中就不断判断哪条路更有希望。

等方法选出更好的答案，从而将额外的推理计算转化为性能提升。
## 1.3 Latent Reasoning 开始替代显式 token 推理

近年来，研究开始从显式 CoT 转向 **Latent Reasoning / Continuous CoT**。

这类方法不要求模型每一步都生成自然语言 token，而是直接使用**连续向量**作为中间推理状态。与显式 CoT 相比，latent reasoning 更紧凑、计算效率更高，并可能表示一些难以用自然语言表达的抽象推理模式。

例如：
- **COCONUT**：使用最后一个 hidden state 作为下一步 latent thought，并通过 curriculum learning 训练；
- **CODI**：利用 self-distillation 学习 latent autoregressive reasoning；
- **CoLaR**：进一步引入动态 latent compression。

注：
1. **COCONUT：把上一轮的 hidden state 直接当下一轮“想法”**
普通 CoT 是 $\text{hidden state} \rightarrow \text{token} \rightarrow \text{embedding} \rightarrow \text{下一步}$；COCONUT 则直接跳过“说成 token”这一步 $h_t \rightarrow h_{t+1}$，也就是当前 Transformer 最后的 hidden state，直接作为下一步 latent thought 的输入。

这里的 **curriculum learning（课程学习）** 可以理解成不一上来就让模型完全在 latent space 里思考，而是逐渐增加 latent reasoning 的比例，让模型慢慢适应。
2. **CODI：让 latent reasoning 去模仿原来的 CoT**

模型原本会用文字 CoT 解题，现在让 latent hidden states 学着复现这种推理过程，也就是 $\text{显式 CoT} \rightarrow \text{作为教师信号} \rightarrow \text{训练 latent reasoning}$

所以 **self-distillation** 的核心就是用模型自己已有的显式推理能力，去教自己的 latent reasoning。
3. **CoLaR：不只 latent reasoning，还动态决定“压缩多少”**

前两个方法更关注“**怎么让模型在 latent space 里面连续推理？**“，CoLaR 又往前走一步：**latent reasoning 应该压缩到多短？应该思考多少步？**

比如原来的显式 CoT 可能需要 $10\text{ 个 reasoning steps}$，CoLaR 可能学会压缩成 $2\text{ 个 latent thoughts}$，或者问题复杂一点 $5\text{ 个 latent thoughts}$。而不是所有题固定思考同样长度。论文后面也提到，CoLaR 可以通过 “thinking speed” 控制 latent compression，并动态决定何时结束 latent reasoning。
## 1.4 Latent Reasoning 缺少天然的并行采样机制

虽然 latent reasoning 已经能够在连续空间中完成多步推理，但它并不像 token-based 模型那样天然拥有概率分布。

Token-based 模型可以直接从 $p(x_t\mid x_{<t})$ 中进行采样，但 latent reasoning 直接生成连续 hidden vector，因此**没有显式 token probability distribution**，也就缺少天然的随机采样机制，难以直接生成多条不同 latent reasoning trajectories。

注：
1. **token-based 模型**

假设模型下一步可能输出：$\begin{cases} P(A)=0.5 \\ P(B)=0.3 \\ P(C)=0.2 \end{cases}$，那么你可以每次从这个概率分布里随机采样。
- 第一次可能得到：$A\rightarrow D\rightarrow F$
- 第二次可能得到：$B\rightarrow E\rightarrow G$
- 第三次可能得到：$A\rightarrow H\rightarrow I$

所以只要把同一道题跑很多次，就天然能得到：$\text{trajectory}_1,\text{trajectory}_2,\ldots,\text{trajectory}_N$

这就是为什么 token-based CoT 很容易做 parallel sampling。
2. **latent reasoning 模型**

假设当前 latent thought 是 $h_t=[0.31,-0.72,1.05,\ldots]$，模型直接算 $h_{t+1}=f_\theta(h_{1},x)$。如果模型参数、输入和当前状态都一样，那么通常得到的就是**同一个 $h_{t+1}$**，也就是 $h_t \rightarrow h_{t+1} \rightarrow h_{t+2} \rightarrow \cdots$。

它不像 token 模型那样有 $P(h_{t+1}=A),P(h_{t+1}=B),P(h_{t+1}=C)$ 这样的显式概率分布可以直接抽样。
3. **“缺少天然采样机制”不是说完全没法采样**

这个词 **“天然”特别重要**。不是说 latent reasoning **不能**产生多条轨迹，而是说 latent reasoning **本身没有现成的概率分布供你直接随机抽样**，所以必须人为加入随机性。于是这篇论文才提出 $h_t+\epsilon,\epsilon\sim\mathcal N(0,\sigma^2I)$，也就是 **Gaussian Noise**；或者让每次推理使用不同 dropout mask，也就是 **MC-Dropout**。

这样原本 $h_t\rightarrow h_{t+1}$ 就能变成 $h_t \rightarrow \begin{cases} h_{t+1}^{(1)}\ h_{t+1}^{(2)}\ h_{t+1}^{(3)} \end{cases}$，人为造出不同 latent trajectories。
## 1.5 Latent Trajectory 也缺少有效的评分与聚合机制

即使能够生成多条 latent trajectories，还存在第二个问题：**怎么判断哪条 latent trajectory 更好？**

传统 token-based TTS 可以利用 token likelihood 等概率信号对轨迹进行排序，而 latent trajectory 本身只是连续向量，没有天然的：likelihood、step-wise probability、trajectory score，因此传统的 Best-of-N 或 Beam Search 不能直接应用。

注：
1. **likelihood** 
在 token 模型里，一条生成轨迹例如 $x_1,x_2,x_3$，它天然有概率 $p(x_1,x_2,x_3) = p(x_1),p(x_2|x_1),p(x_3|x_1,x_2)$，或者通常取 log，$\log p(x_1,x_2,x_3) = \sum_t \log p(x_t|x_{<t})$。

所以你可以说这条轨迹 likelihood 高，那条轨迹 likelihood 低。但 latent reasoning 里是连续向量 $h_1,h_2,h_3$，模型通常只是直接算 $h_{t+1}=f_\theta(h_{1},x)$，并没有显式告诉你 $p(h_{t+1}|h_{1})$ 是多少。
2. **step-wise probability** 
这个更简单，就是**当前这一步有多“可信”**。Token 模型每一步都有 $p(x_t|x_{<t})$，比如 $P(A)=0.8,\quad P(B)=0.15,\quad P(C)=0.05$，所以第 $t$ 步天然就能得到一个概率。

但 latent reasoning 的一步是 $h_t\in\mathbb R^d$，它不是从一个显式离散概率分布里采出来的，因此通常没有一个现成的 $P(h_t)=0.87$ 这样的数。
3. **trajectory score** 
就是给整条推理轨迹一个总分 $S(h_{1})$，在 token 模型中可以直接用 $S=\sum_t\log p(x_t|x_{<t})$，或者再加 reward model / verifier。但 latent reasoning 如果没有额外设计 scorer，就没有天然的 $S(h_{1})$
## 1.6 已有随机化探索仍然比较初步

此前已经有一些工作开始尝试让 latent reasoning 具有随机性，例如 **CoLaR** 和 **SoftCoT++** 尝试向 latent reasoning 中注入噪声，从而产生不同的推理轨迹，但论文认为这些工作仍处于比较初步的阶段

因此，当前仍然缺少一个完整的 $\text{Latent Sampling} + \text{Trajectory Aggregation}$ 框架。
## 1.7 本文要解决的核心问题

因此，这篇论文关注的问题可以概括为**如何把 token-based reasoning 中成熟的 Parallel Test-Time Scaling，迁移到连续的 latent reasoning 空间**？

具体分为两个核心问题：

1. **如何在 continuous latent space 中有效采样多条不同的 reasoning trajectories？**
2. **如何对这些 latent trajectories 进行评分、选择和聚合？**

论文正是围绕这两个问题，分别提出 **stochastic latent sampling** 和 **Latent Reward Model（LatentRM）**。
# 二、创新点与贡献
## 2.1 首次将 Parallel Test-Time Scaling 引入 Latent Reasoning

本文最核心的贡献，是把原本主要用于 **token-based reasoning** 的并行 Test-Time Scaling 扩展到 **continuous latent space**。

传统 Parallel TTS 依赖 token 概率分布来 $\text{采样多条轨迹} \rightarrow \text{对轨迹进行评分/聚合}$，但 latent reasoning 中间状态是连续向量，缺少天然的随机采样和评分机制。本文围绕这两个缺口构建了一套完整的 latent parallel TTS 框架。
## 2.2 提出两种 Stochastic Latent Sampling 方法

为了解决**如何在 continuous latent space 中生成多条不同的推理轨迹**，论文提出两种随机采样方法：
1. **Monte Carlo Dropout**
在 inference 阶段保持 Dropout 开启，每次 forward 使用不同的 dropout mask $h_{t+1}^{(n)} = f_{\theta^{(n)}}(h_{1}^{(n)},x)$，从而让相同输入产生不同 latent trajectories。

注：**Dropout 是一种防止神经网络过拟合的训练技巧**，**训练时，每次随机把一部分神经元的输出暂时置为 0**。

比如原本某一层输出 $h=[1.2,\ 0.7,\ -0.4,\ 2.1,\ 0.9]$，假设 Dropout rate：$p=0.4$，意思是每个位置大约有 $40\%$ 的概率被随机“关掉”。这一次可能变成 $[1.2,\ 0,\ -0.4,\ 0,\ 0.9]$，下一次 forward 又重新随机 $[0,\ 0.7,\ -0.4,\ 2.1,\ 0]$，所以**每一次训练时，网络实际工作的部分都稍微不一样**。

**为什么要这么干**？如果没有 Dropout，一些神经元可能会形成很强的依赖“只要那个神经元告诉我结果，我就照着它来。”于是模型容易记住训练数据，产生 **overfitting（过拟合）**。

加 Dropout 后，由于你不知道哪个神经元下一次会突然被关掉，所以网络被迫**不要过度依赖某几个神经元，而是让信息分散到更多神经元中**。

有点像做小组作业，没有 Dropout：永远让一个学霸干全部工作；有 Dropout：今天学霸可能“请假”，其他人也必须学会干活 。所以模型通常会更 robust。

2. **Additive Gaussian Noise**
直接在 latent thought 上加入高斯噪声 $\epsilon_t^{(n)} \sim \mathcal N(0,\sigma^2I)$，$h_t^{(n)*} = h_t^{(n)}+\epsilon_t^{(n)}$。再基于扰动后的 latent state 继续推理。该方法用于模拟 **aleatoric uncertainty**。

因此，原本近似确定性的 latent reasoning $x\rightarrow h_1\rightarrow h_2\rightarrow\cdots$ 可以扩展成 $x \rightarrow \left\{ h_1^{(1)},\, h_1^{(2)},\, \ldots,\, h_1^{(N)} \right\}$ ，即多条 latent reasoning trajectories。
## 2.3 提出 Latent Reward Model 对 Latent Thought 进行评分

生成多条 latent trajectories 后，还需要解决：

> **哪条 latent trajectory 更好？**

由于 latent representation 本身没有天然的 likelihood 或 step-wise score，因此论文设计了 **Latent Reward Model（LatentRM）**。

LatentRM 输入当前问题和截至第 $t$ 步的 latent trajectory：

$(x,h_{1})$

输出一个标量分数：

$r_t=g_\phi(x,h_{1})$

表示：

> **从当前 latent thought 继续推理，未来得到正确答案的潜力有多大。**

Parallel_Test-Time_Scaling_for_…

有了这个 scorer 后，就能够把：

- Best-of-N
    
- Beam Search
    

等传统聚合方法重新应用到 latent reasoning 中。

---

## 2.4 使用 Step-wise Contrastive Objective 训练 LatentRM

本文没有简单地把每条 latent thought 独立做二分类，而是让**同一步的多个候选 latent thoughts 相互比较**。

在第 $t$ 步，有 $N$ 个候选：

$h_t^{(1)},h_t^{(2)},\ldots,h_t^{(N)}$

对应评分：

$r_t^{(1)},r_t^{(2)},\ldots,r_t^{(N)}$

通过 softmax：

$p_t^{(n)} = \frac{\exp(r_t^{(n)})}{\sum_{n'}\exp(r_t^{(n')})}$

使 LatentRM 学习：

> **同一个 reasoning step 中，哪个 candidate 比其他 candidate 更值得继续。**

论文发现这种 step-wise contrastive supervision 比单独使用 BCE 的效果更好。 Parallel_Test-Time_Scaling_for_… Parallel_Test-Time_Scaling_for_…

---

## 2.5 发现 MC-Dropout 与 Gaussian Noise 具有不同的探索行为

本文不仅比较最终准确率，还分析了两种采样机制在 latent space 中的几何行为。

论文发现：

- **MC-Dropout**：倾向于沿某些方向进行结构化、定向探索；
    
- **Gaussian Noise**：更像从中心向四周均匀扩散，形成更宽的各向同性探索。
    

Parallel_Test-Time_Scaling_for_…

进一步的可视化表明：

- 对于较难的问题，MC-Dropout 的定向远距离探索更容易到达远离 deterministic trajectory 的正确区域；
    
- Gaussian Noise 则在较强随机性下仍能保持较好的局部覆盖和鲁棒性。 Parallel_Test-Time_Scaling_for_…
    

---

## 2.6 证明 Latent Reasoning 也具有 Test-Time Scaling 能力

随着采样数量 $N$ 增加，论文发现 solution coverage 整体持续提升，说明：

$\boxed{\text{更多 inference compute} \rightarrow \text{更高 latent reasoning performance}}$

即 latent reasoning 同样可以从 test-time compute scaling 中受益。 Parallel_Test-Time_Scaling_for_…

在 trajectory aggregation 上，论文还发现：

$\text{Best-of-N / Beam Search} > \text{Majority Voting}$

表明 LatentRM 确实能够识别更有潜力的 latent trajectories，而不仅仅依靠最终答案投票。 Parallel_Test-Time_Scaling_for_…

---

## 2.7 核心贡献总结

本文的贡献可以压缩成三点：

1. **提出 latent reasoning 的 Parallel Test-Time Scaling 框架；**
    
2. **利用 MC-Dropout 和 Gaussian Noise 解决 continuous latent space 中的多轨迹采样问题；**
    
3. **提出 LatentRM + step-wise contrastive learning，解决 latent trajectory 的评分、选择和聚合问题。** Parallel_Test-Time_Scaling_for_…
    

可以把整篇方法概括成：

$\boxed{\text{Latent Sampling} \rightarrow \text{Multiple Trajectories} \rightarrow \text{LatentRM Scoring} \rightarrow \text{Best-of-N / Beam Search}}$

也就是：

> **先解决“怎么多想几条”，再解决“怎么挑出最好的一条”。**
# 三、实验与结论（数据说明了什么、有什么局限性）

# 四、对我的启发（对我的研究有什么值得参考的）

