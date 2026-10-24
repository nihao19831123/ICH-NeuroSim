"""
ICH-NeuroSim OpenIGTLink Surgical Navigation Gateway (pyigtl)
Broadcasts planned puncture/cannula targets and orientation matrices to
operating room navigation systems (e.g. Brainlab, Medtronic, Remebot).
"""

import numpy as np
from typing import Dict, Any, List
from core.schemas import TrajectoryPlanContract, NavigationExportPacket
from core.coordinates import build_trajectory_transform_matrix


def rotation_matrix_to_quaternion(R: np.ndarray) -> List[float]:
    """Convert 3x3 rotation matrix to quaternion [qx, qy, qz, qw]."""
    tr = R[0, 0] + R[1, 1] + R[2, 2]
    if tr > 0:
        S = np.sqrt(tr + 1.0) * 2.0
        qw = 0.25 * S
        qx = (R[2, 1] - R[1, 2]) / S
        qy = (R[0, 2] - R[2, 0]) / S
        qz = (R[1, 0] - R[0, 1]) / S
    elif (R[0, 0] > R[1, 1]) and (R[0, 0] > R[2, 2]):
        S = np.sqrt(1.0 + R[0, 0] - R[1, 1] - R[2, 2]) * 2.0
        qw = (R[2, 1] - R[1, 2]) / S
        qx = 0.25 * S
        qy = (R[0, 1] + R[1, 0]) / S
        qz = (R[0, 2] + R[2, 0]) / S
    elif R[1, 1] > R[2, 2]:
        S = np.sqrt(1.0 + R[1, 1] - R[0, 0] - R[2, 2]) * 2.0
        qw = (R[0, 2] - R[2, 0]) / S
        qx = (R[0, 1] + R[1, 0]) / S
        qy = 0.25 * S
        qz = (R[1, 2] + R[2, 1]) / S
    else:
        S = np.sqrt(1.0 + R[2, 2] - R[0, 0] - R[1, 1]) * 2.0
        qw = (R[1, 0] - R[0, 1]) / S
        qx = (R[0, 2] + R[2, 0]) / S
        qy = (R[1, 2] + R[2, 1]) / S
        qz = 0.25 * S
    return [float(qx), float(qy), float(qz), float(qw)]


class IGTLinkExportService:
    """Formats and serializes Trajectory Plans into OpenIGTLink Transform packets."""

    @staticmethod
    def create_navigation_packet(patient_id: str, plan: TrajectoryPlanContract) -> NavigationExportPacket:
        entry = np.array([plan.entry_point.x, plan.entry_point.y, plan.entry_point.z])
        target = np.array([plan.target_point.x, plan.target_point.y, plan.target_point.z])

        # Generate 4x4 matrix
        mat_4x4 = build_trajectory_transform_matrix(entry, target)
        quat = rotation_matrix_to_quaternion(mat_4x4[:3, :3])

        return NavigationExportPacket(
            plan_id=plan.plan_id,
            patient_id=patient_id,
            device_name="ICH_Target_Plan",
            transform_matrix_4x4=mat_4x4.tolist(),
            quaternion=quat,
            entry_ras=entry.tolist(),
            target_ras=target.tolist(),
            safety_margin_mm=plan.min_distance_to_cst_mm
        )
