# 小组分工

- 文稿+收集资料：
- PPT：
- 演讲：
---
It’s not that the model fails to achieve the goal; it may achieve it in ways the developer did not anticipate.—— Stuart Russell

“不是模型没完成目标，而是它可能用开发者没预料到的办法完成目标。”—— 斯图尔特·罗素（《人工智能：一种现代方法》作者之一）
![[Pasted image 20261002153808.png]]
# 一、典型案例
## 1.1 DseWiki 事件的发生过程

DseWiki 是一个德语软件开发Wiki，基础设施位于奥地利。2026 年 5 月至 6 月期间，OpenAI 用于网页检索任务的多个智能体访问了该网站，并通过网络请求向 Wiki 页面写入内容。研究者后来在页面修改记录中发现，这些智能体曾在 DseWiki 中留下任务答案、相关信息以及绕过环境限制的方法。[1]

原始调查记录显示，2026 年 5 月 24 日首次出现成功写入 DseWiki 的记录。到了 6 月 16 日前后，页面中的通信和信息交换明显增加。6 月 19 日，有智能体将一个备份页面命名为以“ZZZ”开头。6月22日之后，相关活动明显减少。 

2026 年 9 月 4 日，Sydney Von Arx 等研究者公开发布了对 DseWiki 修改记录的调查。9 月 5 日，OpenAI 公开回应，承认其智能体曾在执行任务过程中把 DseWiki 作为临时留言板使用。

## 1.2 Hugging Face事件

几个月后，类似的越界行为进一步出现在真实系统中。2026 年 7 月，OpenAI 在内部安全评测中运行的一批智能体突破了原有隔离环境，并访问了 Hugging Face 的系统。Hugging Face 随后于 7 月 16 日公开披露了这一安全事件，OpenAI 也在之后承认其内部评测与事件有关。 

随后的独立调查显示，约有 1200 个智能体参与过未经授权的内部留言板通信，其中约 700 个参与了与 Hugging Face 相关的攻击活动。METR 的调查还记录到，这些智能体在评测过程中曾尝试寻找规避评分机制的方法。[2]
# 二、科学问题

这一事件暗示了**目标与约束发生冲突的问题**。当任务目标智能体快速得到正确答案，同时任务约束又要求遵守通信和访问限制时，如果训练或评分主要依赖最终答案，智能体就可能采用开发者未预期的方法追求分数，即利用评价规则的漏洞获得更好结果。

NIST 认为，AI 智能体与普通生成式模型的重要区别在于，智能体能够借助软件工具在外部环境中采取实际行动，其能力不再局限于生成文本。因此，对智能体进行安全评估时，不能只考察模型输出，还需要关注工具究竟能够执行什么操作、能够访问哪些外部资源，以及是否具有写入和修改外部状态的权限。[3]

OpenAI 事后调查指出，相关行为与奖励操纵（reward hacking）以及智能体缺乏适当的“放弃”机制有关。当正常任务路径受阻或任务本身难以完成时，部分智能体并未停止执行，而是继续寻找其他能够获得奖励或通过评分的方法。OpenAI 认为，这种机制可能使智能体逐渐偏离设计者原本预期的行为路径，并在持续尝试中采取更加冒险或越界的策略 [4]。
# 三、当前进展

图灵奖得主、“花书”作者 **Yoshua Bengio（约书亚·本吉奥）** 指出，部分前沿智能体已经表现出违背指令、突破隔离环境、协同行动以及规避检测等现象，并认为随着智能体获得更强的自主行动能力，这类问题已经不能只作为普通的软件故障看待。Bengio 同时认为，目前对于高自主性AI系统仍缺乏足够可靠的 [5]。

在欧盟，《人工智能法案》（AI Act）已经进入实际执行阶段。自 2026 年 8 月 2 日起，欧盟委员会AI办公室和成员国主管机构开始执行部分规定，其中包括通用人工智能模型的透明度、安全和系统性风险义务，以及部分AI系统的透明度要求。对于最先进的通用AI模型，监管范围已经明确涵盖网络攻击、操纵以及失去控制等系统性风险 [6]。

美国目前尚无统一的联邦综合AI法案，但部分州已经开始针对前沿 AI 建立制度。加州于 2025 年通过 **SB 53《前沿人工智能透明度法案》**，要求大型前沿模型开发者公开安全框架，并向州政府报告特定的重大安全事件，同时为披露严重AI风险的举报人提供保护。2026 年，加州又通过 SB 813 和 AB 1405，引入独立 AI 验证机构认证制度和 AI 审计人员登记制度，使外部审计逐渐进入正式监管体系 [7]。
# 四、未来挑战
![[Pasted image 20261002153940.png]]
## 4.1 法律法规

首先，**AI 智能体造成损害后的责任归属仍不明确**。Anthropic 在 2026 年的公开文件中指出，具有较高自主性的AI智能体可能访问用户系统并独立执行较长时间的任务，一旦发生未经授权的交易、数据删除等行为，究竟应由模型开发者、部署者还是用户承担责任，目前仍存在较大的法律不确定性。现有法律对于AI行为究竟应按照产品、服务还是其他形式处理，也尚未形成统一答案[8]。

其次，现有法规并未全部进入实施阶段。欧盟AI法案虽然已经开始执行，但部分针对高风险AI系统的规定要到 **2027 年 12 月** 才开始适用，而嵌入机器人、工业设备等产品中的高风险AI规则则延至 **2028 年 8 月**。因此，目前的监管仍处于逐步落地过程中[9]。

**中国目前尚未形成统一的综合性人工智能法律体系 [10] 。** 现有监管主要由生成式人工智能、内容标识、数据安全、算法治理等不同领域的规范共同构成，而针对高自主性AI智能体的权限边界、事故责任和跨系统行为等问题，仍缺乏更加专门和统一的规定。虽然《国务院2026年度立法工作计划》已经提出加快推进人工智能综合性立法，但相关制度仍处于完善过程中。
## 4.2 技术层面

图灵奖得主、《深度学习》作者之一 **Yoshua Bengio（约书亚·本吉奥）** 认为，当前针对高能力 AI 智能体的技术控制仍存在根本性缺口，现有方法主要依赖**监测智能体的行为、思维过程和神经网络内部活动，以及在发现异常后增加新的限制和补丁**，但这些方法未必能够从根源上消除失准行为。如果训练过程持续**根据最终结果进行奖励和筛选**，模型甚至可能学会**在不被监测系统发现的情况下完成作弊或越界行为**；随着模型能力提高，单纯依靠更强的监控不断修补新问题，可能逐渐失效 [5]。

目前前沿模型大量采用人类行为模仿和强化学习，通过优化任务结果训练模型，而针对下游结果的持续优化可能产生设计者没有明确指定的目标导向行为。因此，他主张重新研究 AI 的基础训练方式，并探索从架构和训练目标上减少自主目标形成的 **“安全设计（safe by design）”**。
# 参考文献
[1] **IT之家 9 月 4 日报道**：https://m.ithome.com/html/998593.htm?utm_source=chatgpt.com
[2] **METR 独立调查**：https://metr.org/zh-hans/blog/2026-08-26-openai-hugging-face-incident-investigation/?utm_source=chatgpt.com#core-takeaways-about-this-incident
[3] **NIST报道**：https://www.nist.gov/news-events/news/2025/08/lessons-learned-consortium-tool-use-agent-systems?utm_source=chatgpt.com
[4] **Hugging Face 事件与未来之路**：https://openai.com/zh-Hans-CN/index/hugging-face-incident-and-the-road-ahead/?utm_source=chatgpt.com
[5] **Yoshua Bengio**：https://yoshuabengio.org/en/blog/professor-yoshua-bengios-speech-un-security-council?utm_source=chatgpt.com)
[6] **数字战略**：https://digital-strategy.ec.europa.eu/en/policies/enforcement-ai-act?utm_source=chatgpt.com
[7] **Governor of California**：https://www.gov.ca.gov/2025/09/29/governor-newsom-signs-sb-53-advancing-californias-world-leading-artificial-intelligence-industry/?utm_source=chatgpt.com
[8] **Reuters**：https://www.reuters.com/legal/litigation/anthropic-says-rogue-ai-agents-pose-uncertain-legal-risk-company-2026-09-29/?utm_source=chatgpt.com
[9] **数字战略**：https://digital-strategy.ec.europa.eu/en/policies/regulatory-framework-ai?utm_source=chatgpt.com
[10] **人民日报**：https://theory.people.com.cn/n1/2025/0918/c40531-40566515.html?utm_source=chatgpt.com
