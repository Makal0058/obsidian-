#### 方向一：LLM做卫星自主操控/GNC

**Language Models are Spacecraft Operators**（arXiv 2404.00413，MIT+马德里理工，2024） 用LLM做卫星机动的自主控制，在Kerbal Space Program仿真平台上测试，用了prompt engineering、few-shot和fine-tuning，在公开竞赛中拿了第二名。这是这个领域最早的工作之一，引用量已经在涨。 [arXiv](https://arxiv.org/abs/2404.00413)

**LLMSat**（arXiv 2405.01392，2024） 把LLM作为推理引擎设计了一个卫星自主控制器，用KSP模拟深空探测任务。发现LLM的规划能力随任务复杂度上升会下降，但通过合适的prompting框架可以缓解。 [arXiv](https://arxiv.org/abs/2405.01392)

**你可以做的差异化**：这两篇都用KSP游戏引擎仿真，场景偏轨道机动，不是任务调度。你做Earth Observation卫星的任务规划，场景不同，有空间。

---

#### 方向二：LLM做卫星调度算法自动设计

**AgentAD**（ScienceDirect 2025） 提出了一个LLM多智能体框架，能把自然语言描述的卫星调度问题自动转化成可执行的算法代码，解决地球观测卫星调度问题（EOSSP）。 [ScienceDirect](https://www.sciencedirect.com/science/article/pii/S2095809925006654)

这篇角度是"LLM生成算法"，不是"LLM直接做决策"，思路不同。

---

#### 方向三：LLM+RL做LEO卫星波束调度

对比了fixed、rule-based、MLP、fine-tuned LLM四种方案做LEO卫星通信资源分配。结果发现fine-tuned LLM在已知场景下效果崩了（45Mbps vs MLP的357Mbps），原因是输出不稳定，而不是缺乏领域知识。结论是LLM的不可替代价值在于理解自然语言意图，而不是直接做数值优化。 [arxiv](https://arxiv.org/pdf/2604.03562)

**这篇对你很有参考价值**——它指出了LLM的边界在哪，你的工作可以在这个基础上提出改进方案。

---

#### 方向四：可解释卫星调度

用LLM+知识图谱做卫星调度的可解释性，让地面操作员可以用自然语言查询调度逻辑。这个角度偏human-in-the-loop，如果你导师对工程落地感兴趣，这也是一条路。 [AIAA](https://arc.aiaa.org/doi/10.2514/1.I011531)

---

### 给你的选题建议

看完这些工作，**空缺最大的是**：在真实约束（能源、存储、通信窗口、姿态机动时间）下，系统评估LLM规划能力边界，并提出针对性改进。现有论文要么用游戏仿真、要么只做通信资源分配，缺一个面向Earth Observation任务调度的扎实benchmark+方法论工作。