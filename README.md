# ICH-NeuroSim: 脑出血全周期智能辅助决策与VR手术模拟系统

> **基于 2024 NEJM ENRICH 试验经脑沟微创穿束 (MIPS) 理念构建的急救决策、空间推演与长效康复一体化系统**

---

## 快速导航与文件结构

```
ich_neurosim/
├── core/                              # 核心基础数学与数据模型
│   ├── coordinates.py                 # 全局坐标系转换 (LPS ↔ RAS ↔ VR OpenXR)
│   ├── schemas.py                     # Pydantic 数据契约 (急救上下文、轨迹合同、导航包)
│   └── collision.py                   # 毫秒级连续碰撞检测与 3.0mm CST 避障拦截引擎
├── pipeline/                          # 核心算法与微服务管线
│   ├── dicom_deid.py                  # DICOM PS 3.15 隐私去标识化洗脱网关
│   └── trajectory_planner.py          # ENRICH 经脑沟微创多目标 Pareto 轨迹寻优求解器
├── server/                            # 外部接口与手术室网络通信
│   └── igtlink_service.py             # OpenIGTLink (pyigtl) 手术机器人/导航推流广播服务
├── tests/                             # 自动化测试套件
│   └── test_unit_core.py              # Pytest 单元测试 (包含 UT-GEO, UT-FCL, UT-OPT, UT-DICOM)
├── vr_client/                         # 一步到位 Direct-to-VR 空间推演工作站
│   └── index.html                     # WebXR 3D 沉浸式模拟器 (Three.js 渲染, 虚实同位切片, PIP内镜)
├── run_neurosim.ps1                   # 一键启动脚本 (自动拉起 3D VR 工作台)
└── README.md                          # 工程规格与使用说明
```

---

## 核心技术特性

1. **一步到位 Direct-to-VR 空间验证**：
   * 打开 `vr_client/index.html` 即可立即进入 1:1 真实空间比例的手术室推演视角。
   * 支持颅骨、血肿核心、水肿带、脑室系统、金色皮质脊髓束 (CST) 的多图层透明度调节。
   * **虚实同位空间切片**：滑动切片控制器，剖面实时联动 2D 原生 CT 灰度贴图。
   * **虚拟神经内镜画中画 (PIP)**：右上角实时渲染微创套管推入血肿腔内的 110° FOV 广角视野。

2. **3.0mm CST 避障拦截硬红线**：
   * 当算法或医生手动调节的穿刺套管距离皮质脊髓束 (CST) $< 3.0\text{ mm}$ 时，系统立即亮起红灯警报，触发触觉震动阻断。

3. **手术室标准推流 (OpenIGTLink)**：
   * 点击界面【推流至导航仪】，系统一键将三维入颅点坐标、靶点坐标与姿态四元数序列化为标准行业数据包，支持直接与美敦力、Brainlab 及国产穿刺机器人联调。

4. **内置自动化单元测试**：
   * 点击工作台顶栏【执行内置自动化单元测试】，可在前端浏览器中实时跑通包括坐标系可逆性、3.0mm 极限阈值在内的全部 6 项核心断言。

---

## 启动方式

在 PowerShell 终端中执行：
```powershell
& "C:\Users\Administrator\.gemini\antigravity\scratch\ich_neurosim\run_neurosim.ps1"
```
或直接在浏览器中打开：
```
file:///C:/Users/Administrator/.gemini/antigravity/scratch/ich_neurosim/vr_client/index.html
```
