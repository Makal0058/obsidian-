> [!info] 基本信息
> - **论文题目**：Parallel Test-Time Scaling for Latent Reasoning Models
> - **中文题目**：面向潜在推理模型的并行测试时扩展
> - **期刊/会议**：ACL 2026（Long Papers）
> - **作者**：Runyang You, Yongqi Li, Meng Liu, Wenjie Wang, Liqiang Nie, Wenjie Li
> - **Tag**：#潜在推理 #测试时扩展 #并行推理 #随机采样 #潜在奖励模型 #思维链
```table-of-contents
```
# 一、研究背景（前人做到哪一步）
## 1.1 Test-Time Scaling（TTS）

**Test-Time Scaling** 已经成为提升大语言模型推理能力的重要方法：在推理阶段投入更多计算，而不重新训练模型。

现有方法主要有两条路线：  
1. **Sequential scaling**：让单条推理链更长
2. **Parallel scaling**：同时采样多条推理轨迹，再通过多数投票、Best-of-N 或搜索等方式进行聚合。

## 1.2 在传统 **token-based CoT** 中，并行 TTS 很自然，因为模型每一步都会输出 token 的概率分布，因此可以使用 top-k、nucleus sampling 等方法随机采样出多条不同的 reasoning trajectories。Parallel_Test-Time_Scaling_for_Latent_Reasoning_Models.pdfPDF
    
- 与此同时，已有研究开始转向 **Latent Reasoning / Continuous CoT**：不再要求每一步都生成自然语言 token，而是直接在连续 hidden space 中进行推理。相比显式 CoT，这种方法通常更紧凑、更高效，并且可能表达一些难以直接语言化的抽象推理模式。Parallel_Test-Time_Scaling_for_Latent_Reasoning_Models.pdfPDF
    
- 现有 latent reasoning 已经能够进行连续的自回归推理。例如 **COCONUT** 使用上一时刻的 hidden state 作为下一步 latent thought，并通过 curriculum learning 进行训练；**CODI** 则通过 self-distillation 学习 latent autoregression。Parallel_Test-Time_Scaling_for_Latent_Reasoning_Models.pdfPDF
    
- 但已有 latent reasoning 的一个关键缺口是：**缺少成熟的并行 Test-Time Scaling 能力。**  
    原因有两个：
    
    **① 缺少天然的采样机制。**  
    token 模型有显式概率分布，可以直接随机采样；但 latent reasoning 操作的是连续向量，并没有天然的 token probability distribution，因此不能直接复制传统 sampling 方法。Parallel_Test-Time_Scaling_for_Latent_Reasoning_Models.pdfPDF
    
    **② 缺少轨迹聚合和评分机制。**  
    token-based 方法可以利用 token likelihood 等信号给不同轨迹排序，但 latent trajectory 本身只是连续向量，没有天然的 likelihood 或 step-wise score，因此 Best-of-N、Beam Search 等方法不能直接使用。Parallel_Test-Time_Scaling_for_Latent_Reasoning_Models.pdfPDF
    
- 此前已经有少量工作尝试给 latent reasoning 加入随机性，例如 **CoLaR** 和 **SoftCoT++** 尝试注入噪声，但论文认为这些 stochastic latent reasoning 的探索仍然比较初步，尚未形成完整的 sampling + aggregation 框架。Parallel_Test-Time_Scaling_for_Latent_Reasoning_Models.pdfPDF
    

因此，这篇论文真正接着前人往前推进的问题是：

> **既然 token-based CoT 可以通过“多采样 + 聚合”获得并行 TTS，那么 latent reasoning 能不能也做到？如果可以，连续空间里该怎么采样，又该怎么选出最好的 latent trajectory？**

这也正是本文要解决的两个核心问题：**continuous latent space 中的 stochastic sampling**，以及 **latent trajectories 的有效 aggregation**。Parallel_Test-Time_Scaling_for_Latent_Reasoning_Models.pdfPDF
# 二、创新点与贡献

# 三、实验与结论（数据说明了什么、有什么局限性）

# 四、对我的启发（对我的研究有什么值得参考的）

