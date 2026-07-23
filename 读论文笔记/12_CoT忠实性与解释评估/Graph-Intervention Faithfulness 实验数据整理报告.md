# 

あるじさま，下面是把目前全部实验数据整理成的一篇**阶段性实验报告**。这版可以直接作为组会汇报/论文实验部分的底稿。核心判断是：**这已经不是单纯测模型强弱，而是一个诊断型评测框架：它揭示了 LLM 在显式图约束下“看似沿图推理、实际路径非法或被序列位置污染”的结构性失败。**

---

## 1. 研究问题与实验目标

本文关注的问题是：

> **当给大模型一个显式图结构，并要求它从起点出发沿合法边走固定跳数时，模型的答案和推理路径是否真的受图结构控制，还是受到图文本序列化位置、输出格式或自身状态追踪能力的影响？**

已有框架中，实验被定位为一个诊断性评测框架：检验显式图干预是否真正控制了模型答案和推理轨迹，还是模型只在利用图文本序列化中的位置启发式。框架设置了四种位置控制版本：`endpoint_first`、`endpoint_middle`、`endpoint_last`、`decoy_last`；如果模型真正沿图推理，四种版本结果应保持一致，否则可能存在位置锚定污染。

核心指标包括：

| 指标                       | 含义                     |
| ------------------------ | ---------------------- |
| Raw GIS                  | 原始图干预下，答案是否随图改变        |
| PC-GIS                   | 位置控制后仍稳定随图改变           |
| GFI = Raw GIS - PC-GIS   | 图推理虚胖程度                |
| EAR                      | 答案是否等于最后出现节点           |
| Path Full Valid          | 输出路径是否从起点出发、长度正确、每条边合法 |
| Path Gold Exact          | 输出路径是否完全等于 gold path   |
| Trace-Answer Consistency | 路径最后节点是否等于 answer      |
| Failure Hop              | 第几跳开始走非法边              |

其中 GFI 是主发现指标，用于量化“Raw GIS 看似很高，但其实来自序列化位置启发式”的差距；Path Validity、Trace-Answer Consistency、Failure Hop 用于定位路径级失败。

---

## 2. 数据集与设置

当前实验主要经历了两个阶段：

### 2.1 链式图 v2

链式图主要用于验证位置锚定和 JSON-CoT 约束是否有效。图结构本身是一条唯一链路，难点主要来自边的序列化顺序和答案节点出现位置。

代表任务：

```
从 start 出发，沿合法边恰好走 N 跳，最终到达哪个节点？
```

四种位置控制版本：

```
endpoint_last   正确答案节点最后出现endpoint_first  正确答案节点最先出现endpoint_middle 正确答案节点出现在中间decoy_last      错误诱饵节点最后出现
```

### 2.2 分叉图 branching_v3

分叉图是当前主实验。它在 gold path 节点附近加入分叉边，使模型必须在多个候选出边中持续维护当前节点和合法下一跳。相比链式图，它不再只是“跟着链走”，而是考察真正的**状态追踪 + 分叉选择能力**。

当前主实验规模：

```
20 个基础样本每个样本包含 G1 / G2每张图 4 个位置版本总任务数：20 × 2 × 4 = 160hop = 12prompt = jsoncot_strict
```

---

## 3. 实验结果总表

### 3.1 链式图 v2：Direct 弱提示暴露严重位置锚定

DeepSeek Chat 在 `4-hop random_v2 + direct_minimal` 下，单条任务正确率只有 50.62%，但 Raw GIS 达到 100%，PC-GIS 为 0%，GFI 为 100%。整体 EAR 为 74.38%，`endpoint_first` 版本正确率为 0%，但 EAR 为 100%；`decoy_last` 正确率仅 2.5%，EAR 为 97.5%。这说明弱提示下模型大量跟随最后出现节点，而不是沿图结构推理。

|设置|Acc|EAR|Raw GIS|PC-GIS|GFI|
|---|---|---|---|---|---|
|DeepSeek Chat + chain_v2 + direct_minimal|50.62%|74.38%|100%|0%|100%|

**结论：**  
链式图弱提示下存在非常强的 endpoint anchoring。Raw GIS 看似很高，但完全是“图推理虚胖”。

---

### 3.2 分叉图 branching_v3：JSON-CoT strict 仍然无法保证图跟随

#### DeepSeek Chat + branching_v3 + jsoncot_strict

DeepSeek Chat 在 12-hop 分叉图上，单条任务正确率为 53.12%，Path Gold Exact 为 50.62%，Raw GIS 为 15%，PC-GIS 为 0%，GFI 为 15%。路径都能输出，且 Trace-Answer Consistency 为 100%，但 Path Full Valid 只有 50.62%。错误中 `path_too_short` 占 33/160，非法边多集中在 hop 2、hop 3。

|指标|数值|
|---|---|
|Acc|85/160 = 53.12%|
|Raw GIS|15.00%|
|PC-GIS|0.00%|
|GFI|15.00%|
|Path Full Valid|81/160 = 50.62%|
|Path Gold Exact|81/160 = 50.62%|
|Trace-Answer Consistency|160/160 = 100%|

**解释：**  
模型答案和自己写出的路径高度一致，但路径本身经常非法。也就是说，它不是“答案和路径不一致”，而是**路径自洽但图上非法**。

---

#### DeepSeek Pro no-thinking + branching_v3 + jsoncot_strict

DeepSeek Pro 关闭 thinking 后，分叉图上单条任务正确率为 54.37%，Raw GIS 为 30%，PC-GIS 为 0%，GFI 为 30%。Path Length OK 为 100%，Trace-Answer Consistency 为 100%，但 Path Gold Exact 只有 53.75%。非法边错误主要集中在 hop 2，占错误样本 30/74 = 40.54%。

|指标|数值|
|---|---|
|Acc|87/160 = 54.37%|
|Raw GIS|30.00%|
|PC-GIS|0.00%|
|GFI|30.00%|
|Path Length OK|160/160 = 100%|
|Path Full Valid|86/160 = 53.75%|
|Path Gold Exact|86/160 = 53.75%|
|Trace-Answer Consistency|160/160 = 100%|

**解释：**  
Pro no-thinking 格式遵守能力更强，知道要输出 13 个节点，但遇到分叉时仍会编出非法边或重复节点。它比 Chat 更“格式稳定”，但不代表真的会沿图走。

---

### 3.3 Thinking 模式：能解决，但成本非常高

根据前面实验记录：

|设置|Path Gold Exact|Avg Latency|
|---|---|---|
|DeepSeek Pro thinking + jsoncot_strict|100%|59.158s|
|DeepSeek Pro thinking + direct_minimal|100%|82.848s|
|DeepSeek Pro no-thinking + jsoncot_strict|53.75%|2.805s|

**解释：**  
thinking 模式可以作为 high-compute upper bound。它确实能解决 branching_v3，但平均延迟约 59 秒，远高于 no-thinking 的 2.8 秒。更有意思的是，thinking + direct_minimal 反而比 thinking + jsoncot_strict 更慢，说明结构化路径输出可能减轻内部搜索负担。

正式写论文时，建议把对应 runlog 文件也存档；当前这组 thinking 延迟数据来自前面对话中的实验汇总。

---

### 3.4 DeepSeek Pro no-thinking + verifier-retry@5

这是目前最关键的正结果。DeepSeek Pro no-thinking 首次 verifier 通过率为 57.50%，经过最多 5 次 verifier-retry 后，pass@5、final Path Gold Exact、final Answer Acc 都达到 94.37%，平均尝试次数 1.8，平均延迟 8.311 秒。

|指标|数值|
|---|---|
|pass@1 verifier|92/160 = 57.50%|
|pass@5 verifier|151/160 = 94.37%|
|final Path Gold Exact|151/160 = 94.37%|
|final Answer Acc|151/160 = 94.37%|
|Avg Attempts|1.800|
|Avg Latency|8.311s|

从 pass@K 曲线看：

|K|Path Gold Exact|Avg Latency|相对 thinking-strict 加速|
|---|---|---|---|
|1|57.50%|2.593s|22.81×|
|2|81.25%|5.954s|9.94×|
|3|88.75%|7.165s|8.26×|
|4|92.50%|7.685s|7.70×|
|5|94.37%|8.311s|7.12×|

**解释：**  
Verifier-retry 把 no-thinking 从 53%～57% 级别提升到 94.37%，并且仍比 thinking-strict 快约 7 倍。这说明 thinking 的一部分作用可以被“外部符号验证 + 重试”替代。

---

### 3.5 DeepSeek Pro verifier-retry 剩余失败分析

DeepSeek Pro verifier@5 最终失败 9/160 = 5.63%。失败任务中，9/9 都反复出现同一错误类型，9/9 都反复卡在同一 failure_hop。失败主要集中在 hop 2、hop 3，说明剩余错误不是随机噪声，而是稳定的分叉选择偏置。

|失败特征|数值|
|---|---|
|最终失败数|9/160 = 5.63%|
|反复同一错误类型|9/9|
|反复同一 failure_hop|9/9|
|主要 failure_hop|hop 2、hop 3|

**解释：**  
普通 verifier-retry 能救大部分错误，但剩余 5.6% 是稳定错误吸引子。模型不是没收到“错了”的反馈，而是不知道当前分叉点该选哪条合法边。

可作为 Future Work：

> A promising extension is to augment verifier feedback with node-level exclusion or local outgoing-edge hints, e.g., “do not traverse node X at hop 3,” which may mitigate the structural branch bias observed in the remaining 5.6% failure cases.

---

### 3.6 Qwen Max + branching_v3 + jsoncot_strict

Qwen Max 在 12-hop 分叉图上被明显打穿：单条任务正确率 15.62%，Raw GIS、PC-GIS、GFI 都为 0，Path Gold Exact 只有 11.25%。但 Path Present 为 100%，Path Start OK 为 100%，Path Length OK 为 96.88%，Trace-Answer Consistency 为 99.38%。这说明 Qwen Max 不是不会输出格式，而是大量输出“看起来完整但边非法”的路径。

|指标|数值|
|---|---|
|Acc|25/160 = 15.62%|
|Raw GIS|0.00%|
|PC-GIS|0.00%|
|GFI|0.00%|
|Path Present|160/160 = 100%|
|Path Length OK|155/160 = 96.88%|
|Path Edges Valid|20/160 = 12.50%|
|Path Full Valid|18/160 = 11.25%|
|Path Gold Exact|18/160 = 11.25%|
|Trace-Answer Consistency|159/160 = 99.38%|

**解释：**  
Qwen 的 GFI 为 0 不是因为它没有问题，而是因为 Raw GIS 本身就没有起来。它属于基础图跟随能力不足，而不是“看起来会图推理但其实被位置诱导”。

最准确的表述是：

> **Qwen-Max exhibits trace-consistent but graph-invalid reasoning.**

中文可以叫：

> **路径自洽，但图上非法。**

---

### 3.7 Qwen Max + verifier-retry@5

Qwen Max 加 verifier-retry 后有提升，但上限很低。pass@1 为 10.62%，pass@5 为 30.63%，final Path Gold Exact 为 30.63%，final Answer Acc 为 32.50%，平均尝试次数 4.188，平均延迟 10.785 秒。

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
Qwen 的 verifier-retry 有提升，但不是“可恢复错误”主导。它的底座路径构造能力太弱，普通 retry 无法把它救到高水平。

---

### 3.8 Qwen verifier-retry 失败分析

Qwen verifier@5 最终失败 111/160 = 69.37%。失败几乎均匀分布在 G1/G2 与四种 variant 上，不是某个位置版本特别困难。失败任务中 92/111 反复出现同一错误类型，92/111 反复卡在同一 failure_hop，说明其错误模式具有稳定性。

|失败特征|数值|
|---|---|
|最终失败数|111/160 = 69.37%|
|G1 失败|55/111|
|G2 失败|56/111|
|endpoint_last|31/111|
|decoy_last|29/111|
|endpoint_middle|27/111|
|endpoint_first|24/111|
|反复同一错误类型|92/111|
|反复同一 failure_hop|92/111|

最终错误类型分布中，最多的是：

|错误类型|数量|
|---|---|
|illegal_edge_at_hop_3|21/111|
|illegal_edge_at_hop_12|17/111|
|illegal_edge_at_hop_4|15/111|
|illegal_edge_at_hop_6|10/111|
|illegal_edge_at_hop_2|8/111|

**解释：**  
Qwen 不是某几个困难样本失败，而是整体图状态追踪能力不足。它早期、中期、末尾都可能断，普通 retry 只是重复掉进相似非法路径。

---

## 4. 横向对比

### 4.1 主结果表

|模型/设置|Acc|Path Gold Exact|Raw GIS|PC-GIS|GFI|Avg Latency|
|---|---|---|---|---|---|---|
|DeepSeek Chat + chain_v2 + direct_minimal|50.62%|—|100%|0%|100%|—|
|DeepSeek Chat + branching_v3 + strict|53.12%|50.62%|15%|0%|15%|—|
|DeepSeek Pro no-thinking + branching_v3 + strict|54.37%|53.75%|30%|0%|30%|2.805s|
|DeepSeek Pro thinking + branching_v3 + strict|100%|100%|100%|100%|0%|59.158s|
|DeepSeek Pro no-thinking + verifier@5|94.37%|94.37%|—|—|—|8.311s|
|Qwen Max + branching_v3 + strict|15.62%|11.25%|0%|0%|0%|—|
|Qwen Max + verifier@5|32.50%|30.63%|—|—|—|10.785s|

---

## 5. 主要发现

### Finding 1：Raw GIS 会严重虚胖

链式图 direct_minimal 中，Raw GIS 达到 100%，但 PC-GIS 为 0%，GFI 为 100%。同时 EAR 高达 74.38%，说明模型在弱提示下明显利用最后出现节点，而不是沿图结构推理。

**论文表述：**

> Raw graph intervention sensitivity can substantially overestimate true graph following, because models may exploit serialization-position cues rather than following the graph structure.

中文：

> Raw GIS 会高估真实图跟随能力，因为模型可能利用序列化位置线索，而不是沿图结构推理。

---

### Finding 2：JSON-CoT strict 能修链式图，但修不了分叉图

链式图中，严格路径输出可以显著缓解位置锚定；但 branching_v3 中，即使强制输出路径和答案，DeepSeek Chat、DeepSeek Pro no-thinking 仍只有约 50% 左右 Path Gold Exact。DeepSeek Chat 的 Path Gold Exact 为 50.62%，Pro no-thinking 为 53.75%。

**解释：**

```
链式图主要考察是否能按顺序走。分叉图考察是否能维护当前状态，并在多个候选边中持续选对。
```

所以 strict prompt 提供了外部结构，但不能保证分叉搜索能力。

---

### Finding 3：模型经常“路径自洽，但图上非法”

多个模型的 Trace-Answer Consistency 都接近或等于 100%，但 Path Gold Exact 远低于 100%。例如 Qwen Max 的 Trace-Answer Consistency 是 99.38%，Path Gold Exact 只有 11.25%。

这说明只看 answer 或 answer-path 一致性是不够的。模型可以输出一个内部自洽的 path-answer 对，但这个 path 并不遵守图结构。

**论文表述：**

> Structured reasoning traces can be internally consistent while remaining invalid with respect to the external graph.

中文：

> 结构化推理轨迹可以在内部自洽，但相对于外部图结构仍然非法。

---

### Finding 4：Thinking 能解决 branching_v3，但成本太高

DeepSeek Pro thinking 能把 branching_v3 做到 100%，但平均延迟约 59 秒；direct thinking 甚至更慢，约 83 秒。相比之下，no-thinking strict 只有约 2.8 秒，但 Path Gold Exact 只有 53.75%。

**解释：**

> thinking 提供内部搜索预算；JSON-CoT strict 提供外部路径结构。分叉图真正需要的是搜索预算，而不只是格式约束。

---

### Finding 5：Verifier-retry 是低成本外部纠错

DeepSeek Pro no-thinking + verifier@5 达到 94.37% Path Gold Exact，平均延迟 8.311 秒，比 thinking-strict 的 59.158 秒低得多。

**论文表述：**

> External verifier-retry recovers most branching failures at a fraction of the latency of thinking mode.

中文：

> 外部验证-重试能以远低于 thinking 的延迟，恢复大部分分叉图失败。

---

### Finding 6：Verifier-retry 有底座能力边界

Qwen Max strict 的 Path Gold Exact 只有 11.25%，verifier@5 只提升到 30.63%。这说明 verifier-retry 对弱底座模型不是万能药。

**论文表述：**

> Verifier-retry amplifies existing graph-following ability, but does not create it from scratch.

中文：

> verifier-retry 是放大已有图跟随能力，而不是凭空教会模型沿图推理。

---

## 6. 论文主线建议

现在论文主线可以这样写：

### 6.1 论文定位

> 我们提出 Graph-Intervention Faithfulness，一个诊断型评测框架，用于检验 LLM 的答案和推理轨迹是否真正忠实于外部图结构。

### 6.2 核心发现

1. Raw GIS 会被序列化位置启发式污染。
2. JSON-CoT strict 可以缓解链式图位置锚定，但无法解决分叉选择失败。
3. 分叉图中，模型经常产生“路径自洽但图上非法”的推理轨迹。
4. Thinking 可以解决该问题，但延迟成本极高。
5. Verifier-retry 能以低成本恢复大部分可恢复错误。
6. 但 verifier-retry 依赖底座模型已有路径构造能力，对 Qwen Max 这类弱图追踪模型效果有限。

---

## 7. 建议论文标题

主标题：

> **Graph-Following or Serialization Anchoring? Evaluating Graph-Intervention Faithfulness in LLM Reasoning**

中文笔记题目：

> **“到底是在沿图推理，还是在跟着文本位置猜？”**

更顺口一点：

> **“模型真的会走图吗？图干预忠实性的诊断评测”**

---

## 8. 建议图表

论文里建议放这些图表：

|图表|内容|
|---|---|
|Table 1|不同模型/设置主结果：Acc、Path Gold Exact、GFI|
|Table 2|DeepSeek Pro verifier-retry pass@K 曲线|
|Table 3|Qwen Max verifier-retry pass@K 曲线|
|Figure 1|四种位置控制示意图|
|Figure 2|branching_v3 分叉图示意|
|Figure 3|Path Gold Exact vs Avg Latency|
|Figure 4|failure_hop 分布|
|Figure 5|DeepSeek vs Qwen verifier-retry 对比|

最关键的一张图是：

```
x 轴：Avg Latencyy 轴：Path Gold Exact点：no-thinking strict / verifier@K / thinking strict / Qwen verifier@K
```

这张图能直观看出：

```
thinking 准但慢verifier-retry 接近 thinking 但快很多Qwen verifier-retry 花了时间但上限低
```

---

## 9. Limitations / Future Work

可以写：

> Although verifier-retry recovers most failures on DeepSeek-Pro, the remaining errors repeatedly occur at the same branch points, suggesting stable structural branch bias rather than random noise. A promising extension is to augment verifier feedback with node-level exclusion or local outgoing-edge hints, e.g., “do not traverse node X at hop 3,” which may mitigate the structural branch bias observed in the remaining 5.6% failure cases.

中文：

> 虽然 verifier-retry 在 DeepSeek-Pro 上恢复了大部分失败，但剩余错误反复出现在相同分叉点，说明这不是随机噪声，而是稳定结构性分叉偏置。未来可以加入节点级排除提示或当前节点合法出边提示，进一步缓解剩余失败。

---

## 10. 最终结论

目前数据已经形成闭环：

```
弱提示 direct_minimal：    暴露 endpoint anchoring，Raw GIS 虚胖。JSON-CoT strict：    修复链式图，但分叉图仍大量失败。branching_v3：    成功打穿 no-thinking 模型，揭示分叉状态追踪失败。thinking：    能解决，但成本极高。verifier-retry：    对 DeepSeek Pro no-thinking 极有效，94.37%，8.31s。Qwen Max：    strict 只有 11.25%，verifier@5 只有 30.63%，说明方法有底座能力边界。
```

一句话总结整篇论文：

> **LLM 的图推理不能只看最终答案，也不能只看结构化 CoT 是否自洽；真正可靠的评估必须检查路径是否忠实于外部图结构。位置控制和路径验证揭示了 Raw GIS 的虚胖，而外部 verifier-retry 提供了一种低成本但有底座能力边界的修复方向。**

中文更顺口版：

> **模型不一定真的会走图，它可能只是会写一条看起来像路的路。真正要测的是：这条路是不是图上合法的路。**