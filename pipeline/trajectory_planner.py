"""
ICH-NeuroSim Multi-Objective Surgical Trajectory Planner (CDSS)
Implements ENRICH (2024 NEJM) minimally invasive transsulcal parafascicular approach (MIPS).
Optimizes puncture and tubular retractor trajectories avoiding eloquent cortex and major tracts.
"""

import numpy as np
import uuid
from typing import List, Tuple, Optional
from core.schemas import TrajectoryPlanContract, Point3D, ApproachType
from core.collision import CollisionChecker, SAFETY_CLEARANCE_MM


class TrajectoryOptimizer:
    """
    Multi-objective trajectory solver based on OMPL / Pareto optimization concepts.
    Generates safe, minimally disruptive access corridors into hematoma targets.
    """
    def __init__(self, collision_checker: CollisionChecker):
        self.collision_checker = collision_checker

    def generate_candidate_entry_points(self, skull_center_ras: np.ndarray, radius: float = 75.0) -> List[np.ndarray]:
        """
        Generate candidate burr hole / entry points on frontal and parietal non-eloquent skull.
        Safe zones: Frontal (Kocher's point area), Parieto-occipital (Keen's point area).
        """
        candidates = []
        # Frontal safe corridor (around Kocher's point: X: 25-35mm, Y: 10-25mm, Z: 65-80mm)
        for dx in [22.0, 28.0, 34.0, -22.0, -28.0, -34.0]:
            for dy in [12.0, 20.0, 28.0]:
                for dz in [65.0, 72.0, 78.0]:
                    candidates.append(np.array([dx, dy, dz]))

        # Parietal safe corridor (around Keen's point: X: 35-45mm, Y: -50 to -40mm, Z: 50-60mm)
        for dx in [36.0, 42.0, -36.0, -42.0]:
            for dy in [-48.0, -40.0]:
                for dz in [52.0, 60.0]:
                    candidates.append(np.array([dx, dy, dz]))

        return candidates

    def plan_optimal_trajectories(self, target_ras: np.ndarray, pca_axis: np.ndarray,
                                  top_k: int = 2) -> List[TrajectoryPlanContract]:
        """
        Search for top-k optimal trajectories minimizing cortical disruption and maximizing hematoma coverage.
        """
        candidates = self.generate_candidate_entry_points(target_ras)
        evaluated_plans = []

        pca_norm = pca_axis / (np.linalg.norm(pca_axis) + 1e-8)

        for i, entry in enumerate(candidates):
            depth = float(np.linalg.norm(entry - target_ras))
            if depth < 30.0 or depth > 110.0:  # depth filter: acceptable clinical range
                continue

            traj_vec = (target_ras - entry) / depth
            cos_alignment = abs(float(np.dot(traj_vec, pca_norm)))

            # Check collision with CST and vessels
            is_safe, dist_cst, dist_vessel, warnings = self.collision_checker.evaluate_cannula_safety(entry, target_ras)

            # Objective Cost Function J(L)
            # Penalize long depth, proximity to CST and vessels. Reward alignment with major axis.
            cst_penalty = 100.0 / (dist_cst + 0.5) if dist_cst < 10.0 else 5.0
            vessel_penalty = 150.0 / (dist_vessel + 0.5) if dist_vessel < 10.0 else 5.0
            
            # Massive penalty if violating 3.0mm hard safety bound
            hard_penalty = 10000.0 if not is_safe else 0.0

            total_cost = (0.2 * depth) + cst_penalty + vessel_penalty - (15.0 * cos_alignment) + hard_penalty

            plan = TrajectoryPlanContract(
                plan_id=f"plan_{uuid.uuid4().hex[:8]}",
                approach_type=ApproachType.MIPS_TRANSSULCAL,
                entry_point=Point3D(x=float(entry[0]), y=float(entry[1]), z=float(entry[2])),
                target_point=Point3D(x=float(target_ras[0]), y=float(target_ras[1]), z=float(target_ras[2])),
                trajectory_length_mm=round(depth, 1),
                min_distance_to_cst_mm=round(dist_cst, 2),
                min_distance_to_vessel_mm=round(dist_vessel, 2),
                is_safe=is_safe,
                warning_flags=warnings,
                cost_score=round(total_cost, 2),
                is_primary_recommendation=False
            )
            evaluated_plans.append(plan)

        # Sort by cost ascending
        evaluated_plans.sort(key=lambda p: p.cost_score)

        # Mark primary and alternative
        results = evaluated_plans[:top_k]
        if len(results) > 0:
            results[0].is_primary_recommendation = True

        return results
