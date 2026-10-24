"""
ICH-NeuroSim Automated Unit Test Suite (pytest)
Verifies:
  - UT-GEO-001: LPS ↔ RAS coordinate transformation reversibility
  - UT-GEO-002: RAS to OpenXR VR millimeter-to-meter scale mapping
  - UT-FCL-001: 3.0mm hard safety collision threshold boundary check
  - UT-DICOM-001: DICOM PS 3.15 de-identification scrubbing
  - UT-OPT-001: Trajectory planning cost function & Pareto optimality
  - UT-IGTL-001: OpenIGTLink matrix transformation orthonormality
"""

import pytest
import numpy as np
import sys
import os

# Add parent directory to sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from core.coordinates import lps_to_ras, ras_to_lps, ras_to_vr, vr_to_ras, build_trajectory_transform_matrix
from core.collision import CollisionChecker, SAFETY_CLEARANCE_MM
from core.schemas import PatientCaseContext, TrajectoryPlanContract
from pipeline.dicom_deid import sanitize_dicom_metadata, generate_pseudonym_id
from pipeline.trajectory_planner import TrajectoryOptimizer
from server.igtlink_service import IGTLinkExportService, rotation_matrix_to_quaternion


# ==========================================
# UT-GEO-001: LPS ↔ RAS Reversibility
# ==========================================
def test_ut_geo_001_lps_ras_reversibility():
    """Verify that converting LPS to RAS and back preserves exact coordinates (error < 1e-6 mm)."""
    np.random.seed(42)
    random_coords = np.random.uniform(-250.0, 250.0, size=(1000, 3))
    for pt in random_coords:
        ras = lps_to_ras(pt)
        restored_lps = ras_to_lps(ras)
        np.testing.assert_allclose(restored_lps, pt, atol=1e-6, err_msg="LPS to RAS round-trip error!")


# ==========================================
# UT-GEO-002: RAS to VR Meter Scaling
# ==========================================
def test_ut_geo_002_ras_to_vr_scaling():
    """Verify that RAS (mm) converts to OpenXR VR space (meters) with correct scale and axis mapping."""
    pt_ras = np.array([120.0, -80.0, 95.0]) # mm
    vr_pt = ras_to_vr(pt_ras)
    
    # In VR: X = 0.12m, Y (Superior) = 0.095m, Z (Posterior) = 0.080m
    expected_vr = np.array([0.12, 0.095, 0.080])
    np.testing.assert_allclose(vr_pt, expected_vr, atol=1e-5, err_msg="RAS to VR unit conversion error!")

    # Inverse mapping
    restored_ras = vr_to_ras(vr_pt)
    np.testing.assert_allclose(restored_ras, pt_ras, atol=1e-5, err_msg="VR to RAS round-trip error!")


# ==========================================
# UT-FCL-001: 3.0mm Safety Clearance Check
# ==========================================
def test_ut_fcl_001_safety_clearance_boundary():
    """Verify that trajectory clearance at 3.01mm passes, while 2.99mm is strictly intercepted."""
    # Define vertical CST fiber segment: (0, 0, 0) to (0, 0, 100)
    cst_points = np.array([
        [0.0, 0.0, 0.0],
        [0.0, 0.0, 100.0]
    ])
    checker = CollisionChecker(cst_points=cst_points)

    # Cannula outer radius is 1.5mm, CST radius is 2.0mm -> sum = 3.5mm
    # Centerline distance = 6.51mm -> Clearance = 6.51 - 3.5 = 3.01mm (SAFE)
    entry_safe = np.array([6.51, 0.0, 0.0])
    target_safe = np.array([6.51, 0.0, 100.0])
    is_safe, dist_cst, _, warnings = checker.evaluate_cannula_safety(entry_safe, target_safe)

    assert is_safe is True, "3.01mm clearance should be marked SAFE!"
    assert dist_cst >= 3.0, f"Expected clearance >= 3.0mm, got {dist_cst}"
    assert len(warnings) == 0

    # Centerline distance = 6.49mm -> Clearance = 6.49 - 3.5 = 2.99mm (DANGER / HARD INTERCEPT)
    entry_danger = np.array([6.49, 0.0, 0.0])
    target_danger = np.array([6.49, 0.0, 100.0])
    is_safe_danger, dist_cst_danger, _, warnings_danger = checker.evaluate_cannula_safety(entry_danger, target_danger)

    assert is_safe_danger is False, "2.99mm clearance must be strictly INTERCEPTED!"
    assert dist_cst_danger < 3.0, f"Expected clearance < 3.0mm, got {dist_cst_danger}"
    assert any("CST_COLLISION_ALERT" in w for w in warnings_danger), "Missing CST collision alert flag!"


# ==========================================
# UT-DICOM-001: DICOM PS 3.15 De-identification
# ==========================================
def test_ut_dicom_001_deidentification():
    """Verify that direct patient identifiers are thoroughly scrubbed per PS 3.15."""
    raw_meta = {
        "PatientName": "Zhang^San",
        "PatientID": "PAT123456789",
        "PatientBirthDate": "19680512",
        "PixelSpacing": [0.488, 0.488],
        "SliceThickness": 1.0,
        "InstitutionName": "Central Hospital"
    }
    clean = sanitize_dicom_metadata(raw_meta)

    assert clean["PatientName"] == "ANONYMOUS"
    assert clean["PatientID"].startswith("SUBJ_")
    assert clean["PatientID"] != raw_meta["PatientID"]
    assert clean["PatientBirthDate"] == "19000101"
    # Geometry preserved
    assert clean["PixelSpacing"] == [0.488, 0.488]
    assert clean["SliceThickness"] == 1.0


# ==========================================
# UT-OPT-001: Trajectory Planning & Cost
# ==========================================
def test_ut_opt_001_trajectory_optimization():
    """Verify trajectory planning generates primary and secondary plans with valid geometry."""
    cst_points = np.array([[10.0, -15.0, -20.0], [15.0, -12.0, 60.0]])
    checker = CollisionChecker(cst_points=cst_points)
    optimizer = TrajectoryOptimizer(checker)

    target_ras = np.array([25.0, 10.0, 35.0])
    pca_axis = np.array([0.2, 0.8, 0.5])

    plans = optimizer.plan_optimal_trajectories(target_ras, pca_axis, top_k=2)

    assert len(plans) == 2, "Should return primary and alternative plans"
    assert plans[0].is_primary_recommendation is True
    assert plans[1].is_primary_recommendation is False
    assert plans[0].cost_score <= plans[1].cost_score, "Primary plan must have lower or equal cost penalty"
    assert plans[0].trajectory_length_mm > 0.0


# ==========================================
# UT-IGTL-001: Matrix & Quaternion Integrity
# ==========================================
def test_ut_igtl_001_quaternion_orthonormality():
    """Verify OpenIGTLink transformation matrix is orthonormal and quaternion has unit norm."""
    entry = np.array([30.0, 20.0, 70.0])
    target = np.array([25.0, 10.0, 35.0])

    mat = build_trajectory_transform_matrix(entry, target)

    # Check orthonormality of 3x3 rotation
    R = mat[:3, :3]
    np.testing.assert_allclose(R.T @ R, np.eye(3), atol=1e-5, err_msg="Rotation submatrix not orthonormal!")

    # Check quaternion unit norm
    q = rotation_matrix_to_quaternion(R)
    norm_sq = sum(c * c for c in q)
    np.testing.assert_allclose(norm_sq, 1.0, atol=1e-5, err_msg="Quaternion is not unit length!")


if __name__ == "__main__":
    pytest.main(["-v", __file__])
