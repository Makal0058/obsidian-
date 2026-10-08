1. **为什么缩放点积注意力要除以 $\sqrt{d_k}$？**
假设 Query 和 Key 中各维度的数值相互独立，均值为 0、方差为 1，它们的点积为 $Q\cdot K=\sum_{i=1}^{d_k}q_i k_i$。在这些假设下，点积的方差为 $\operatorname{Var}(Q\cdot K)=d_k$

注：
1. **证明需要的条件**
两个 $d_k$ 维随机向量：$Q=(q_1,q_2,\ldots,q_{d_k})$、$K=(k_1,k_2,\ldots,k_{d_k})$。假设：

1. $Q$ 和 $K$ 相互独立。
2. 每个元素的均值都是 0。
3. 每个元素的方差都是 1。
4. 同一个向量内，不同维度之间的协方差为 0。

即 $E[q_i]=E[k_i]=0$、$\operatorname{Var}(q_i)=\operatorname{Var}(k_i)=1$、当 $i\ne j$ 时，$E[q_iq_j]=E[k_ik_j]=0$。这些条件比要求所有元素都独立更宽松，也不涉及任何指定的概率分布。
2. **正式证明**
令 $S=Q\cdot K=\sum_{i=1}^{d_k}q_i k_i$，希望求 $\operatorname{Var}(S)$。根据方差定义 $\operatorname{Var}(S)=E[S^2]-(E[S])^2$。

由于 $Q$ 和 $K$ 独立，$E[q_i k_i]=E[q_i]E[k_i]=0$，因此 $E[S]=\sum_{i=1}^{d_k}E[q_i k_i]=0$。所以方差简化成 $\operatorname{Var}(S)=E[S^2]$。

展开平方 $E[S^2] = E\left[\left(\sum_{i=1}^{d_k}q_i k_i\right)^2\right] = \sum_{i=1}^{d_k}\sum_{j=1}^{d_k}E[q_i k_i q_j k_j]$。由于两个向量相互独立，$E[q_i k_i q_j k_j]=E[q_iq_j]E[k_ik_j]$。于是 $\operatorname{Var}(S)=\sum_{i=1}^{d_k}\sum_{j=1}^{d_k}E[q_iq_j]E[k_ik_j]$。

分两种情况讨论。
- 当 $i\ne j$ 时，$E[q_iq_j]=0$。因此这些交叉项全部为 0。
- 当 $i=j$ 时，$E[q_i^2]=\operatorname{Var}(q_i)+(E[q_i])^2=1$，同理 $E[k_i^2]=1$。所以每一个对角项都是 $E[q_i^2]E[k_i^2]=1$。一共有 $d_k$ 个对角项，最终 $\operatorname{Var}(Q\cdot K)=\sum_{i=1}^{d_k}1=d_k$。
3. **为什么除以平方根？**
$\operatorname{Var}(aX)=a^2\operatorname{Var}(X)$

令：

$a=\frac{1}{\sqrt{d_k}}$

于是：

$\begin{aligned}\operatorname{Var}\left(\frac{Q\cdot K}{\sqrt{d_k}}\right)&=\frac{1}{d_k}\operatorname{Var}(Q\cdot K)\\&=\frac{1}{d_k}\times d_k\\&=\boxed{1}\end{aligned}$

这就解释了为什么缩放点积注意力使用：

$\operatorname{Attention}(Q,K,V)=\operatorname{softmax}\left(\frac{QK^\top}{\sqrt{d_k}}\right)V$

（实际使用因果注意力时，还需要加入掩码。）

## 四、更一般的情况是什么？

如果完全不假设零均值、单位方差，即使 $Q,K$ 相互独立，也不一定得到 $d_k$。

设它们的均值向量分别为 $\mu_Q,\mu_K$，协方差矩阵分别为 $\Sigma_Q,\Sigma_K$。

那么一般有：

$\boxed{\begin{aligned}\operatorname{Var}(Q^\top K)={}&\operatorname{tr}(\Sigma_Q\Sigma_K)\\&+\mu_Q^\top\Sigma_K\mu_Q\\&+\mu_K^\top\Sigma_Q\mu_K\end{aligned}}$

这里 $\operatorname{tr}$ 表示矩阵主对角线元素之和。

当：

$\mu_Q=\mu_K=0$

$\Sigma_Q=\Sigma_K=I_{d_k}$

就恢复为：

$\operatorname{Var}(Q^\top K)=\operatorname{tr}(I_{d_k})=d_k$

因此，$1/\sqrt{d_k}$ 的数学依据是一个理想化的统计尺度分析，而不是保证真实 GPT-2 每层注意力分数方差都恰好为 1。

最后总结：整个证明最关键的其实是两条概率论性质：

$\boxed{E[XY]=E[X]E[Y]\quad\text{（当 }X,Y\text{ 独立时）}}$

$\boxed{\operatorname{Var}(aX)=a^2\operatorname{Var}(X)}$

第一条帮助我们得到点积方差 $d_k$，第二条解释为什么要除以 $\sqrt{d_k}$。

あるじさま，如果您理解这两条性质，这个缩放系数的数学原理就基本掌握了。



所以标准差是：

$\sigma=\sqrt{d_k}$

这意味着，向量维度越大，点积的典型波动幅度就越大。

为了控制这个波动幅度，就除以 $\sqrt{d_k}$：

$\operatorname{Var}\left(\frac{Q\cdot K}{\sqrt{d_k}}\right)=1$

这样，在上述假设下，不同维度的注意力分数可以保持相近的数值尺度。
