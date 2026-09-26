> [!info] 基本信息
> - **论文题目**：LEPO: Latent Reasoning Policy Optimization for Large Language Models
> - **中文题目**：LEPO：面向大语言模型的潜在推理策略优化
> - **期刊/会议**：Findings of ACL 2026
> - **作者**：Yuyan Zhou、Jiarui Yu、Hande Dong、Zhezheng Hao、Hong Wang、Jianqing Zhang、Qiang Lin
> - **Tag**：Latent Reasoning、Reinforcement Learning、Gumbel-Softmax、Stochastic Reasoning
```table-of-contents
```
# 一、研究背景（前人做到哪一步）

传统大语言模型主要通过 **Chain-of-Thought（CoT）** 进行推理，即每一步都从词表中选择一个离散 token。问题在于，模型内部原本包含丰富的概率分布信息，但一旦采样成单个 token，这些信息就会被压缩甚至丢失。

因此，近年来开始出现 **Latent Reasoning（潜在推理）**：不再要求模型每一步都生成可读 token，而是直接在连续表示空间中进行推理。

已有工作主要使用两类连续表示：

- **hidden state**：直接把模型隐藏状态作为下一步推理输入；
- **weighted vocabulary embedding**：保留整个词表概率分布，并对所有 token embedding 做**加权求和**，得到下一步的连续输入。
## 1.1 Latent reasoning 已经形成了多种训练路线

论文把已有工作分为三类：

1. **Training-free**：$\begin{cases} \text{不额外训练模型} \\ \text{直接使用词表 embedding 的加权和进行 latent reasoning} \end{cases}$
2. **Pre-training**：在**预训练阶段**就让模型学习连续推理表示，例如连续 token 与离散 token 混合，或使用内部 continuous CoT。
3. **Post-training**：在已有模型上进一步训练 latent reasoning，又分为 SFT 和 RL 两条路线。

也就是说，到 LEPO 之前，研究重点已经不再只是“模型能不能在隐空间里思考？”，而是开始进一步研究**怎样训练和优化这种隐空间推理过程**。
## 1.2 但大部分 latent reasoning 仍然是确定性的

已有 latent reasoning 虽然保留了一个分布，而不是只保留一个 token，但存在一个重要问题，**相同输入往往会产生相同的 latent trajectory**。因为没有真正的随机采样过程，所以整个 latent reasoning 是确定性的。

论文把“探索能力”分成两层：$\begin{cases} \text{step-level exploration：一个 latent state 内同时保留多个可能性} \\ \text{trajectory-level exploration：同一个问题可以采样出不同的完整推理路径} \end{cases}$。传统 latent reasoning 已经有一定的 **step-level exploration**，因为一个概率分布可以同时表示多个候选 token。

但它缺少 **trajectory-level exploration**，$\text{同一个问题} \rightarrow \text{几乎总是同一条 latent reasoning path}$，因此模型虽然“一步内部有多个可能”，却很难真正探索多条不同的完整推理路线。
## 1.3 已经有人开始给 latent reasoning 加随机性

在 LEPO 之前，已经有工作提出使用 **Gumbel-Softmax** 给连续 latent representation 注入随机性。

注：
Gumbel-Softmax：**“能保持可微分的随机采样**。”普通 Softmax 只会给出一个概率分布，例如 $\pi=(0.6,0.3,0.1)$，如果直接拿这个分布往后传，其实每次都是一样的，所以推理是确定性的。

Gumbel-Softmax 会先给每个候选加一份随机噪声 $z_{t,k}=\frac{\exp((\log \pi_{t,k}+\epsilon_k)/\tau)}{\sum_j \exp((\log \pi_{t,j}+\epsilon_j)/\tau)}$，其中：

- $\pi_{t,k}$：原来的 token 概率
- $\epsilon_k$：Gumbel 随机噪声
- $\tau$：temperature，控制分布有多尖锐

所以原本 $(0.6,0.3,0.1)$ 这一次采样可能变成 $(0.75,0.20,0.05)$，下一次又可能 $(0.45,0.48,0.07)$。于是**同一个输入可以走出不同的 latent reasoning trajectory**。LEPO 就是用它，把原本确定性的 latent reasoning 变成随机的 latent reasoning，从而恢复 trajectory-level exploration。

还有一个很关键的参数 $\tau\rightarrow0$ 时，分布会越来越接近 one-hot，也就是越来越像“只选一个 token”；而 $\tau\rightarrow\infty$ 时，分布会越来越接近均匀分布。

其基本思想是 $\pi_t \rightarrow \text{加入 Gumbel noise} \rightarrow z_t$。因此，即使原始概率分布 $\pi_t$ 相同，不同采样也可能产生不同的 $z_t$，从而得到不同的后续推理轨迹。

这一步实际上解决的是 $\text{确定性 latent reasoning} \rightarrow \text{随机性 latent reasoning}$。论文认为，这种随机性能够恢复模型的 **trajectory-level exploration**。
## 1.4 Latent reasoning 也已经开始结合强化学习

在 LEPO 之前，也已经出现了针对 latent reasoning 的强化学习方法。

例如已有工作尝试：

- 给 latent embedding 加 **Gaussian noise** 后进行 RL；
- 使用重参数化方法估计 latent representation 的梯度；
- 混合 latent token 和采样出的 discrete token 进行训练。LEPO.pdfPDF

注：
1. **给 latent embedding 加 Gaussian noise 后进行 RL**

原本 latent state 是一个确定向量 $z$，别人会人为加一份高斯噪声 $\tilde z=z+\epsilon,\epsilon\sim\mathcal N(0,\sigma^2I)$，于是同一个 $z$，每次都会稍微变一点 $z+\epsilon_1,\quad z+\epsilon_2,\quad z+\epsilon_3$。这样就能产生不同 latent trajectory，再用奖励告诉模型哪种扰动后得到的推理结果更好，就往那个方向学。

所以它本质上是 $\boxed{\text{固定 latent}\rightarrow\text{随机扰动 latent}\rightarrow\text{RL}}$。论文明确提到已有工作使用 **Gaussian noise 扰动 embedding，再进行 RL 优化**。

2. **使用重参数化方法估计 latent representation 的梯度**

假设 $z\sim\mathcal N(\mu,\sigma^2)$，直接“从分布采样”这一步不好求梯度，于是改写成 $\epsilon\sim\mathcal N(0,I),z=\mu+\sigma\epsilon$。这样随机性被放进了 $\epsilon$，而 $\mu,\sigma$ 仍然是模型可以反向传播优化的参数。

所以这里不是说“又提出了一种新的思考表示”，而是解决**latent state 有随机采样以后，怎么把梯度传回去训练模型**？论文把这类已有工作概括为利用 **reparameterization trick 进行 gradient estimation**。

3. **混合 latent token 和采样出的 discrete token 进行训练**

这个意思是推理过程中**不一定全部都是连续 latent token**，可以类似 $\text{latent}\rightarrow\text{latent}\rightarrow\text{discrete token}\rightarrow\text{latent}\rightarrow\cdots$，或者在训练时同时利用连续的 latent representation 与从分布真正采样出来的 discrete token。这样既利用 latent representation 中丰富的信息，又通过 discrete sampling 引入随机性。

所以可以把它理解成 $\boxed{\text{连续思考}+\text{离散采样}}$，论文相关工作里提到，有方法通过混合 latent 与 sampled discrete tokens 来引入随机性。

### 三个东西最简单的区别

$\text{Gaussian noise}$

是在问：**怎么让 latent 随机起来？**

$\text{Reparameterization}$

是在问：**随机采样以后怎么反向传播？**

$\text{latent}+\text{discrete token}$

是在问：**连续推理和离散采样怎么结合？**

所以它们其实不是三个完全平行的“算法”，而是在解决 latent reasoning 里的**不同技术问题**。

因此，到这篇论文出现之前，前人的路线实际上已经发展到了 $\text{离散 CoT} \rightarrow \text{连续 latent reasoning} \rightarrow \text{随机 latent reasoning} \rightarrow \text{latent reasoning + RL}$。真正还没有被很好解决的问题是：**如何既让 latent reasoning 保持随机探索能力，又直接通过强化学习优化这些连续 latent states**。
# 二、创新点与贡献

# 三、实验与结论（数据说明了什么、有什么局限性）

# 四、对我的启发（对我的研究有什么值得参考的）

