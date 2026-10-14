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
# 二、创新点与贡献

注：
1. **最传统的：普通 CoT + RL**
输入问题 $\to$ 模型一个 token 一个 token 生成 CoT $\to$ 生成最终答案 $\to$ 根据最终答案算 reward $\to$ 用 policy gradient（策略梯度）更新这些离散 token 的生成概率。这里所有“思考”本身都是 **离散 token**。

例如：
```
Q: 12 + 17 = ?
CoT:
12 + 10 = 22
22 + 7 = 29
Answer: 29
```
RL 训练时，本质上是在说**这条 token 序列最后拿到了高 reward，那以后就更容易生成这条或者类似的 token 序列**。所以传统 RL 天然适配 token，因为每一步都有明确的 $\pi_\theta(a_t|s_t)$，也就是“在当前状态下，选择这个 token 的概率”。

2. **普通 latent reasoning**
后来 Coconut、Soft Thinking 这类方法说：为什么一定要把中间思考说成文字？于是流程变成：$\text{Question} \to \text{Encoder / LLM} \to z_1 \to z_2 \to z_3 \to \cdots \to z_T \to \text{discrete answer}$，中间的 $z_1,z_2,\dots,z_T$ 不是词，而是连续向量。比如原本 `"12 + 10 = 22"` 现在可能变成一个 4096 维 hidden state $z_t\in\mathbb{R}^{4096}$，然后直接把这个 latent state 喂回模型继续推理。

这里就出现问题了，对于离散 token，有 $P(\text{token}="22")$，但是对于 latent vector，比如 $z_t=[0.13,-0.47,0.82,\dots]$，很难直接说“模型选择这个 latent vector 的概率是多少？”

因为传统 latent reasoning 往往是 $z_t=f_\theta(z_{t-1},x)$，是一个**确定性映射**。同一个输入 $x \to z_1 \to z_2 \to z_3$ 每次都一样，所以 RL 很难像操作 token 一样操作 latent state。

3. **以前 latent reasoning + RL 怎么做**

很多方法其实还是 $\text{Question} \to \text{latent reasoning} \to z_1 \to z_2 \to z_3 \to z_4 \to \text{discrete token answer} \to \text{Reward} \to \text{主要优化最终输出}$，也就是说 latent reasoning 负责“想”，RL 更多还是在最终 token 输出处发挥作用。

这时候 reward 是 $R(\text{answer})$，例如答案正确 $R=1$；错误 $R=0$，但是一个核心问题出现了：中间到底哪个 latent state 是好的？

例如 $z_1 \to z_2 \to z_3 \to z_4 \to \text{正确答案}$，最终得到 reward = 1。但 $z_1$ 好不好、$z_2$ 好不好、$z_3$ 是不是其实走偏了、$z_4$ 才纠正回来。传统做法里，这个 credit assignment 很模糊。

## 2.1 用 Gumbel-Softmax 给 latent reasoning 引入可控随机性

以往很多 latent reasoning 虽然保留的是连续分布，但同一个输入通常还是会得到相同的 latent trajectory，缺少真正的轨迹级探索。

LEPO 的第一个核心改进是 $\pi_t\rightarrow\text{Gumbel-Softmax}\rightarrow z_t$，也就是在原始词表概率分布 $\pi_t$ 上加入 Gumbel noise，得到随机 latent token $z_t$。这样，同一个问题可以采样出不同的 latent reasoning trajectory，从而恢复 trajectory-level exploration。

与简单 Gaussian noise 相比，论文认为 Gumbel-Softmax 更适合这里，因为它仍然保持：

- 是合法的概率分布；
- 不会直接退化成 one-hot；
- 尽量保留原始概率分布的信息。

所以第一项创新可以概括成 $\boxed{\text{Deterministic Latent Reasoning}\rightarrow\text{Stochastic Latent Reasoning}}$。
## 2.2 把强化学习直接作用到连续 latent reasoning 过程

以往 RL 更多是在优化最后生成出来的 discrete token，LEPO 不只优化最终答案，还直接优化中间的 latent token。

对于离散 token，仍然使用类似标准 policy gradient 的目标 $J_{\text{discrete}}$，而对于连续 latent token，它把采样得到的 latent distribution $z_t$ 当成一个 soft label $J_{\text{latent}}=\sum_t\hat A_i\sum_k z_{i,t,k}\log\pi_{\theta,k}$。如果某条 rollout 最后奖励高，那么这条轨迹中出现过的 latent distributions 也会被强化。

也就是说，$\boxed{\text{Reward 不只训练“最后说什么”}\rightarrow\text{也训练“中间怎么想”}}$，这是 LEPO 最核心的方法贡献之一。
## 2.3 统一优化 latent token 与 discrete token

LEPO 进一步把两部分放进同一个训练目标 $J_{\text{total}}=J_{\text{latent}}+J_{\text{discrete}}$，最终整体目标再加入 KL regularization $J_{\text{LEPO}}=J_{\text{total}}-\beta D_{\mathrm{KL}}$。所以一条完整 trajectory 中，$\text{latent reasoning}\rightarrow\text{discrete answer}$ 前半段的“隐式思考”和后半段的“显式回答”可以在同一个 RL 框架里联合优化。
## 2.4 实验证明 stochastic latent reasoning 更适合探索和 RL

论文不只是提出方法，还专门做了 motivation experiments（预备实验），证明加入随机性之后：
- entropy 更高；
- Pass@32 更高；
- 更多原本几乎做不出来的问题，被移动到“中等难度、可以通过 RL 学会”的区域。

作者因此认为 $\text{更强探索}\rightarrow\text{更多可学习轨迹}\rightarrow\text{更有效 RL}$，而正式实验中，LEPO 也比 discrete RL 和已有 latent RL baseline 表现更好。

论文自己总结的三项主要贡献就是：
- 验证 stochastic latent reasoning 的探索优势；
- 提出 LEPO 这一 latent RL 框架；
- 在多个 benchmark 上取得更好结果。
# 三、实验与结论（数据说明了什么、有什么局限性）
## 3.1 实验设置

LEPO 在 3 个基础模型上进行实验：
- Qwen2.5-7B
- Qwen2.5-3B
- Llama-3.2-3B-Instruct
训练数据使用 DAPO-MATH-17k。数学推理评测包括 GSM8K、MATH500、MinervaMath、AIME2024、AIME2025 和 AMC23；另外还在 GPQA-Diamond、ARC-C 和 MMLU-STEM 上进行分布外泛化测试。论文同时报告 Pass@1 和 Pass@32：前者主要反映单次生成质量，后者反映多次采样后能否探索到正确解。

对比方法包括：
- 普通 CoT
- GRPO
- Soft Tokens
- HRPO
- GRPO + latent inference

因此实验实际上同时比较了普通离散推理、普通潜在推理、离散强化学习，以及已有潜在强化学习方法。
## 3.2 LEPO 的总体准确率更高

在 Qwen2.5-7B 上，LEPO 的六个数学数据集平均结果为：$\text{Pass@1}=45.30$、$\text{Pass@32}=69.54$；GRPO 为：$43.51,\quad 67.56$；Soft Tokens 为：$43.27,\quad 62.29$。

Pass@1 提高说明 LEPO 不只是“生成得更随机”，最终单次推理能力也确实提高了； Pass@32 的提高更加符合论文的核心主张：加入随机潜在推理后，同一个问题可以探索更多不同的推理轨迹，因此多次采样时更容易找到至少一条正确路径。

所以这组结果真正支持的是 $\boxed{\text{随机潜在推理提高了探索覆盖率}}$，而不仅仅是“加噪声后准确率变高”。
## 3.3 随机性确实增强了探索能力

作者专门做了 motivation experiments，在 Qwen2.5-7B + MATH500 上，随机潜在推理表现出：
- 更高的熵；
- 更高的 Pass@32；
- 但初始平均准确率与其他方法相近。

这说明它不是简单让模型“整体变强”，而是首先让模型生成的轨迹更加多样。论文还把题目按照基础正确率分组。加入随机性之后，一部分原本处于 $0\sim0.2$ 正确率区间、几乎解不出来的问题，被移动到了 $0.2\sim0.5$ 这个中等正确率区间。

这个现象对强化学习很重要，因为如果一道题 $P(\text{正确})\approx0$，模型几乎所有 rollout 都错：$0,0,0,0,\dots$，就没有多少有用的奖励差异；但如果变成 $P(\text{正确})=0.3$，就可能采到 $0,1,0,0,1,\dots$，强化学习终于可以比较“哪些轨迹成功、哪些轨迹失败”。

因此作者的逻辑是：$\text{增加随机探索}\to\text{更容易偶然找到正确路径}\to\text{产生更丰富的奖励信号}\to\text{强化学习更容易优化}$，这其实是论文实验部分非常重要的一条证据链。
## 3.4 LEPO 在训练过程中保持了更高的探索性

作者还跟踪了训练过程中的熵，随着强化学习不断训练：$\text{Entropy}\downarrow$ 是正常的，因为模型逐渐确定哪些路线更好。但整个训练过程中：$H_{\text{LEPO}}>H_{\text{GRPO}}$，也就是 LEPO 始终保持更高的熵。

这说明 LEPO 并没有在强化学习过程中迅速坍缩成单一路径，而是仍然保留了一定程度的探索能力。这点和论文提出 stochastic latent reasoning 的动机是直接对应的。
## 3.5 不同噪声并不是一样有效

作者还把 Gumbel-Softmax 换成了 Gaussian noise 和 Dirichlet noise，结果发现 Gaussian 和 Dirichlet 两种噪声的训练收敛都比 Gumbel noise 更差，甚至弱于 GRPO。

这很重要，因为它说明实验并不是 $\boxed{\text{只要加随机噪声就行}}$，而更接近 $\boxed{\text{随机性的形式本身也很重要}}$。作者认为 Gumbel-Softmax 的优势在于，它更接近从词表分布中进行离散采样，同时仍然保留连续分布的信息。

这也意味着简单写成 $z_t\sim\mathcal N(\mu_t,\Sigma_t)$ 不一定就能得到 LEPO 相同的效果。
## 3.6 LEPO 并不是越随机越好

Gumbel-Softmax 有一个温度参数 $\tau_g$，实验发现较有效的范围大约是 $\tau_g\in[0.3,0.6]$，在这一范围内，LEPO 稳定优于 GRPO。

原因可以理解为：
- $\tau_g$ 太小：分布接近 one-hot，重新变得接近离散采样；
- $\tau_g$ 太大：分布接近均匀，随机性太强，原始语义信息被冲淡。

所以真正需要的是 $\boxed{\text{探索性和信息保持之间的平衡}}$，而不是无限增加随机性。
## 3.7 对分布外任务也有一定泛化能力

在 Qwen2.5-7B 上，LEPO 还测试了：
- GPQA-Diamond
- ARC-C
- MMLU-STEM

LEPO 平均达到：$65.40\% \text{ Pass@1}$，$95.73\% \text{ Pass@32}$，而 GRPO 为 $64.70\%,\quad94.68\%$，说明提升并不仅局限于训练使用的数学数据。

不过这个提升并不算巨大，因此更适合说有一定泛化证据
## 3.8 这篇论文真正证明了什么

综合这些实验，更稳妥的结论是 $\boxed{\text{确定性潜在推理}\to\text{加入合适的随机性}\to\text{扩大轨迹探索}\to\text{提高找到正确轨迹的概率}\to\text{给强化学习提供更好的训练信号}}$，再配合 LEPO 对潜在步骤本身进行强化学习优化，最终提高推理性能。

所以论文的实验支持 stochastic latent reasoning 比 deterministic latent reasoning 更适合与强化学习结合。但不能进一步直接推出“随机 latent 本身一定比所有确定性 latent 更强。”因为这里实际上同时改变了采样机制、强化学习目标以及联合优化方式。
## 3.9 局限性

论文自己明确指出两个主要局限：
1. **潜在推理不可直接解释**

离散 CoT 可以直接看到：$\text{“先计算 A，再计算 B”}$，而 LEPO 的中间过程是连续分布，人不能直接读懂。虽然可以取：$\arg\max_k z_{t,k}$ 把每一步近似解码成概率最大的词元，但这只是近似解释，并不能完整表达潜在分布里的信息。

2. **只能先潜在推理，再输出文字**

当前 LEPO 的结构固定为 $\text{潜在推理}\to\text{离散回答}$，也就是说 $z_1\to z_2\to\cdots\to z_T\to y_1\to y_2\to\cdots$，目前不能动态变成 $z_1\to\text{文字}\to z_2\to\text{文字}\to z_3$，作者也认为这种潜在推理与文字生成动态交替的模式，可能更适合开放式任务。

3. **还有一个值得您自己注意、但作者没有作为主要 limitation 强调的问题**

LEPO 的奖励主要还是结果奖励 $r=\begin{cases} 1,&\text{答案正确} \\ 0,&\text{答案错误} \end{cases}$，然后同一条 rollout 的优势值用于指导中间多个潜在步骤。因此仍然存在一个问题：$z_1\to z_2\to z_3\to z_4\to\text{正确答案}$ 虽然最后答对了，但不能保证 $z_1,z_2,z_3,z_4$ 每一步都是好的。

也就是说，潜在步骤的细粒度信用分配仍然比较粗。这个点其实非常值得您以后继续追，因为“最终成功”和“每一步内部推理质量”并不是完全等价的。
# 四、对我的启发（对我的研究有什么值得参考的）
## 4.1 latent reasoning 不应该只看“一个确定向量”

LEPO 最直接的启发是潜在推理不一定非要表示成唯一的确定状态，也可以显式保留随机性和分布信息。

传统做法更像 $z_t=f_\theta(z_{t-1},x)$，同一个输入通常得到同一条潜在轨迹。LEPO 则说明，可以把每一步潜在状态改造成带随机性的形式 $z_t\sim q_\theta(z_t|z_{t-1},x)$，这和我的设想比较接近 $q_A(z),\ q_B(z),\ q_C(z)$ 即每条思路不一定只是单个向量 $z_A,z_B,z_C$，而可以表示成一个带有中心和不确定性的分布。

这意味着后续研究可以进一步考虑 $\boxed{\text{单点 latent state} \to \text{distributional latent state}}$ 从而显式保留推理的不确定性和多样性。
## 4.2 随机性本身不是目的，关键是“可控探索”

LEPO 的实验说明不是随便加噪声都有效，Gaussian noise、Dirichlet noise 并没有表现得和 Gumbel-Softmax 一样好。

这说明真正的问题不是 $\text{要不要加随机性}$，而是 $\boxed{\text{什么样的随机性能够产生有效探索，同时保持语义稳定}}$，这和我的研究问题直接相关。如果多条 latent 思路只是 $z_t^{(k)}=z_t+\epsilon_k$，那么它们可能只是围绕同一个中心做小扰动，并没有形成真正不同的推理路线。

因此多候选方法不能只追求 $\text{diversity}$，还需要控制 $\text{semantic consistency}$，也就是思路可以不同，但不能因为随机性太强而逐渐偏离原问题。
## 4.3 可以把“不确定性”作为是否展开多思路的信号

LEPO 通过提高潜在推理的熵来维持探索能力。这给我的一个直接启发是没必要在所有步骤都维持同样强度的多候选探索。如果某一步模型已经非常确定 $H_t\approx0$，可以让候选独立推进，甚至减少候选数量。

如果 $H_t$ 较高，说明当前推理存在较大不确定性，就可以 $\text{增加探索}$ 或者 $\text{触发候选之间的信息交流}$，因此可以设计 $H_t>\tau \Rightarrow \text{开启多思路探索 / 通信}$，$H_t\le\tau \Rightarrow \text{保持独立推理}$，这比“每一步强制通信”更自然，也可能降低计算量。
## 4.4 LEPO 解决的是“一条轨迹如何探索”，但没有真正解决“多条思路如何协作”

LEPO 虽然通过随机采样生成不同轨迹，但这些轨迹本质上还是 $\tau^{(1)},\tau^{(2)},\dots,\tau^{(K)}$ 各自独立 rollout。它没有重点研究 $z_t^{(1)} \leftrightarrow z_t^{(2)} \leftrightarrow z_t^{(3)}$ 之间该如何
- 交换信息；
- 判断别人提供的信息是否可信；
- 合并不同思路；
- 避免所有候选逐渐变得一样；
- 决定什么时候交流。

而这些正好是我的研究可以继续推进的部分。因此可以把关系写成 $\boxed{\text{LEPO：如何产生不同 latent trajectories}}$，而我的目标更进一步 $\boxed{\text{不同 latent trajectories 如何共同推理}}$，这是一个比较自然的延伸。
## 4.5 “候选坍缩”可能比单纯缺少随机性更重要

LEPO 主要关注 deterministic latent reasoning 缺乏探索。但对于多候选系统，即使最开始 
$z_0^{(1)} \neq z_0^{(2)} \neq z_0^{(3)}$，经过多步更新后仍可能出现 $z_t^{(1)} \approx z_t^{(2)} \approx z_t^{(3)}$，即候选坍缩。

这样表面上维护了 $K$ 条思路，实际上只有一条。因此我的研究除了引入随机性，还需要显式研究 $\text{如何长期维持有意义的候选差异}$，可能需要 $\text{diversity regularization}$ 或者独立候选目标、互信息约束、距离约束等机制。

这点尤其重要，因为仅靠随机初始化或噪声并不能保证多条思路长期保持分化。
## 4.6 最终奖励对中间潜在步骤的监督仍然很粗

LEPO 仍然主要依据最终答案得到 reward：$z_1\to z_2\to z_3\to z_4\to\text{正确答案}$，然后整条轨迹获得较高优势值。但这并不能说明 $z_1,z_2,z_3,z_4$ 每一步都是好的。

例如可能存在：$z_1\to\text{错误方向}\to z_3\to\text{后面纠正}\to\text{正确答案}$，因此 LEPO 仍然存在比较明显的 $\boxed{\text{credit assignment 问题}}$，这给我的启发是**多候选 latent reasoning 中，不能只关心最终哪条轨迹成功，还要考虑中间哪些信息真正帮助了后续推理**。

尤其当候选之间发生通信之后，还可以进一步研究 $\text{某条候选提供的信息}\to\text{最终性能提升多少}$，也就是对跨候选信息进行来源追踪和贡献分配。这与我想做的“带来源上下文的工作记忆”比较契合。
## 4.7 LEPO 可以作为我的随机 latent baseline

从实验设计角度，LEPO 很适合成为后续工作的一个 baseline，可以比较：
- $\text{Deterministic single latent}$
- $\text{Stochastic single latent（LEPO式）}$
- $\text{Independent multi-latent}$
- $\text{Communicating multi-latent}$

这样可以把问题拆清楚：
1. 单纯随机性有没有帮助？
2. 多候选有没有额外帮助？
3. 多候选通信是否进一步提升？
4. 提升究竟来自“更多采样”，还是候选之间真正发生了有效的信息复用？

这样比只比较 $\text{普通模型}\quad vs\quad\text{我的模型}$ 更容易解释机制。
## 4.8 对我最重要的一句话

LEPO 给我的最大启发不是“给 latent 加噪声。”而是：$\boxed{\text{latent reasoning 本身可以被看成一个需要探索和优化的内部决策过程}}$

LEPO 研究的是：$\text{一条潜在思路如何进行随机探索}$
而我更想研究的是：$\boxed{\text{当内部同时存在多条潜在思路时，它们应该何时分化、何时交流、如何选择性复用彼此的信息}}$
所以 LEPO 更像是我研究路线中的一个前置基础，而不是最终目标。
