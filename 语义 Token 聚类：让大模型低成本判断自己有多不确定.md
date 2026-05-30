> [!info] 基本信息
> - **论文题目**：Semantic Token Clustering for Efficient Uncertainty Quantification in Large Language Models
> - **中文题目**：面向大语言模型高效不确定性量化的语义 Token 聚类
> - **期刊/会议**：EACL 2026 Short Papers
> - **年份**：2026
> - **Tag**： #LLM不确定性量化 #语义token聚类 #推理效率 #白盒模型 #RAG置信度

---
```table-of-contents
```
---
# 一、研究背景（前人做到哪一步）

**问题根源：LLM过度自信**。LLM在事实性任务上不保证准确，且存在过度自信问题——即使答案错误也会给出高置信度。因此需要uncertainty quantification（UQ）来识别不可靠输出
## 1.1 前人方法的两条路线
### 1.1.1 监督方法

训练额外的probe来预测生成结果的正确性。缺点是需要标注数据，且泛化性差
### 1.1.2 无监督方法

主流，又分三类：

1. **基于logit**：Perplexity直接用token级logit算uncertainty，简单但不感知语义——"TV"和"television"被当作完全不同的token处理

2. **基于多次采样**：Semantic Entropy、EigenScore、SAR等，通过多次随机采样衡量语义分散程度，语义感知能力强，但计算开销极高（overhead ~200-500%）

3. **基于单次生成+外部模型**：CCP用NLI模型做token级UQ，单次生成但依赖外部模型，overhead仍高达~60-130%

---
## 1.2 前人留下的空缺

没有方法同时满足：语义感知 + 单次生成 + 无外部模型 + 低开销。STC填的就是这个空

---
# 二、拟解决的问题（为什么现有方法不行）

## 2.1 **现有方法的核心矛盾**

语义感知能力和计算效率之间存在直接冲突，没有方法能同时拿到两边

---
## 2.2 逐类分析为什么不行

1. Perplexity类方法：计算极快，但语义盲——概率质量分散在语义等价token上的问题没有处理，导致系统性低估模型置信度，UQ质量差

2. 多次采样方法（Semantic Entropy、SAR等）：语义感知通过多次生成+NLI比较来实现，但代价是overhead 200-500%，相当于每次推理要多跑2-5倍的计算量。在实际部署场景（RAG检索触发、Agent决策门控）里完全不现实

3. CCP：把多次采样的需求压缩到单次生成，但语义感知依赖外部NLI模型，overhead仍有60-130%，且引入了额外依赖，不是self-contained的系统

---
## 2.3 根本原因

前人获取语义信息的方式都是**外部的**——要么多次采样后比较，要么调NLI模型判断语义等价性。这两种方式本质上都绕开了LLM内部已经编码好的语义结构

LLM的token embedding空间里，语义相近的token本来就聚集在一起，这个信息一直在那里，只是没人用来做UQ

---
## 2.4 STC的切入点

不从外部获取语义信息，直接利用LLM词表embedding中已有的语义结构，离线聚类一次，推理时零成本复用。把"外部语义感知"变成"内部语义利用"，从根本上打破了效率和语义感知之间的trade-off

---
# 三、创新点与贡献

## 3.1 核心创新：语义信息的获取路径不同

不依赖外部语义信号，直接把LLM词表embedding空间中已有的语义结构转化为UQ的计算单元。这一路径转变是方法论层面的，不只是工程优化

---
## 3.2 具体贡献

1. **Embedding Clustering** 把vocabulary按token embedding（input+output拼接）做Agglomerative Clustering，离线预计算一次，得到约16000个语义cluster。推理时直接查表，不引入任何额外计算。这是把**模型内部已知的语义结构显式化**的关键步骤

2. **Prefix Matching** 处理tokenization碎片化问题。television可能被切成"tele"+"vision"，embedding clustering未必能捕捉这种surface-form变体。prefix matching作为补充，把与后续生成内容前缀一致的token也纳入同一cluster，增强语义一致性。两个组件互补：clustering管语义相似，prefix matching管形式一致

3. **效率上的实质性突破** 推理时overhead仅1-7%，对比CCP的60-130%减少约98%，且全程CPU可运行，不需要GPU。这不是小幅改进，是量级差异

4. **性能不降** 在NQ/TQA/WQ三个数据集、六个模型上AUROC持平甚至略优于CCP，与多次采样方法持平。效率提升没有以性能换代价

---
## 3.3 贡献的边界

需要white-box访问是硬约束，闭源模型无法适用。静态embedding对polysemy的处理是遗留问题。校准（calibration）未涉及。这三点论文自己在Limitations里明确承认了

---
# 四、方法与模型

## 4.1 整体框架

两阶段流程，核心思想是把计算开销前置到离线阶段
### 4.1.1 预计算（离线，每个模型只做一次）

对全词表做 Embedding Clustering：

1. 每个 token 取 input embedding + output embedding 拼接
2. 用 Agglomerative Clustering（cosine distance）聚成 16000 个 cluster
3. 结果存成查找表

参数不敏感，Table 9-13 的 sensitivity analysis 显示 clustering 算法、距离度量、cluster 数量、embedding 类型换来换去结果基本不变，唯一例外是 single linkage 会显著掉点。

预计算时间从 Llama-2-7B 的 1 分钟到 Qwen2.5-14B 的 34 分钟不等，一次性成本
### 4.1.2 推理（在线）

每个 decoding step 做三件事：

1. **找语义等价 token 集合**

$$T_i = T_i^e \cup T_i^p$$

- $T_i^e$：与生成 token $y_i$ 同 cluster 的所有 token
- $T_i^p$：后续生成内容以该 token 为前缀的所有 token

2. **聚合概率质量**

$$\hat{p}_c(y_i|x, y_{<i}) = \sum_{t \in T_i} p(t|x, y_{<i})$$

3. **计算序列级 uncertainty score**

$$S(x,y) = 1 - \prod_{i=1}^{n} \hat{p}_c(y_i|x, y_{<i})$$

形式上和 negative log-likelihood 一脉相承，但每步用的是 cluster 概率质量而不是单 token 概率。

---
## 4.2 实现细节

- **停用词**：function words 从 clustering 中排除，"the"、"a" 之类语义聚类无意义
- **数字**：阿拉伯数字不参与 embedding clustering——embedding 相近的数字（如 3 和 8）数值上可能完全不等价，聚在一起反而引入噪声

---
## 4.3 方法本质

对 Perplexity 的语义感知升级版：把每步的单 token 概率替换成语义 cluster 的概率质量总和，其他结构不变。简单、自洽、可直接应用于任何 white-box LLM

---
# 五、实验与结论（数据说明了什么、有什么局限性）
## 5.1 实验设置
### 5.1.1 模型

- Llama-2-7B, Llama-3-8B, Mistral-7B-v0.3
- Qwen2.5-3B, Qwen2.5-7B, Qwen2.5-14B
### 5.1.2 数据集

- TriviaQA（TQA）：9960 samples
- Natural Questions（NQ）：3610 samples
- WebQuestions（WQ）：2032 samples
### 5.1.3 评估指标

- **AUROC**：uncertainty score 区分正确/错误答案的能力
- **PRR**（Prediction Rejection Ratio）：按uncertainty排序拒绝回答时的性能曲线
- 正确性判定用 GPT-4.1 作为 judge，而非 ROUGE-L——避免参考答案覆盖不全的问题

---
## 5.2 数据说明了什么

### 5.2.1 性能（Table 5，Figure 2）

- AUROC 全面持平或略优于 CCP（当前最强单次生成方法）
- 与 Semantic Entropy、EigV 等多次采样方法持平
- 对所有六个模型结论一致，没有模型依赖性
### 5.2.2 效率（Table 7-8，Figure 3）

- 推理时 overhead 仅 **1-7%**，对比基础推理
- CCP overhead 60-130%，Semantic Entropy 类 200-500%
- **对比 CCP 减少约 98% 的推理时间开销**
- 全程 CPU 可运行，不需要 GPU
### 5.2.3 消融实验（Table 2）

1. 两个组件都有贡献，缺一性能下降：embedding clustering 贡献 > prefix matching 贡献，两者互补

| 配置 | 性能影响 |
|------|----------|
| 去掉 embedding clustering | 中等下降 |
| 去掉 prefix matching | 小幅下降 |
| 两者都去掉（退化为原始概率） | 显著下降 |
2. Sensitivity Analysis（Table 9-13）

- clustering 算法（Kmeans vs Agglomerative）：几乎无影响
- 距离度量（Euclidean vs Cosine）：完全无影响
- cluster 数量（8000/12000/16000）：几乎无影响
- embedding 类型（input/output/concatenated）：几乎无影响
- linkage 设置：**single linkage 显著掉点**，average/complete 无差异

结论：方法对超参数高度不敏感，工程上稳定可靠

---
## 5.3 局限性
### 5.3.1 硬约束

**需要 white-box 访问**：token logits 和 token embeddings 在闭源模型（GPT、Claude 等）中不可获取，方法无法直接迁移
### 5.3.2 方法层面

1. **静态 embedding 的 polysemy 问题**：clustering 用的是脱离上下文的静态 embedding，同一个词的不同义项会被聚在同一 cluster。比如"cold"的温度义和感冒义会混在一起。实践中 LLM 对语义不兼容的 token 倾向于给低概率，能部分缓解，但没有从根本上解决。作者提出 future work 方向是引入 contextualized embedding

2. **没有做 uncertainty calibration**：输出的 uncertainty score 是相对排序有意义，但绝对数值没有经过校准，不能直接解释为概率。需要下游任务自行 post-calibrate
### 5.3.3 场景层面

**中文适用性下降：** prefix matching 的设计动机是英文 tokenization 碎片化，中文场景下这个组件基本失效，但 embedding clustering 仍然有效，整体方法可用，只是有一个组件变成死重量

### 5.3.4 三类扩展

论文只做了什么专门针对**事实性QA任务**的uncertainty quantification——输入一个问题，输出一个短答案，判断这个答案对不对。场景极其单一

1. **判断数据的不确定性** 理论上可以迁移。比如RAG里模型读了一段检索回来的文档，生成摘要或抽取答案，STC可以估计这个生成的置信度。但论文没有在这个场景下验证过

2. **判断决策的不确定性** Agent做决策时输出的是动作指令而不是事实答案，STC的score能不能反映"这个决策是否可靠"是未知的。事实性错误和决策错误的性质不同，uncertainty的含义也不一样，直接套用结论不可靠

3. **判断动作的不确定性** 同上，更复杂。动作往往是结构化输出（function call、JSON），token级的概率聚合是否还有意义需要单独验证。

**根本问题：** STC的uncertainty score本质上是**生成序列的token级概率的函数**，它反映的是"模型对这个字符串形式有多确定"。在事实性QA里这和"答案是否正确"有强相关，但在决策和动作场景里这个相关性是否成立，论文完全没有触碰