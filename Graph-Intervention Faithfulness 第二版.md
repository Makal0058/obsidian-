
```table-of-contents
```

----
# 1 Introduction

利用大语言模型（LLM）协助知识图谱和结构化数据的推理，已经成为一条重要的路线。关系路径规划[22]、图上搜索[19]、工具调用或受约束解码[23]等方法中，已有使LLM在多跳问答等图任务中利用显式图结构并得到的可观的性能提升。然而，LLM不能直接处理抽象图本身，必须将图这种结构化对象，转换成LLM可以处理的文本形式（例如边列表、邻接表或 JSON 序列化等）。token序列具有图本身不具有的额外属性，例如顺序、格式、位置等，图 $\to$ 文本的转化会引入额外信息。于是，一个设想上完全由图结构决定的推理任务，可能会在输入时附加一层token层面的诱导。前人研究已表明LLM对输入高度敏感：同一张图，仅改变描述格式、节点名称或边的排列顺序就可能改变LLM预测[1]；长上下文中模型更容易忽略中间信息[37]；多选题仅调换选项顺序即可显著改变预测[16]。早期 CoT faithfulness 研究已指出，应区分推理过程看起来合理与模型决策的真正依据（plausibility 与 faithfulness）[7]；随后，行为干预式 CoT faithfulness 研究进一步表明，判断忠实性需要通过输入扰动或偏置信号干预来观察模型行为是否随之改变 [4,5]。

本文继承前人的忠实性研究，从图结构 $\to$ token序列中揭露一个潜在的问题：模型在图任务中答对或答案随图干预改变时，是真的遵循图结构，又或是利用额外引入的”例如正确答案往往出现在终点位置“这种位置信息。换言之，答案随图改变只是图忠实性的必要非充分条件：真正遵循图结构的模型对干预敏感，但干预下的答案变化也可能来自终点位置的文本内容变化。同时，本文类比 CoT faithfulness 研究的思路与方法论，将该观察迁移到图推理中的结构化轨迹：一条路径看起来连贯，并且其末节点与最终答案一致，并不意味着该路径忠实于输入图，即模型可能生成内部自洽的 path 与 answer，但中间的某些路径并不是图中的合法边。因此，图推理中轨迹-答案一致只能说明形式自洽，不能替代路径合法性验证。本文继承 CoT faithfulness 研究干预式视角，但将忠实性的对象从语言解释转向外部图结构：不再关注模型 CoT，而通过反事实图、位置控制和路径合法性等手段检验模型答案与轨迹是否受到输入图结构的约束。总而言之，本文关注两层问题，第一层发生在答案：模型答案看似随图结构改变，但这种敏感性可能来自锚定序列化文本的终点位置。第二层发生在路径：模型输出的答案与路径末节点一致，甚至是最终答案正确，但中间的路径不一定是图中合法边。

本文提出 Graph-Intervention Faithfulness，简称 GIF，共包含两层受控诊断。路径层，首先构造正确终点不同且经符号验证的反事实图对，用于检测模型答案是否随图结构改变；其次为同一张图构造多种序列化版本，分别将正确终点放在开头 endpoint-first 、中间 endpoint-middle 、结尾 endpoint-last ，并在文本末尾放置错误的诱饵节点 decoy-last ，用于检验模型的“随图变换”是真正来自图跟随，还是终点这个位置信息。并定义原始图干预敏感性 Raw Graph Intervention Sensitivity（Raw GIS）、位置控制图干预敏感性 Position-Controlled GIS（PC-GIS）、图跟随能力虚胖 Graph-Following Inflation（GFI）和终点锚定率 Endpoint Anchoring Rate（EAR）。其中，$GFI = Raw GIS − PC-GIS$ ，用于检验位置虚胖是否存在，EAR用于衡量模型是否倾向于选择最后出现的节点。路径层，定义路径合法性 PathValid、黄金路径完全匹配 PathGoldExact、轨迹-答案一致性 Trace-Answer Consistency（TAC）和首次失败跳数 FailureHop 区分“轨迹自洽”与“图上合法”。

实验中为去除常识联想、参数记忆等统计关联，专注考察追踪推理能力，使用无语义先验的随机符号节点。进一步，通过无图先验控制 prior-only（不给图结构，看模型是否凭任务描述、节点名或候选项猜对答案）与无图候选控制 candidate-only controls（只给候选答案，看模型是否偏好某个候选位置或 token）排除答案先验和候选偏好造成的混淆，两种先验控制下准确率均接近零、低于随机基线。实验覆盖两类图族：链式图（chain graph）用于揭示仅输出答案下的终点位置捷径、分叉图（branching graph）用于检验模型能否在多跳分支中追踪当前状态，和三个模型：DeepSeek、Qwen 与 GPT-5.4-mini 并比较思考模式与 verifier-retry 等。

实验揭示两类容易被误认为图忠实的表面行为，其主导形态随难度和 prompt 发生此消彼长。

![[Pasted image 20260609230531.png]]

链式图弱提示下，模型表现出统计显著的答案层图跟随虚胖（DeepSeek-V4-Flash 的 Raw GIS 达 68.5%，但 PC-GIS 降为 0%，说明答案随图改变可能主要来自终点位置锚定，而非真实结构跟随），进一步，chain 长度扫描显示，DeepSeek-V4-Flash 稳定依赖终点位置捷径（endpoint-position shortcut），GPT-5.4-mini 表现为中间型捷径依赖，而 Qwen Max 在较长链上逐渐失去图干预敏感性（原因主要是模型已难以稳定响应图干预）。结果表明不同模型存在不同程度与性质的图跟随虚胖。同时，Qwen 实验表明 GFI 需与 Raw GIS 一起解释，只在 Raw GIS 较高而 PC-GIS 较低时，GFI 才刻画图跟随虚胖；若 Raw GIS 本身接近 0，则更应理解为图干预敏感性崩塌。

当转入分叉图 branching graph 后，失败的主要因素从答案层的位置捷径转向路径层的非法路径。在12hop + jsoncot_strict 的组合中，DeepSeek-V4-Flash 的 轨迹-答案一致性 TAC 为 99.3%，但非法路径差距 $\Delta_{\text{illegal}}$ 达到了 50.8%；Qwen Max 则更加极端，TAC 为 99.2%，$\Delta_{\text{illegal}}$ 高达 90.8%。jsoncot_strict 能让模型生成看似完整、答案一致的轨迹，却不能保证轨迹中的每一步都忠实于图。基于此，本文尝试了两种缓解机制：内部预算推理（思考模式） vs 外部符号反馈（verifier-retry）。![[Pasted image 20260609232618.png]]
DeepSeek-V4-Pro thinking 在 branching-12hop 上几乎完美解决任务，PathGoldExact 达 99.9%，但平均耗时 46.7 秒；相比之下 DeepSeek-V4-Flash_verifier-retry 的PathGoldExact 从 pass@1 的 48.6% 提升到 pass@5 的 70.6%，累计平均耗时 4.42 秒，说明外部符号验证能以较低延迟放大已有的图跟随能力；值得注意的是，Qwen Max 仅从 8.4% 提升到 33.4%，说明外部符号反馈只是放大而非凭空创造能力，其收益受底座模型状态追踪能力限制。

最后总结本文贡献。第一，问题层面，指出图任务的高准确率、轨迹-答案一致性等都不足以证明 LLM 忠实使用图，模型既可能在答案层依赖终点位置捷径，也可能在路径层生成自洽但图上非法的轨迹。第二，方法层面，提出一种面向序列化图推理的图干预忠实性诊断框架 GIF，结合反事实图对、位置控制序列化等，诊断答案层的位置锚定与路径层的非法轨迹，并定义 GFI、EAR、$\Delta_{\text{illegal}}$ 和 FailureHop 等指标。第三，发现层面，揭示了 LLM 图推理中的两类假忠实性及其随任务难度切换主要影响。弱提示链式图主要暴露答案层位置虚胖；困难分叉图暴露路径层非法轨迹。两种缓解机制显示 thinking 几乎完美消除失败，代价是时间太长，verifier-retry 能以较低延迟部分修复非法路径，但受限于底座模型能力。

---
# 2 Related Work

## 2.1 语言化推理忠实性与结构化路径输出

CoT 提示提升了 LLM 在数学、逻辑和多步推理任务上的表现，但也引出了一个核心问题：模型生成的推理过程是否真实反映了驱动其预测的因素。已有的忠实性研究区分了合理性（plausibility）与忠实性（faithfulness）[7]，这点对图推理同样重要：一个推理路径可以看起来完整连贯，但不忠实于图。行为干预式研究进一步表明，忠实性不能只通过阅读判断模型生成的解释，还需要观察模型在输入扰动、偏置信号或反事实条件下的行为是否相应改变。Turpin 等人表明，模型可能受输入中偏置信号影响，生成看似合理的解释[5]；Lanham 等人通过改变或移除 CoT，观察最终答案是否随之变化来衡量 CoT 是否真的参与模型决策[9]。前人的这些工作已经说明，模型生成的推理过程不一定真实反映驱动预测的因素，最终答案正确、解释看起来合理、解释忠实推理是不同的属性。近期工作还区分了语言化忠实性与更广义的因果或结构忠实性。Young 等人检验推理模型 CoT 是否显式承认影响答案提示或偏置信号，但这仍主要是检验模型是否报告相关因素[4]。白盒计算图验证方法提供另一条互补路径，但通常依赖特定模型并需要访问内部激活[6]。现有忠实性工作大多关注语言化推理是否忠实地报告模型答案的成因。与之不同，本文借鉴这一方法论，但将对象从语言化解释转向图推理中的结构化路径输出。图推理中，真正相关的问题不只是模型能否给出合理解释,而是输出路径是否真的由图的合法边组成。轨迹与答案一致只能说明输出内部自洽,不能替代路径合法性验证。GIF 利用 TAC 、PathValid、PathGoldExact 和 FailureHop 等诊断“自洽但图上非法”的路径层失败。

## 2.2 序列化位置敏感性与反事实诊断

图是无序结构，LLM 处理的是token序列，当图结构被转换为边列表、邻接表、JSON、自然语言描述或工具返回的局部观察时，节点和边将不可避免的获得某种顺序和位置。已有研究表明，LLM 图推理器缺乏序列化不变性，一张图的等价文本表示在仅更改节点标号、边排列顺序或描述格式的情况下，就可能改变模型输出[1]。类似的位置敏感性也出现在其他任务中，例如，多选题中调换选项顺序即可显著影响模型预测[16]；列表排序[13]和推荐任务[14]中，项目位置也会影响模型判断。这些结果共同说明，本应与任务语义无关的顺序和位置，可能被 LLM 当作决策线索。反事实基准被用于排除特定捷径，CofCA 构造反事实多跳问答样本降低模型对记忆性事实的统计关联，检验模型能否真正沿给定上下文完成多步推理[30]。这与本文动机高度相关：CofCA 针对的是记忆关联造成的推理虚胖；GIF 关注的是序列化图后额外引入的位置和顺序线索造成的图跟随虚胖。二者都在追问同一个问题：当某条捷径被系统性控制后，表面上的推理表现是否仍然成立？这一观察直接对应本文的答案层诊断问题。在序列化图推理中，正确终点可能稳定出现在文本中的显著位置，使模型即使没有真正沿图结构推理，也表现出答案随图干预改变的表面敏感性。GIF 通过 endpoint-first \ middle \ last 和 decoy-last 等位置控制，进一步区分真实结构敏感性与终点位置锚定，并用 GFI 和 EAR 量化答案层的图跟随虚胖。

## 2.3 图推理、路径跟随与验证

一类方法围绕知识图谱路径和显式图式推理展开：它们生成或检索关系路径[22]，沿给定路径完成推理[24]，构造显式图式推理过程[25]，或对生成过程施加路径约束[26]，使模型借助显式图结构完成多跳问答。另一类将图推理建模为图上搜索[19]、工具调用[23]等，让模型通过搜索函数或图工具逐步获取邻居信息并完成推理。这些方法表明显式图结构能提高图任务和多跳问答表现。然而，性能提升或路径生成本身并不自动证明模型忠实使用了图结构。首先，若输入图或检索路径以线性文本形式呈现，模型可能受到终点、顺序或格式线索的影响。其次，即使模型生成显式路径，该路径也可能只是在输出层面与答案自洽，不一定对应输入图上的合法边。因此，图结构“被提供”、“被检索”或“被生成”与图结构“被忠实遵循”之间仍存在诊断缺口。这一点对路径奖励和路径对齐方法尤其重要，此类方法通常要求模型外显一条候选路径，才能计算该路径与知识图谱或目标 CoT 的对齐程度[28]。但路径外显本身并非中性，改变输出接口可能显著改变模型的失败模式。本文结果显示，要求模型输出结构化路径，一方面可以显著压低 answer-only 设置下的终点位置捷径，另一方面并不保证生成路径真的由输入图中的合法边组成，路径层仍可能存在非法轨迹问题。因此，依赖路径外显的训练或评测方法，也需要显式检验路径合法性与位置控制下的结构忠实性。已有一些工作开始超越纯答案准确率，关注路径或推理过程的结构有效性。例如，FidelityAcc 仅当答案正确且预测路径可达时，才将一次预测记为正确[29]，这是本文最接近的评测动机之一。但 FidelityAcc 主要关注答案是否由可达路径支撑，并未进一步隔离序列化位置线索，同时也没有诊断答案层的图跟随虚胖。GIF 与这些工作互补：一方面，通过反事实图对与位置控制，检验答案是否真的受图结构而非终点位置控制；另一方面，通过 PathValid、PathGoldExact、TAC 和 FailureHop，检验结构化轨迹是否真的是输入图上的合法路径。也就是说，GIF 不仅问“答案是否由某条路径支撑”，还问“答案是否在位置控制后仍随图结构改变”，以及“模型生成的这条路径是否真的忠实于图边”。

总体而言，已有工作分别回答了三个相邻但不同的问题：图推理工作主要关心如何利用图结构提高最终答案表现、图序列化工作主要关心不同的输入线性化方式如何影响模型输出、路径验证工作主要关心生成路径是否可被检查，以及是否能够支撑答案。GIF 关注的是一个更细的图忠实性问题：图被序列化为文本后，模型答案和结构化路径是否仍受输入图结构本身约束，而非由终点位置、边列表顺序或输出内部自洽性制造出表面忠实性。为此，GIF 将反事实图干预、位置控制序列化和路径级合法性验证结合起来，同时诊断答案层的图跟随虚胖与路径层的自洽但非法轨迹。

---
# 3 Graph-Intervention Faithfulness

本节提出 Graph-Intervention Faithfulness，简称 GIF。GIF 是一个黑箱诊断框架，用于检验 LLM 在序列化图任务中是真正受输入图结构约束，还是文本位置线索、答案先验或输出内部自洽性制造出表面忠实性。GIF 关注两层忠实性。第一层是答案层忠实性：模型答案是否随图干预而改变，并且这种变化是否在控制终点位置后保持，即$\text{答案随图干预改变} \overset{?}{\Longleftrightarrow} \text{答案忠实遵循图}$。形式化地，令 $R$ 表示一个理想但不可直接观测的事件：模型预测结果因果上由输入图结构 $G$ 控制；令 $C_\alpha$ 表示一个可观测事件：某一序列化操作 $\sigma_\alpha$ 下，模型在反事实图对 $(G_1,G_2)$ 上分别输出对应的正确终点 $y_1$ 与 $y_2$ 。图忠实性蕴含反事实敏感性 $R \Rightarrow C_\alpha$ ，但反事实敏感性并不天然蕴含图忠实性 $C_\alpha \nRightarrow R$ 。原因是答案可能是跟随图干预同步变化的文本，而非图结构本身。例如，若 $G_1$ 中正确终点 $y_1$ 总是出现在边列表最后，$G_2$ 中正确终点 $y_2$ 也总是出现在边列表最后，那么模型只需学会“输出最后出现的节点”就可表现出很高的图干预敏感性，位置控制正是为了诊断这个 $C_\alpha$ 与 $R$ 之间的缺口。第二层是路径层忠实性：当模型输出结构化路径时，该路径是否真的是图中合法路径，而非仅与最终答案自洽，即$\text{轨迹与答案一致} \overset{?}{\Longleftrightarrow} \text{轨迹在图上合法}$。令 TAC 表示模型输出路径的末节点是否等于模型给出的答案，PathValid 表示模型从起点出发，每一步都沿真实边移动且长度正确，则 $\mathrm{TAC}=1 \not\Rightarrow \mathrm{PathValid}=1$，即模型生成的轨迹可以与正确答案完全自洽，但不是图上的合法路径。

## 3.1 任务设定与反事实图对构造

给定有向图 $G=(V,E)$，$V$ 为节点集合，$E\subseteq V\times V$ 为有向边集合，关注一种受控定长多跳图推理任务：给定起跳点 $s\in V$ 和跳数 $k$，模型需从点 $s$ 出发，沿图中合法有向边走 $k$ 跳后输出最终到达的节点。一条长为 $k$ 的合法路径记为 $p^*=(v_0,v_1,\dots,v_k)$，其中 $v_0=s$，$v_k=y$，且对 $\forall i\in{0,\dots,k-1}$，有 $(v_i,v_{i+1})\in E$ 。任务标准答案为路径终点 $y=v_k$。

由于 LLM 不能直接处理图 $G$，只能处理图的线性化文本表示。因此定义一个序列化函数 $\sigma_\alpha(G)=(x_1,x_2,\dots,x_n)$。其中 $\alpha$ 表示一种具体的序列化配置，包括节点标号、边顺序、语法格式以及位置控制策列。给定任务描述 $T$ 和序列化图 $\sigma_\alpha(G)$ ，模型输出最终答案 $\hat{a}$，并在结构化提示下额外输出显式路径 $\hat{p}$，得到 $f_\theta(T,\sigma_\alpha(G))\rightarrow(\hat{p},\hat{a})$。




$$  
.  
$$

在 answer-only prompt 下，模型只输出答案，可视为：

$$  
\hat{p}=\varnothing.  
$$

为了检验模型答案是否真正受图结构控制，构造反事实图对：

$$  
(G_1,G_2).  
$$

两张图共享相同的起点 (s) 和跳数 (k)，但对应的合法 (k)-hop 终点不同：

$$  
G_1: s \xrightarrow{k\text{ hops}} y_1,  
$$

$$  
G_2: s \xrightarrow{k\text{ hops}} y_2,  
$$

且：

$$  
y_1\neq y_2.  
$$

对应的黄金路径分别为：

$$
p_1^* = (s,\dots,y_1),\qquad p_2^* = (s,\dots,y_2).
$$

如果模型真正遵循输入图结构，那么当图从 (G_1) 被干预为 (G_2) 时，模型答案也应该从 (y_1) 改为 (y_2)。这构成答案层图忠实性的必要条件。但这个条件并不充分：模型可能并没有沿图推理，而只是利用了与图干预同步变化的文本线索，例如正确终点总是出现在边列表最后。后续位置控制正是为了排除这类混淆。

在实验构造中，我们使用随机符号节点以削弱语义先验，并通过 prior-only 和 candidate-only prior controls 检查无图条件下的固定答案偏好。若模型在无图条件下已经稳定输出某一候选答案，则该样本可能被视为 prior-confounded，并在主实验中剔除或单独报告。本文的主实验中，prior controls 表明答案先验和候选偏好不能解释主要结果。

此外，本文核心实验采用唯一黄金路径设定：给定 ((G,s,k))，从 (s) 出发恰好 (k) 跳可达的合法终点唯一，对应黄金路径 (p^_) 也唯一。该唯一性通过符号枚举验证。需要强调的是，唯一性主要用于定义 PathGoldExact；路径合法性、TAC 和 FailureHop 并不依赖唯一黄金路径。若未来扩展到多合法路径场景，可将单一路径 (p^_) 替换为黄金路径集合 (P^*)。
## 3.2 Position-Controlled Serialization

反事实图对检验模型答案是否随图改变，但无法排除序列化位置捷径。尤其是在边列表或邻接表序列化中，正确终点可能位于文本中的显著位置，例如最后一条边、最后一个节点或列表末端。此时，模型即使不沿图推理，也可能通过“选择最后出现的节点”获得较高的图干预敏感性。

为此，GIF 对同一张图 (G) 构造一组位置控制序列化：

$$  
\Sigma(G)=  
{  
\sigma_{\text{first}}(G),  
\sigma_{\text{middle}}(G),  
\sigma_{\text{last}}(G),  
\sigma_{\text{decoy}}(G)  
}.  
$$

其中，($\sigma_{\text{first}}$)、($\sigma_{\text{middle}}$) 和 ($\sigma_{\text{last}}$) 分别将正确终点节点置于序列化边列表的较前、中间和结尾位置。这三个变体构成终点位置扫描，用于检测模型是否稳定依赖正确终点的文本位置。

($\sigma_{\text{decoy}}$) 则是一个对抗探针：它将一个非答案诱饵节点放在结尾位置。该诱饵节点 ($d$) 满足：

$$  
d\neq y,  
$$

并且不是从起点 ($s$) 出发恰好 ($k$) 跳可达的合法答案。若模型在 decoy-last 条件下输出诱饵节点，则说明模型可能依赖“最后出现节点”这一位置线索，而不是沿图求解。

位置控制的目标是在保持图结构不变的前提下，只改变文本位置线索。若模型真正忠实于图结构，则对于任意位置控制序列化 ($\sigma_\alpha(G)\in\Sigma(G)$)，模型都应输出同一个图结构答案 ($y$)

## 3.3 Answer-Level Metrics: Raw GIS, PC-GIS, GFI, and EAR

答案层指标用于诊断模型答案是否真正受图结构干预控制，以及这种表面图敏感性是否被终点位置线索虚高。

对第 ($j$) 个反事实图对 ($(G_1^{(j)},G_2^{(j)})$)，其对应终点为 ($y_1^{(j)}$) 和 ($y_2^{(j)}$)。在某一序列化条件 ($\alpha$) 下，定义模型是否随图干预正确改变答案：

$$  
C_{\alpha}^{(j)}

\mathbb{1}  
\left[  
f_\theta(T,\sigma_\alpha(G_1^{(j)}))=y_1^{(j)}  
;\wedge;  
f_\theta(T,\sigma_\alpha(G_2^{(j)}))=y_2^{(j)}  
\right].  
$$

### Raw Graph Intervention Sensitivity

Raw Graph Intervention Sensitivity，简称 Raw GIS，衡量模型在未进行位置控制或默认有利序列化条件下，答案是否随反事实图干预改变。在本文实验中，raw 条件对应 endpoint-last 风格序列化，即正确终点位于较显著的结尾位置。该设置用于刻画不控制位置时可能得到的表面图跟随表现。

对样本 ($j$)，定义：

$$  
\mathrm{RawGIS}^{(j)}=C_{\text{raw}}^{(j)}.  
$$

数据集层面的 Raw GIS 为：

$$  
\mathrm{RawGIS}

\frac{1}{N}\sum_{j=1}^{N}\mathrm{RawGIS}^{(j)}.  
$$

Raw GIS 高说明模型答案随图干预改变，但这只是图忠实性的必要条件，不是充分条件。若正确答案在两个反事实图中都位于显著位置，模型可以仅凭位置启发式获得较高 Raw GIS。

### Position-Controlled GIS

Position-Controlled GIS，简称 PC-GIS，要求模型在所有位置控制序列化下都能正确随图改变答案。对样本 ($j$)，定义：

$$  
\mathrm{PCGIS}^{(j)}

\prod_{\alpha\in\Sigma}  
C_{\alpha}^{(j)}.  
$$

也就是说，只有当模型在 endpoint-first、endpoint-middle、endpoint-last 和 decoy-last 四种条件下都对反事实图对作出正确响应时，($\mathrm{PCGIS}^{(j)}=1$)。

数据集层面的 PC-GIS 为：

$$  
\mathrm{PCGIS}

\frac{1}{N}\sum_{j=1}^{N}\mathrm{PCGIS}^{(j)}.  
$$

PC-GIS 比 Raw GIS 更严格，因为它要求模型的图干预敏感性不能依赖某个特定的终点位置。

### Graph-Following Inflation

Graph-Following Inflation，简称 GFI，用于量化 Raw GIS 中可能被位置线索虚高的部分。对样本 ($j$)，定义：

$$
\mathrm{GFI}^{(j)}
=
\mathrm{RawGIS}^{(j)}
-
\mathrm{PCGIS}^{(j)}.
$$

数据集层面的 GFI 为：

$$  
\mathrm{GFI}

\frac{1}{N}\sum_{j=1}^{N}\mathrm{GFI}^{(j)}.  
$$

当 Raw GIS 高而 PC-GIS 低时，GFI 会升高，说明模型在默认序列化下看似能随图改变答案，但这种能力无法通过位置控制检验。本文将这种现象称为图跟随虚胖：模型的表面图敏感性被终点位置等文本捷径高估。

### Endpoint Anchoring Rate

为了直接测量模型是否被显著位置吸引，GIF 还报告 decoy-last Endpoint Anchoring Rate，简称 EAR。

设 ($d^{(j)}$) 是第 ($j$) 个样本在 decoy-last 序列化中被放在最后的诱饵节点。该节点满足：

$$  
d^{(j)}\neq y^{(j)}.  
$$

定义样本级 decoy-last EAR 为：

$$  
\mathrm{EAR}_{\text{decoy}}^{(j)}

\mathbb{1}  
\left[  
\hat{a}_{\text{decoy}}^{(j)}=d^{(j)}  
\right],  
$$

其中 ($\hat{a}_{\text{decoy}}^{(j)}$) 表示模型在 decoy-last 条件下的输出答案。数据集层面取平均：

$$  
\mathrm{EAR}_{\text{decoy}}

\frac{1}{N}\sum_{j=1}^{N}  
\mathrm{EAR}_{\text{decoy}}^{(j)}.  
$$

decoy-last EAR 是比 endpoint-last 选择率更干净的锚定指标，因为在 decoy-last 条件下，最后出现节点被保证为错误诱饵。若模型仍输出该节点，则更直接地说明它受到位置线索驱动。

---

## 3.4 Path-Level Metrics: TAC, PathValid, PathGoldExact, and FailureHop

答案层诊断仍然不充分。即使模型给出正确答案，或者答案随图干预改变，也不能说明它真的沿图走了一条合法路径。特别是在结构化 CoT 或 JSON path 输出中，模型可能生成一条看似完整、且终点与答案一致的路径，但其中某些边并不存在于输入图中。

因此，GIF 进一步引入路径层指标，用于区分“文本自洽”与“图上合法”。

设模型输出路径为：

$$  
\hat{p}=(\hat{v}_0,\hat{v}_1,\dots,\hat{v}_k),  
$$

输出答案为：

$$  
\hat{a}.  
$$

### Trace-Answer Consistency

Trace-Answer Consistency，简称 TAC，检查路径终点是否等于最终答案：
$$  
\mathrm{TAC}(\hat{p},\hat{a})

\mathbb{1}  
\left[  
\hat{a}=\hat{v}_k  
\right].  
$$

TAC 高说明模型输出内部自洽：它声称的路径终点与最终答案一致。然而，TAC 不检查路径是否真的存在于图上。

### Path Validity

PathValid 检查模型输出路径是否为输入图上的合法 ($k$)-hop walk：


$$  
\mathrm{PathValid}(\hat{p},G)

\mathbb{1}  
\left[  
\hat{v}_0=s  
;\wedge;  
|\hat{p}|=k+1  
;\wedge;  
\forall i\in{0,\dots,k-1},,  
(\hat{v}_i,\hat{v}_{i+1})\in E  
\right].  
$$

该指标同时检查三件事：路径是否从指定起点出发，路径长度是否正确，以及每一步是否沿图中真实存在的边移动。

### Self-Consistent but Illegal Trace Gap

为了量化“轨迹自洽但图上非法”的失败模式，定义非法路径差距：

$$
\begin{aligned}
\Delta_{\text{illegal}}
&= \mathrm{TAC} - \mathrm{PathValid}.
\end{aligned}
$$

当 TAC 很高而 PathValid 很低时，($\Delta_{\text{illegal}}$) 会很大，说明模型能够生成与答案一致的结构化轨迹，却没有生成输入图上的合法路径。该指标是本文路径层诊断的核心信号。

这一点可写成：

$$  
\mathrm{TAC}=1  
;\not\Rightarrow;  
\mathrm{PathValid}=1.  
$$

即，轨迹与答案一致，并不意味着轨迹忠实于输入图结构。

### Path Gold Exact

在唯一黄金路径设定下，进一步定义 PathGoldExact：

$$  
\mathrm{PathGoldExact}(\hat{p},p^*)

\mathbb{1}  
\left[  
\hat{p}=p^*  
\right].  
$$

PathGoldExact 比 PathValid 更严格。PathValid 只要求路径是合法的 ($k$)-hop walk；PathGoldExact 要求模型路径完全等于生成器标注的黄金路径。在当前唯一黄金路径设置下，二者数值通常高度一致；但在多合法路径设置中，PathValid 和 PathGoldExact 可以分离。

若未来扩展到多条合法黄金路径，可定义：

$$  
\mathrm{PathGoldExact}(\hat{p},P^*)

\mathbb{1}  
\left[  
\hat{p}\in P^*  
\right].  
$$

### FailureHop

为了定位模型从哪一步开始偏离图结构，定义 FailureHop。若模型输出路径长度不足、起点错误或格式错误，则将其记录为相应错误类型；若路径长度足够且起点正确，则 FailureHop 为第一条非法边所在的 hop：

$$
\operatorname{FailureHop}(\hat{p}, G)
=
\min
\left\{
i \in \{1,\dots,k\}
:
(\hat{v}_{i-1}, \hat{v}_i) \notin E
\right\}.
$$

若全部边均合法，则 FailureHop 记为 pass。

FailureHop 的作用是把“路径错了”细化为“从第几跳开始错”。这对于分析分叉图尤其重要，因为模型可能反复在早期分叉点、终端转移或特定状态更新位置失败。后续实验将使用 FailureHop 区分局部结构瓶颈与整体状态追踪失败。

## 3.5 Symbolic Verifier and Retry

GIF 的核心是诊断模型原始行为，但我们还引入符号 verifier-retry，用于研究外部结构反馈是否能修复非法路径，以及这种修复是否受底座模型能力限制。

给定第 ($j$) 个样本在第 ($t$) 次尝试中的输出：

$$  
(\hat{p}_{j,t},\hat{a}_{j,t}),  
$$

符号验证器检查以下条件：

1. 输出是否可解析为指定格式；
    
2. 路径是否从起点 ($s$) 出发；
    
3. 路径长度是否为 ($k+1$)；
    
4. 每一条边是否属于输入图 ($E$)；
    
5. 路径终点是否等于模型答案 ($\hat{a}_{j,t}$)
    

需要强调的是，在线 verifier feedback 不泄露黄金答案 ($y$)，也不直接告诉模型正确下一跳。黄金答案正确性只在离线评估阶段计算。

若验证失败，验证器返回结构性错误反馈，例如：

```text
Your path is invalid at hop 3:
edge (J9E9, W6S2) does not exist in the graph.
Please retry with a valid k-hop path from the given start node.
```

模型随后重新生成路径和答案，最多尝试 ($K$) 次。记第 ($j$) 个样本第一次通过验证的尝试编号为：

$$  
\tau_j

\min  
{  
t:  
\mathrm{VerifierPass}_{j,t}=1  
}.  
$$

若在 ($K$) 次内始终未通过，则记为：

$$  
\tau_j=\infty.  
$$

定义 $pass@K$：

$$  
\mathrm{pass@}K

\frac{1}{N}  
\sum_{j=1}^{N}  
\mathbb{1}  
[  
\tau_j\le K  
].  
$$

除了 $pass@K$，GIF 还记录每次尝试的延迟、错误类型和 FailureHop。设第 ($j$) 个样本第 ($t$) 次尝试的延迟为 ($\ell_{j,t}$)，则预算 ($K$) 下的累计延迟为：

$$  
L_j^{(K)}

\sum_{t=1}^{\min(\tau_j,K)}  
\ell_{j,t},  
$$

其中若 ($\tau_j=\infty$)，则累计全部 ($K$) 次尝试。数据集平均累计延迟为：

$$  
L^{(K)}

\frac{1}{N}  
\sum_{j=1}^{N}  
L_j^{(K)}.  
$$

因此，verifier-retry 不仅报告最终修复率，还报告成本—效果曲线：

$$  
(\mathrm{pass@}1,L^{(1)}),  
(\mathrm{pass@}2,L^{(2)}),  
\dots,  
(\mathrm{pass@}K,L^{(K)}).  
$$

对于在 ($K$) 次后仍失败的样本，进一步统计其最终错误类型和最终 FailureHop 分布：

$$  
{e_{j,K}:\tau_j=\infty},  
$$

$$  
{h_{j,K}:\tau_j=\infty}.  
$$

这一步用于判断剩余失败是随机噪声，还是稳定结构瓶颈。如果模型在多次 retry 后仍反复卡在同一 hop，则说明 verifier 能发现错误，但模型本身缺少修复该错误所需的状态更新能力。

因此，verifier-retry 在 GIF 中有双重作用。它既是一个低成本修复机制，用于检验外部符号反馈能否提高路径合法性；也是一个诊断工具，用于区分“模型能在反馈下修正路径”与“模型反复卡在同一结构转移处”这两种情况

---
# 4 Experimental Setup

本节说明实验如何运行，包括数据集构造、模型与 prompt 设置、输出解析、统计方法和延迟记录。GIF 的指标定义已在第 3 节给出，本节不再重复框架定义，只描述具体实验配置。

## 4.1 Synthetic Graph Construction

我们构造合成符号图任务，而不是直接使用自然语言知识图谱。每个节点使用随机符号标识，例如 `J9E9`、`W6S2` 等，以削弱实体名称、常识关联和参数记忆带来的语义先验。这样，模型若要完成任务，主要必须依赖输入中的显式图结构。

每个基础样本包含一个起点 ($s$)、一个跳数 ($k$)、一条唯一黄金路径 ($p^*$) 和一个黄金终点 ($y$)。模型任务是从 ($s$) 出发，沿图中合法有向边恰好走 ($k$) 跳，并输出最终节点。

对于每个基础样本，构造一组反事实图对：

$$  
(G_1,G_2),  
$$

其中两张图共享相同起点 ($s$) 与相同跳数 ($k$)，但拥有不同黄金终点：

$$  
y_1\neq y_2.  
$$

每张图进一步生成四种位置控制序列化：

$$  
\sigma_{\text{first}},  
\quad  
\sigma_{\text{middle}},  
\quad  
\sigma_{\text{last}},  
\quad  
\sigma_{\text{decoy}}.  
$$

因此，每个基础样本对应：

$$  
2 \times 4 = 8  
$$

个模型查询。每个数据集包含 (N=200) 个基础样本，因此每个 dataset 在单一模型和单一 prompt 下包含：

$$  
200 \times 2 \times 4 = 1600  
$$

个查询。

本文使用六个主数据集：

|Dataset|Topology|Hop length|Base samples|Queries per model/prompt|
|---|--:|--:|--:|--:|
|chain_3hop_N200|Chain|3|200|1600|
|chain_4hop_N200|Chain|4|200|1600|
|chain_5hop_N200|Chain|5|200|1600|
|chain_6hop_N200|Chain|6|200|1600|
|branching_4hop_N200|Branching|4|200|1600|
|branching_12hop_N200|Branching|12|200|1600|

### Chain graphs

Chain graphs 用于检测 answer-only 接口下的 endpoint-position shortcut。在链式图中，从起点到答案存在唯一黄金路径，结构相对简单，因此如果模型表现出较高 Raw GIS 但 PC-GIS 为 0，就能较清楚地说明模型依赖了终点位置，而不是真正稳定地使用图结构。

我们使用 chain-3hop 到 chain-6hop 进行长度扫描。该设置用于观察弱提示下的答案层失败是否随 hop 长度变化，并比较不同模型是否表现出稳定位置捷径、部分捷径依赖或图干预敏感性崩溃。

### Branching graphs

Branching graphs 用于检测路径层状态追踪能力。与链式图不同，分叉图在中间节点处包含多个候选分支，模型不能只依赖最后出现节点或局部显著节点，而必须持续维护当前节点状态，并在每一步选择图中真实存在的后继边。

我们使用 branching-4hop 和 branching-12hop 两档难度。branching-4hop 作为中间难度设置，用于观察从简单链式读取到分叉状态追踪之间的过渡；branching-12hop 作为主要困难设置，用于放大长程状态追踪失败和非法路径生成。

### Graph validation

所有图在进入实验前均通过符号程序验证。验证内容包括：

1. ($G_1$) 与 ($G_2$) 均包含完整图结构；
    
2. 两张图共享相同起点 ($s$) 与跳数 ($k$)；
    
3. 两张图的黄金终点不同，即 ($y_1\neq y_2$)；
    
4. 每张图中从 ($s$) 出发恰好 ($k$) 跳的黄金终点唯一；
    
5. 当前实验设定下黄金路径唯一；
    
6. decoy 节点不是合法答案；
    
7. 四种位置控制序列化满足 endpoint-first\middle\last 与 decoy-last 的位置约束；
    
8. 边列表中不存在破坏唯一性的额外路径。
    

只有通过全部检查的样本才进入最终评测。

## 4.2 Models and Prompts

### Models

本文评估四个主要模型配置：

|Model|Mode|Role|
|---|---|---|
|DeepSeek-V4-Flash|no-thinking|低延迟主模型，用于观察位置捷径、非法路径和 verifier-retry 的修复上限|
|DeepSeek-V4-Pro|no-thinking|更强模型的有限推理预算基线|
|DeepSeek-V4-Pro|thinking|高推理预算对照，用于检验内部 reasoning budget 是否能解决路径非法问题|
|Qwen Max|no-thinking|跨模型家族对照，用于检验失败模式是否稳定存在|
|GPT-5.4-mini|no-thinking|额外闭源模型对照，用于观察位置捷径和路径非法是否跨模型出现|

DeepSeek-V4-Pro thinking 只在关键困难设置上运行，即：

$$\text{branching-12hop} + \text{jsoncot\_strict}$$

该设置用于回答：额外内部推理预算是否能显著提高路径合法性，以及这种提升需要多高延迟成本。

verifier-retry 也只在困难设置上运行：

$$  
\text{branching-12hop} + \text{jsoncot\_strict},\quad K=5.  
$$

该设置用于回答：外部符号验证能否在低于 thinking mode 的延迟下部分修复非法路径，以及其收益是否依赖底座模型本身的图跟随能力。

### Prompt interfaces

本文使用五类 prompt，其中前三类用于主任务，后两类用于 prior control。

|Prompt|Output|Purpose|
|---|---|---|
|direct_minimal|answer only|检测 answer-only 接口下的 endpoint-position shortcut|
|jsoncot_basic|JSON path + answer|观察显式路径输出是否降低位置锚定，并开启路径级诊断|
|jsoncot_strict|strict JSON path + answer|强制路径长度、起点、逐边合法性和 answer-path consistency 的结构化输出格式|
|prior_only|answer only, no graph|检查无图条件下的固定答案先验|
|candidate_only_prior|answer only, candidates but no graph|检查候选集合偏好是否能解释答案命中|

`direct_minimal` 只要求模型输出最终答案，不要求给出路径。因此，该 prompt 主要用于答案层指标，包括 Accuracy、Raw GIS、PC-GIS、GFI 和 decoy-last EAR。

`jsoncot_basic` 要求模型输出 JSON 格式的路径与最终答案，例如：

```json
{
  "path": ["S0", "...", "Y"],
  "answer": "Y"
}
```

该设置让路径级指标可被计算，包括 TAC、PathValid、PathGoldExact 和 FailureHop。

`jsoncot_strict` 在 `jsoncot_basic` 基础上加入更严格的格式约束。模型必须输出严格 JSON，不得包含额外文本；路径必须包含 ($k+1$) 个节点，必须从起点 ($s$) 开始，答案必须等于路径最后一个节点。需要注意的是，这些约束只规定输出格式，并不保证模型实际生成的每条边都属于输入图。因此，所有结构化输出仍需进行符号路径验证。

`prior_only` 和 `candidate_only_prior` 不提供完整图结构，用于排除答案先验和候选偏好。若模型在无图或仅候选条件下已经能稳定命中正确答案，则相应样本可能被视为 prior-confounded，并从主分析中剔除或单独报告。

### Decoding configuration

所有主实验使用确定性解码：

$$  
\text{temperature}=0.  
$$

若某些模型 API 不暴露 temperature 控制，则使用 provider 默认确定性设置，并在实验记录中标注。所有请求记录模型名称、prompt mode、dataset、serialization variant、latency、parse status、timeout status 和原始输出路径。

## 4.3 Evaluation and Statistics

### Output parsing

对于 answer-only prompt，我们解析模型输出中的最终答案 ($\hat{a}$)。若模型输出多个候选或无法定位唯一答案，则记为 parse failure。

对于 structured prompt，我们解析：

$$  
(\hat{p},\hat{a}).  
$$

其中 ($\hat{p}$) 为模型输出路径，($\hat{a}$) 为模型最终答案。若 JSON 无法解析、缺少必要字段、路径不是 list、节点格式不合法，或输出包含无法恢复的额外文本，则记为 format failure。format failure 在路径级指标中视为无效路径，并在错误类型统计中单独记录。

### Answer-level evaluation

答案层评估使用第 3 节定义的指标：

- Accuracy；
    
- Raw GIS；
    
- PC-GIS；
    
- GFI；
    
- decoy-last EAR。
    

Raw GIS 和 PC-GIS 在同一批反事实图对上逐样本配对计算。GFI 在样本级先计算：

$$  
\mathrm{GFI}^{(j)}=\mathrm{RawGIS}^{(j)}-\mathrm{PCGIS}^{(j)},  
$$

再在数据集层面取平均。

### Path-level evaluation

路径层评估使用第 3 节定义的指标：

- TAC；
    
- PathValid；
    
- PathGoldExact；
    
- ($\Delta_{\text{illegal}}$)；
    
- FailureHop；
    
- error type distribution。
    

TAC 检查答案是否等于路径末节点；PathValid 检查路径是否从起点出发、长度是否为 ($k+1$)、每条边是否存在于输入图中；PathGoldExact 检查路径是否完全等于唯一黄金路径；FailureHop 记录第一条非法边所在的 hop。

对于路径过短、路径过长、起点错误、格式错误和 trace-answer mismatch，分别记录对应错误类型。对于路径长度足够且起点正确但某一步边不存在的输出，记录为：

```text
illegal_edge_at_hop_i
```

其中 ($i$) 表示第一条非法边所在 hop。

### Verifier-retry evaluation

verifier-retry 实验在 branching-12hop + jsoncot_strict 上运行，最大重试次数为：

$$  
K=5.  
$$

每次尝试后，符号验证器检查输出格式、路径起点、路径长度、逐边合法性以及 answer-path consistency。若验证失败，验证器只返回结构性错误反馈，例如非法边所在 hop 或路径长度错误，不泄露 gold answer 或正确下一跳。

对每个样本记录：

- 每次尝试的输出路径与答案；
    
- 每次尝试的 latency；
    
- 每次尝试的 verifier pass/fail；
    
- 每次失败的 FailureHop；
    
- 每次失败的 error type；
    
- 第一次通过验证的尝试编号 ($\tau_j$)。
    

报告 $pass@K$：

$$  
\mathrm{pass@}K

\frac{1}{N}  
\sum_{j=1}^{N}  
\mathbb{1}[\tau_j\le K].  
$$

同时报告每个 ($K$) 档的累计平均延迟：

$$  
L^{(K)}

\frac{1}{N}  
\sum_{j=1}^{N}  
\sum_{t=1}^{\min(\tau_j,K)}  
\ell_{j,t},  
$$

其中 ($\ell_{j,t}$) 是第 ($j$) 个样本第 ($t$) 次尝试的延迟。若样本在 ($K$) 次内未通过验证，则累计全部 ($K$) 次尝试。

对于 ($K=5$) 后仍失败的样本，我们统计最终 FailureHop 分布、最终 error type 分布，以及 repeated_same_hop 比例。repeated_same_hop 表示模型在多次 retry 中反复失败于同一 hop，用于判断剩余失败是否为稳定结构瓶颈。

verifier-retry 结果对 DeepSeek-V4-Flash 报告 3 次独立运行的平均值；对 Qwen Max 报告 2 次独立运行的平均值。误差棒或置信区间基于这些重复运行和样本级统计计算。

### Confidence intervals

对主实验中的样本级指标报告 bootstrap 置信区间。由于模型调用使用确定性解码，bootstrap 反映的是样本选择带来的不确定性，而不是 decoding randomness。

对 Raw GIS、PC-GIS、GFI 等配对指标，使用 paired bootstrap：以基础反事实图对为单位重采样，并在每个重采样集合内重新计算指标。对 Accuracy、TAC、PathValid、PathGoldExact、($\Delta_{\text{illegal}}$) 等样本级比例指标，使用 sample-level bootstrap。

本文默认使用 95% confidence intervals。对于 verifier-retry 的 pass@K 和 latency 曲线，报告多 run 均值，并在图中显示运行间误差或样本级不确定性。

### Latency and timeout handling

所有模型调用记录 wall-clock latency。对于普通推理，latency 记录单次请求耗时；对于 verifier-retry，latency 记录每次尝试的耗时，并累计至通过验证或达到最大重试次数 ($K$)。

若请求超过预设 timeout，则记为 timed_out。timeout 输出不计为正确答案，也不计为合法路径；在路径级指标中视为无效输出，并在错误统计中单独保留。latency 分析报告平均值、中位数和高分位数，以避免少数极端慢请求掩盖整体趋势。

### Reproducibility

所有实验保存以下信息：

- dataset name；
    
- sample id；
    
- graph id；
    
- model name；
    
- prompt mode；
    
- serialization variant；
    
- gold answer；
    
- gold path；
    
- model output；
    
- parsed answer；
    
- parsed path；
    
- parse status；
    
- metric values；
    
- latency；
    
- timeout status；
    
- verifier feedback and retry history, when applicable。
    

图生成器、序列化脚本、输出解析器和符号 verifier 均使用同一套节点与边表示，以避免评估阶段出现格式不一致。所有主结果均基于通过图结构校验的数据集计算。

---
# 5 Results

本节报告 GIF 在符号图任务上的主要结果。整体发现可以概括为三点。第一，prior controls 表明模型不能仅凭答案先验或候选偏好完成任务。第二，在 chain graphs 的弱提示条件下，Raw GIS 会被 endpoint-position shortcut 显著虚高；位置控制后，这种表面图跟随能力会崩塌。第三，在 branching graphs 的结构化输出条件下，位置捷径被削弱，但更深层的路径非法问题暴露出来：模型经常生成与答案自洽、但图上非法的路径。

除非特别说明，本节中的比例指标均以百分比报告。

![[Pasted image 20260609225610.png]]

## 5.1 Prior controls rule out answer priors

首先检查模型是否能够在无图或仅给候选节点的情况下猜中答案。若模型在 prior-only 或 candidate-only prior 条件下已经能稳定输出正确答案，那么主任务上的成功可能来自答案先验、候选偏好或格式偏好，而不是图结构追踪。

在 branching-12hop 上，prior controls 基本排除了这一解释。prior-only 条件下，DeepSeek-V4-Flash 和 Qwen Max 的准确率均为 0%。candidate-only prior 条件下，DeepSeek-V4-Flash 的准确率为 0.25%，Qwen Max 为 0%。这一结果低于或接近随机候选基线：

$$  
\frac{1}{84}\approx 1.19%.  
$$

因此，后续主实验中的成功或失败不能由无图答案先验解释。模型必须利用输入图结构，才可能稳定命中正确终点。

**Finding 1.** Prior controls rule out answer priors: without graph structure, models almost never identify the correct endpoint on branching-12hop.

---

## 5.2 Weak prompts induce answer-level positional shortcuts

接下来分析 answer-only 弱提示是否会诱发答案层位置捷径。我们使用 chain graphs 作为浅层诊断环境，因为链式结构中从起点到终点只有唯一简单路径，若正确终点总被放在显著位置，模型可能不真正沿图推理，而是直接选择最后或最显著的节点。
![[Pasted image 20260610002354.png]]
Table 1 显示 chain-4hop + direct_minimal 下的结果。DeepSeek-V4-Flash 的 Raw GIS 达到 68.5%，但 PC-GIS 为 0%，因此 GFI 也达到 68.5%。这说明模型在默认 endpoint-last 条件下看似能随图改变答案，但这种能力完全无法通过位置控制检验。decoy-last EAR 进一步达到 63.8%，说明当错误诱饵被放在最后时，模型经常被最后位置吸引。
![[Pasted image 20260609230203.png]]
Qwen Max 也呈现相同方向：Raw GIS 为 38.0%，PC-GIS 为 0%，GFI 为 38.0%。不过 Qwen 的 decoy-last EAR 只有 19.7%，说明它并不是单纯稳定地选择最后节点；在更长链上，它更接近图干预敏感性崩溃，即模型对图变化本身逐渐不敏感。

|Model|Accuracy|Raw GIS|PC-GIS|GFI|decoy-last EAR|
|---|--:|--:|--:|--:|--:|
|DeepSeek-V4-Flash|29.5|68.5 [62.0, 75.0]|0.0 [0.0, 0.0]|68.5 [62.0, 75.0]|63.8 [59.2, 68.2]|
|Qwen Max|46.1|38.0 [31.5, 45.0]|0.0 [0.0, 0.0]|38.0 [31.5, 45.0]|19.7 [15.8, 23.8]|

**Table 1.** Chain-4hop under direct_minimal. Raw GIS can be substantially inflated by endpoint-position shortcuts; after position control, PC-GIS collapses to zero.

进一步的 chain 长度扫描显示，不同模型呈现出递进式答案层失败。DeepSeek-V4-Flash 在 chain-3hop 到 chain-6hop 上都保持较高 GFI 与 decoy-last EAR，说明其弱提示行为稳定受到 endpoint-position shortcut 影响。GPT-5.4-mini 表现为中间型：它也受到位置线索影响，但随 hop 增长逐步下降。Qwen Max 则在较长链上 Raw GIS 急剧降低，说明其主要问题逐渐从位置捷径转向图干预敏感性崩溃。

具体而言，Raw GIS 在 chain-3hop 到 chain-6hop 上呈现如下趋势：

|Hop|DeepSeek-V4-Flash|GPT-5.4-mini|Qwen Max|
|--:|--:|--:|--:|
|3|92.5|86.4|85.5|
|4|68.5|71.0|38.0|
|5|62.5|63.0|4.0|
|6|67.2|46.7|3.0|

对应的 decoy-last EAR 也显示出类似差异：

|Hop|DeepSeek-V4-Flash|GPT-5.4-mini|Qwen Max|
|--:|--:|--:|--:|
|3|81.3|44.3|24.0|
|4|63.8|58.3|19.8|
|5|75.8|66.3|9.0|
|6|77.5|62.0|10.5|

这些结果说明，弱提示并不只产生一种失败。DeepSeek-V4-Flash 的失败更像稳定的位置捷径；GPT-5.4-mini 处于中间状态；Qwen Max 在长链上则表现为 sensitivity collapse。仅看 Raw GIS 会把这些不同机制混在一起，而 GFI 与 EAR 能进一步区分它们。

**Finding 2.** Weak answer-only prompts induce answer-level false faithfulness: Raw GIS may be high under endpoint-last serialization, but PC-GIS collapses after position control.

---

## 5.3 Structured output removes chain shortcuts but exposes illegal traces

结构化输出显著改变了 chain graphs 上的行为。在 chain-4hop + jsoncot_strict 下，DeepSeek-V4-Flash 几乎完全解决任务，Accuracy、Raw GIS、PC-GIS 和 PathGoldExact 均为 100%。Qwen Max 也达到 99.8% Accuracy、100.0% Raw GIS、98.5% PC-GIS 和 99.8% PathGoldExact。与 direct_minimal 相比，严格结构化输出几乎消除了 chain 上的答案层位置捷径。

|Model|Accuracy|Raw GIS|PC-GIS|GFI|PathGoldExact|
|---|--:|--:|--:|--:|--:|
|DeepSeek-V4-Flash|100.0|100.0|100.0|0.0|100.0|
|Qwen Max|99.8|100.0|98.5|1.5|99.8|

**Table 2.** Chain-4hop under jsoncot_strict. Structured output removes answer-level shortcuts on simple chain graphs.

然而，这并不意味着结构化输出保证图忠实性。当任务转入 branching-12hop 后，jsoncot_strict 暴露出更深层的路径非法问题。Table 3 显示，多个模型都能生成与答案高度自洽的结构化路径，但路径本身并不合法。

DeepSeek-V4-Flash 的 TAC 达到 99.3%，说明其答案几乎总是等于路径末节点；但 PathValid 和 PathGoldExact 只有 48.5%，导致非法路径差距 (\Delta_{\text{illegal}}) 达到 50.8%。Qwen Max 的情况更极端：TAC 为 99.2%，但 PathGoldExact 只有 8.4%，(\Delta_{\text{illegal}}) 高达 90.8%。这说明 Qwen Max 非常擅长保持输出内部自洽，却几乎无法保证路径逐边合法。

GPT-5.4-mini 的 PathGoldExact 也很低，为 8.1%，但其 TAC 只有 79.9%。这表明 GPT-5.4-mini 与 Qwen Max 的失败表面上同样表现为低路径正确率，但机制不同：Qwen Max 是“高度自洽但非法”，GPT-5.4-mini 则包含更多基础输出不自洽或轨迹构造失败。

|Model|Accuracy|PC-GIS|TAC|PathValid|PathGoldExact|(\Delta_{\text{illegal}})|
|---|--:|--:|--:|--:|--:|--:|
|DeepSeek-V4-Flash|50.2|0.0|99.3 [98.9, 99.7]|48.5 [46.1, 50.9]|48.5 [46.1, 50.9]|50.8 [48.5, 53.2]|
|DeepSeek-V4-Pro no-thinking|56.3|2.0|99.9 [99.8, 100.0]|55.3 [52.5, 58.1]|55.3 [52.5, 58.1]|44.6 [41.8, 47.4]|
|Qwen Max|13.7|0.0|99.2 [98.7, 99.6]|8.4 [6.9, 9.9]|8.4 [6.9, 9.9]|90.8 [89.2, 92.3]|
|GPT-5.4-mini|8.3|0.0|79.9 [77.9, 81.8]|8.1 [6.6, 9.6]|8.1 [6.6, 9.6]|71.8 [69.4, 74.1]|

**Table 3.** Branching-12hop under jsoncot_strict. Models often produce self-consistent traces, but these traces are not valid paths in the input graph.
![[Pasted image 20260610002418.png]]
Branching-4hop 作为中间难度设置进一步支持这一解释。与 chain-4hop 不同，branching-4hop 已经引入分叉结构，因此模型必须维护当前节点状态，而不能只读取线性链条。结果显示，chain-4hop + jsoncot_strict 几乎被完全解决；branching-4hop 开始出现非零非法路径差距；到 branching-12hop 时，该差距显著放大。这说明困难不只是来自 JSON 输出格式，也不只是来自 hop 数增加，而是来自模型在分叉结构中持续维护状态的能力不足。

**Finding 3.** Structured output removes simple chain shortcuts, but exposes trace-level false faithfulness on branching graphs: high TAC does not imply high PathValid.

---

## 5.4 Thinking reduces failures at high latency

进一步比较 DeepSeek-V4-Pro 的 no-thinking 与 thinking 模式。结果显示，thinking 几乎解决 branching-12hop + jsoncot_strict，但代价是显著更高延迟。

在 no-thinking 模式下，DeepSeek-V4-Pro 的 Accuracy 为 56.3%，PathGoldExact 为 55.3%，PC-GIS 仅为 2.0%，仍存在明显路径非法和图跟随不稳定问题。开启 thinking 后，Accuracy 提升到 99.9%，Raw GIS 为 100.0%，PC-GIS 为 99.5%，GFI 降到 0.5%，PathGoldExact 达到 99.9%。这说明在足够高的内部推理预算下，模型能够几乎完全消除路径非法问题。

然而，thinking 的延迟成本也显著增加。DeepSeek-V4-Pro no-thinking 平均延迟约为 2.4 秒，而 thinking 平均延迟为 46.7 秒，中位数为 42.4 秒，p95 达到 203 秒。平均延迟约增加 19 倍。

|Model / Mode|Accuracy|Raw GIS|PC-GIS|GFI|PathGoldExact|Avg latency|
|---|--:|--:|--:|--:|--:|--:|
|DeepSeek-V4-Pro no-thinking|56.3|25.5|2.0|23.5|55.3|2.4s|
|DeepSeek-V4-Pro thinking|99.9|100.0|99.5|0.5|99.9|46.7s|

**Table 4.** Thinking mode on branching-12hop + jsoncot_strict. Extra reasoning budget nearly solves the task, but at much higher latency.

这一结果有两个含义。第一，branching-12hop 任务本身并非不可解；强模型在高推理预算下可以接近完美完成。第二，no-thinking 模式下的失败不是简单格式问题，而是有限推理预算下的状态追踪失败。thinking 可以缓解该问题，但其延迟成本较高。

**Finding 4.** Thinking reduces both answer-level and path-level failures, but incurs a large latency cost.

---

## 5.5 Verifier-retry partially repairs illegal paths

最后分析外部符号 verifier-retry 是否能以较低成本修复非法路径。该实验在 branching-12hop + jsoncot_strict 上运行，最大重试次数为 (K=5)。验证器只返回结构性错误反馈，例如路径长度错误或某一跳边不存在；它不泄露 gold answer，也不告诉模型正确下一跳。
![[Pasted image 20260609232653.png]]
Table 5 显示 pass@K 曲线。DeepSeek-V4-Flash 从 pass@1 的 48.6% 提升到 pass@5 的 70.6%，累计延迟为 4.42 秒。Qwen Max 从 pass@1 的 8.4% 提升到 pass@5 的 33.4%，累计延迟为 12.12 秒。

|Model|pass@1|pass@2|pass@3|pass@4|pass@5|Latency@5|
|---|--:|--:|--:|--:|--:|--:|
|DeepSeek-V4-Flash + retry|48.6|59.0|64.4|68.6|70.6|4.42s|
|Qwen Max + retry|8.4|17.2|24.1|29.8|33.4|12.12s|

**Table 5.** Verifier-retry on branching-12hop + jsoncot_strict. pass@K improves with retry budget, but gains saturate and depend strongly on the base model.

Verifier-retry 的结果表明，外部验证确实有用，但它并不能凭空创造图推理能力。DeepSeek-V4-Flash 的 pass@1 已接近 50%，说明模型本身已经具备一定图跟随能力，因此结构性反馈可以修复一部分错误。Qwen Max 的 pass@1 只有 8.4%，即使经过 5 次重试也只达到 33.4%，说明当底座模型状态追踪能力较弱时，反馈收益存在明显上限。

与 DeepSeek-V4-Pro thinking 相比，DeepSeek-V4-Flash verifier@5 以 4.42 秒达到 70.6% 的路径通过率，而 Pro thinking 以 46.7 秒达到 99.9% 的 PathGoldExact。也就是说，verifier-retry 不能替代 thinking，但能以不到十分之一的平均延迟恢复大量路径合法性。

pass@K 曲线也显示出边际收益递减。DeepSeek-V4-Flash 从 K=1 到 K=2 提升 10.4 个百分点，但从 K=4 到 K=5 只提升 2.0 个百分点。Qwen Max 也呈现类似饱和趋势。这说明 verifier 能发现错误，但后续修复仍依赖模型自身维护图状态和选择合法后继的能力。

**Finding 5.** Verifier-retry partially repairs illegal paths at lower latency, but its ceiling is determined by the base model’s graph-following ability.

---

## 5.6 Ablation summary

第 5.2 至 5.5 节报告了最能展示机制差异的代表性结果。为了避免结论依赖少数挑选出的 cell，本节进一步总结 prompt interface、topology-depth、reasoning budget 和 verifier budget 四个维度的系统消融。完整逐项结果、补充表格和附图放在 Appendix A。

|Ablation axis|Main takeaway|Full results|
|---|---|---|
|Prompt interface|`direct_minimal` 最容易暴露答案层位置捷径；`jsoncot_basic` 和 `jsoncot_strict` 能显著缓解 chain graphs 上的 shortcut，但不能保证 branching graphs 上的路径合法性。`jsoncot_basic` 与 `jsoncot_strict` 的对比进一步表明，更强格式约束并不自动等价于更强图合法性，prompt interface 本身是控制图忠实性的关键变量。|Appendix A.1|
|Topology and depth|Chain depth scan 显示答案层失败具有模型差异：DeepSeek-V4-Flash 在 chain 3–6 hop 上持续保持较高 Raw GIS / GFI，而 Qwen Max 随 hop 增长从较高 Raw GIS 转为 near-zero sensitivity collapse。Branching depth comparison 显示路径层非法性随分叉深度放大：branching-4hop 已出现非零 illegal-trace gap，branching-12hop 则将该失败放大为主导机制。|Appendix A.2|
|Reasoning budget|DeepSeek-V4-Pro thinking 在 branching-12hop 上几乎消除答案层和路径层失败，但平均延迟显著高于 no-thinking。这表明困难任务本身可解，但需要更高内部推理预算。|Appendix A.3|
|Verifier budget|pass@K 从 K=1 到 K=5 持续上升但边际收益递减；DeepSeek-V4-Flash 的提升和上限明显高于 Qwen Max，说明 verifier-retry 放大已有图跟随能力，而不是凭空创造图推理能力。|Appendix A.4|

这些消融共同支持本文的机制解释：弱提示链式图主要暴露答案层位置虚胖，分叉图结构化输出主要暴露路径层自洽但非法，thinking 与 verifier-retry 分别从内部推理预算和外部结构反馈两个方向缓解失败，但成本和上限不同。

---
# 6 Analysis

第 5 节已经报告了主要实验结果：弱提示下的 chain graphs 会暴露答案层位置虚胖，结构化输出能缓解简单链式图上的 shortcut，但在 branching graphs 上又暴露出路径层非法轨迹；thinking 能显著缓解失败但延迟较高，verifier-retry 能部分修复非法路径但存在上限。

本节不再重复结果表，而是进一步解释这些现象背后的机制。我们关注三个问题：

1. 为什么自洽的结构化轨迹仍然可能是非法路径？
    
2. 为什么 verifier-retry 有效但会饱和？
    
3. FailureHop 和 repeated same-hop failure 如何揭示结构性瓶颈？
    

总体而言，分析表明，模型的关键失败并不是不会输出路径，也不是简单格式错误，而是无法稳定维护图上的当前状态，并在每一步选择真实存在的后继节点。

---

## 6.1 为什么自洽轨迹仍然可能是非法路径

在 branching-12hop + jsoncot_strict 设置下，多数模型可以生成格式正确、答案与路径末节点一致的结构化输出。换言之，它们通常能满足：

$$  
\hat{a}=\hat{v}_k.  
$$

这解释了为什么 TAC 可以很高。模型知道 JSON 中应该包含 `path` 和 `answer`，也知道 `answer` 应该等于 `path[-1]`。但是，这种输出层面的自洽性并不等于路径在图上合法。真正的路径合法性要求模型在每一步都执行图上的状态更新：

$$  
\hat{v}_{i+1}\in N^+(\hat{v}_i),  
$$

其中 (N^+(\hat{v}_i)) 表示当前节点 (\hat{v}_i) 的出邻居集合。模型必须维护“当前节点是谁”，再从当前节点的合法后继中选择下一跳。只要某一步生成了图中不存在的边：

$$  
(\hat{v}_i,\hat{v}_{i+1})\notin E,  
$$

整条路径就不再是输入图上的合法 walk。

因此，strict JSON-CoT 主要提升的是格式服从能力和局部文本自洽能力，而不是自动保证图状态追踪能力。模型可以生成一条看似完整、终点与答案一致的路径，但这条路径可能只是围绕答案构造出来的结构化解释，而不是模型真正沿图边移动得到的结果。

这与自然语言 CoT 中的事后合理化类似。在普通 CoT 中，模型可能先形成答案，再生成一段看起来支持该答案的解释；在图路径任务中，模型也可能先锁定某个答案节点，再补出一条看似通向该节点的路径。区别在于，这里的解释被包装成了结构化路径，因此更容易被误认为是可验证的推理轨迹。

GIF 的路径级诊断正是为了防止这种误判。TAC 只能说明模型输出内部不矛盾，不能说明路径中的每条边都存在。对于路径类图任务，真正关键的是逐边验证：

$$  
\forall i,;(\hat{v}_i,\hat{v}_{i+1})\in E.  
$$

因此，PathValid、PathGoldExact 和 FailureHop 不是附加指标，而是区分“结构化解释”和“图上合法路径”的必要条件。

---

## 6.2 为什么 verifier-retry 会饱和

Verifier-retry 能提高 pass@K，说明外部符号反馈确实有用。但第 5 节也显示，retry 的收益会逐渐饱和，而且不同模型的上限差异很大。这说明 verifier-retry 实际上区分了两种能力：

|能力|由谁提供|含义|
|---|---|---|
|错误发现|符号验证器|判断路径哪一步不合法|
|错误修复|语言模型|根据输入图重新生成合法路径|

验证器只能提供第一种能力。它可以告诉模型某一步边不存在、路径长度错误、起点错误或答案与路径末节点不一致。例如：

```text
Your path is invalid at hop 3:
edge (J9E9, W6S2) does not exist in the graph.
```

但是，验证器不会泄露 gold answer，也不会直接告诉模型正确下一跳是什么。因此，模型收到反馈后，仍然必须自己完成图上的状态更新：

$$  
\hat{v}_{i+1}\in N^+(\hat{v}_i).  
$$

也就是说，修复一条非法路径所需要的能力，正是模型最初失败的能力：从当前节点检索合法后继，并维持更新后的当前状态。

因此，verifier-retry 的饱和不是偶然现象，而是底座模型状态追踪能力不足的直接结果。

这也解释了模型间差异。DeepSeek-V4-Flash 的初始 pass@1 已经接近一半，说明它本身具备一定图跟随能力，验证器反馈可以修复其中一部分可纠正错误。Qwen Max 的 pass@1 很低，即使多次收到结构性反馈，也经常无法重建合法路径。这说明 verifier-retry 更像是放大已有能力，而不是创造新的图推理能力。

因此，verifier-retry 的正确定位不是：

> verifier teaches the model how to reason over graphs.

而是：

> verifier exposes structural errors and gives the model another chance to use whatever graph-following ability it already has.

这一点也解释了为什么 verifier-retry 可以在较低延迟下恢复大量路径合法性，却不能完全替代 thinking。Thinking 提供的是更高内部推理预算；verifier-retry 提供的是外部错误检测和重复尝试机会。二者缓解失败的方式不同，成本和上限也不同。

---

## 6.3 FailureHop 揭示结构性瓶颈

FailureHop 分析进一步说明，retry 后的剩余失败不是随机噪声。若模型每次 retry 都错在不同位置，那么失败可能主要来自随机解码波动；但若模型反复卡在同一个 hop，则说明该位置存在稳定结构瓶颈。

在 branching-12hop + verifier-retry 的最终失败样本中，DeepSeek-V4-Flash 约 69.0% 的失败具有 repeated_same_hop=True；Qwen Max 这一比例达到 83.7%。这意味着，在大量失败样本中，模型不是没有收到错误反馈，而是在收到反馈后仍然无法越过同一个状态转移位置。

$$  
\text{repeated same-hop rate}_{\text{Flash}}=69.0%,  
$$

$$  
\text{repeated same-hop rate}_{\text{Qwen}}=83.7%.  
$$

这个指标比单纯的 pass@K 更能说明 verifier-retry 的边界。pass@K 告诉我们有多少样本最终被修复；repeated same-hop 告诉我们剩余失败为什么修不回来。它说明模型在某些样本上反复失败于同一结构位置，而不是随机生成了不同错误。

从 FailureHop 分布看，DeepSeek-V4-Flash 的剩余失败主要集中在 hop 2、hop 3 和 hop 12。hop 2/3 通常对应早期分叉点，说明模型在进入分叉结构后容易选错分支；hop 12 对应终端转移，说明模型在最后落点时容易为了抵达某个答案节点而生成图中不存在的末步边。此外，DeepSeek-V4-Flash 还有一部分 path_too_short 错误，即模型在走满 (k) 跳前提前停止。

这里需要区分两种结尾附近的失败。path_too_short 是路径未走满，模型提前终止；terminal-transition bottleneck 则是模型走到最后一步附近，但为了抵达某个答案节点而生成非法边。前者是不足，后者是强凑。二者都发生在路径完成阶段附近，但机制不同。

相比之下，Qwen Max 的错误更分散，多个中间 hop 和终端 hop 都会出现非法边。这说明 Qwen Max 的问题不是某一个局部分叉点特别难，而是整体多跳状态追踪能力较弱。它通常能够生成长度接近要求、答案与路径末节点一致的轨迹，但无法稳定保证每一步都沿输入图边移动。

因此，FailureHop 不只是错误统计，而是一种能力画像。它可以区分：

|错误形态|机制解释|
|---|---|
|错误集中在少数 hop|局部结构瓶颈，例如早期分叉或终端转移|
|错误分散在多个 hop|整体状态追踪能力不足|
|repeated_same_hop 高|feedback 后仍反复卡在同一结构转移处|
|path_too_short|无法维持完整 (k)-hop 轨迹|

这说明 verifier-retry 不只是一个修复机制，也是一个诊断工具。它揭示模型错误是否能在外部反馈下被修正，还是会反复卡在同一类结构障碍上。

---

## 6.4 Summary

本节解释了第 5 节结果背后的机制。

第一，结构化输出能提高格式服从和 trace-answer consistency，但不能保证路径逐边合法。模型可以生成答案与路径末节点一致的轨迹，却仍然违反输入图的边约束。

第二，verifier-retry 的提升会饱和，因为验证器只能发现错误，不能替代模型修复错误所需的状态更新能力。修复非法边本质上仍要求模型完成：

$$  
\hat{v}_{i+1}\in N^+(\hat{v}_i),  
$$

而这正是失败模型所缺乏的能力。

第三，FailureHop 和 repeated same-hop failure 表明剩余错误是结构性的，而不是随机噪声。大量最终失败会反复卡在同一个 hop，说明模型在收到结构性反馈后仍难以越过同一状态转移瓶颈。

因此，图推理评测不应只检查最终答案，也不应只检查推理轨迹是否与答案一致。对于路径类图任务，真正关键的是验证模型生成的每一步状态转移是否忠实于输入图结构。

---

---
# 7 Conclusion

本文提出了 Graph-Intervention Faithfulness（GIF），一个用于诊断大语言模型是否真正遵循显式图结构的评估框架。与只报告最终答案准确率的图推理评测不同，GIF 关注两个更细的忠实性问题：第一，模型答案是否真的受图结构控制，而不是受序列化位置线索驱动；第二，模型生成的结构化路径是否真的是图上的合法路径，而不只是与最终答案自洽。

实验揭示了 LLM 图推理中的两类假忠实性。

第一类是答案层假忠实性：在弱 answer-only 提示下，模型可能表现出较高 Raw GIS，即答案看似随反事实图干预改变，但这种敏感性在位置控制后消失。链式图实验进一步显示，不同模型存在递进式失败模式：DeepSeek-V4-Flash 稳定依赖 endpoint-position shortcut，GPT-5.4-mini 表现出中间型位置捷径依赖，而 Qwen Max 在较长链上逐渐失去图干预敏感性。这说明，Raw GIS alone 不是可靠的图忠实性证据。

第二类是路径层假忠实性：在 branching-12hop + jsoncot-strict 设置下，模型通常能够生成格式正确、路径终点与答案一致的输出，但这些路径经常包含图中不存在的非法边。换言之，trace-answer consistency 并不蕴含 structural path validity。结构化 CoT 可以让模型的输出更容易解析，也可以缓解简单链式图上的位置捷径，但它本身并不能保证模型真正沿图逐边推理

进一步地，thinking 与 verifier-retry 实验揭示了图跟随能力、推理预算和外部验证之间的关系。DeepSeek-V4-Pro thinking 几乎完全解决 branching-12hop，说明该任务本身可解，no-thinking 模式下的失败主要来自有限推理预算和状态追踪能力不足。Verifier-retry 则能显著提高 pass@K，并降低非法路径错误，但其收益明显受底座模型限制。它可以放大已有图跟随能力，却不能凭空创造图推理能力。FailureHop 分析进一步表明，剩余失败不是随机噪声，而是常常集中在早期分叉点或最终转移处，暴露出稳定的结构性瓶颈

这些结果共同说明，可靠的图推理评估不能只检查最终答案，也不能只检查模型是否输出了看似合理的路径。对于路径类图任务，评测必须同时关注位置控制后的答案稳定性、路径逐边合法性，以及失败发生的位置和类型。GIF 正是围绕这一目标构建的：它将答案层位置控制、路径层符号验证和 verifier-retry 失败分析结合起来，从而区分真正的图跟随与两类常见假阳性。

本文仍有若干局限。我们的实验主要基于符号图和路径到达任务，未来可以扩展到更丰富的图任务，例如可达性判断、最短路、连通性、拓扑性质判断和知识图谱推理。同时，本文主要分析文本序列化图上的行为忠实性，并不直接观测模型内部计算过程。未来工作可以将 GIF 与白盒表征分析、工具调用轨迹分析或训练期干预结合起来，进一步研究模型是否在内部形成稳定的图状态表示。

总体而言，本文的核心结论是：LLM 在图任务中“答案随图变”和“解释自洽”都不足以证明其真正沿图推理。只有通过反事实图干预、位置控制、路径合法性验证和失败模式分析，才能更可靠地诊断模型是否忠实于输入图结构。

---
#  Limitations

本文有若干限制。

第一，本文使用的是合成符号图，而不是自然语言知识图谱或真实世界图结构。这一选择是刻意的：随机符号节点能够最大程度削弱实体名称、常识关联和参数记忆带来的语义先验，使实验更集中地诊断模型是否依赖输入图结构。然而，这也意味着本文结论不能直接等同于真实知识图谱问答或开放域图推理中的全部现象。真实图中的实体名称、关系语义和世界知识可能与图约束发生交互，未来工作可以引入中等强度或强语义先验，进一步研究模型在先验与图结构冲突时是否仍遵循输入图。

第二，本文任务集中在 fixed-hop path following，即从给定起点出发，沿有向边恰好走 (k) 跳并输出终点。这一任务便于构造反事实图对、位置控制序列化和路径级合法性验证，但它并不覆盖所有图推理形式。例如，子图检索、最短路径、连通性判断、图匹配、图属性预测和真实知识图谱问答可能引入不同的失败模式。GIF 的核心思想可以扩展到这些任务，但具体指标和构造方式需要进一步适配。

第三，GIF 是一种黑箱行为诊断框架，而不是对模型内部机制的直接证明。本文通过反事实图干预、位置控制和符号路径验证来检验模型行为是否与图忠实性相一致，但并不声称直接观察或证明模型内部“真正理解”了图结构。尤其是 (R) 作为理想的图因果控制事件不可直接观测，本文指标只能提供可操作的近似诊断。

第四，本文主要关注位置线索和路径合法性两类失败，但序列化图任务中还可能存在其他混淆因素，例如节点命名方式、边列表格式、关系文本描述、上下文长度和候选集合设计。本文通过随机符号节点和位置控制削弱了部分混淆，但没有穷尽所有可能的序列化偏置。未来可以系统比较不同图编码格式、邻接表风格、自然语言描述风格和工具接口风格。

第五，verifier-retry 实验使用的是单一符号验证器设计。该验证器只返回结构性错误反馈，例如格式错误、路径长度错误、非法边所在 hop 或 trace-answer mismatch，不泄露 gold answer 或正确下一跳。不同反馈粒度、不同错误提示措辞、是否给出邻居集合、以及是否结合搜索式修复，可能影响 retry 的上限和延迟成本。因此，本文关于 verifier-retry 的结论应理解为在受控反馈设置下的诊断结果，而不是所有外部验证系统的最终上限。

第六，verifier-retry 的重复运行次数在模型之间并不完全一致。DeepSeek-V4-Flash 报告 3 次独立运行均值，Qwen Max 报告 2 次独立运行均值。这足以观察主要趋势，但不足以完全刻画运行间方差。未来工作可以增加更多独立运行，尤其是在更大样本和更多模型上估计 pass@K、latency 和 final failure distribution 的稳定性。

第七，本文主实验使用确定性解码。Bootstrap confidence intervals 主要反映样本选择带来的不确定性，而不反映 decoding randomness。若使用非零 temperature 或采样式 decoding，模型可能呈现不同的答案分布和 retry 行为。未来工作可以比较 deterministic decoding 与 stochastic decoding 下的 GIF 指标差异。

第八，本文覆盖的模型数量有限，主要包括 DeepSeek、Qwen 和 GPT-5.4-mini 等代表性模型配置。虽然这些模型已经展示出不同失败机制，例如位置捷径、sensitivity collapse、自洽但非法路径和高预算 thinking 修复，但更多开源模型、闭源模型、专门图推理模型和工具增强模型仍有待评估。

这些限制不削弱本文的核心主张：最终答案正确、Raw GIS 高或轨迹与答案自洽，都不足以单独证明模型忠实使用输入图结构。相反，它们说明图忠实性需要在更多任务、更多模型和更多序列化条件下继续系统诊断。

---
# Appendix A Full Ablations

Appendix A 提供 prompt-interface、topology-depth、reasoning-budget 和 verifier-retry budget 的完整消融结果。正文 §5.6 只总结主要趋势，本附录报告逐项表格、补充图和额外分析，以支持第 5 节的主要结论。

## A.1 Prompt-interface ablation

本节比较三种 prompt interface：

```
direct_minimal
jsoncot_basic
jsoncot_strict
```

`direct_minimal` 是 answer-only 接口，主要暴露答案层位置捷径。`jsoncot_basic` 要求模型输出结构化路径和答案，使路径级诊断成为可能。`jsoncot_strict` 进一步要求严格 JSON、固定路径长度、起点一致和 answer-path consistency。

这一消融用于回答：

> 显式路径输出和更强格式约束是否真的提高图忠实性？

完整结果应报告 direct_minimal、jsoncot_basic 和 jsoncot_strict 在 chain 与 branching 设置下的 Accuracy、Raw GIS、PC-GIS、GFI、decoy-last EAR、TAC、PathValid、PathGoldExact 和 (\Delta_{\text{illegal}})。

特别需要保留 basic vs strict 的对比。若 jsoncot_basic 在某些设置下具有更高单点正确率，但 jsoncot_strict 具有更强格式稳定性或更低位置污染，应明确报告这一 trade-off。该对比说明 prompt interface 不是简单的“越严格越好”，而是在答案正确率、位置稳健性、格式服从和路径合法性之间产生不同权衡。

## A.2 Topology-depth ablation

本节报告 chain depth scan 与 branching depth comparison。

Chain depth scan 包括：

```
chain_3hop_N200
chain_4hop_N200
chain_5hop_N200
chain_6hop_N200
```

该扫描用于检验答案层位置虚胖是否随 hop 长度变化，以及不同模型是否呈现不同失败机制。需要突出两类趋势：DeepSeek-V4-Flash 在 chain 3–6 hop 上持续保持较高 Raw GIS / GFI，说明其 answer-only 行为稳定受 endpoint-position shortcut 影响；Qwen Max 则随 hop 增长从较高 Raw GIS 迅速转为 near-zero sensitivity collapse，说明它在长链上不只是抗位置偏置，而是逐渐失去对图干预的敏感性。

Branching depth comparison 包括：

```
branching_4hop_N200
branching_12hop_N200
```

branching-4hop 作为中间难度设置，用于观察从简单 chain 到困难 branching-12hop 之间的过渡。branching-4hop 已经开始出现非法路径差距，而 branching-12hop 将该差距进一步放大，说明路径层失败并不是 JSON 输出格式造成的偶然现象，而是来自分叉结构中的持续状态追踪困难。

## A.3 Reasoning-budget ablation

本节比较 DeepSeek-V4-Pro no-thinking 与 DeepSeek-V4-Pro thinking。

该消融只在关键困难设置上运行：

```
branching_12hop_N200 + jsoncot_strict
```

报告指标包括 Accuracy、Raw GIS、PC-GIS、GFI、TAC、PathValid、PathGoldExact、(\Delta_{\text{illegal}})、平均延迟、中位延迟和 p95 延迟。

该消融用于回答：

> 更高内部推理预算是否能消除答案层和路径层失败？

结果显示，thinking 几乎解决 branching-12hop，但平均延迟显著高于 no-thinking。这说明任务本身可解，no-thinking 失败主要来自有限推理预算下的状态追踪不足，而不是数据集不可解或评估器过严。

## A.4 Verifier-retry budget ablation

本节报告 verifier-retry 在不同 retry budget 下的结果：

```
K=1,2,3,4,5
```

核心指标包括：

```
pass@1
pass@2
pass@3
pass@4
pass@5
latency@K
final PathValid
final PathGoldExact
final FailureHop distribution
final error type distribution
repeated_same_hop
```

该消融用于回答：

> 外部符号验证是否能以较低成本修复非法路径？这种修复是否随 K 增加持续提升？

结果显示，pass@K 随 K 增加而上升，但边际收益递减。DeepSeek-V4-Flash 的提升幅度和最终上限明显高于 Qwen Max，说明 verifier-retry 的收益依赖底座模型已有的图跟随能力。对于 K 次后仍失败的样本，FailureHop 和 repeated_same_hop 分析进一步表明，剩余错误常常集中在稳定结构瓶颈上，而不是随机噪声。




---
# 附录

![[newplot (2).png]]

![[Pasted image 20260610002145.png]]

![[Pasted image 20260610002334.png]]


















![[Pasted image 20260609230122.png]]
![[Pasted image 20260610002119.png]]
![[Pasted image 20260610002654.png]]










---
### 🎯 第一梯队 · 定义 GIF 自身 / 直接动机（4 篇，最核心）

[1]**图没变，字变了：LLM 图推理的序列化不变性危机**（Lost in Serialization）— GIF 最近邻，序列化不变性危机 = 引言第 2–3 段的直接动机。
[2]. **图帮文本去噪，文本帮图复活**（TGS-RAG）— GFI = Raw GIS − PC-GIS 精确表述、pilot 数字、"生成层留空"缺口、真实 RAG testbed。
[3]. **别让大模型手算图：图推理应从复现算法转向设计算法**（Simple-RTC）— "工程绕过 vs 诊断显微镜"的对照，metrics 语境。

### 🔬 第二梯队 · 忠实性谱系（Related Work 主战场，9 篇）

[4]. **思维链会招供，最终答案会闭嘴**（Lie to Me, Young 2026）— verbalization vs structural faithfulness 的关键区分；跨家族 roster 借用源。
[5]. **思维链不忠实：模型如何把偏见包装成推理**（Turpin 2023）— 行为干预测忠实性的思想祖先。
[6]]. **给 CoT 推理拍 X 光：用计算图验证**（CRV）— 把 GIF 定位成黑盒/任务无关诊断框架；pilot 规模小→定位为 diagnostic benchmark 的依据。
[7]. **忠实性不是"看起来合理"：NLP 解释该如何证明自己没撒谎** — faithfulness 的严格定义来源，写 intro/定义节必引。
[8]. **会解释，不代表真会想：大模型忠实思维链为何困难**（Hardness of Faithful CoT）— "忠实本身就难"的理论背书。
[9]. **大模型的"推理小作文"可信吗？**（Measuring Faithfulness in CoT）— 忠实性测量方法谱系。
[10]. **先有答案，再编理由：真实场景中的 CoT 不忠实**（CoT in the Wild）— 真实场景不忠实的证据。
[11]. **偏见进了答案，却没进思维链**（Bias & CoT Faithfulness, VLLM）— 偏置注入法的旁证。
[12]. **模型嘴里的推理，未必是脑中的理由：CoT 忠实性失真** — 忠实性失真证据。⚠️ 这篇 frontmatter 的"论文题目"写成了 FiDeLiS，疑似复制错，建议核对。

### 📍 第三梯队 · 位置偏置/序列化（支撑 endpoint anchoring，5 篇）

[13]. **排名别看位置：InvariRank** — "注意力泄漏 ≫ 位置编码"的机制分解；endpoint anchoring 升级到机制归因的钩子。
[14]. **排在前面就更香：RISE** — 位置偏置量化框架；给你第二条反锚定干预臂（逐跳单步选择）。
[15]. **把图塞进 KV：Graph-KV** — 强制串行化→位置偏置/Lost-in-the-Middle，序列化弊端的总论来源。
[16]. **选项换个座位，模型换个答案**（MCQ 选项顺序敏感）— 位置敏感的跨任务旁证。
[17]. **顺序一换，模型就乱：LLM 输入排列敏感性** — 排列敏感跨 benchmark 证据。⚠️ frontmatter"论文题目"写成 Graph-constrained Reasoning，明显是复制错，建议修。

### 🧭 第四梯队 · 图推理方法（被诊断的"增强路线" + 数据/testbed，11 篇）

[18]. **图结构不是文本：LLM 需要导航**（GraphWalk）— 底座（合成图生成器）+ 反例 + 弹药三合一。
[19]. **边看边走：SoG**（Search-on-Graph）— 最佳真实世界 testbed。
[20]. **把计划画成图：用 GNN 抓任务规划错接漏步**（GNNVerifier）— 真实图数据源（TaskBench/UltraTool）。
[21]. **路径别全塞：KGQA 需要看几跳历史？**（BPC）— 行为冗余的层级互补论据。
[22]. **让大模型沿着图走：知识图谱把推理从"表演"拉回"路径"**（RoG）— 忠实 KG 推理代表方法。
[23]. **别让大模型硬算图：拆成三步调用图工具**（GCR, Graph-constrained Reasoning）— 标题自带"faithful reasoning"，正面对照。
[24]. **别让 CoT 瞎想：让大模型顺着知识图谱走**（Follow the Path）— KG 路径推理。
[25]. **让大模型沿着图走：Graph-CoT** — RAG 从找文本升级到走关系。
[26]. **给大模型一张地图：FiDeLiS** — 忠实 KGQA 约束路径。
[27]. **边想边查图：用知识图谱逐步补脑**（Graph-Augmented Reasoning）— 迭代式 KG 检索。
[28]. **KG 当奖励模型：路径对齐训练组合推理** — 下游意义/安全攸关迁移的研究故事（"忠实诊断是前置必要条件"）。
[29]. **LLM 真的会看懂图吗？**（Revisiting Graph Reasoning Ability）— 图推理失败的实证弹药。

### 📐 第五梯队 · 多跳评测/反事实基准（3 篇）

[30]. **别让模型背答案：CofCA** — 反事实多跳、抗记忆虚胖，与你"反事实图构造"是姊妹方法。
[31]. **Omanic：一步步检查多跳推理** — step-wise 多跳评测。
[32]. **答案对了，不代表会推理**（多维度推理步评估）— 推理质量评测维度。

### 🛰 第六梯队 · 验证/Agent（弱关联，按需，3 篇）

[33]. **把推理拆成图：GoV 用 DAG 验算** — DAG 拓扑序验证骨架。
[34]. **把多条思路织成一张图：GraphReason** — 图结构验证法。
[35]. **从"会调用"到"会纠错"：工具增强大模型的元验证与反思学习** — 工具增强忠实性，关联 verify-retry 那条实验线。
[36]. **Thinking While Listening**（FSRM）— 最弱，仅"递归架构能自发学结构但是否忠实仍需诊断"一句。
[37]. Lost in the Middle



