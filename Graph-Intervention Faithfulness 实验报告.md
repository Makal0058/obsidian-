

あるじさま，下面把目前全部实验整理成一篇**可直接改成论文实验部分的报告版**。我会按“实验目的 → 数据构造 → 指标 → 结果 → 发现 → 论文结论”的顺序写。

---

## 0. 摘要

本文围绕 **Graph-Intervention Faithfulness，图干预忠实性** 展开实验，目标是检验大语言模型在图推理任务中是否真正遵守显式图结构，而不是依赖节点在文本序列中的出现位置、格式约束或表面路径输出。

实验通过构造反事实图对 G1/G2G_1/G_2G1​/G2​，并在每张图内生成四种位置控制序列化版本：`endpoint_first`、`endpoint_middle`、`endpoint_last`、`decoy_last`，来区分真实图跟随与位置启发式。核心指标包括 Raw GIS、PC-GIS、GFI、EAR、Path Gold Exact、Path Full Valid、Trace-Answer Consistency 和 failure_hop。

主要发现是：

1. **Raw GIS 会虚胖**：弱提示下模型会严重依赖最后出现节点，Raw GIS 高但 PC-GIS 为 0。
2. **JSON-CoT 不等于忠实推理**：模型常输出“路径和答案一致，但路径本身非法”的推理轨迹。
3. **分叉图比链式图更能打穿模型**：链式图 strict prompt 可解决，但 12-hop branching_v3 中 no-thinking 模型大量失败。
4. **thinking 能解决但成本高**：DeepSeek Pro thinking 可达到 100%，但平均延迟约 59 秒。
5. **verifier-retry 是低成本外部纠错**：DeepSeek Pro no-thinking + verifier@5 达到 94.37%，平均延迟 8.31 秒。
6. **verifier-retry 有底座能力边界**：Qwen Max strict 只有 11.25%，verifier@5 也只有 30.63%，说明外部验证只能放大已有图跟随能力，不能凭空创造能力。

---

## 1. 实验目标

本文不是做普通模型排行榜，而是做一种**诊断型模型测评**。

核心问题是：

> 当模型被要求从起点出发，沿图中合法边恰好走固定跳数时，它的答案是否真的由图结构决定？

进一步拆成四个问题：

|问题|含义|
|---|---|
|RQ1|改变图结构后，模型答案是否随图改变？|
|RQ2|这种变化来自图结构，还是来自文本位置启发式？|
|RQ3|如果模型失败，它从第几跳开始偏离合法路径？|
|RQ4|prompt、thinking、verifier-retry、模型底座能力如何影响图跟随？|

原始论文规划里已经把该框架定位为：检验显式图干预是否真正控制 LLM 的答案和推理轨迹，还是模型只是在利用图文本序列化中的位置启发式。

---

## 2. 数据与任务设计

### 2.1 基础任务

每个任务给定：

```
起点 start跳数 hop一组有向边 edges
```

要求模型输出：

```
{  "path": ["start", "...", "answer"],  "answer": "answer"}
```

其中路径必须满足：

∣path∣=hop+1|path| = hop + 1∣path∣=hop+1

并且每一条相邻边：

(pathi,pathi+1)∈E(G)(path_i, path_{i+1}) \in E(G)(pathi​,pathi+1​)∈E(G)

---

### 2.2 反事实图对

每个样本包含两张图：

|图|作用|
|---|---|
|G1G_1G1​|gold path 指向 y1y_1y1​|
|G2G_2G2​|gold path 指向 y2y_2y2​，且 y1≠y2y_1 \neq y_2y1​=y2​|

如果模型真正遵守图结构，则输入 G1G_1G1​ 时应输出 y1y_1y1​，输入 G2G_2G2​ 时应输出 y2y_2y2​。

---

### 2.3 四种位置控制版本

每张图生成四种边序列：

|Variant|含义|
|---|---|
|endpoint_last|正确答案节点最后出现|
|endpoint_first|正确答案节点最先出现|
|endpoint_middle|正确答案节点出现在中间|
|decoy_last|错误诱饵节点最后出现|

如果模型真的沿图推理，四种版本都应该输出同一个正确答案。  
如果模型只是跟随最后出现节点，`endpoint_last` 会高，`decoy_last` 会崩。

---

### 2.4 图类型

目前已经完成两类图：

|图类型|作用|
|---|---|
|chain_v2|链式图，用来暴露位置锚定|
|branching_v3|分叉图，用来测试分支选择和状态追踪|

当前主实验是：

```
branching_v3hop = 1220 个基础样本每个样本 G1/G2每张图 4 个 variant总任务数 = 20 × 2 × 4 = 160
```

---

## 3. 指标定义

### 3.1 Raw GIS

Raw GIS 衡量原始图干预下，模型答案是否随图改变：

Raw GIS=1[f(x,G1)=y1]⋅1[f(x,G2)=y2]\text{Raw GIS} = \mathbb{1}[f(x,G_1)=y_1] \cdot \mathbb{1}[f(x,G_2)=y_2]Raw GIS=1[f(x,G1​)=y1​]⋅1[f(x,G2​)=y2​]

直观来说：

> 改图后，模型答案是否跟着图变？

---

### 3.2 PC-GIS

PC-GIS 是位置控制后的 GIS。  
只有当模型在四种位置版本下都稳定输出正确答案，才算真正通过。

---

### 3.3 GFI

GFI=Raw GIS−PC-GIS\text{GFI} = \text{Raw GIS} - \text{PC-GIS}GFI=Raw GIS−PC-GIS

GFI 越大，说明 Raw GIS 越可能是“图推理虚胖”。

---

### 3.4 EAR

EAR 衡量模型是否倾向于输出最后出现的节点：

EAR=#(answer equals last-mentioned node)#(samples)\text{EAR} = \frac{\#(\text{answer equals last-mentioned node})}{\#(\text{samples})}EAR=#(samples)#(answer equals last-mentioned node)​

---

### 3.5 Path Gold Exact

路径完全等于 gold path 才算正确。

这是本文最重要的路径级指标。

---

### 3.6 Trace-Answer Consistency

检查：

answer=path[−1]answer = path[-1]answer=path[−1]

如果为真，只说明答案和模型自己的路径一致，不说明路径合法。

---

### 3.7 Failure Hop

failure_hop 表示模型从第几跳开始走非法边。

例如：

```
illegal_edge_at_hop_3
```

说明第 3 跳开始偏离图结构。

---

# 4. 实验结果

## 4.1 Chain v2 + direct_minimal：Raw GIS 严重虚胖

在链式图、弱提示 direct_minimal 下，DeepSeek Chat 出现明显位置锚定。

|指标|数值|
|---|---|
|Acc|81/160 = 50.62%|
|Overall EAR|119/160 = 74.38%|
|Raw GIS|100%|
|PC-GIS|0%|
|GFI|100%|

四种位置版本表现：

|Variant|Acc|EAR|
|---|---|---|
|endpoint_last|40/40 = 100%|40/40 = 100%|
|endpoint_first|0/40 = 0%|40/40 = 100%|
|endpoint_middle|40/40 = 100%|0/40 = 0%|
|decoy_last|1/40 = 2.5%|39/40 = 97.5%|

这说明模型不是沿图推理，而是强烈跟随最后出现节点。Raw GIS 虽然为 100%，但 PC-GIS 为 0，GFI 达到 100%，构成非常强的“图推理虚胖”证据。

**结论：**

> 弱提示下，Raw GIS 不能作为真实图跟随能力的可靠指标。

---

## 4.2 Branching v3 + jsoncot_strict：DeepSeek Chat

DeepSeek Chat 在 12-hop 分叉图上，虽然能输出路径和答案，但路径合法性不稳定。

|指标|数值|
|---|---|
|Acc|85/160 = 53.12%|
|Raw GIS|15%|
|PC-GIS|0%|
|GFI|15%|
|Path Present|100%|
|Path Length OK|127/160 = 79.37%|
|Path Full Valid|81/160 = 50.62%|
|Path Gold Exact|81/160 = 50.62%|
|Trace-Answer Consistency|160/160 = 100%|

主要错误：

|错误类型|数量|
|---|---|
|path_too_short|33/79 = 41.77%|
|illegal_edge_at_hop_2|15/79 = 18.99%|
|illegal_edge_at_hop_3|16/79 = 20.25%|

**解释：**

模型经常能够保证 `answer = path[-1]`，但路径本身不合法。  
这说明它不是答案和路径不一致，而是：

> **路径自洽，但图上非法。**

---

## 4.3 Branching v3 + jsoncot_strict：DeepSeek Pro no-thinking

DeepSeek Pro 关闭 thinking 后，格式服从更好，但仍然大量分叉失败。

|指标|数值|
|---|---|
|Acc|87/160 = 54.37%|
|Raw GIS|30%|
|PC-GIS|0%|
|GFI|30%|
|Path Present|100%|
|Path Start OK|100%|
|Path Length OK|100%|
|Path Full Valid|86/160 = 53.75%|
|Path Gold Exact|86/160 = 53.75%|
|Trace-Answer Consistency|100%|

错误类型中，`illegal_edge_at_hop_2` 占 30/74 = 40.54%，说明大量错误发生在早期分叉选择。

**解释：**

Pro no-thinking 会严格输出 13 个节点，但遇到分叉时仍会编出非法边或重复节点。  
它比 Chat 更守格式，但没有真正稳定沿图走。

---

## 4.4 Branching v3 + jsoncot_basic：Prompt 消融

jsoncot_basic 比 jsoncot_strict 更宽松，不强制每一步都严格合法。结果很有意思：

|设置|Acc|Path Gold Exact|Raw GIS|PC-GIS|GFI|
|---|---|---|---|---|---|
|Pro no-thinking + jsoncot_strict|54.37%|53.75%|30%|0%|30%|
|Pro no-thinking + jsoncot_basic|62.50%|61.88%|50%|10%|40%|

jsoncot_basic 的 Path Gold Exact 更高，达到 61.88%，但 GFI 也升到 40%，PC-GIS 只有 10%。

**解释：**

basic prompt 的自由度更高，可能让模型靠局部匹配走对更多单题；但位置控制稳定性更差，图推理虚胖更明显。

**结论：**

> 普通 JSON-CoT 能提高表面表现，但不能消除序列化敏感的图跟随失败。

---

## 4.5 DeepSeek Pro thinking：高计算上界

此前实验显示：

|设置|Path Gold Exact|Avg Latency|
|---|---|---|
|DeepSeek Pro thinking + jsoncot_strict|100%|59.158s|
|DeepSeek Pro thinking + direct_minimal|100%|82.848s|
|DeepSeek Pro no-thinking + jsoncot_strict|53.75%|2.805s|

**解释：**

thinking 可以解决 12-hop branching_v3，但代价很高。

它相当于给模型大量内部搜索和自检预算。  
jsoncot_strict + thinking 比 direct_minimal + thinking 更快，说明结构化输出可以降低内部搜索负担。

---

## 4.6 DeepSeek Pro no-thinking + verifier-retry@5

这是目前最强的正结果。

|指标|数值|
|---|---|
|pass@1 verifier|92/160 = 57.50%|
|pass@5 verifier|151/160 = 94.37%|
|final Path Gold Exact|151/160 = 94.37%|
|final Answer Acc|151/160 = 94.37%|
|Avg Attempts|1.800|
|Avg Latency|8.311s|

pass@K 曲线：

|K|Path Gold Exact|Avg Latency|相对 thinking-strict 加速|
|---|---|---|---|
|1|57.50%|2.593s|22.81×|
|2|81.25%|5.954s|9.94×|
|3|88.75%|7.165s|8.26×|
|4|92.50%|7.685s|7.70×|
|5|94.37%|8.311s|7.12×|

**解释：**

verifier-retry 用外部符号验证替代一部分 thinking 的内部自检。  
它不能达到 100%，但以 8.31 秒达到 94.37%，比 59.158 秒的 thinking-strict 快约 7.1 倍。

**核心结论：**

> thinking 是昂贵的内部纠错；verifier-retry 是廉价的外部纠错。

---

## 4.7 DeepSeek Pro verifier@5 剩余失败分析

verifier@5 后，DeepSeek Pro 仍有 9/160 失败。

|指标|数值|
|---|---|
|最终成功|151/160 = 94.37%|
|最终失败|9/160 = 5.63%|
|反复出现同一错误类型|9/9|
|反复卡在同一 failure_hop|9/9|

失败主要集中在 hop 2 和 hop 3。

**解释：**

剩余失败不是随机噪声，而是稳定分叉错误。模型一旦在某个分叉点选错，普通 retry 只告诉它“错了”，但它仍可能反复掉进同一错误吸引子。

**Future Work 可写：**

> A promising extension is to augment verifier feedback with node-level exclusion or local outgoing-edge hints, e.g., “do not traverse node X at hop 3,” which may mitigate the structural branch bias observed in the remaining 5.6% failure cases.

---

## 4.8 Qwen Max + jsoncot_strict

Qwen Max 在 12-hop branching_v3 上被明显打穿。

|指标|数值|
|---|---|
|Acc|25/160 = 15.62%|
|Raw GIS|0%|
|PC-GIS|0%|
|GFI|0%|
|Path Present|160/160 = 100%|
|Path Start OK|160/160 = 100%|
|Path Length OK|155/160 = 96.88%|
|Path Edges Valid|20/160 = 12.50%|
|Path Full Valid|18/160 = 11.25%|
|Path Gold Exact|18/160 = 11.25%|
|Trace-Answer Consistency|159/160 = 99.38%|

**解释：**

Qwen Max 不是不会输出格式。它几乎总能输出路径，路径长度也大多正确，答案也基本等于路径最后节点。  
但它输出的边大多不合法。

这说明：

> **Qwen Max exhibits trace-consistent but graph-invalid reasoning.**

中文：

> **路径自洽，但图上非法。**

---

## 4.9 Qwen Max + verifier-retry@5

Qwen 加 verifier-retry 后有提升，但远不如 DeepSeek Pro。

|指标|数值|
|---|---|
|pass@1 verifier|17/160 = 10.62%|
|pass@5 verifier|49/160 = 30.63%|
|final Path Gold Exact|49/160 = 30.63%|
|final Answer Acc|52/160 = 32.50%|
|Avg Attempts|4.188|
|Avg Latency|10.785s|

pass@K 曲线：

|K|Path Gold Exact|Answer Acc|Avg Attempts|Avg Latency|
|---|---|---|---|---|
|1|10.62%|13.13%|1.000|2.633s|
|2|18.12%|25.62%|1.894|5.181s|
|3|25.00%|27.50%|2.712|7.101s|
|4|27.50%|31.87%|3.462|8.960s|
|5|30.63%|32.50%|4.188|10.785s|

**解释：**

Qwen 的 pass@K 曲线确实上升，但上限很低。  
它不像 DeepSeek Pro 那样从 57.50% 提升到 94.37%，而是从 10.62% 提升到 30.63%。

**结论：**

> verifier-retry 需要底座模型已有一定路径构造能力。它能修复可恢复错误，但不能凭空教会弱图追踪模型。

---

## 4.10 Qwen verifier@5 失败分析

Qwen verifier@5 后仍失败 111/160。

|指标|数值|
|---|---|
|最终成功|49/160 = 30.63%|
|最终失败|111/160 = 69.37%|
|G1 失败|55/111|
|G2 失败|56/111|
|endpoint_last|31/111|
|decoy_last|29/111|
|endpoint_middle|27/111|
|endpoint_first|24/111|
|反复同一错误类型|92/111|
|反复同一 failure_hop|92/111|

最终错误类型主要包括：

|错误类型|数量|
|---|---|
|illegal_edge_at_hop_3|21/111|
|illegal_edge_at_hop_12|17/111|
|illegal_edge_at_hop_4|15/111|
|illegal_edge_at_hop_6|10/111|
|illegal_edge_at_hop_2|8/111|

**解释：**

Qwen 的失败不是集中在某个图、某个 variant 或某个位置控制条件上，而是广泛分布。  
这说明它不是被某个特殊设计坑住，而是整体图状态追踪能力不足。

---

# 5. 总结果对比表

|模型 / 设置|Acc|Path Gold Exact|Raw GIS|PC-GIS|GFI|Avg Latency|
|---|---|---|---|---|---|---|
|DeepSeek Chat + chain direct_minimal|50.62%|—|100%|0%|100%|—|
|DeepSeek Chat + branching strict|53.12%|50.62%|15%|0%|15%|—|
|DeepSeek Pro no-thinking + branching strict|54.37%|53.75%|30%|0%|30%|2.805s|
|DeepSeek Pro no-thinking + branching basic|62.50%|61.88%|50%|10%|40%|—|
|DeepSeek Pro thinking + branching strict|100%|100%|100%|100%|0%|59.158s|
|DeepSeek Pro no-thinking + verifier@5|94.37%|94.37%|—|—|—|8.311s|
|Qwen Max + branching strict|15.62%|11.25%|0%|0%|0%|—|
|Qwen Max + verifier@5|32.50%|30.63%|—|—|—|10.785s|

---

# 6. 核心发现

## Finding 1：Raw GIS 会高估真实图跟随

chain direct_minimal 中 Raw GIS 达到 100%，但 PC-GIS 为 0，GFI 为 100%，说明模型只是跟随序列化位置，而不是真正沿图走。

---

## Finding 2：结构化 CoT 不等于路径忠实

多个模型的 Trace-Answer Consistency 很高，但 Path Gold Exact 很低。

最典型的是 Qwen：

```
Trace-Answer Consistency = 99.38%Path Gold Exact = 11.25%
```

这说明模型能让答案和路径自洽，但路径本身不遵守图结构。

---

## Finding 3：分叉图揭示状态追踪失败

链式图中 strict prompt 容易成功；但 branching_v3 中，模型必须持续维护当前节点并选择合法下一跳，no-thinking 模型大量失败。

这说明：

> 图推理失败的关键不只是路径长度，而是分叉状态追踪。

---

## Finding 4：thinking 是有效但昂贵的内部搜索

DeepSeek Pro thinking 可以达到 100%，但平均延迟约 59 秒。  
它适合作为 high-compute upper bound，不适合作为可扩展方案。

---

## Finding 5：verifier-retry 是低成本外部纠错

DeepSeek Pro no-thinking + verifier@5 达到 94.37%，平均延迟 8.31 秒。  
这说明外部符号验证可以恢复大部分可恢复错误。

---

## Finding 6：verifier-retry 依赖底座能力

Qwen Max strict 只有 11.25%，verifier@5 只到 30.63%。  
因此 verifier-retry 不是万能方法，它不能凭空创造图状态追踪能力。

---

# 7. 论文贡献总结

这篇论文可以主张三点贡献：

## Contribution 1：提出 Graph-Intervention Faithfulness 诊断框架

通过 G1/G2G_1/G_2G1​/G2​ 反事实图干预和四种位置控制，区分真实图跟随与序列化位置启发式。

---

## Contribution 2：提出路径级忠实性指标

不仅看 answer，还检查：

```
Path Full ValidPath Gold ExactTrace-Answer Consistencyfailure_hop
```

揭示“路径自洽但图上非法”的失败模式。

---

## Contribution 3：提出 verifier-retry 低成本纠错基线

展示：

```
thinking: 准但慢verifier-retry: 接近 thinking，快很多Qwen: 说明方法有底座能力边界
```

---

# 8. 推荐论文表述

## 8.1 主发现英文版

> Structured reasoning traces can be internally consistent while remaining invalid with respect to the external graph.

中文：

> 结构化推理轨迹可以内部自洽，但相对于外部图结构仍然非法。

---

## 8.2 verifier-retry 英文版

> External verifier-retry recovers most branching failures at a fraction of the latency of thinking mode.

中文：

> 外部验证-重试能以远低于 thinking 的延迟恢复大部分分叉图失败。

---

## 8.3 方法边界英文版

> Verifier-retry amplifies existing graph-following ability, but does not create it from scratch.

中文：

> verifier-retry 放大已有图跟随能力，但不能凭空创造这种能力。

---

# 9. 还缺什么？

目前**不缺主实验**。  
如果为了 ACL Findings 更稳，可以考虑：

| 优先级 | 内容                               | 是否必须   |
| --- | -------------------------------- | ------ |
| 高   | 整理图表和论文结构                        | 必须     |
| 高   | bootstrap 置信区间或多 seed            | 强烈建议   |
| 中   | direct_legal 消融                  | 可选     |
| 中   | shuffle-only / branching-only 消融 | 可选     |
| 低   | 更多模型                             | 不建议继续扩 |

当前最重要的不是继续跑模型，而是：

```
整理表格画图写 Method写 Results写 Analysis
```

---

# 10. 最终结论

本文实验表明：

> LLM 在图任务中的“推理轨迹”不能只看是否结构化，也不能只看答案是否正确。模型可能生成一条看起来完整、答案也和路径一致的推理链，但这条路径并不符合外部图结构。

位置控制揭示了 Raw GIS 的虚胖；路径级验证揭示了“路径自洽但图上非法”的失败模式；thinking 能解决但代价高；verifier-retry 提供了一条低成本外部纠错路线，但其效果依赖底座模型本身的图状态追踪能力。

最浓缩的一句话是：

> **模型不一定真的会走图，它可能只是会写一条看起来像路的路。真正要测的是：这条路是不是图上合法的路。**