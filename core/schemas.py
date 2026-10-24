"""
ICH-NeuroSim Core Data Schemas & API Contracts
Defines standardized Pydantic data models for patient context, segmentation output,
trajectory planning, collision warnings, and surgical navigation export.
"""

from pydantic import BaseModel, Field
from typing import List, Optional, Tuple, Dict
from enum import Enum


class ApproachType(str, Enum):
    MIPS_TRANSSULCAL = "MIPS_Transsulcal"          # ENRICH 2024 NEJM Tubular retractor
    STEREOTACTIC_NEEDLE = "Stereotactic_Needle"    # Puncture & catheter drainage
    ENDOSCOPIC_SULCAL = "Endoscopic_Sulcal"        # Neuroendoscopic evacuation
    CRANIOTOMY_DECOMPRESS = "Craniotomy_Decompress"# Large bone flap decompressive craniectomy


class Point3D(BaseModel):
    x: float = Field(..., description="X coordinate in RAS (mm)")
    y: float = Field(..., description="Y coordinate in RAS (mm)")
    z: float = Field(..., description="Z coordinate in RAS (mm)")

    def to_list(self) -> List[float]:
        return [self.x, self.y, self.z]


class PatientCaseContext(BaseModel):
    patient_id: str = Field(..., description="Pseudonymized patient ID (PS 3.15)")
    study_uid: str = Field(..., description="DICOM StudyInstanceUID")
    onset_to_ct_mins: int = Field(..., ge=0, description="Time from symptom onset to CT (minutes)")
    initial_sbp: float = Field(..., ge=50.0, le=280.0, description="Emergency initial systolic BP (mmHg)")
    gcs_score: int = Field(15, ge=3, le=15, description="Glasgow Coma Scale score (3-15)")
    anticoagulant_used: bool = Field(False, description="Whether patient is taking DOACs/Warfarin")


class HematomaQuantification(BaseModel):
    hematoma_volume_ml: float = Field(..., description="Hematoma core volume in mL (exact voxel calculation)")
    edema_volume_ml: float = Field(..., description="Perihematomal edema (PHE) volume in mL")
    midline_shift_mm: float = Field(0.0, description="Septum pellucidum shift distance (mm)")
    expansion_risk_level: str = Field("LOW", description="LOW | MEDIUM | HIGH expansion risk")
    expansion_probability: float = Field(0.0, ge=0.0, le=1.0, description="Predicted HE probability")
    centroid_ras: Point3D = Field(..., description="Hematoma center of mass in RAS (mm)")
    pca_major_axis: List[float] = Field(..., description="Hematoma major eigenvector (3D vector)")


class TrajectoryPlanContract(BaseModel):
    plan_id: str = Field(..., description="Unique plan identifier")
    approach_type: ApproachType = Field(ApproachType.MIPS_TRANSSULCAL)
    entry_point: Point3D = Field(..., description="Entry point on skull in RAS (mm)")
    target_point: Point3D = Field(..., description="Target point in hematoma in RAS (mm)")
    trajectory_length_mm: float = Field(..., description="Depth of penetration (mm)")
    min_distance_to_cst_mm: float = Field(..., description="Min distance to Corticospinal Tract (mm)")
    min_distance_to_vessel_mm: float = Field(..., description="Min distance to major cerebral arteries (mm)")
    is_safe: bool = Field(..., description="True if min_dist >= 3.0mm, otherwise False")
    warning_flags: List[str] = Field(default_factory=list, description="Safety alerts: CST_COLLISION_ALERT, etc.")
    cost_score: float = Field(..., description="Total multi-objective optimization penalty score")
    is_primary_recommendation: bool = Field(True, description="True for primary plan, False for alternative")


class NavigationExportPacket(BaseModel):
    plan_id: str
    patient_id: str
    device_name: str = "ICH_Target_Plan"
    transform_matrix_4x4: List[List[float]] = Field(..., description="4x4 affine matrix for OpenIGTLink")
    quaternion: List[float] = Field(..., description="[qx, qy, qz, qw] orientation")
    entry_ras: List[float]
    target_ras: List[float]
    safety_margin_mm: float
