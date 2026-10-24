"""
ICH-NeuroSim Global Coordinate Transformations & Spatial Math
Standardized coordinate conversions across:
  - DICOM Physical Space (LPS: Left-Posterior-Superior)
  - Neuroimaging / Slicer Space (RAS: Right-Anterior-Superior)
  - VR / OpenXR Space (Y-Up, Right-Handed, Unit: Meters)
  - Surgical Navigation Space (Tracker Matrix, Unit: Millimeters)
"""

import numpy as np
from typing import Tuple, List

# Matrix: LPS to RAS (X inverted, Y inverted, Z unchanged)
MAT_LPS_TO_RAS = np.diag([-1.0, -1.0, 1.0, 1.0])
MAT_RAS_TO_LPS = np.diag([-1.0, -1.0, 1.0, 1.0])

# Scale factor: Millimeters to Meters for OpenXR
MM_TO_METERS = 0.001
METERS_TO_MM = 1000.0


def lps_to_ras(coord_lps: np.ndarray) -> np.ndarray:
    """Convert DICOM LPS coordinates (mm) to Neuroimaging RAS coordinates (mm)."""
    assert coord_lps.shape == (3,), "Input coordinate must be a 3D vector [x, y, z]"
    homo = np.append(coord_lps, 1.0)
    return (MAT_LPS_TO_RAS @ homo)[:3]


def ras_to_lps(coord_ras: np.ndarray) -> np.ndarray:
    """Convert RAS coordinates (mm) back to DICOM LPS coordinates (mm)."""
    assert coord_ras.shape == (3,), "Input coordinate must be a 3D vector [x, y, z]"
    homo = np.append(coord_ras, 1.0)
    return (MAT_RAS_TO_LPS @ homo)[:3]


def ras_to_vr(coord_ras: np.ndarray, origin_anchor_ras: np.ndarray = np.array([0.0, 0.0, 0.0])) -> np.ndarray:
    """
    Convert RAS coordinates (mm) to OpenXR VR Space (meters).
    RAS (X: Right, Y: Anterior, Z: Superior)
    OpenXR (X: Right, Y: Up/Superior, Z: Posterior/Backward)
    Applies standard neuro-to-VR coordinate mapping:
      X_vr = (X_ras - origin_x) * 0.001
      Y_vr = (Z_ras - origin_z) * 0.001  (Superior is Up)
      Z_vr = -(Y_ras - origin_y) * 0.001 (Anterior is Forward/-Z)
    """
    rel = coord_ras - origin_anchor_ras
    x_vr = rel[0] * MM_TO_METERS
    y_vr = rel[2] * MM_TO_METERS
    z_vr = -rel[1] * MM_TO_METERS
    return np.array([x_vr, y_vr, z_vr])


def vr_to_ras(coord_vr: np.ndarray, origin_anchor_ras: np.ndarray = np.array([0.0, 0.0, 0.0])) -> np.ndarray:
    """Inverse convert OpenXR VR space (meters) back to RAS (mm)."""
    x_ras = coord_vr[0] * METERS_TO_MM + origin_anchor_ras[0]
    y_ras = -coord_vr[2] * METERS_TO_MM + origin_anchor_ras[1]
    z_ras = coord_vr[1] * METERS_TO_MM + origin_anchor_ras[2]
    return np.array([x_ras, y_ras, z_ras])


def build_trajectory_transform_matrix(entry_ras: np.ndarray, target_ras: np.ndarray) -> np.ndarray:
    """
    Build 4x4 rigid transformation matrix from entry point to target point.
    Z-axis aligns with the trajectory vector.
    Used for OpenIGTLink推流 (pyigtl) and VR cannula rendering.
    """
    direction = target_ras - entry_ras
    length = np.linalg.norm(direction)
    assert length > 1e-4, "Entry and target points cannot coincide"
    z_axis = direction / length

    # Arbitrary orthogonal vector for X-axis
    ref = np.array([0.0, 0.0, 1.0]) if abs(z_axis[2]) < 0.9 else np.array([1.0, 0.0, 0.0])
    x_axis = np.cross(ref, z_axis)
    x_axis = x_axis / np.linalg.norm(x_axis)
    y_axis = np.cross(z_axis, x_axis)

    mat = np.eye(4)
    mat[:3, 0] = x_axis
    mat[:3, 1] = y_axis
    mat[:3, 2] = z_axis
    mat[:3, 3] = entry_ras
    return mat
