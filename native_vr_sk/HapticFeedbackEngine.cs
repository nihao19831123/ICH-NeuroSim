using System;

namespace ICH_NeuroSim.VR
{
    /// <summary>
    /// 解剖组织力学分层枚举
    /// </summary>
    public enum AnatomicalTissueLayer
    {
        AirBeforeScalp,     // 空气间隙 (无阻力)
        ScalpSkin,          // 头皮及皮下软组织 (黏弹性形变)
        SkullCortex,        // 颅骨外板及骨质 (高刚度、高频电钻震颤)
        DuraMater,          // 硬脑膜 (高韧性阻力与穿透落空感)
        BrainParenchyma,    // 脑白质 (极低顺应性黏弹性)
        HematomaCavity,     // 血肿腔 (凝血块阻力与微血管搏动)
        BoneHoleBoundary    // 骨孔边缘碰撞硬限制
    }

    /// <summary>
    /// 6自由度触觉反馈力学解算引擎 (OpenHaptics / Phantom Omni 规范)
    /// 针对经额叶脑沟微创穿束手术提供逼真的物理阻力、骨磨钻振动与落空感
    /// </summary>
    public class HapticFeedbackEngine
    {
        // 组织穿刺位移阈值 (单位: mm, 以颅外入点为基准 0mm)
        public const double SCALP_DEPTH_MM = 6.0;      // 头皮厚度 ~6mm
        public const double SKULL_DEPTH_MM = 12.0;     // 颅骨厚度 ~6mm (深度 6~12mm)
        public const double DURA_DEPTH_MM = 13.0;      // 硬脑膜 ~1mm (深度 12~13mm)
        public const double HEMATOMA_START_MM = 38.5;  // 血肿前缘深度
        public const double HEMATOMA_END_MM = 61.2;    // 血肿后下质心深度

        // 力学常数 (单位: N, 牛顿)
        private const double SCALP_MAX_FORCE_N = 3.2;
        private const double SKULL_DRILL_FORCE_N = 18.5;
        private const double DURA_PEAK_FORCE_N = 5.4;
        private const double DURA_POP_RESIDUAL_N = 0.8;
        private const double BRAIN_VISCOUS_FORCE_N = 0.45;
        private const double HEMATOMA_RESISTANCE_N = 0.65;

        private Random _rng = new Random();

        /// <summary>
        /// 根据当前穿刺套管推进深度 (mm) 与推进行进速度 (mm/s) 计算当前瞬时触觉反馈力矩
        /// </summary>
        /// <param name="penetrationDepthMm">沿穿刺方向推进深度</param>
        /// <param name="velocityMmPerSec">推进速度</param>
        /// <param name="tissueLayer">输出当前所处解剖层级</param>
        /// <param name="vibrationIntensity">输出手柄高频震动强度 (0.0 ~ 1.0)</param>
        /// <returns>沿穿刺反方向的阻力 (单位: 牛顿 N)</returns>
        public double ComputeHapticForce(double penetrationDepthMm, double velocityMmPerSec,
                                        out AnatomicalTissueLayer tissueLayer, out double vibrationIntensity)
        {
            vibrationIntensity = 0.0;

            if (penetrationDepthMm <= 0.0)
            {
                tissueLayer = AnatomicalTissueLayer.AirBeforeScalp;
                return 0.0;
            }
            else if (penetrationDepthMm < SCALP_DEPTH_MM)
            {
                // 1. 头皮层：胡克定律非线性弹性形变 + 黏滞阻力
                tissueLayer = AnatomicalTissueLayer.ScalpSkin;
                double deformRatio = penetrationDepthMm / SCALP_DEPTH_MM;
                double elasticForce = SCALP_MAX_FORCE_N * Math.Pow(deformRatio, 1.6);
                double viscousDamping = 0.05 * velocityMmPerSec;
                return elasticForce + viscousDamping;
            }
            else if (penetrationDepthMm < SKULL_DEPTH_MM)
            {
                // 2. 颅骨板障：电钻旋转高刚度阻力 + 150Hz 磨钻触觉振动
                tissueLayer = AnatomicalTissueLayer.SkullCortex;
                vibrationIntensity = 0.85 + (_rng.NextDouble() * 0.15); // 高频电钻颤动
                double drillResistance = SKULL_DRILL_FORCE_N + (velocityMmPerSec * 0.4);
                return drillResistance;
            }
            else if (penetrationDepthMm < DURA_DEPTH_MM)
            {
                // 3. 硬脑膜：高韧性阻力积累，临界点发生穿刺落空感 (Pop Effect)
                tissueLayer = AnatomicalTissueLayer.DuraMater;
                double duraRatio = (penetrationDepthMm - SKULL_DEPTH_MM) / (DURA_DEPTH_MM - SKULL_DEPTH_MM);
                if (duraRatio < 0.85)
                {
                    // 膜撕裂前抗力陡增
                    return DURA_PEAK_FORCE_N * (0.6 + 0.4 * duraRatio);
                }
                else
                {
                    // 临界穿透瞬间：手感阻力骤降（落空感），伴随微小低频单次脉冲
                    vibrationIntensity = 0.4;
                    return DURA_POP_RESIDUAL_N;
                }
            }
            else if (penetrationDepthMm < HEMATOMA_START_MM)
            {
                // 4. 经脑沟脑白质推进：顺应性极好的柔软阻力，保护神经纤维
                tissueLayer = AnatomicalTissueLayer.BrainParenchyma;
                double whiteMatterForce = BRAIN_VISCOUS_FORCE_N + (velocityMmPerSec * 0.02);
                return whiteMatterForce;
            }
            else if (penetrationDepthMm <= HEMATOMA_END_MM)
            {
                // 5. 进入血肿腔：凝血块微小阻力 + 大脑中动脉微弱搏动感
                tissueLayer = AnatomicalTissueLayer.HematomaCavity;
                // 模拟心动周期 1.1Hz 的微血管搏动波
                double arterialPulse = 0.08 * Math.Sin(DateTime.Now.TimeOfDay.TotalSeconds * 2.0 * Math.PI * 1.1);
                vibrationIntensity = Math.Max(0.0, arterialPulse);
                return HEMATOMA_RESISTANCE_N + arterialPulse;
            }
            else
            {
                // 超过靶点深度：硬碰撞报警，防止伤及对侧深部基底核
                tissueLayer = AnatomicalTissueLayer.BoneHoleBoundary;
                vibrationIntensity = 1.0; // 剧烈震颤报警
                return 30.0; // 坚硬阻挡
            }
        }
    }
}
