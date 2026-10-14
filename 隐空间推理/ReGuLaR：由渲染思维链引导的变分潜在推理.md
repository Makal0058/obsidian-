> [!info] 基本信息
> - **论文题目**：ReGuLaR: Variational Latent Reasoning Guided by Rendered Chain-of-Thought
> - **中文题目**：ReGuLaR：由渲染思维链引导的变分潜在推理
> - **期刊/会议**：arXiv:2601.23184v1
> - **作者**：Fanmeng Wang，Haotian Liu，Guojiang Zhao，Hongteng Xu，Zhifeng Gao
> - **Tag**： #潜在推理 #变分自编码器 #VAE #思维链 #推理压缩 #多模态推理 #大语言模型
```table-of-contents
```
# 一、研究背景（前人做到哪一步）
## 1.1 显式思维链已经很成熟，但推理成本高

CoT 通过逐 token 生成中间推理步骤提升复杂任务性能，但会产生大量冗余 token，带来较高计算开销和推理延迟。

## 1.2 前人开始把推理搬到连续潜在空间

Latent Reasoning 不再生成完整的自然语言推理链，而是在连续隐空间中传递中间推理状态，以减少解码开销。

代表工作包括：
  
- **iCoT**：训练过程中逐渐去掉显式推理步骤
- **Coconut**：把上一时刻最后层 hidden state 直接作为 continuous thought，再送回模型继续推理

注：
1. **什么叫 hidden state**

Transformer 每处理一个 token，最后一层都会得到一个向量 $h_t \in \mathbb{R}^d$。这个 $h_t$ 就是当前上下文经过模型计算后的**内部表示**。

2. **Coconut 做了什么**

正常 CoT 是 $\text{hidden state} \rightarrow \text{词概率} \rightarrow \text{生成文字 token}$，而 Coconut 直接跳过“生成文字”这一步 $h_t \rightarrow \text{直接当成下一步输入} \rightarrow h_{t+1}$，也就是把上一时刻的最后层 hidden state，直接当作下一步的“思考表示”。

3. **为什么叫 continuous thought**

因为它不再是离散文字 token，而是一个连续向量。

- **普通 CoT：想法 → 说成文字 → 再读文字继续想。**  
- **Coconut：想法 → 不说出来 → 直接拿这个内部向量继续想。**

- **CODI**：通过自蒸馏，让 latent thought 与显式 CoT 的隐藏表示对齐

注：
同时训练一个“显式 CoT 老师”和“隐式 CoT 学生”，让两边在关键 hidden state 上对齐，把原来用文字表达的推理能力压进连续空间。论文报告在 GSM8K 上，GPT-2 规模下可以做到接近显式 CoT，同时达到约 3.1× 的推理压缩。

- **CoLaR**：把一段推理 token 的 embedding 压缩成 latent state，并支持可变压缩率

注：
**本质上是先把“很多 token 的一小段推理”压成一个 latent，再让模型学着一步一步预测这些 latent**。例如原来 `token1 → token2 → token3 → token4 → token5 → token6` 可能压缩成 `latent1 → latent2`。

而且它有一个“**压缩率**”概念，例如一次 latent step 可以代表多个原始 reasoning tokens。训练时会把连续 token embedding 合并，然后学习预测后续的 compressed embedding；后面还用 RL 去探索更短、但仍然能做对题的 latent reasoning 路径。

论文报告，在相近压缩条件下比已有 latent baseline 准确率高，并能显著减少 reasoning chain 长度。

3. **现有 latent reasoning 的主要问题是“压缩后信息丢失”**  

这些方法虽然减少了显式 token，但潜在状态通常缺乏足够约束；推理状态不断递归传递时容易发生**误差累积、信息丢失和语义漂移**，因此性能往往明显低于显式 CoT。

4. **另一方面，视觉表示已被证明可以高密度压缩文本信息**  

VisInContext、VIST、DeepSeek-OCR 等工作已经证明：把文本渲染成图像，再通过视觉编码器压缩，可以用较少的表示保留较丰富的语义信息。

**总结**

前人已经实现了“**不生成文字、直接在 latent space 中推理**”，但目前核心瓶颈仍然是：**latent state 如何在高度压缩的同时保留足够的推理语义，并避免递归推理中的信息丢失和漂移。**
# 二、创新点与贡献
## 2.1 将 latent reasoning 建模为概率分布，而不是确定向量

以往 Coconut、CoLaR 等方法主要把 latent thought 看作一个确定的连续表示，ReGuLaR 则把第 $k$ 步 latent thought 建模为高斯分布 $p_\phi(z_k\mid Q,Z_{<k}) = \mathcal N(\mu_k,\operatorname{diag}(\sigma_k^2))$：已知问题 $Q$ 和前面所有 latent thought $Z_{<k}$，模型认为第 $k$ 步 latent thought $Z_{<k}$ 服从一个高斯分布。

再通过重参数化采样 $z_k=\mu_k+\sigma_k\odot\epsilon,\epsilon\sim\mathcal N(0,I)$：先采一个标准正态噪声 $\epsilon\sim\mathcal N(0,I)$，然后 $z_k=\mu_k+\sigma_k\odot\epsilon$，这样就能从 $\mathcal N(\mu_k,\sigma_k^2)$ 里得到一个具体样本 $z_k$。

注：
- $p_\phi$：参数由 $\phi$ 控制的概率模型。
- $\odot$：表示 **按元素相乘**，$z_i=\mu_i+\sigma_i\epsilon_i$ 就是每一个维度都用自己的 $\sigma_i$ 去乘对应的随机噪声 $\epsilon_i$。

因此 latent reasoning 从 $z_1\rightarrow z_2\rightarrow z_3$ 变成了 $q(z_1)\rightarrow q(z_2)\rightarrow q(z_3)$，即把 latent reasoning 放进 **VAE / 变分推断框架**中。

## 2.2 核心创新

**给 latent distribution 一个“有语义的 prior”**

单纯变成概率分布还不够，作者认为现有 latent reasoning 最大的问题是 latent state 一步步递归下去却**没有足够监督**，因此容易**信息丢失和 semantic drift**。

注：
semantic drift（语义漂移）：模型一开始还在想原来的问题，但 latent state 一步一步传下去以后，内部表示慢慢偏离了原本应该表达的意思。

所以他们引入 $D_{KL} \left[ p_\phi(z_k\mid Q,Z_{<k}) \Vert p_\gamma(z_k\mid R_k) \right]$，让模型自己产生的 posterior $p_\phi$ 不要乱跑，而要靠近一个包含真实 CoT 信息的 prior $p_\gamma$。

这其实才是这篇论文最关键的思想**允许 latent reasoning 是概率性的，但用语义先验把它“拴住”**。
## 2.3 很特别的一招：把 CoT 渲染成图片来构造 prior

这是这篇最显眼的技术点，它不是直接把`首先计算……然后……所以……”`压成 token embedding，而是`显式 CoT → 渲染成图片 → 视觉编码器 → 高密度视觉表示 → 作为 latent prior`，即 $R_k \xrightarrow{\text{render}} I_k \xrightarrow{\text{visual encoder}} v_k \xrightarrow{\text{adapter}} \hat z_k$，然后 $p_\gamma(z_k\mid R_k) = \mathcal N(\hat z_k,I)$。

注：
- $R_k$：第 $k$ 步对应的显式 CoT
- $R_k \rightarrow I_k$：把文字“渲染”成图片
- $I_k \rightarrow v_k$：视觉编码器提取表示
- $v_k \rightarrow \hat z_k$：adapter 转到 latent reasoning 空间。视觉编码器输出的 $v_k$ 和模型自己的 latent thought $z_k$，通常不在同一个空间里。比如 $v_k\in\mathbb R^{1024}$ 但 $z_k\in\mathbb R^{4096}$，所以中间放一个 adapter $\hat z_k=A(v_k)$ 把视觉表示转换成 latent reasoning 能使用的表示。因此 $\boxed{\hat z_k=\text{由真实 CoT 得到的 latent 参考中心}}$。
- $p_\gamma(z_k\mid R_k) = \mathcal N(\hat z_k,I)$：已知真实 CoT $R_k$，我们认为合理的 latent thought $z_k$ 应该分布在 $\hat z_k$ 附近。

作者的理由是，视觉编码器能够把大量文字以较少的视觉 token 压缩成高密度表示，因此相比简单地把若干 token embedding 平均/压缩，能少丢一些语义。
## 2.4 在 ELBO 下统一训练 latent reasoning

整个目标被写成类似 VAE 的 $\text{答案生成} + \text{latent 对 reasoning 的重构} - \text{KL 正则}$，也就是说同时要求：
1. $z_k$ 最后能把答案做对；
2. $z_k$ 还能包含对应 CoT 片段的信息；
3. 模型自己产生的 posterior 不要偏离 CoT 提供的 prior。

所以不是简单 $Q\rightarrow z\rightarrow A$，而是 $Q \rightarrow q_\phi(z) \overset{KL}{\longleftrightarrow} p_\gamma(z\mid CoT) \rightarrow A$，这给 latent state 增加了显式的信息约束。

注：
- $Q$：问题 Question
- $q_{\phi}(z)$：模型自己根据问题产生的 latent thought 分布
- $p_{\gamma}(z \mid CoT)$：由显式 CoT 构造出来的参考分布
- $A$：最终答案 Answer
## 2.5 还自然支持多模态 reasoning

因为它本来就把 reasoning 信息放进视觉表示，所以公式、图、文本等内容可以一起被编码进 latent state。

作者报告 ReGuLaR 在压缩 reasoning length 的同时超过已有 latent reasoning baseline，并在一些多模态 reasoning 场景甚至超过显式 CoT。
# 三、实验与结论（数据说明了什么、有什么局限性）

## 3.1 结论

1. **ReGuLaR 相比已有 latent reasoning 方法，确实同时提高了准确率并减少了推理步数**

在 LLaMA-3.2-1B 上，对 GSM8K-Aug、GSM-Hard、SVAMP、MultiArith 四个数据集测试。最强基线 CoLaR 的平均准确率为 $41.7\%$，平均 latent reasoning length 为 $4.70$；ReGuLaR 提升到 $45.6\%$，同时将平均推理长度降到 $3.03$，约减少 $35\%$。这说明 rendered-CoT prior 能让更少的 latent state 承载更多有效推理信息。

2. **压缩率越高，性能仍会下降，但 ReGuLaR 比 CoLaR 更抗压缩。**

作者控制相同 compression rate，比“token embedding 压缩”的 CoLaR 和“视觉语义压缩”的 ReGuLaR。随着一个 latent state 要承载越来越多 CoT token，两者准确率都会下降，但 ReGuLaR 在不同压缩率和两个 backbone 上一直优于 CoLaR。因此实验主要支持的是：**视觉 prior 比简单聚合 token embedding 更能保留原 reasoning 的信息**。

3. **即使把整个 CoT 压成一个 latent state，ReGuLaR 仍能工作。**

作者做了极端实验 $K=1$，也就是 $\text{整条 CoT}\rightarrow\text{一个 latent thought}$。

在 MATH 上，CoLaR 平均准确率只有 $7.76\%$，需要约 $62.2$ 个 latent steps；ReGuLaR 用 **1 个 latent step** 达到 $11.9\%$。在 AQUA-RAT 上同样是单步 ReGuLaR 明显优于 CoLaR。这个结果证明它的压缩能力确实很强，但也暴露出一个问题：**在真正困难的 MATH 上，绝对准确率仍然很低，11.9% 远谈不上解决复杂推理**。

4. **最重要的消融实验说明：真正决定性能的其实是 prior + KL 约束。**

只保留最终答案监督时，平均准确率只有 $12.8\%$；加入 reasoning reconstruction 但没有 KL，也只有 $13.1\%$。一旦加入 KL prior，即使不使用 reasoning reconstruction，准确率直接达到 $41.9\%$；三个目标全部使用时达到 $45.6\%$。

说明这篇论文真正有效的核心并不是单纯“把 thought 变成概率分布”，而是**利用有语义的 prior 对 latent distribution 进行约束**。[arXiv](https://arxiv.org/html/2601.23184)

5. **概率分布本身有作用，但提升其实没有 prior 那么大。**

作者还直接比较了 deterministic latent 和 probabilistic latent：
- $\text{Deterministic}:44.2\%$
- $\text{Probabilistic}:45.6\%$

概率建模确实更好，但平均只提升约 $1.4$ 个百分点。作者解释为确定性预测容易产生 mean collapse：多个可能的下一步被平均成一个模糊表示；概率分布则能采样出不同的、更明确的 latent states。
## 3.2 局限性

论文自己承认，目前大量实验仍集中在 GSM8K 一类规模有限、推理链较简单的数学数据上，因此还不能说明方法在真正长程、开放式复杂 reasoning 上同样有效。作者也明确把构建更大、更复杂的 reasoning benchmark 放到了 future work。

另外，我觉得还有三个对您研究特别重要、但论文没有充分解决的问题。

1. 它**训练时仍然依赖正确的显式 CoT** $CoT \rightarrow \text{render} \rightarrow p_\gamma(z\mid CoT)$

也就是说，它解决的是“**如何把已有的正确 reasoning 压进 latent space**”，而不是“模型如何在没有现成 CoT 的情况下自己发现新的 reasoning modes”。

2. 它使用的 prior 是 $p_\gamma(z_k\mid R_k)=\mathcal N(\hat z_k,I)$，本质上仍是**单峰高斯**。

如果一个问题存在 A、B、C 三种真正不同的解题思路，这种单峰 Gaussian 是否足够表达多模态 reasoning，论文没有回答。

3. 它虽然是 stochastic latent reasoning，但没有真正研究 $q_A(z),q_B(z),q_C(z)$ 这样的**多个独立 thought distributions 如何产生、保持差异、互相交流、竞争和融合**。
# 四、对我的启发

## 4.1 ReGuLaR 说明“用概率分布表示 latent thought”在技术上是可行的 

我的思路也可以把每个独立思路表示为分布 $q_A(z),q_B(z),q_C(z)$，而不是固定向量 $z_A,z_B,z_C$。这样每个思路不仅有一个中心状态，还能保留自身的不确定性和一定的发散空间。
## 4.2 ReGuLaR 提醒我：概率化之后必须控制 semantic drift

我的多个思路会连续演化、还会互相通信，因此漂移问题可能比 ReGuLaR 更严重。也就是说，不能只让 $q_i^{t}\rightarrow q_i^{t+1}$ 自由变化，还需要某种语义锚点，使每条思路始终和原问题、当前约束保持联系。

## 4.3 ReGuLaR 和我的核心问题不同

ReGuLaR 主要研究 $\text{一条 reasoning trajectory} \rightarrow \text{压缩成更少的 latent states}$

我的工作研究的是 $\{q_A,q_B,q_C\} \rightarrow \text{多个思路独立演化} \rightarrow \text{选择性交流} \rightarrow \text{继续推理}$

因此，ReGuLaR 的 distribution 主要服务于**压缩后的语义保持**；我的 distribution 则主要服务于**思路发散、不确定性表达和多思路交互**。
## 4.4 它给我的直接设计启发是：多思路交流不能只交换一个采样向量

如果每个思路本身是一个分布，那么通信时可以考虑传递 $(\mu_i,\Sigma_i)$，或者只选择性读取其中和当前问题相关的部分，而不是简单交换某一个 sampled latent $z_i$。这样更符合我原本设想的“不同思路保留自己的状态，只读取其他思路中有用的信息”。
