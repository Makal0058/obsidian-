> [!info] 基本信息
> - **论文题目**：SeLaR: Selective Latent Reasoning in Large Language Models
> - **中文题目**：SeLaR：大语言模型中的选择性潜在推理
> - **期刊/会议**：ACL 2026，主会长论文
> - **作者**：Renyu Fu，Guibo Luo（北京大学深圳研究生院）
> - **Tag**：Latent Reasoning；Soft Embedding；Entropy Gating；Contrastive Regularization；Training-free Reasoning
```table-of-contents
```
# 一、研究背景（前人做到哪一步）
## 1.1 传统 Chain-of-Thought（CoT）已经能显著提升多步推理能力

   CoT 通过显式生成中间推理步骤，让大语言模型在数学、逻辑等复杂任务上表现更好。但它每一步都必须从词表中选择一个离散 token，相当于**很早就对当前推理方向做出明确承诺**，这会丢失其他可能的候选路径信息。
## 1.2 为避免过早离散化，前人开始研究 latent reasoning

   这类方法不再要求每一步都生成离散 token，而是使用 hidden state 或 soft embedding 作为中间推理载体，从而在连续空间中保留更多潜在推理信息，甚至隐式表示多个候选方向。
## 1.3 现有 latent reasoning 主要分成两类

- **需要训练的方法**：例如 Coconut，将 hidden state 直接作为下一步推理信号，通过微调学习连续隐空间中的多步推理。

注：
1. Transformer 原本下一步接收的是 $\text{token embedding}$，而 Coconut 突然往输入位置塞： $\text{hidden state}$，这两个空间虽然维度可能一样，但**分布和语义并不一样**。
	
	所以模型原来学的是 $e(x_t)\rightarrow \text{Transformer}$，现在却变成 $h_t\rightarrow \text{Transformer}$，模型得重新学会“这个 hidden state 放到输入位置时，我该怎么理解它？”
	
	因此 Coconut 需要微调。SeLaR 也指出，这类方法可能面临 hidden-state space 与 input-embedding space 之间的 domain gap。

2. $\text{token embedding}$ 就是**把一个离散的 token，转换成 Transformer 能处理的连续向量。
	
	比如一句话“我 喜欢 猫”分词以后可能得到三个 token：$x_1=\text{“我”},\quad x_2=\text{“喜欢”},\quad x_3=\text{“猫”}$
	
	但 Transformer 不能直接处理“猫”这个文字，所以先通过一个 embedding 表$E\in\mathbb{R}^{|V|\times d}$，其中：
	- $|V|$：词表大小
	- $d$：向量维度

	然后把 token “猫”查表得到一个向量 $e_{\text{猫}} = E[\text{猫}]$，比如 $e_{\text{猫}} = [0.21,-0.73,0.44,0.18]$，这一个向量，就是 **token embedding**。
	
	所以流程可以记成：$\text{token} \rightarrow \text{token embedding} \rightarrow \text{Transformer}$ 

- **无需训练的方法**：例如 Soft Thinking，通过词概率加权多个 token embedding，形成 soft embedding，再送回模型继续推理。soft embedding 可以表示为 $e_t=\sum_{v\in V}p_t(v)e_v$，也就是说，它不是只选择一个 token，而是把多个候选 token 按概率混合成一个连续向量。

注：
它不直接用 hidden state，而是先让模型正常产生 $p(v\mid x_{<t})$，也就是**下一个 token 的概率分布**。

例如，therefore：$0.5$、because：$0.3$、however：$0.2$，普通 CoT 会直接选一个 $x_t=\text{therefore}$，然后取得它的 embedding $e_{\text{therefore}}$。

Soft Thinking 则说“我为什么非得立刻只选一个？”，于是把几个 token 的 embedding 按概率加权 $e_t = \sum_{v\in V} p_t(v)e_v$

例如 $e_t = 0.5e_{\text{therefore}} + 0.3e_{\text{because}} + 0.2e_{\text{however}}$，得到一个新的 **soft embedding**。然后 $e_t \rightarrow \text{Transformer} \rightarrow p_{t+1}$，再继续下一步。

## 1.4 但是已有 latent reasoning 还有两个明显问题

1. **几乎所有步骤都启用 latent reasoning**。

   现有 training-free 方法往往在整个推理过程中都使用 soft embedding，但很多步骤其实模型已经非常确定。这时继续使用 soft embedding **反而会引入扰动，破坏原本稳定的推理过程**。

2. **soft embedding 会发生“路径坍缩”**。

   虽然 soft embedding 一开始混合了多个候选 token，但随着推理继续，它会**越来越靠近概率最高的 Top-1 token**，最后实际上又退化成单一路径推理，失去了 latent reasoning 原本想保留多种可能性的意义。

## 1.5 因此，这篇论文真正接着前人往前推的问题是

不是“要不要做 latent reasoning”，而是**什么时候才应该进入 latent reasoning**，以及**进入以后，怎样避免多个潜在方向迅速坍缩成一条路径**？

论文因此提出 SeLaR：只在**高不确定性的步骤启用 soft embedding，并通过对比正则化让表示不要过快靠近 Top-1 token**。

如果压缩成一句话，就是**前人已经做到“用连续表示替代离散 token 进行 latent reasoning”，但还没有很好解决“何时启用”和“如何持续保持多路径探索”这两个问题**。
# 二、创新点与贡献
## 2.1. 提出“选择性 latent reasoning”

以前很多 training-free latent reasoning 方法，往往在整个推理过程中都持续使用 soft embedding。

SeLaR 的核心改动是**不是每一步都进入 latent reasoning，而是根据模型当前的不确定性决定是否启用**。

具体来说，它计算当前 top-k token 概率分布的熵 $H_t=-\sum_{v\in V_k}\hat p_t(v)\log \hat p_t(v)$，然后将其归一化为 $\bar H_t$ 再与阈值 $\tau$ 比较，$e_t= \begin{cases} E_{x_t}, & \bar H_t\leq\tau\\ \sum_{v\in V_k}\hat p_t(v)e_v, & \bar H_t>\tau \end{cases}$。

也就是说 $\begin{cases} \text{低熵、模型很确定} \to \text{正常离散 token 推理} \\ \text{高熵、模型不确定} \to \text{启用 soft embedding 进行 latent reasoning} \end{cases}$，论文把这个机制称为 **Entropy-Gated Selective Activation（熵门控选择性激活）**。

它解决的是**什么时候应该进行 latent reasoning**，而不是默认“latent reasoning 越多越好”。
## 2.2 提出熵感知的对比正则化，防止路径坍缩

作者认为，仅仅决定“什么时候启用 latent reasoning”还不够，因为 soft embedding 虽然一开始融合了多个候选 token $e_t=\sum_i p_i e_i$，但随着推理继续，它会越来越接近概率最大的 Top-1 token embedding，最后又退化成单一路径，也就是 $e_t \rightarrow e_{v_t^*}$。这就是论文说的 **premature collapse（过早坍缩）**。

为了解决这个问题，SeLaR 先计算 $\Delta_t=e_t-e_{v_t^*}$，然后得到远离 Top-1 token 的方向 $\hat\Delta_t= \frac{\Delta_t}{\|\Delta_t\|+\epsilon}$，最后修正 soft embedding $\tilde e_t = e_t + \bar H_t\cdot \hat\Delta_t \cdot \|\Delta_t\|$。直观上就是**主动把 soft embedding 往远离 Top-1 token 的方向推一点**。

而且这个“推力”由熵控制 $\begin{cases} \text{熵高} \to \text{模型更犹豫} \to \text{推得更强}\\ \text{熵低} \to \text{模型更确定} \to \text{推得更弱} \end{cases}$，所以它不是固定扰动，而是一个 **entropy-aware contrastive regularization（熵感知对比正则化）**。

它解决的是**进入 latent reasoning 后，怎样让多个候选方向不要马上坍缩成一条路径**？
## 2.3 证明 latent reasoning 其实只需要发生在少数关键步骤

这篇论文还有一个比较重要的经验性发现，大多数 CoT 推理步骤其实都是低熵、高置信的，真正高不确定的步骤只占少数。

在 Qwen3-8B 上，exploratory steps 只占大约 $6.2\%\sim13.8\%$，平均约 $10\%$。也就是说，大约 **10 个 token 中只有 1 个真正需要进入 latent reasoning**，这给论文前面的 selective activation 提供了实验依据。
## 3.4 方法不需要重新训练模型

SeLaR 还有一个实际贡献，**它是 training-free 的**。它不需要重新训练 Transformer 参数，而是在推理阶段动态 $\text{计算熵} \rightarrow \text{决定离散/latent} \rightarrow \text{调整 soft embedding}$。

所以作者把它定位为一个 **轻量级、无需训练的 latent reasoning 框架**。
# 三、实验与结论（数据说明了什么、有什么局限性）
## 3.1 结论
### 3.1.1 总体性能：SeLaR 平均效果最好

作者在 5 个推理数据集上测试了 SeLaR，包括 GSM8K、MATH500、GPQA、AIME 2024 和 AIME 2025，并比较了 CoT、Soft Thinking 和 SwiReasoning。

在 Qwen3-8B 上，平均准确率为：

- $\text{CoT}=79.68\%$
- $\text{Soft Thinking}=76.99\%$
- $\text{SwiR}=76.40\%$
- $\text{SeLaR}=83.56\%$

其中 AIME 2025 从 CoT 的 $66.67\%$ 提升到 $80.00\%$，提升最明显。说明**选择性开启 latent reasoning，比全程使用 soft embedding 更有效，尤其是在复杂多步推理任务上**。
### 3.1.2 两个核心模块都确实有用

消融实验中 $\text{完整 SeLaR}=83.56\%$，去掉选择性激活后 $78.37\%$，去掉对比正则化后 $75.74\%$，甚至都低于普通 CoT 的 $79.68\%$。

说明两个机制都很关键：

- **选择性激活**：避免在模型本来很确定的时候引入无谓扰动。
- **对比正则化**：防止 soft embedding 很快坍缩到 Top-1 路径。
### 3.1.3 真正需要 latent reasoning 的步骤其实很少

实验发现，高熵 exploratory steps 只占全部推理 token 的 $6.2\%\sim13.8\%$，平均大约 $10\%$。也就是**大部分步骤模型其实都很确定，只有少量关键步骤真正需要探索多个可能方向**。
### 3.1.4 对比正则化确实减缓了路径坍缩

作者用 logit lens 分析发现没有对比正则化时，soft embedding 会越来越接近 Top-1 路径。加入正则化后，Top-1 和 Top-2 对应的信息在深层网络中都能保持较高重叠，说明不是简单地“从 Top-1 换成 Top-2”，而是确实保留了多个潜在方向。
## 3.2 局限性
### 3.2.1 仍然只在 token embedding 空间里操作

SeLaR 使用的是 $\text{soft embedding}$，而不是直接操作 hidden state。

作者自己承认，token embedding 的表达能力有限，而 hidden state 才是 LLM 内部更主要的推理信息载体。
### 3.2.2 对基础模型本身的置信度比较敏感

不同模型的熵分布不一样，如果一个模型本身经常高熵，就会频繁触发 latent reasoning，反而可能过度探索。

所以作者认为未来需要更自适应的 confidence-aware activation，而不能只依赖当前这种熵门控。
### 3.2.3 仍然依赖人工设定阈值

当前方法需要给定 $\tau$，不同数据集甚至用了不同的阈值。

虽然作者发现 $\tau\in[0.3,0.7]$ 时性能比较稳定，但它本质上仍然是一个人工超参数，而不是模型自己学出来的动态判断机制。
## 3.3 一句话总结

**实验说明 latent reasoning 不是越多越好，真正重要的是只在少数不确定步骤进行探索，同时避免 soft embedding 过早坍缩；但 SeLaR 仍受限于 token embedding 空间、固定熵阈值和模型间置信度差异。**
# 四、对我的启发

## 4.1 多思路不一定需要全程开启

SeLaR 最重要的启发是**探索不是越多越好，而应该只在真正不确定的地方发生**，论文发现真正需要探索的高熵步骤平均只占约 $10\%$。

对应到我的多思路模型，可以考虑 $\begin{cases} \text{高置信} \rightarrow \text{保持当前思路独立推进} \\ \text{低置信 / 出现分歧} \rightarrow \text{启动多思路探索或交流} \end{cases}$，这样比让多个思路从头到尾持续通信更合理，也能减少无意义的信息干扰。
## 4.2 “什么时候交流”本身可以成为一个机制

SeLaR 用当前熵和固定阈值 $\tau$ 决定什么时候进入 latent reasoning，我的方法可以进一步考虑**自适应门控**：$H_1,H_2,\ldots,H_t \rightarrow \text{动态不确定性评分} \rightarrow g_t$，其中 $g_t\in[0,1]$。

再由 $g_t$ 控制：
- 是否产生更多候选思路
- 是否读取其他思路的信息
- 交流多少信息
- 当前需要多强的探索

这样就不是固定 $H_t>\tau$，而是根据**当前状态 + 历史不确定性**动态决定。

这一点是从 SeLaR 的局限进一步推出来的，不是论文已经实现的方法。论文自己也指出，不同模型的置信度分布不同，因此未来需要更自适应的 activation mechanism。SeLaR.pdfPDF
## 4.3 多思路模型必须防止“候选坍缩”

SeLaR 说明，即使一开始同时保留多个候选，soft embedding 最后仍可能逐渐被 Top-1 主导，退化成单一路径，这和我之前实验中的**候选坍缩**非常类似。

所以我的多候选 latent reasoning 不能只做到 $z^{(1)},z^{(2)},z^{(3)}$ 形式上有多个候选，还必须保证 $z^{(1)}\neq z^{(2)}\neq z^{(3)}$ 在功能上也真正探索不同方向。

因此以后需要专门设计**多样性保持 / 防坍缩机制**，而不是单纯增加候选数量。
## 4.4 可以继续考虑比 token embedding 更丰富的思路表示

SeLaR 自己承认，它只在 token embedding 空间操作，表达能力仍然受到限制；作者认为 hidden state 是更主要的内部推理信息载体。

这对我的方向很重要，我的“一个思路”不一定应该只是一个固定向量，也可以进一步研究成**隐空间中的分布表示**。例如 $z_i\sim\mathcal N(\mu_i,\Sigma_i)$，这样一个思路表达的不是“我的思路就是这个点”，而更像“我的核心思路大概位于这一片区域，同时保留一定不确定性和探索空间。”
## 4.5 对我最核心的启发

可以浓缩成**多思路 latent reasoning 不应该始终分叉、始终通信，而应该根据不确定性动态决定何时探索、何时交流；同时必须防止多个候选重新坍缩成同一思路，并探索比固定向量更丰富的思路表示**。