> [!info] 基本信息
> - **论文题目**：Reinforcing LLM Agents via Policy Optimization with Action Decomposition
> - **中文题目**：基于动作分解策略优化的 LLM 智能体强化方法
> - **期刊/会议**：NeurIPS 2024
> - **年份**：2024
> - **主题**：#强化学习 #大语言模型 #智能体 #策略优化 #动作分解 #序列决策 #信用分配

---
```table-of-contents
```
---
# 一、研究背景（前人做到哪一步）

## 1.1 LLM做决策agent

前人发现LLM不只能聊天，还能在交互环境里做序列决策。ReAct、Reflexion等工作证明了LLM作为agent的可行性，但问题是LLM不了解具体环境的规律，会生成无效动作。

---
## 1.2 用RL来对齐agent

GLAM和TWOSOME是这条路上最重要的前人工作。思路是：让agent在环境里试错，用RL奖惩来让它学会环境规律。做法是把整句话当一个action，用PPO来优化action的概率。但留下了两个问题
$$ \begin{cases} 信用分配粒度太粗，不知道哪个token重要 \\ 动作空间太大，不得不手动限制候选动作集合 \end{cases} $$

---
## 1.3 token级别的RL

RLHF（ChatGPT用的那套）已经在单步任务里把token当micro-action来训练，效果不错。ArCHer尝试把这个思路用到多步决策，但用了多个价值网络，不稳定，调参难。前人没解决的问题：把token展开成马尔可夫决策过程（MDP）会引入理论偏差，没人正式推导过这个偏差是什么、怎么消除

---
# 二、拟解决的问题（为什么现有方法不行）

## 2.1 信用分配太粗

TWOSOME把整句话当一个整体来奖惩。比如输出walk to kitchen得到奖励，但模型不知道到底是walk重要还是kitchen重要，三个词一起被奖励或惩罚。学习效率低，收敛慢

---
## 2.1 动作空间太大

LLM可以自由输出任何句子，可能的动作数量是词表的token数次幂，根本搜不完。TWOSOME的解决办法是手动限制候选动作，只让agent从几个预设句子里选。但这样做有硬伤：**现实任务里根本没办法提前列出所有候选动作**，比如写代码，你不可能把所有可能的代码都列出来让agent选

有人尝试过拆token，但引入了新问题把。token展开成小MDP后，discount factor会累积，导致前面的词天然比后面的词得到更少奖励，引入了理论偏差。这个偏差之前没人正式推导过，也没人解决过。

---
# 三、创新点与贡献

## 3.1 理论层面

首次正式推导了**朴素token级别优化**和**action级别优化**之间的偏差是什么，给出了精确的数学表达式，而不是凭直觉说有问题

---
## 3.２ 方法层面

提出BAD，通过把句子内部的折扣系数设为1，从理论上消除了这个偏差，同时保留了token级别的精细信用分配。把BAD塞进PPO，得到POAD，可以直接用来训练LLM agent

---
## 3.3 实践层面

把动作空间复杂度从$|V|^{|a|} \rightarrow |a| \times |V|$，让开放动作空间的任务变得可训练，不再需要手动限制候选动作

---
## 3.4 实验层面

在三类任务上验证：
1.　限制动作空间的经典任务（Overcooked、VirtualHome）：比TWOSOME收敛更快更稳
2.　开放动作空间任务（DataSciCoding）：TWOSOME直接用不了，POAD可以，而且7B小模型打败了GPT-4
3.　泛化能力：训练过的任务迁移到没见过的类似任务，POAD表现最好
4.　原有语言能力没有损失

---
# 四、方法与模型（框架图/公式/关键步骤）

## 4.1 核心框架

两个网络协同工作$$ \begin{cases} Actor：就是LLM本身，负责生成token \\ Critic：价值网络，负责评估每个token的价值 \end{cases} $$

---
## 4.2 关键公式

BAD，分两种情况：
1.　句子内部（还没说完）： 直接继承下一个token的价值，不打折$$V(s, w^{1:j}) = V(s, w^{1:j+1})$$
2.　句子结尾（说完整句话）：用真实reward加下一句的折扣价值
$$V(s, w^{1:|a|}) = R(st, at) + \gamma V(s_{t+1})$$

---
## 4.3 关键步骤

$$\begin{array}{c}
\text{Actor生成一句话，比如“Turn on TV"} \\
\downarrow \\
\text{环境执行返回reward}\\
\downarrow \\
\text{Critic用BAD从后往前算每个token的价值}\\
\downarrow \\
\text{算每个token的advantage：}\hat{A}^j = Q(s, w^{1:j}) - V(s, w^{1:j-1})\\
\downarrow \\
\text{用PPO的clip更新Actor：好token概率上升，坏token概率下降}
\end{array}$$

---
## 4.4 和前人方法的核心区别

| 方法      | 粒度    | 动作空间  | 理论一致性 |
| ------- | ----- | ----- | ----- |
| TWOSOME | 整句话   | 需要限制  | 一致    |
| NTPO    | token | 不需要限制 | 不一致   |
| POAD    | token | 不需要限制 | 一致    |

---
# 五、实验与结论（数据说明了什么、有什么局限性）

## 5.1 实验结论

1. 限制动作空间任务（Overcooked、VirtualHome）：POAD比TWOSOME收敛更快，训练曲线更稳定，最终性能持平或更好。证明了BAD的信用分配确实有效

2. 开放动作空间任务（DataSciCoding）：TWOSOME直接用不了，POAD可以。用7B小模型训练2-3小时，找到的最优代码在6个数据集上全部超过了CAAFE+GPT-4的结果。证明了POAD在无限制动作空间里的有效性

3. 泛化能力：在"热煎饼"任务训练完，迁移到"热汉堡""热披萨"等8个没见过的任务，POAD在7个里表现最好

4. 语言能力：RL训练后在ARC、HellaSwag等标准测试上没有下降，甚至略有提升

---
## 5.2 局限性

必须有定量的reward函数。现实很多任务没有明确的奖励信号，比如"写一篇好文章"很难量化成一个数字。作者说未来想结合自我奖励或者hindsight relabeling来解决这个问题，但目前还没做