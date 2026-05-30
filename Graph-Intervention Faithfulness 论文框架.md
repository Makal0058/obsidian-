
---
```table-of-contents
```
---
# 一、定位

**一句话**：一个诊断性评测框架，检验显式图干预是否真正控制了LLM的答案和推理轨迹，还是模型只在利用图文本序列化中的位置启发式。

**和CofCA的平行关系**：

|       | CofCA        | 本文               |
| ----- | ------------ | ---------------- |
| 发现的虚胖 | 记忆造成的推理虚胖    | 序列化位置造成的图推理虚胖    |
| 切断手段  | 反事实数据切断记忆    | 位置控制切断位置启发式      |
| 核心工具  | 子问题链评估       | 图干预对照+位置控制       |
| 主发现   | 最终答案正确≠推理链正确 | Raw GIS高≠真正遵守图结构 |

**不是什么**：

- 不是提出让LLM更好沿图推理的方法（Graph-constrained Reasoning已有人做）

- 不是研究参数知识vs上下文知识冲突（arXiv:2506.15732已有覆盖）

- 不是普通CoT Faithfulness研究（Turpin et al. 2023已有）

---
# 二、核心研究问题

**主问题**：当**显式图约束**和参数先验冲突时，LLM答案和推理轨迹是否真正受图结构控制，还是受图文本序列化中的位置线索控制？

**四个RQ**：

**RQ1**：图干预是否改变答案？ 给同一问题分别输入 $∅/G₁/G₂$，如果$G₁→y₁$，$G₂→y₂$，模型答案是否随图变化？

**RQ2**：这种变化来自**图结构**还是**位置启发式**？ 控制**终点节点**在图描述中的出现位置后，图干预敏感性是否显著下降？

**RQ3**：如果失败，**失败发生在哪一跳**？ 模型从哪条边、哪个节点开始偏离合法路径？

**RQ4**：什么条件下图控制力更弱？ 参数先验强度、推理链长度、图拓扑结构、提示方式如何影响图干预忠实性？

---
# 三、实验设计

## 3.1 三组对照

每个样本有三种输入：

| 组别    | 内容         | 作用                  |
| ----- | ---------- | ------------------- |
| 无图组 ∅ | 只给问题       | 估计模型自然先验$y_{prior}$ |
| G₁组   | 图路径指向y₁    | 主干预                 |
| G₂组   | 反事实图路径指向y₂ | 对照干预                |

**实验成立的三个必要条件**：

- $y_₁ ≠ y_₂$
- $y_₂ ≠ y_{prior}$（最关键——否则无法区分图控制和先验）
- G₂的结构与G₁不同但跳数相同

## 3.2 位置控制组

每张图额外生成四种序列化版本：

| 版本              | 作用              |
| --------------- | --------------- |
| Endpoint-first  | 正确答案节点**最早出现**  |
| Endpoint-middle | 正确答案节点出现在**中间** |
| Endpoint-last   | 正确答案节点**最后出现**  |
| Decoy-last      | **错误干扰**节点最后出现  |

如果模型真正沿图推理，四种版本答案应一致。如果跟着最后出现的节点走，说明GIS被位置锚定污染

## 3.3 图类型

|图类型|作用|
|---|---|
|链式图 A→B→C→D|基础多跳路径|
|分叉图|测分支选择是否被先验带偏|
|汇聚图|测多路径到同一节点时是否混乱|
|干扰图|测模型是否被相似错误路径诱导|

## 3.4 先验强度控制

| 类型  | 构造方式                         |
| --- | ---------------------------- |
| 弱先验 | 随机符号节点（A17、B42）              |
| 中先验 | 半语义实体（disease、battery、orbit） |
| 强先验 | 真实世界高频关系或few-shot诱导          |

无图组用来估计$P(y|x,∅)$，只保留$P(y₂|x,∅) < τ$的样本。

## 3.5 跳数设置

1-hop / 2-hop / 3-hop / 4-hop，覆盖CofCA同样的复杂度层次

## 3.6 图表示格式

主实验用随机顺序Edge List + JSON路径输出：

```
A -> C, C -> B, B -> D
```

自然语言图描述放ablation，因为位置偏差更强

## 3.7 提示方式

|设置|作用|
|---|---|
|Direct|无解释，直接答|
|JSON-CoT|强制结构化输出路径+答案|
|Step-wise JSON|强制一步一步输出节点|
|Free-form CoT|小规模鲁棒性对照|

JSON-CoT格式：

json

```json
{
  "path": ["A", "B", "C", "D"],
  "answer": "D",
  "explanation": "..."
}
```

---

# 四、核心指标

## 4.1 主指标（主文）

1. **Graph Intervention Sensitivity (GIS)**

$$\text{GIS}= \mathbb{1}[f(x,G_1)=y_1] \cdot \mathbb{1}[f(x,G_2)=y_2] \cdot \mathbb{1}[y_1 \neq y_2]$$
改图后答案是否跟着变

2. **Position-Controlled GIS (PC-GIS)** 在四种位置变化下GIS均成立才计为1。比GIS更严格

3. **Graph-Following Inflation (GFI)**

$$\text{GFI} = \text{Raw GIS} - \text{PC-GIS}$$

这个差距就是"图推理虚胖"的量化。主发现

4. **Prior Override Rate (POR)**

$$\text{POR} = \frac{\#(f(x,G)=y_{prior})}{\#(\text{graph-prior conflict cases})}​$$

改图后模型是否仍输出先验答案

5. **Endpoint Anchoring Rate (EAR)**

$$\text{EAR} = \frac{\#(\text{answer equals last-mentioned node})}{\#(\text{samples})}$$

模型是否在跟文本位置走而不是图结构走

## 4.2 辅助指标（主文+附录）

1. **Path Validity**：CoT路径中所有边是否合法

$$\forall (v_i, v_{i+1}) \in \text{Trace},\ (v_i, v_{i+1}) \in E(G)$$

2. **Trace-Answer Consistency**：CoT推出的终点和最终答案是否一致

3. **Failure Hop**：模型从第几跳开始偏离合法路径

$$h_{fail} = \min h,\ e_h \notin E(G)$$

---

# 五、失败模式分类

|失败模式|含义|特别价值|
|---|---|---|
|Prior-locked Answer|改图后答案仍是先验|说明图完全没有因果控制力|
|Trace-only Compliance|CoT按图变了，但答案没变|连接CoT Faithfulness，是区别于2506.15732的核心贡献|
|Answer-only Compliance|答案变了，但路径非法|说明模型猜对了但没真推|
|Endpoint Anchoring|答案等于图中最后出现的节点|说明GIS来自位置启发式|
|Hop-level Drift|前几跳合法，某一跳开始偏离|定位错误传播起点|

---

# 六、数据构造流程

**Step 1**：生成有向无环图G，控制节点数、分支数、路径长度、干扰路径数量

**Step 2**：生成问题模板

```
Given the graph, starting from node A, which terminal node 
can be reached after exactly N valid hops?
```

**Step 3**：构造G₁，让路径指向y₁

**Step 4**：构造G₂，只改关键边或中间节点，让答案变成y₂，要求y₂ ≠ y₁且y₂ ≠ y_prior

**Step 5**：无图采样估计先验，过滤不干净样本

**Step 6**：BFS/DFS符号程序验证gold path唯一性，确保G₁唯一答案是y₁，G₂唯一答案是y₂

**Step 7**：生成四种位置控制版本

---

# 七、核心贡献(如果成功的话)

**Contribution 1**：提出Graph-Intervention Faithfulness问题，区别于CoT Faithfulness（CoT是否忠实于答案）——你问的是答案和CoT是否忠实于外部图结构

**Contribution 2**：发现Graph-Following Inflation 量化Raw GIS与PC-GIS的差距，证明相当比例的"图遵守"行为来自序列化位置启发式而非图结构推理

**Contribution 3**：提出位置控制图干预实验设计 endpoint-first/middle/last/decoy-last四组控制，排除位置锚定混淆

**Contribution 4**：失败模式分类体系 尤其是Trace-only Compliance——CoT路径合法但答案回归先验，这是此前工作未系统分析的失败模式

---

# 八、与相关工作的核心差异

| 维度    | CofCA          | 2506.15732                   | Graph-constrained Reasoning | 本文                                  |
| ----- | -------------- | ---------------------------- | --------------------------- | ----------------------------------- |
| 核心问题  | context真的控制答案吗 | 参数知识与反事实冲突                   | 如何强制模型沿图走                   | 图结构还是图序列化控制答案                       |
| 主要手段  | 反事实数据          | 合成图+反事实上下文                   | KG-Trie/约束解码                | G₁/G₂干预+位置控制                        |
| 推理链分析 | 子问题链正确率        | 不重点分离trace和answer            | 不涉及                         | 分离路径合法率/答案一致率/trace-answer mismatch |
| 失败定位  | 失败发生在哪一跳       | context-ignoring/overfitting | 不涉及                         | failure hop + 失败模式分类                |
| 位置控制  | 无              | 无                            | 无                           | **核心控制变量**                          |

---

# 九、Pilot优先级

| 优先级 | Pilot                   | 目的        | 成功标准                   |
| --- | ----------------------- | --------- | ---------------------- |
| 1   | JSON-CoT路径输出            | 解决路径抽取问题  | 路径解析成功率>90%            |
| 2   | y₂ ≠ y_prior过滤率         | 确认样本还能剩多少 | 强先验下保留率>30%            |
| 3   | GFI是否显著存在               | 验证核心发现    | Raw GIS - PC-GIS > 20% |
| 4   | Trace-only Compliance比例 | 验证核心失败模式  | 比例>10%有信号              |
| 5   | 图表示格式ablation           | 选主实验格式    | 确认edge list优于自然语言      |

**Pilot 3是整篇论文的生死线**——如果GFI < 5%，论文的核心narrative垮掉，需要重新定位主发现

---

### 十、论文结构

**Title**：_Graph-Following or Serialization Anchoring? Evaluating Graph-Intervention Faithfulness in LLM Reasoning_

1. Introduction：图增强推理默认图控制答案 → 这个假设未经严格检验 → 我们提出位置控制图干预 → 发现GFI
2. Related Work：四条线（CofCA/参数上下文冲突/CoT Faithfulness/图约束推理）逐一对比差异
3. Task Definition：形式化x/G/y_prior/y_G/T
4. Benchmark Construction：图生成/G₁G₂构造/位置控制/先验过滤/gold path验证
5. Metrics：GIS/PC-GIS/GFI/POR/EAR/Path Validity/Failure Hop
6. Experiments：主实验+CoT对比+图位置实验+干扰路径实验
7. Analysis：失败模式分析，重点Trace-only Compliance和Endpoint Anchoring
8. Limitations：合成图/CoT非内部推理/diagnostic不是solution/闭源无法机制分析
9. Conclusion：接回Graph-RAG和知识图谱增强推理的可靠性问题