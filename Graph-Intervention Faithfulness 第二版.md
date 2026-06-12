
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
DeepSeek-V4-Pro thinking 在 branching-12hop 上几乎完美解决任务，PathGoldExact 达 99.9%，但平均耗时 46.7 秒；相比之下 DeepSeek-V4-Flash_verifier-retry 的PathGoldExact 从 pass@1 的 48.6% 提升到 pass@5 的 70.6%，累计平均耗时 4.42 秒，说明verifier-retry 能以较低时延提高 pass@K，即提高多次尝试中获得通过 verifier 路径的概率；但它并不直接提升单次生成能力，收益受模型初始通过率限制；值得注意的是，Qwen Max 仅从 8.4% 提升到 33.4%，说明外部符号反馈只是放大而非凭空创造能力，其收益受底座模型状态追踪能力限制。

最后总结本文贡献。第一，问题层面，指出图任务的高准确率、轨迹-答案一致性等都不足以证明 LLM 忠实使用图，模型既可能在答案层依赖终点位置捷径，也可能在路径层生成自洽但图上非法的轨迹。第二，方法层面，提出一种面向序列化图推理的图干预忠实性诊断框架 GIF，结合反事实图对、位置控制序列化等，诊断答案层的位置锚定与路径层的非法轨迹，并定义 GFI、EAR、$\Delta_{\text{illegal}}$ 和 FailureHop 等指标。第三，发现层面，揭示了 LLM 图推理中的两类假忠实性及其随任务难度切换主要影响。弱提示链式图主要暴露答案层位置虚胖；困难分叉图暴露路径层非法轨迹。两种缓解机制显示 thinking 几乎完美消除失败，代价是时间太长，verifier-retry 能以较低延迟部分缓解非法路径，但受限于底座模型能力。

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

本节正式提出 Graph-Intervention Faithfulness，简称 GIF。GIF 是一个黑箱诊断框架（Diagnostic）而非benchmark，用于检验 LLM 在序列化图任务中是真正受输入图结构约束，还是由文本位置线索、答案先验或输出内部自洽性制造出表面忠实性。GIF 关注两层忠实性。

第一层是答案层忠实性：关心的不只是模型答案是否随图干预改变，还关心这种变化在控制终点位置后是否仍然存在，即检验下面这个关系 $\text{答案随图干预改变} \nRightarrow\text{答案忠实遵循图}$。答案随图改变是图忠实性的必要条件，但不是充分证据。形式化地，令 $R$ 表示一个理想但不可直接观测的事件：模型预测结果因果上由输入图结构 $G$ 控制；令 $C_\alpha$ 表示一个可观测事件：某一序列化操作 $\sigma_\alpha$ 下，模型在反事实图对 $(G_1,G_2)$ 上分别输出对应的正确终点 $y_1$ 与 $y_2$ 。若模型真的忠实遵循图结构，则有 $R \Rightarrow C_\alpha$ ，但反之不成立 $C_\alpha \nRightarrow R$ 。原因是答案随图改变也可能来自与图干预同步变化的文本线索。例如，若 $G_1$ 中正确终点 $y_1$ 总是出现在边列表最后，$G_2$ 中正确终点 $y_2$ 也总是出现在最后，那么模型只需学会“输出最后出现的节点”就能表现出很高的图干预敏感性，位置控制正是为了诊断 $C_\alpha$ 与 $R$ 之间的缺口。第二层是路径层忠实性：关心这条路径是否真的是图中合法路径，而非仅与最终答案自洽，即检验$\text{轨迹与答案一致} \nRightarrow \text{轨迹在图上合法}$。令 TAC 表示模型输出路径的末节点是否等于模型给出的答案，PathValid 表示模型从起点出发，每一步都沿真实边移动且长度正确，则 $\mathrm{TAC}=1 \not\Rightarrow \mathrm{PathValid}=1$。换言之，模型可以生成一条与答案完全自洽，但中间存在不是图中合法边的路径。

## 3.1 任务设定与反事实图对构造

给定有向图 $G=(V,E)$，$V$ 为节点集合，$E\subseteq V\times V$ 为有向边集合，待评测的 LLM 为 $f$。关注一种受控定长多跳图推理任务：给定起跳点 $s\in V$ 和跳数 $k$，模型需从点 $s$ 出发，沿图中合法有向边走 $k$ 跳后输出最终到达的节点。

一条长为 $k$ 的合法路径（Path Valid）记为 $p=(v_0,v_1,\dots,v_k)$，其中 $v_0=s$，$v_k=y$，且对 $\forall i\in{0,\dots,k-1}$，有 $(v_i,v_{i+1})\in E$ ，其终点 $v_k$​ 即为该路径对应的答案。由于 LLM 不能直接处理图 $G$，而是接收图的线性化文本表示。因此定义一个序列化函数 $\sigma_\alpha(G)=(x_1,x_2,\dots,x_n)$。其中 $\alpha$ 表示一种具体的序列化配置，包括节点标号、边顺序、语法格式以及位置控制策略。给定任务指令 $T$（包含起点 $s$、跳数 $k$ 及输出格式要求）和序列化图 $\sigma_\alpha(G)$，模型输出预测终点 $\hat{y}$；在结构化路径提示下，模型还需输出显式路径 $\hat{p}$，即 $f(T,\sigma_\alpha(G))\rightarrow(\hat{p},\hat{y})$；在 answer-only prompt 下，模型只输出预测终点 $\hat{y}$，此时可视为 $\hat{p}=\varnothing$。

答案层为检验模型输出是否真正受图控制，构造反事实图对 $(G_1,G_2)$，两张图共享相同起点 $s$ 和跳数 $k$ ，但对应的合法 $k-hop$ 终点不同$$
\begin{aligned}
G_1 &: s \xrightarrow{k\text{ hops}} y_1 \\
G_2 &: s \xrightarrow{k\text{ hops}} y_2
\end{aligned}
$$，其中 $y_1\neq y_2$，且对应的黄金路径分别为 $p_1^* = (s,\dots,y_1), \ \ p_2^* = (s,\dots,y_2)$。如果模型输入真正遵循图结构，则图从 $G_1$ 被干预为 $G_2$ 时，答案也应从 $y_1$ 改为 $y_2$，但这仅是必要条件，模型可能没有沿图推理，而直接利用与图干预同步变化的文本线索。例如，正确终点总是出现在边列表最后。后续位置控制正是为了排除这类混淆。实验中使用随机符号节点消除语义先验，通过无图先验控制（prior-only）和候选项限定的先验控制（candidate-only prior controls）检查无图条件下的固定答案偏好。若模型在无图条件下已经稳定输出某一候选答案，则该样本可能被视为受先验混淆的（prior-confounded）。本文主实验中，prior controls 表明答案先验和候选偏好不能解释主要结果。

此外，在合法路径基础上对每个任务实例施加唯一黄金路径（Path Gold Exact）约束，给定 $(G,s,k)$，存在一条从 $s$ 出发的唯一合法路径，使得 LLM 恰好走 $k$ 跳到达标准答案 $y$，则将这条路径记为黄金路径 $p^*=(v_0,v_1,\dots,v_k)$，其终点 $y=v_k$​ 即为任务标准答案，唯一性通过符号枚举验证。需要强调的是，唯一性主要用于定义 Path Gold Exact；路径合法性、TAC 和 FailureHop 并不依赖唯一黄金路径。若需要扩展到多合法路径场景，将单一路径 $p^*$ 扩展为为黄金路径集合 $\mathcal{P}^*=\{(v_0,\dots,v_k)\mid v_0=s,\ v_k=y,\ \forall i\in\{0,\dots,k-1\},\ (v_i,v_{i+1})\in E\}$ 即可。

## 3.2 位置控制序列化

反事实图对可以检验模型答案是否随图改变，但无法排除序列化位置捷径，即模型可能没有沿图推理，而是直接选择文中某个显著位置的节点，例如最后出现的节点，获得较高的图干预敏感性。为此，GIF 对同一张图 $G$ 专门构造一个位置控制组 $\Sigma(G)=\{\sigma_{\text{first}}(G),\sigma_{\text{middle}}(G),\sigma_{\text{last}}(G),\sigma_{\text{decoy}}(G)\}$，其中 $\sigma_{\text{first}}$、$\sigma_{\text{middle}}$ 和 $\sigma_{\text{last}}$ 分别表示将正确终点节点置于序列化边列表的首 \ 中 \ 尾位置，这三个变体构成终点位置扫描，用于检测模型是否在不同终点位置下稳定输出结构答案；$\sigma_{\text{decoy}}$ 是一个对抗探针，将一个非正确答案（$d\neq y$）的诱饵节点 $d$ 放置于末尾位置，若模型在 decoy-last 下输出诱饵节点，说明模型可能依赖“最后出现节点”这一位置线索，而非沿图求解。若模型真正忠实于图，则对任意位置控制序列化 $\sigma_\alpha(G)\in\Sigma(G)$，模型都应输出同一个答案 $y$。

## 3.3 答案层评估指标：Raw GIS、PC-GIS、GFI 与 EAR

这些指标用于诊断多大程度上存在位置锚定以及导致虚胖现象有多严重。在某一序列化条件 $\alpha$ 下，定义模型是否随图干预正确改变答案$C_{\alpha}^{(j)}=\mathbb{1}\!\left[f(T,\sigma_\alpha(G_1^{(j)}))=y_1^{(j)} \land f(T,\sigma_\alpha(G_2^{(j)}))=y_2^{(j)}\right]$，其中 $(G_1^{(j)},G_2^{(j)})$ 表示第 $j$ 个反事实图对，其对应终点为 $y_1^{(j)}$ 与 $y_2^{(j)}$。
### 3.3.1 原始图干预敏感性（Raw Graph Intervention Sensitivity）

原始图干预敏感性（Raw Graph Intervention Sensitivity），简称 Raw GIS。对于样本 $j$，定义 $\mathrm{RawGIS}^{(j)}=C_{\mathrm{last}}^{(j)}$，其中 $C_{\alpha}^{(j)}=\mathbb{1}\!\left[\hat{y}_{1,\alpha}^{(j)}=y_1^{(j)} \land\ \hat{y}_{2,\alpha}^{(j)}=y_2^{(j)}\right]$，即模型在反事实图对 $(G_1,G_2)$ 上分别输出对应的正确终点 $y_1$ 和 $y_2$，则认为该样本在 Raw 条件下通过，使用 endpoint-last 计算，刻画在不控制终点位置时，输出是否随反事实图干预改变。为减少单个样本偶然误差，本文对所有样本级 Raw GIS 取平均，定义数据集层面 $\mathrm{Raw\ GIS}=\frac{1}{N}\sum_{j=1}^{N}\mathrm{RawGIS}^{(j)}$。
### 3.3.2 位置控制图干预敏感性（Position-Controlled GIS）

Position-Controlled GIS，简称 PC-GIS。对于样本 $j$，定义$\mathrm{PC-GIS}^{(j)}=\prod_{\alpha\in\Sigma}C_{\alpha}^{(j)}$，即模型在 endpoint-first \ middle \ last 和 decoy-last 四种条件下都作出正确响应时，才有$\mathrm{PC-GIS}^{(j)}=1$。同理，数据集层面 PC-GIS 是所有样本级 PC-GIS 的平均值，$\mathrm{PC-GIS}=\frac{1}{N}\sum_{j=1}^{N}\mathrm{PC-GIS}^{(j)}$。PC-GIS 比 Raw GIS 更严格，因为它要求模型的图干预敏感性不能依赖某个特定的终点位置。
### 3.3.3 图跟随能力虚胖（Graph-Following Inflation）

Graph-Following Inflation，简称 GFI。对样本 $j$，定义 $\mathrm{GFI}^{(j)}=\mathrm{RawGIS}^{(j)}-\mathrm{PCGIS}^{(j)}$，衡量 Raw GIS 与 PC-GIS 之间的差距，当 Raw GIS 较高而 PC-GIS 较低时，GFI 会升高，说明输出看似随图干预改变答案，但这种表面敏感性很可能依赖终点位置锚定：一旦正确终点不再稳定处于显著位置，模型就无法稳定输出图结构决定的答案，本文将这种现象称为图跟随虚胖，即模型的表面图敏感性被终点位置等文本捷径高估。需要注意的是，GFI 的解释必须以 Raw GIS 为前提，若 Raw GIS 本身已经很低，则模型在默认条件下已经不能稳定随图改变答案，此时不应把低 GFI 解读为位置锚定被消除，而应怀疑图干预敏感性崩塌。同上，数据集层面的 GFI 定义为 $\mathrm{GFI}=\frac{1}{N}\sum_{j=1}^{N}\mathrm{GFI}^{(j)}$。
### 3.3.4 终点锚定率（Endpoint Anchoring Rate)

为直接测量模型是否被显著位置吸引，GIF 还报告干扰项后置终点锚定率（decoy-last Endpoint Anchoring Rate），简称 EAR。沿用 3.2 decoy-last 设定，记 $d^{(j)}$ 为第 $j$ 个样本中被放置在序列末尾的诱饵节点，定义样本级 EAR 为 $\mathrm{EAR}_{\mathrm{decoy}}^{(j)}=\mathbb{1}\!\left[\hat{y}_{\mathrm{decoy}}^{(j)}=d^{(j)}\right]$，其中 ($\hat{y}_{\text{decoy}}^{(j)}$) 表示模型在 decoy-last 条件下的输出答案，类似的，数据集层面 $\mathrm{EAR}_{\mathrm{decoy}}=\frac{1}{N}\sum_{j=1}^{N}\mathrm{EAR}_{\mathrm{decoy}}^{(j)}$。相比 endpoint-last，EAR 能更直接的识别终点位置锚定，因为 endpoint-last 中最后出现节点就是正确答案，因此模型输出该节点可能因为模型真正实现图跟随，也可能是末位位置捷径；而在 decoy-last 中，最后出现节点被替换为错误诱饵 $d^{(j)}$，将正确答案与末位位置线索解耦。若模型仍输出 $d$，则说明其更可能依赖“最后出现节点”这一文本位置线索。

## 3.4 路径层指标：TAC、PathValid、PathGoldExact 与 FailureHop

只靠模型给出正确答案或答案随图干预改变无法说明真的沿图走了一条合法路径，特别是在结构化 CoT 或 JSON path 输出中，模型可能生成一条看似完整、且终点与答案一致的路径，但其中某些边不合法。因此，GIF 进一步引入路径层指标，用于区分“文本自洽”与“图上合法”。设模型输出路径为 $\hat{p}=(\hat{v}_0,\hat{v}_1,\dots,\hat{v}_m)$(模型可能输出非 $k$ 长度)，输出答案为 $\hat{y}$。

### 3.4.1 轨迹-答案一致性（Trace-Answer Consistency）

Trace-Answer Consistency，简称 TAC，定义 $\mathrm{TAC}(\hat{p},\hat{y})=\mathbb{1}\!\left[\hat{y}=\hat{v}_m\right]$(只关注末节点，不关注长度)，用于检查路径终点是否等于最终答案。TAC 高说明模型输出内部自洽，即声称的路径终点与最终答案一致，然而该路径不一定真的存在于图上。
### 3.4.2 路径合法性（Path Validity）

定义 $\mathrm{Path\ Valid}\ (\hat{p},G)=\mathbb{1}\!\left[\hat{v}_0=s \land |\hat{p}|=k+1 \land \forall i\in\{0,\dots,k-1\},\,(\hat{v}_i,\hat{v}_{i+1})\in E\right]$，用于检查模型输出路径是否为输入图上的合法 $k-hop$ walk，同时执行三个检查：起点是否正确 $\hat{v}_0=s$、路径长度是否正确 $|\hat{p}|=k+1$、每一步是否为合法边 $\forall i\in\{0,\dots,k-1\},\ (\hat{v}_i,\hat{v}_{i+1})\in E$。注意，PathValid 检查的是 $|\hat{p}|=k+1$（长度是否正确），TAC 只关注末节点是否等于答案
### 3.4.3 自洽但非法的轨迹缺口（Self-Consistent but Illegal Trace Gap）

定义路径层诊断的核心信号非法路径差距 $\Delta_{\text{illegal}}$，其中 $\Delta_{\text{illegal}}=\mathrm{TAC}-\mathrm{Path\ Valid}$，用于量化“轨迹自洽但图上非法”的失败模式，TAC 较高而 PathValid 较低时 $\Delta_{\text{illegal}}$ 增大，此时模型生成与答案一致但不是图上的合法路径的结构化轨迹，即 $\mathrm{TAC}=1 \nRightarrow \mathrm{PathValid}=1$。
### 3.4.4 黄金路径完全匹配（Path Gold Exact）

定义黄金路径完全匹配（Path Gold Exact），在 3.1 的唯一黄金路径设定下，定义 $\mathrm{Path\ Gold\ Exact}\ (\hat{p},p^*)=\mathbb{1}\!\left[\hat{p}=p^*\right]$，唯一黄金路径是 $p^*$ 本身；Path Gold Exact 是检查 $\hat{p}$​ 是否等于 $p^*$ 的指标。
### 3.4.5 首次失败跳数（FailureHop）

为了定位模型从哪一步开始偏离图结构，将颗粒度从路径细化为第几跳，引入 $\operatorname{FailureHop}\ (\hat{p},G)=\min\left\{i\in\{1,\dots,k\}:(\hat{v}_{i-1},\hat{v}_i)\notin E\right\}$，FailureHop 只定义非法边位置，若路径长度足够且起点正确，则 FailureHop 记录第一条非法边所在的 hop；若全部边均合法，则 FailureHop 记为 pass；错误类型（长度 \ 起点 \ 格式 \ 非法边)单独作为 error type 记录。FailureHop 对于分析分叉图尤其重要，因为模型可能反复在早期分叉点、终端转移或特定状态更新位置失败。

## 3.5 符号验证器与重试机制（Symbolic Verifier and Retry）

再使用 GIF 诊断模型原始行为后，本文还尝试了两种缓解机制：内部预算推理（思考模式） vs 外部符号反馈（verifier-retry），本节主要介绍 verifier-retry 的概念。对样本 $j$，定义第 $t$ 次尝试输出为 $(\hat{p}_{j,t},\hat{y}_{j,t})$，使用符号验证器检查以下条件：输出是否可解析为指定格式、路径是否从起点 $s$ 出发、路径长度是否为 $k+1$、 每一条边是否属于输入图 $G$、路径终点是否等于模型答案 $\hat{y}_{j,t}$。需要强调的是， verifier-retry 不泄露黄金答案 $y$，也不告诉模型正确下一跳，只在离线评估阶段计算黄金答案正确性。若验证失败，验证器返回结构性错误反馈，例如：
```text
Your path is invalid at hop 3:
edge (J9E9, W6S2) does not exist in the graph.
Please retry with a valid k-hop path from the given start node.
```
模型随后重新生成路径和答案，最多尝试 $K$ 次。记样本 $j$ 第一次通过验证的尝试编号为 $\tau_j=\min\{t:\mathrm{Verifier\ Pass}_{j,t}=1\}$，若在 $K$ 次内始终未通过，则记为 $\tau_j=\infty$。在此基础上定义 $\mathrm{pass@}K=\frac{1}{N}\sum_{j=1}^{N}\mathbb{1}\!\left[\tau_j\le K\right]$，即最多尝试 $K$ 次，只要其中任意一次通过 verifier，就算这个样本成功。

除了 $pass@K$， verifier-retry 还记录每次尝试的延迟，设样本 $j$ 第 $t$ 次尝试延迟为 $\ell_{j,t}$，则预算 $K$ 下累计延迟为 $L_j^{(K)}=\sum_{t=1}^{\min(\tau_j,K)}\ell_{j,t}$。同理，数据集平均累计延迟为 $L^{(K)}=\frac{1}{N}\sum_{j=1}^{N}L_j^{(K)}$。最终得到成本—效果曲线 $\left(\mathrm{pass@}1,L^{(1)}\right),\left(\mathrm{pass@}2,L^{(2)}\right),\dots,\left(\mathrm{pass@}K,L^{(K)}\right)$，对于达到预算 $K$ 后仍未通过 verifier 的样本，进一步统计其第 $K$ 次输出的最终错误类型（error type）和最终 FailureHop 分布，用于判断失败是随机噪声，还是稳定结构瓶颈。如果模型在多次 retry 后仍反复卡在同一 hop，则说明 verifier 能发现错误，但模型本身缺少修复该错误所需的状态更新能力。因此，verifier-retry 有双重作用，既是一个低成本修复机制，用于检验外部符号反馈能否提高路径合法性；也是一个诊断工具，用于区分“模型能在反馈下修正路径”与“模型反复卡在同一结构转移处”这两种情况。

---
# 4 Experimental Setup

本节说明实验如何运行，包括数据集构造、模型与 prompt 设置、输出解析、统计方法和延迟记录。GIF 的指标定义已在第 3 节给出，本节不再重复框架定义，只描述具体实验配置。

## 4.1 合成图构造（Synthetic Graph Construction）

合成符号图中每个节点使用 `J9E9`、`W6S2` 这类随机符号标识，原因不再赘述。每个基础样本由一个起点 $s$、一个跳数 $k$、一条黄金路径 $p^*$ 和一个黄金终点 $y$ 构成，随后，为每个基础样本对应一组反事实图对 $(G_1,G_2)$，每张图包含四种位置控制序列化 endpoint-first \ middle \ last 和 decoy-last。因此，每个基础样本最终展开为 $2\times4=8$ 次模型调用。每个数据集（dataset）包含 N=200 个基础样本，因此每个 dataset 在单一模型和单一 prompt 下包含 $200 \times 8 = 1600$ 次调用。本文构造六个图任务数据集，如表所示：

| 数据集（Dataset）         | 拓扑类型（Topology） | 跳数 / 路径长度（Hop length） | 基础样本数（Base samples） | 每个模型/提示下的调用次数（Queries per model/prompt） |
| -------------------- | -------------: | --------------------: | ------------------: | --------------------------------------: |
| chain_3hop_N200      |          Chain |                     3 |                 200 |                                    1600 |
| chain_4hop_N200      |          Chain |                     4 |                 200 |                                    1600 |
| chain_5hop_N200      |          Chain |                     5 |                 200 |                                    1600 |
| chain_6hop_N200      |          Chain |                     6 |                 200 |                                    1600 |
| branching_4hop_N200  |      Branching |                     4 |                 200 |                                    1600 |
| branching_12hop_N200 |      Branching |                    12 |                 200 |                                    1600 |

### 4.1.1 链式图（Chain graphs）

Chain graphs 用于检测仅答案（answer-only）设置下的终点位置捷径（endpoint-position shortcut）。如果模型表现出较高 Raw GIS，但 PC-GIS 在位置控制后明显降低时，就说明模型的表面图跟随能力可能依赖了终点位置，而非真正使用图结构。同时使用 3 \ 4 \ 5 \ 6 hop 进行长度扫描，观测弱提示下位置依赖是否随长度变化，比较不同模型的位置依赖程度（稳定、部分依赖或崩溃）。
### 4.1.2 分叉图（Branching graphs）

与链式图不同，分叉图在中间节点包含多个候选分支，用于检测路径层状态追踪能力，模型不能只依赖最后出现节点或局部显著节点，必须持续维护当前节点状态，并在每一步选择图中真实存在的后继边。branching graphs 使用 4hop 和 12hop 两档难度。branching-4hop 用于与 chain-4hop 对照，控制相同跳数，突出拓扑结构从简单链式路径跟随到分叉状态追踪的转变，观察主要错误机制是否由答案层位置依赖转向路径层非法轨迹；branching-12hop 作为主要困难设置，用于考察在更长路径和更多状态更新步骤下，路径层非法轨迹是否成为更主要的失败模式。
### 4.1.3 汇聚图（Converging graph）

汇聚图天然有多条合法路径到同一终点 $y$，会破坏本文的核心路径指标唯一黄金路径；此外，汇聚图主要考察多路径下模型是否存在混淆\选错分支汇合点，这是另一个关于路径歧义消解的研究问题，并非本文研究问题，因此本文将汇聚图留作未来工作，用于多路径扩展，当前刻意用唯一路径换干净判据。
### 4.1.4 图验证（Graph validation）

所有图在进入实验前均通过符号程序验证，只有通过全部检查的样本才进入最终评测。

## 4.2 模型与提示（Models and Prompts）

### 4.2.1 模型（Models）

本文用于诊断的四个模型配置：

| Model             | Mode        | 诊断作用                                    |
| ----------------- | ----------- | --------------------------------------- |
| DeepSeek-V4-Flash | no-thinking | 低延迟模型，观察位置捷径、非法路径和 verifier-retry 的缓解效果 |
| DeepSeek-V4-Pro   | no-thinking | 作为思考模式的消融实验，观察关闭思考模式后图忠实性表现如何变化         |
| DeepSeek-V4-Pro   | thinking    | 观察思考模式是否缓解答案层与路径层失败                     |
| Qwen Max          | no-thinking | 开源模型对照，相同任务设置下检验失败模式是否稳定存在              |
| GPT-5.4-mini      | no-thinking | 闭源模型对照，相同任务设置下检验失败模式是否稳定存在              |
需要说明的是，GPT-5.4-mini 结果来自第三方 OpenAI-compatible 中转服务，因此本文按由服务商路由的模型配置（provider-routed model configuration）报告该结果，而不将其等同于官方 API 配置。此外，不同模型接口对结构化输出的支持并不完全一致。GPT-5.4-mini 的部分调用使用了 API 级 JSON 输出约束（`response_format: {"type": "json_object"}`），而 DeepSeek 和 Qwen 的对应调用主要依赖 prompt 约束输出格式。因此，跨模型比较 format failure 或 parse failure 时需谨慎；GPT-5.4-mini 较低的格式失败率可能部分来自接口级 JSON 约束，而不完全反映模型自身的格式遵循能力。本文的主要跨模型比较聚焦于答案层和路径层图推理指标，对格式相关指标仅作辅助诊断。
### 4.2.2 提示接口（Prompt interfaces）

本文使用五类 prompt，其中前三类用于主任务，后两类用于 prior control。

| 提示（Prompt）                      | 输出格式（Output）                                      | 设计目的（Purpose）                                  |
| ------------------------------- | ------------------------------------------------- | ---------------------------------------------- |
| 直接最简提示（direct_minimal）          | 仅答案（answer only）                                  | 检测仅答案输出设置下的终点位置捷径（endpoint-position shortcut）  |
| 基础 JSON-CoT 提示（jsoncot_basic）   | JSON 路径 + 答案（JSON path + answer）                  | 观察显式路径输出是否降低位置锚定，并使路径层诊断成为可能                   |
| 严格 JSON-CoT 提示（jsoncot_strict）  | 严格 JSON 路径 + 答案（strict JSON path + answer）        | 约束路径长度、起点、逐边合法性和轨迹-答案一致性（TAC），用于减少格式错误并暴露路径层失败 |
| 纯先验提示（prior_only）               | 仅答案，无图（answer only, no graph）                     | 检查无图条件下是否存在固定答案先验                              |
| 候选项限定先验提示（candidate_only_prior） | 仅答案，有候选项但无图（answer only, candidates but no graph） | 检查候选集合本身是否引入固定答案偏好                             |

`direct_minimal` 只要求模型输出最终预测终点，不要求给出路径。因此，该 prompt 主要用于答案层指标，包括 Raw GIS、PC-GIS、GFI 和 EAR。

`jsoncot_basic` 要求模型输出 JSON 格式的路径与最终预测终点，例如：
```json
{
  "path": ["S0", "...", "Y"],
  "answer": "Y"
}
```
该设置让路径级指标可被计算，包括 TAC、PathValid、PathGoldExact 和 FailureHop。

`jsoncot_strict` 在 `jsoncot_basic` 基础上加入更严格的格式约束。模型必须输出严格 JSON，不得包含额外文本；路径应包含 ($k+1$) 个节点，应从起点 $s$ 开始，预测终点应等于路径最后一个节点。需要注意的是，这些约束只是提示层面的格式与结构要求，并不保证模型实际生成的每条边都属于输入图。因此，所有结构化输出仍需进行符号路径验证。

`prior_only` 和 `candidate_only_prior` 不提供完整图结构，用于排除答案先验和候选集合偏好。若模型在无图或仅候选条件下已经稳定命中正确答案，则说明该样本可能受到 prior confounding 影响；本文将这些控制结果单独报告，用于判断主实验结果是否可由答案先验或候选偏好解释。
### 4.2.3 解码配置（Decoding configuration）

非 retry 主实验使用确定性解码，全程$temperature=0$；对于 verifier-retry，仅第一次尝试使用 $temperature=0$，若路径未通过符号验证器，则后续 retry 使用 temperature=0.3，以减少模型在确定性解码下重复生成同一结构错误的情况。因此，verifier-retry 结果包含一定解码随机性（decoding randomness）。本文对 verifier-retry 进行多次独立运行，并报告 pass@K 与累计延迟的均值。

## 4.3 评估与统计（Evaluation and Statistics）

### 4.3.1 答案层评估（Answer-level evaluation）

评估使用第 3 节定义的指标：Raw GIS、PC-GIS、GFI、EAR，其中 Raw GIS 和 PC-GIS 按反事实图对逐样本配对计算；GFI 先在样本级计算，再在数据集层面平均；EAR 则按 decoy-last 输入实例计算，最后在数据集层面平均。
### 4.3.2 路径层评估（Path-level evaluation）

路径层评估使用第 3 节定义的指标：TAC、Path Gold Exact、$\Delta_{\text{illegal}}$、FailureHop、error type distribution。其中 Path Gold Exact 作为路径正确率的主报告指标（检查是否完全等于唯一黄金路径 $p^*$），原因是在唯一黄金路径设定下，Path Valid 蕴含 Path Gold Exact（合法且长度正确的 $k$ 跳路径必为唯一的 $p^*$），因此本文以 Path Gold Exact 作为路径正确性的报告指标，主表不再单独报告 Path Valid；其余指标用于诊断而非报告，具体而言，TAC 检查答案是否等于输出路径末节点；$\Delta_{\text{illegal}}$=TAC−Path Valid 量化“自洽但非法”轨迹（其中 Path Valid 检查起点、长度与逐边合法性）；FailureHop 记录第一条非法边所在的 hop；对于路径过短、路径过长、起点错误、格式错误和轨迹-答案不一致，分别记录对应错误类型；对于路径长度足够且起点正确但某一步边不存在的输出，记录为：
```text
illegal_edge_at_hop_i
```
其中 $i$ 表示第一条非法边所在 hop。
### 4.3.3 验证器重试评估（Verifier-retry evaluation）

verifier-retry 仅在 jsoncot_strict 设置下评估，因为该设置要求模型输出结构化路径与预测终点。对于达到最大预算后仍失败的样本，本文统计最终 error type、最终 FailureHop 分布以及 repeated_same_hop 比例。repeated_same_hop 表示模型在多次 retry 中反复失败于同一 hop，用于判断剩余失败是否呈现稳定的结构瓶颈。verifier-retry 结果对 DeepSeek-V4-Flash 报告 3 次独立运行的平均值；对 Qwen Max 报告 2 次独立运行的平均值。
### 4.3.4 置信区间（Confidence intervals）

本文默认报告 95% confidence intervals，对于非 retry 主实验，所有模型调用均使用确定性解码 $temperature=0$，因此 bootstrap 置信区间主要反映由测试样本选择带来的不确定性，而不反映解码随机性。除特别说明外，所有 bootstrap 置信区间均使用 $B=10{,}000$ 次重采样，并采用 percentile bootstrap，即取 bootstrap 分布的第 2.5 和第 97.5 百分位作为区间端点。对于 Raw GIS、PC-GIS 和 GFI 等反事实配对指标，本文使用 paired bootstrap。具体而言，以基础反事实图对为重采样单位；在每个 bootstrap 重采样集合内，重新计算 Raw GIS、PC-GIS，并由二者差值得到 GFI。对于 TAC、Path Gold Exact 和 $\Delta_{\text{illegal}}$ 等指标，本文使用 sample-level bootstrap，以样本为单位重采样，并在每个重采样集合内重新计算对应比例指标。对于 verifier-retry，由于第一次尝试使用 $temperature=0$，后续 retry 使用 $temperature=0.3$，结果同时受到样本选择和解码随机性的影响；本文对每个 run 和每个重试预算 $K$，分别计算 $\mathrm{pass@}K$ 和累计平均延迟 $L^{(K)}$。最终报告 run-level 均值，并使用不同 run 之间的波动反映 retry 阶段的解码随机性。若对 verifier-retry 报告 bootstrap 区间，则该区间仅表示给定 run 内的样本级不确定性；跨 run 的均值和波动用于补充刻画解码随机性。
### 4.3.5 延迟与超时处理（Latency and timeout handling）

所有模型调用均记录端到端 wall-clock latency，即从请求发出到模型返回完整响应或触发超时之间的耗时。对于普通推理，latency 记录单次请求耗时；对于 verifier-retry，记录每次尝试的耗时 $\ell_{j,t}$​，并在不同重试预算 $K$ 下计算样本级累计延迟。若第 $j$ 个样本在第 $\tau_j$​ 次尝试首次通过验证，则其在预算 $K$ 下的累计延迟为 $L_j^{(K)}=\sum_{t=1}^{\min(\tau_j,K)}\ell_{j,t}$；若所有 $K$ 次尝试均未通过验证，则累计前 $K$ 次尝试的耗时。若请求超过预设 timeout，则记为 timed_out。timeout 输出不计为正确答案，也不计为合法路径；在路径层评估中视为无效输出，并在错误统计中单独报告。对于 verifier-retry，timeout 的单次尝试视为失败尝试，并计入对应预算下的累计延迟。延迟分析报告平均值、中位数和高分位数，并单独报告 timeout rate，以避免少数极端慢请求掩盖整体趋势。
### 4.3.6 可复现性（Reproducibility）

所有模型调用均保存任务元信息、模型配置、原始输出和运行状态。任务元信息包括 dataset name、task id、sample id、topology、hop、start node、graph side、serialization variant、gold answer、gold path、decoy node 以及输入图边列表。模型配置包括 provider、model name、model tag、thinking type、prompt mode 和 decoding temperature。每次调用还记录 raw model output、request success、latency、token usage 和 timeout status。模型输出解析与指标计算在离线评估阶段完成。评估文件保存 parsed answer、parsed path、parse status、answer correctness、last-node anchoring、decoy-last EAR 标记、path error type、PathValid、TAC、PathGoldExact 和 FailureHop 等任务级字段，并进一步汇总为 setting-level、sample-level 和 bootstrap confidence interval 结果。对于 verifier-retry 实验，记录每个任务在不同重试预算 $K$ 下的 pass/fail 状态、累计延迟、attempts used、最终 error type 和最终 FailureHop。对于达到最大预算后仍失败的样本，额外统计 error type 序列、FailureHop 序列、repeated_same_error 和 repeated_same_hop，用于分析剩余失败是否呈现稳定结构瓶颈。图生成器、序列化脚本、输出解析器和符号 verifier 均使用同一套节点与边表示。所有主结果均基于通过图结构校验的数据集计算。

---
# 5 Results

本节报告 GIF 在符号图任务上的主要结果，整体发现可以概括为三点。第一，prior controls 表明 LLM 表现不能由答案先验或候选偏好充分解释；第二，chain graphs 在弱提示条件设置下表现出较高 Raw GIS，但这一表现主要来自终点位置依赖，一旦控制终点位置，表面图跟随能力便明显下降；第三，branching graphs 在结构化输出设置下，位置依赖被削弱，但更深层的非法路径问题暴露出来，即模型常生成答案自洽但图上非法的路径。除非特别说明，本节中比例指标均以百分比报告。
![[Pasted image 20260609225610.png]]
## 5.1 先验控制排除了答案先验的影响（Prior controls rule out answer priors）

首先在代表性数据集上进行 prior-only 与 candidate-only prior 控制，包括 chain-4hop、branching-4hop 和 branching-12hop。没有对每一类 chain hop 都单独运行 prior controls 的原因是所有数据集均使用无语义先验的随机符号节点（例如 `J9E9` 或 `W6S2`），答案先验混淆的强度不应随 hop 长度发生显著变化；此外，3 \ 5 \ 6-hop 主要用于 GFI 长度扫描，即考察位置依赖现象如何随路径长度变化，这与 prior control 的目的不同。结果如表所示：在 prior-only 条件下，DeepSeek-V4-Flash 和 Qwen Max 的准确率均为 0%；在 candidate-only prior 条件下，模型准确率也低于或接近随机候选基线。在不给出图结构时，模型几乎不能稳定识别正确终点，因此后续实验中的成功或失败模式不能由答案先验或候选列表偏好单独解释。

| Dataset                |              Random baseline | DS-Flash prior-only | Qwen Max prior-only | DS-Flash candidate-only | Qwen Max candidate-only | Prior controls |
| ---------------------- | ---------------------------: | ------------------: | ------------------: | ----------------------: | ----------------------: | :------------: |
| `chain_3hop_N200`      |                            — |                   — |                   — |                       — |                       — |       No       |
| `chain_4hop_N200`      | $\frac{1}{22}\approx 4.55\%$ |            $0.00\%$ |            $0.00\%$ |                $2.50\%$ |                $3.00\%$ |      Yes       |
| `chain_5hop_N200`      |                            — |                   — |                   — |                       — |                       — |       No       |
| `chain_6hop_N200`      |                            — |                   — |                   — |                       — |                       — |       No       |
| `branching_4hop_N200`  | $\frac{1}{28}\approx 3.57\%$ |            $0.00\%$ |            $0.00\%$ |                $3.50\%$ |                $1.50\%$ |      Yes       |
| `branching_12hop_N200` | $\frac{1}{84}\approx 1.19\%$ |            $0.00\%$ |            $0.00\%$ |                $0.25\%$ |                $0.00\%$ |      Yes       |

**Table X.** Prior-control results on representative datasets. DS-Flash denotes DeepSeek-V4-Flash. Prior-only and candidate-only controls remain at or near the random baseline, suggesting that the main results cannot be explained by answer priors or candidate-set biases.
**Finding 1.** 在代表性符号图数据集上，prior controls 显示模型在无图条件下的表现低于或接近随机候选基线；因此，主结果不能归因于答案先验或候选偏好。（On representative symbolic graph datasets, prior controls indicate that model performance in no-graph settings remains below or comparable to the random candidate baseline. This suggests that the main results cannot be explained by answer priors or candidate-set biases.）

## 5.2 弱提示会诱发答案层的位置捷径（Weak prompts induce answer-level positional shortcuts）

本节报告答案层的位置依赖实验结果，包括各模型在不同链长和拓扑上的 GFI （位置虚胖）长度扫描，实验揭示了三个主要发现：

第一，chain graphs 图干预敏感性在位置控制后消失，branching 上 $GFI≈0$ 是 Raw GIS 崩塌的结果，非忠实性提高：整体上 chain graphs 中 Raw GIS 往往较高，但 PC-GIS 几乎始终接近 0 导致 GFI 与 Raw GIS 基本重合，表明在 direct_minimal 弱提示下模型表现出的图干预敏感性大多不能在位置控制后保持，多数是终点位置捷径虚胖化；由于位置捷径在分叉图中失效，Raw GIS 本身低，导致 GFI ≈0。这对应 3.3.3 的 caveat：低 GFI 并非虚胖消除，而是 Raw GIS 崩塌的自然结果。branching 上的主要失败转入路径层（见 §5.3）。
![[Pasted image 20260612135148.png]]
图注：GPT-5.4-mini 在 direct_minimal 下仅评测 chain 拓扑，branching 数据缺失，汇总图应注明该点仅取三模型平均。

第二，三模型位置依赖性质不同：DeepSeek-V4-Flash 呈现稳定的位置锚定型：chain 3–6 hop 持续高位虚胖（$62.5\%$–$92.5\%$），PC-GIS 全程 ≈0，说明 Raw GIS 几乎完全来自位置线索；GPT-5.4-mini 表现为中间型：chain 3–6 hop 的 GFI 随 hop 单调下降（$82.4\% \to 46.7\%$），但 PC-GIS 贴地导致二者仍基本重合，说明它同样受到位置线索影响，只是这种位置依赖随 hop 增加缓慢衰减；Qwen Max 则呈现出另一种失败形态：它在 chain-3hop 上仍有较高 Raw GIS 和 GFI，但从 chain-5hop 开始 Raw GIS 已接近 0（$73.5\% \to 38.0\% \to 4.0\% \to 3.0\%$）。此时低 GFI 不能解释为位置锚定被消除，而应解释为图干预敏感性本身崩塌。
![[Pasted image 20260612135331.png]]![[Pasted image 20260612135315.png]]
注：GPT-5.4-mini 在 direct_minimal 下仅报告 chain graphs，因此没有 branching EAR 点。
![[Pasted image 20260612135353.png]]
第三，EAR 描述模型选择末位诱饵节点的比例，答案层位置锚定的直接证据：在 chain 弱提示下DeepSeek-V4-Flash 的 decoy-last EAR 高达 0.43–0.51，近半数输出直接选择序列末位节点,是赤裸的终点锚定；GPT-5.4-mini 的 EAR 稳定在 0.37–0.40，低于 DeepSeek-V4-Flash 但相当稳定，虽然其 GFI 随 hop 下降，但 EAR 显示它持续受末位线索影响；Qwen Max 的 EAR 则相对较低（chain-3hop 约 0.30）且随 hop 快速衰减，结合其 Raw GIS 同步崩塌，说明不是位置锚定被消除而是模型已经失去稳定的图干预敏感性。需要强调的是EAR 与 GFI 共享同一逻辑，低 EAR 仅在 Raw GIS 崩塌或位置捷径失效时出现，不能被误读为锚定消除——此时模型既不锚定末位、也未真正沿图推理，必须结合 Raw GIS 是否崩塌来解读，而高 EAR 是位置锚定的充分证据；branching 上 EAR 降至近 0，并非位置锚定被消除而是位置捷径失效后 Raw GIS 整体崩塌的伴随结果。

**Finding 2.** 弱 answer-only 提示会诱发答案层的图跟随虚胖：在 chain graphs 中，默认位置条件下的高 Raw GIS 主要来自 endpoint-position shortcut；但在更长链或分叉拓扑中，Raw GIS 本身可能崩塌，因此 GFI 必须结合 Raw GIS 一起解释。（Weak answer-only prompts induce answer-level false faithfulness: Raw GIS may be high under endpoint-last serialization, but PC-GIS collapses after position control.）

## 5.3 结构化输出缓解链式位置捷径，但揭示非法轨迹问题（Structured output removes chain shortcuts but exposes illegal traces）

图 X 汇总了结构化输出前后的答案层与路径层的整体迁移，横轴指标按照“数据集 \ prompt”排列，依次展示 $\text{chain direct } \backslash \text{ structured} \to \text{branching direct } \backslash \text{ structured}$ 的变化，纵轴指标同时报告 Raw GIS、GFI、EAR 和 $\Delta_{\text{illegal}}$，展示了主导失败形态的演变：chain + `direct_minimal` 下的失败主要来自答案层位置虚胖；引入结构化输出后，chain 上 GFI 被压低，Raw GIS 上升到接近满分；当任务转入 branching + structured output 后，路径层 $\Delta_{\text{illegal}}$ 明显升高，非法轨迹成为主要失败形式。
![[Pasted image 20260612162353.png]]
注：`direct_minimal` 设置下模型只输出答案，路径层指标 $\Delta_{\text{illegal}}$ 不适用，图 X 中将其绘制为 0 仅用于视觉对齐。

发现一，prompt $\texttt{direct\_minimal} \to \texttt{JSONCOT}$ 明显降低位置依赖且未引入非法路径：在 chain graphs 上，结构化输出首先改变的是答案层位置依赖。图 X 中，chain-3hop 和 chain-4hop 的 `direct_minimal` 设置下，Raw GIS 与 GFI 较高，EAR 接近 0.4，引入结构化输出`JSONCOT`后，chain-4hop 的行为发生明显变化。Raw GIS 上升到 1.0，GFI 、$\Delta_{\text{illegal}}$ 均在 0 附近，说明结构化输出在 chain graphs 上降低位置依赖的同时未引入路径层非法轨迹。完整的 GFI bootstrap 95% CI 进一步支持这一结论。附录图 X 显示，在 chain graphs 上，结构化输出显著压低答案层位置虚胖。例如 DeepSeek-V4-Flash 在 chain-4hop 下的 GFI 从 `direct_minimal` 的高位下降到 `JSONCOT` 的接近 0，且置信区间明显分离，CI 紧贴 1.0；Qwen Max 也呈现相同趋势。也就是说，`direct_minimal` 到 `JSONCOT` 的变化显著降低了图干预的位置依赖现象。

发现二，branching-4hop 是过渡点：与 chain-4hop 相比具有相同 hop 长度，但拓扑上额外引入了分叉选择。图 X 中，chain-4hop structured 的 Raw GIS 为 1.0，GFI 与 $\Delta_{\text{illegal}}$ 均接近 0 而 branching-4hop structured 的 Raw GIS 只有约 0.40，$\Delta_{\text{illegal}}$ 升至约 0.23，在相同 hop 长度下，分叉拓扑使结构化输出开始揭露另一个问题——边非法；与 branching-12hop 相比路径更短、状态追踪更少，因此结构化输出仍能恢复一部分答案层图干预敏感性。图 X 中 Raw GIS 从 branching-4hop direct 条件下的接近 0 回升到约 0.40，与此同时 $\Delta_{\text{illegal}}$ 也首次明显升高，达到约 0.23，说明路径层非法轨迹开始成为更主要的失败形式但尚未完全主导。这一过渡趋势也说明结构化输出的作用是双层的，显著削弱答案层位置捷径提高图忠实性，使 Raw GIS、PC-GIS 和 PathGoldExact 同时接近满分，同时把失败从答案层暴露到路径层，原本隐藏在答案层的失败转化为可被路径验证器观测到的结构性错误。这正是 GIF 同时需要答案层指标和路径层指标的原因。
![[Pasted image 20260610002418.png]]
发现三，branching-12hop 的 prompt $\texttt{direct} \to \texttt{JSONCOT}$，模型开始恢复一部分 Raw GIS ，同时非法边问题成为失败的主要形式：Table 3 展示了 branching-12hop 的结果。在 `direct_minimal` 条件下，模型只输出答案，因此无法评估路径是否合法；此时 DeepSeek-V4-Flash 的 Raw GIS 为 $0.0\%$，Qwen Max 的 Raw GIS 也为 $0.0\%$，说明弱提示下模型几乎不能稳定随图干预改变答案；切换到 `JSONCOT` 后，模型开始显式输出路径，DeepSeek-V4-Flash 的 Raw GIS 从 $0.0\%$ 回升到 $11.5\%$，Qwen Max 从 $0.0\%$ 回升到 $2.0\%$，结构化输出恢复了一部分原始图干预敏感性。但 Table 3 同时显示，恢复出来的并不是稳定的图忠实性，而是伴随着严重的路径层非法轨迹。DeepSeek-V4-Flash 在 `JSONCOT` 下的 $\Delta_{\text{illegal}}$ 达到 $50.8\%$，PathGoldExact 为 $48.5\%$；Qwen Max 的 $\Delta_{\text{illegal}}$ 更高，达到 $90.8\%$，而 PathGoldExact 只有 $8.4\%$，再次说明结构化输出并不意味着导致非法路径，而是使 branching-12hop 中原本不可见的状态追踪错误变得可观察，模型开始生成路径但这些路径常常不是输入图上的合法边。

| Model                       | Prompt           | Accuracy |  Raw GIS |  PC-GIS |      GFI | decoy-last EAR | (\Delta_{\text{illegal}}) | PathGoldExact |
| --------------------------- | ---------------- | -------: | -------: | ------: | -------: | -------------: | ------------------------: | ------------: |
| DeepSeek-V4-Flash           | `direct_minimal` |  $0.9\%$ |  $0.0\%$ | $0.0\%$ |  $0.0\%$ |        $6.0\%$ |                       N/A |           N/A |
| DeepSeek-V4-Flash           | `jsoncot_strict` | $50.2\%$ | $11.5\%$ | $0.0\%$ | $11.5\%$ |        $6.0\%$ |                  $50.8\%$ |      $48.5\%$ |
| Qwen Max                    | `direct_minimal` |  $0.5\%$ |  $0.0\%$ | $0.0\%$ |  $0.0\%$ |        $1.3\%$ |                       N/A |           N/A |
| Qwen Max                    | `jsoncot_strict` | $13.8\%$ |  $2.0\%$ | $0.0\%$ |  $2.0\%$ |        $6.0\%$ |                  $90.8\%$ |       $8.4\%$ |
| DeepSeek-V4-Pro no-thinking | `jsoncot_strict` | $56.4\%$ | $25.5\%$ | $2.0\%$ | $23.5\%$ |        $3.2\%$ |                  $44.6\%$ |      $55.4\%$ |
| GPT-5.4-mini                | `jsoncot_strict` |  $8.3\%$ |  $1.0\%$ | $0.0\%$ |  $1.0\%$ |        $0.2\%$ |                  $71.8\%$ |       $8.1\%$ |
**表 3.** branching-12hop 在仅答案与结构化输出设置下的结果。`direct_minimal` 不输出显式路径，因此 $\Delta_{\text{illegal}}$ 和 PathGoldExact 不适用。结构化输出使路径层失败变得可观测：模型可能生成与最终答案自洽的显式路径，但这些路径往往并不是输入图中的合法路径。（Table 3. Branching-12hop under answer-only and structured-output settings. `direct_minimal` does not produce explicit paths, so (\Delta_{\text{illegal}}) and PathGoldExact are not applicable. Structured output makes path-level failures observable: models may produce explicit paths that are self-consistent with their final answers, yet these paths are often not valid walks in the input graph.）

**Finding 3.** 结构化输出可以缓解简单链式图上的位置捷径，但会在分叉图上暴露轨迹层面的虚假忠实性：路径与答案自洽，并不等于路径合法。（Structured output can mitigate positional shortcuts on simple chain graphs, but exposes trace-level spurious faithfulness on branching graphs: trace-answer consistency does not imply path validity.）

## 5.4 两类缓解机制：内部预算推理（思考模式） vs 外部符号反馈（verifier-retry）

前面的实验结果表明，结构化输出虽然可以缓解 chain graphs 的答案层位置捷径，但在 branching graphs 上揭露出了新的问题，即模型可以生成与最终答案自洽但不合法的路径。基于此，进一步尝试了两类缓解机制：一种是内部缓解，开启思考模式，让模型用更高推理预算维护图状态；另一种是外部缓解，即使用符号 verifier 检查路径是否合法，并在发现路径长度错误或非法边时将错误类型反馈给模型并触发重试。需要强调的是，verifier 只反馈结构错误，不泄露 gold answer、gold path 或正确下一跳。
![[Pasted image 20260612191859.png]]
### 5.4.1 内部缓解：thinking 完全解决任务，代价是时延成本高

首先比较 DeepSeek-V4-Pro 的 no-thinking 与 thinking 模式。 $\texttt{branching-12hop} + \texttt{jsoncot\_strict}$ 的设置下 DeepSeek-V4-Pro 通过思考模式解决了所有任务（1 个因 timeout 未返回有效结果），已完成样本的准确率、路径合法性和 Path Gold Exact、Raw GIS 均几乎达到满分，GFI 接近 0，表明在足够高的内部推理预算下，思考模式可以同时消除答案层位置依赖和路径层非法轨迹同时；也证明了 branching-12hop 任务本身并非不可解，强模型在高推理预算下可以接近完美完成。当然，这一成绩伴随显著的时延成本，DeepSeek-V4-Pro no-thinking 的平均时延约为 2.4 秒，而思考模式的平均时延为 46.7 秒，约为前者的 19 倍。因此，认为 thinking 更适合理解为高推理预算下的高性能参考而非处理任务的默认方案。

Table X. DeepSeek-V4-Pro under no-thinking and thinking modes on branching-12hop + `jsoncot_strict`. All rows use the same model; only the inference mode differs. Metrics except latency are reported in percentages.

| Mode        | Accuracy |   Raw GIS |   PC-GIS |      GFI | Path Gold Exact | Avg. latency |
| ----------- | -------: | --------: | -------: | -------: | --------------: | -----------: |
| no-thinking | $56.3\%$ |  $25.5\%$ |  $2.0\%$ | $23.5\%$ |        $55.3\%$ |         2.4s |
| thinking    | $99.9\%$ | $100.0\%$ | $99.5\%$ |  $0.5\%$ |        $99.9\%$ |        46.7s |
no-thinking 模式下的失败不是简单格式问题，DeepSeek-V4-Pro 的 Accuracy 为 56.3%，Path Gold Exact 为 55.3%，PC-GIS 仅为 2.0%，表明模型存在明显的路径非法和图状态追踪失败。Thinking 可以缓解该问题，但它是一种高成本的内部缓解机制。
### 5.4.2 外部缓解：verifier-retry 可以部分缓解，但受模型能力限制

与 thinking 不同，verifier-retry 不依赖单次高预算的内部推理，而是在模型生成路径后进行外部符号检查。该实验同样在 $\texttt{branching-12hop} + \texttt{jsoncot\_strict}$ 上运行，最大重试次数为 $K=5$。Table X 显示 pass@K 曲线，DeepSeek-V4-Flash 从 pass@1 的 48.6% 提升到 pass@5 的 70.6%，累计延迟为 4.42 秒；Qwen Max 从 pass@1 的 8.4% 提升到 pass@5 的 33.4%，累计延迟为 12.12 秒。

Table X.Verifier-retry results on branching-12hop + `jsoncot_strict`. pass@K is reported as a percentage, and Latency@5 denotes the average cumulative latency at retry budget (K=5). Increasing the retry budget improves pass@K for both models, but the gains saturate and depend strongly on the base model: DeepSeek-V4-Flash reaches 70.6% pass@5 with 4.42s latency, whereas Qwen Max reaches only 33.4% despite a higher 12.12s latency.

| Model                     |   pass@1 |   pass@2 |   pass@3 |   pass@4 |   pass@5 | Latency@5 |
| ------------------------- | -------: | -------: | -------: | -------: | -------: | --------: |
| DeepSeek-V4-Flash + retry | $48.6\%$ | $59.0\%$ | $64.4\%$ | $68.6\%$ | $70.6\%$ |    4.42 s |
| Qwen Max + retry          |  $8.4\%$ | $17.2\%$ | $24.1\%$ | $29.8\%$ | $33.4\%$ |   12.12 s |
结果表明外部 verifier-retry 可以提高路径合法通过率，收益受模型能力限制。DeepSeek-V4-Flash 的 pass@1 已接近 50%，说明模型在首次尝试时就已经能生成相当比例的合法路径，增加重试预算后，pass@K 进一步上升，表明外部结构反馈和重新生成可以提高通过率；相比之下，Qwen Max 的 pass@1 只有 8.4%，即使经过 5 次重试也只达到 33.4%，说明 verifier-retry 提高的是多次尝试下的通过率，而不是直接提升 LLM 单次成功生成合法路径的能力，当模型本身初始通过率就较低时，单纯增加重试次数存在明显的收益上限。这也是 pass@K 曲线呈现边际收益递减（DeepSeek-V4-Flash 从 $K=1$ 到 $K=2$ 提升 10.4 个百分点，但从 $K=4$ 到 $K=5$ 只提升 2.0 个百分点；Qwen Max 也呈现类似饱和趋势）的重要解释之一。通过分析 FailureHop 分布可知，verifier 可以发现错误，也可以提醒 LLM 错误在哪里，但后续修复仍依赖模型自身的图状态追踪能力，前几次 retry 主要处理“可修正或随机失误”类的样本，剩下的失败样本往往卡在同一 hop 或同类非法边，说明特定分叉位置存在稳定的状态追踪瓶颈，因此继续增加 K 新增通过数会越来越少。

总体来看，thinking 和 verifier-retry 代表两种不同的缓解路线。Thinking 是内部缓解，通过增加模型自身推理预算显著降低答案层和路径层失败，但时延成本高；Verifier-retry 是外部缓解，通过符号验证和重试缓解非法路径问题，成本更低，也更模块化，但其上限由底座模型的图跟随能力决定。需要注意的是，在本文的唯一 $k$-hop 合法路径设定下，verifier pass 与 Path Gold Exact 在结果上等价：任何从起点出发、长度正确、逐边合法且 answer 等于路径末节点的输出，都必须对应唯一黄金路径 $p^*$。不过，verifier 本身并不使用 gold path ，它只检查输出路径的结构合法性。思考模式与 verifier retry 二者不存在完全替代，DeepSeek-V4-Pro thinking 以 46.7 秒达到 99.9% 的 Path Gold Exact，而 DeepSeek-V4-Flash verifier@5 以 4.42 秒达到 70.6% 的路径通过率。从效果维度比较，都使用”最终路径正确率“标准，思考模式单次的 $\texttt{Path Gold Exact} ≈ 99.9\%$，而 verifier pass@5 的 PathGoldExact 仅为 71%（DS-Flash）和 34%（Qwen），效果上 thinking 完胜，这是思考模式作为高性能参考可以预见的结果；从成本维度比较，都使用"平均延迟"标准，thinking 的单次推理约耗时约为 46.7s，而 verifier@5 累计耗时约 4.5s（Flash，5次重试的累计），其中通过 verifier-retry 提供结构错误提醒，并给予模型多次重新生成的机会，加上 DeepSeek-V4-Flash 本身生成速度较快，所以重复尝试的总时延成本相对较低，这正是 verifier-retry 的主要优势——以较低的外部检查和重试成本，提高多次尝试下获得合法路径的概率；从同时看效果和成本的性价比维度比较，thinking 用 46.7s，verifier 用 1/10 的时间达到了 thinking 约 71% 的效果（0.71/0.999≈71%），因此一个合理的定位是 verifier 并非是思考模式的上位或等价替代，而是用极低成本逼近 thinking 的大部分效果。

**Finding 4.** 面对 branching graphs 上的轨迹层虚假忠实性，thinking 和 verifier-retry 提供了两类互补缓解机制：thinking 更强但更慢，verifier-retry 更便宜但只能部分缓解非法路径。Verifier-retry 可以在较低延迟下部分缓解非法路径，但其可达到的上限仍由底座模型自身的图跟随能力决定。（Against trace-level spurious faithfulness on branching graphs, thinking and verifier-retry offer complementary mitigation strategies. Thinking substantially improves path correctness but incurs high latency, while verifier-retry provides a cheaper repair mechanism that only partially corrects illegal traces.Verifier-retry partially repairs illegal paths at lower latency, but its ceiling is determined by the base model’s graph-following ability.）
## 5.5 结果汇总（Summary of Results）

第 5.2 至 5.4 节报告了本文的主要代表性结果。本节不再引入新的消融实验，而是从提示形式（prompt interface）、拓扑与路径长度（topology-depth）、推理预算（reasoning budget）和 verifier 预算（verifier budget）四个角度总结前述结果及附录中的补充统计。

| 扫描维度（Scan axis）    | 主要结论（Main takeaway）                                                                                                                                                                                                                                                     | 完整结果（Full results） |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| Prompt interface   | `direct_minimal` 最容易暴露答案层位置捷径；`jsoncot_basic` 和 `jsoncot_strict` 能显著缓解 chain graphs 上的 shortcut，但不能保证 branching graphs 上的路径合法性。`jsoncot_basic` 与 `jsoncot_strict` 的对比进一步表明，更强格式约束并不自动等价于更强图合法性，prompt interface 本身是控制图忠实性的关键变量。                                         | Appendix A.1       |
| Topology and depth | Chain depth scan 显示答案层失败具有模型差异：DeepSeek-V4-Flash 在 chain 3–6 hop 上持续保持较高 Raw GIS / GFI，而 Qwen Max 随 hop 增长从较高 Raw GIS 转为 near-zero sensitivity collapse。Branching depth comparison 显示路径层非法性随分叉深度放大：branching-4hop 已出现非零 illegal-trace gap，branching-12hop 则将该失败放大为主导机制。 | Appendix A.2       |
| Reasoning budget   | DeepSeek-V4-Pro thinking 在 branching-12hop 上几乎消除答案层和路径层失败，但平均延迟显著高于 no-thinking。这表明困难任务本身可解，但需要更高内部推理预算。                                                                                                                                                                | Appendix A.3       |
| Verifier budget    | pass@K 从 K=1 到 K=5 持续上升但边际收益递减；DeepSeek-V4-Flash 的提升和上限明显高于 Qwen Max，说明 verifier-retry 放大已有图跟随能力，而不是凭空创造图推理能力。                                                                                                                                                          | Appendix A.4       |

这些结果共同支持本文的机制解释：弱提示链式图主要暴露答案层位置虚胖，分叉图结构化输出主要暴露路径层自洽但非法，thinking 与 verifier-retry 分别从内部推理预算和外部结构反馈两个方向缓解失败，但成本和上限不同。

---
# 6 Analysis

第 5 节已经报告了主要实验结果：弱提示下的 chain graphs 会暴露答案层位置虚胖，结构化输出能缓解简单链式图上的 shortcut，但在 branching graphs 上又暴露出路径层非法轨迹；thinking 能显著缓解失败但延迟较高，verifier-retry 能部分缓解非法路径但存在上限。

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

## 6.2 为什么 verifier-retry 会饱和（Why verifier-retry saturates）

§5.4 表明，verifier-retry 可以提高 pass@K，但提升幅度会随着 K 增加而迅速变小。本节进一步解释这一饱和现象。核心原因是：verifier-retry 提高的是多次尝试中至少一次通过符号检查的概率，而不是直接提升模型单次生成路径的能力。因此，当剩余失败样本具有稳定结构瓶颈时，继续增加 retry 预算会反复遇到相似错误，新增通过样本逐渐减少。为了区分“多次尝试带来的自然提升”和“结构性瓶颈导致的饱和”，引入一个简单的独立重试基线。若模型每次尝试都以固定概率 $p$ 生成通过 verifier 的路径，并且不同尝试近似独立，则最多尝试 $K$ 次的通过率应满足 $\mathrm{pass@}K = 1-(1-p)^K$，其中 $p$ 可由 pass@1 估计。需要注意的是，这个公式不是模型真实推理过程的理论假设，而是一个无效模型（null model），如果实测 pass@K 接近该曲线，说明 retry 更接近低成功率下的重复采样；如果实测 pass@K 明显低于该曲线，则说明剩余失败并不能通过独立重试自然解决，可能存在任务难度异质性或稳定结构瓶颈。

| 模型（Model）         | 重试预算 K | 实际 pass@K（Observed pass@K） | 独立重试零基线（Independent-retry null baseline） | 差值（Difference） |
| ----------------- | -----: | -------------------------: | ---------------------------------------: | -------------: |
| DeepSeek-V4-Flash |      1 |                   $48.6\%$ |                                 $48.6\%$ |        $0.0\%$ |
| DeepSeek-V4-Flash |      2 |                   $59.0\%$ |                                 $73.5\%$ |      $-14.5\%$ |
| DeepSeek-V4-Flash |      3 |                   $64.4\%$ |                                 $86.4\%$ |      $-22.0\%$ |
| DeepSeek-V4-Flash |      4 |                   $68.6\%$ |                                 $93.0\%$ |      $-24.4\%$ |
| DeepSeek-V4-Flash |      5 |                   $70.6\%$ |                                 $96.4\%$ |      $-25.8\%$ |
| Qwen Max          |      1 |                    $8.4\%$ |                                  $8.4\%$ |        $0.0\%$ |
| Qwen Max          |      2 |                   $17.2\%$ |                                 $16.1\%$ |       $+1.1\%$ |
| Qwen Max          |      3 |                   $24.1\%$ |                                 $23.2\%$ |       $+0.9\%$ |
| Qwen Max          |      4 |                   $29.8\%$ |                                 $29.6\%$ |       $+0.1\%$ |
| Qwen Max          |      5 |                   $33.4\%$ |                                 $35.5\%$ |       $-2.1\%$ |

**Table X.** Observed verifier-retry pass@K versus an independent-retry null baseline for DeepSeek-V4-Flash and Qwen Max. The null baseline assumes that each retry is an independent attempt with the same success probability as pass@1. DeepSeek-V4-Flash falls far below this baseline as K increases, indicating that retry failures are highly correlated and many hard cases remain hard across attempts. In contrast, Qwen Max closely follows the independent-retry baseline, suggesting that its retry gains are mostly consistent with simple repeated sampling rather than systematic repair.

两个模型呈现出明显不同的模式。Qwen Max 的 pass@K 基本贴合独立重试基线。以 pass@1 = 8.4% 估计，独立基线预测 pass@5 约为 35.5%，实测 pass@5 为 33.4%，两者接近，说明 Qwen Max 的 verifier-retry 提升主要可由低单次通过率下的多次尝试解释，模型单次生成合法路径的概率很低，但多试几次后，通过率会按照重复采样的方式缓慢上升。DeepSeek-V4-Flash 则明显低于独立重试基线。以 pass@1 = 48.6% 估计，独立基线预测 pass@5 约为 96.4%，但实测 pass@5 只有 70.6%，低约 25.8 个百分点。这说明 DeepSeek-V4-Flash 的剩余失败并不像独立重采样那样容易被 retry 消除。换言之，虽然它在首次尝试中已经能生成相当比例的合法路径，但那些首次失败的样本中，有相当一部分会在后续尝试中继续失败。

| 模型（Model）         | 一次尝试通过率（pass@1） | 实际 pass@5（observed pass@5） | 独立重试基线@5（independent baseline at K=5） |   差值（gap） |
| ----------------- | --------------: | -------------------------: | ------------------------------------: | --------: |
| DeepSeek-V4-Flash |        $48.6\%$ |                   $70.6\%$ |                              $96.4\%$ | $-25.8\%$ |
| Qwen Max          |         $8.4\%$ |                   $33.4\%$ |                              $35.5\%$ |  $-2.1\%$ |
这一差异说明 pass@K 的饱和并不能只用“尝试次数不够”解释。对于 Qwen Max，主要限制是单次通过率很低，因此 pass@K 随 K 缓慢上升；对于 DeepSeek-V4-Flash，主要限制则是剩余失败样本的相关性更强，继续 retry 往往不能产生独立的新机会。结合 FailureHop 与 repeated_same_hop 统计可以看到![[Pasted image 20260613000229.png]]部分失败样本会反复卡在相同 hop 或相同错误类型上。这表明 verifier 能指出结构错误，也能提高多次尝试下获得合法路径的概率，但当模型反复在同一状态转移处失败时，外部反馈无法保证继续增加 K 就能线性提高通过率。

因此，verifier-retry 的收益具有两层限制。第一，pass@K 的增长速度受 pass@1 约束：单次生成合法路径的概率越低，多次尝试的提升越慢。第二，当失败样本集中在稳定结构瓶颈上时，实测 pass@K 会低于独立重试基线，表现为更早饱和。这个结果也解释了为什么 verifier-retry 对 DeepSeek-V4-Flash 有明显提升，但仍无法达到 thinking 模式的满分级表现；它提高的是有限预算内获得合法路径的概率，而不是直接消除模型内部的状态追踪瓶颈。






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

完整结果应报告 direct_minimal、jsoncot_basic 和 jsoncot_strict 在 chain 与 branching 设置下的 Accuracy、Raw GIS、PC-GIS、GFI、EAR、TAC、PathValid、PathGoldExact 和 (\Delta_{\text{illegal}})。

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



![[Pasted image 20260610002334.png]]

![[Pasted image 20260610002354.png]]
















![[Pasted image 20260609230122.png]]
![[Pasted image 20260610002119.png]]
![[Pasted image 20260610002654.png]]

![[Pasted image 20260609230203.png]]








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



