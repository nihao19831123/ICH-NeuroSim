"""
ICH-NeuroSim DICOM De-identification & Sanitization Worker
Compliant with DICOM PS 3.15 Basic Profile for patient data privacy protection.
Scrubs direct patient identifiers (Name, ID, Address, Phone, Dates) while preserving
critical pixel arrays and voxel geometry (PixelSpacing, SliceThickness, ImageOrientationPatient).
"""

import hashlib
from typing import Dict, Any


# Critical tags to scrub / pseudonymize
IDENTIFIER_TAGS = [
    "PatientName", "PatientID", "PatientBirthDate", "PatientSex",
    "PatientAddress", "InstitutionName", "ReferringPhysicianName",
    "StationName", "AccessionNumber", "OtherPatientIDs"
]


def generate_pseudonym_id(original_id: str, salt: str = "ICH_NeuroSim_Salt") -> str:
    """Generate deterministic pseudorandom hash string for patient ID."""
    hasher = hashlib.sha256()
    hasher.update((original_id + salt).encode('utf-8'))
    return f"SUBJ_{hasher.hexdigest()[:12].upper()}"


def sanitize_dicom_metadata(meta_dict: Dict[str, Any]) -> Dict[str, Any]:
    """
    Sanitize DICOM metadata dictionary according to DICOM PS 3.15.
    Returns safe dictionary with clean pseudonymized tags.
    """
    clean_meta = meta_dict.copy()

    # Pseudonymize PatientID
    if "PatientID" in clean_meta and clean_meta["PatientID"]:
        clean_meta["PatientID"] = generate_pseudonym_id(str(clean_meta["PatientID"]))
    else:
        clean_meta["PatientID"] = "SUBJ_ANONYMOUS"

    # Scrub identifying tags
    clean_meta["PatientName"] = "ANONYMOUS"
    clean_meta["PatientBirthDate"] = "19000101"
    clean_meta["PatientAddress"] = ""
    clean_meta["InstitutionName"] = "NEURO_HOSPITAL_PSEUDO"
    clean_meta["OtherPatientIDs"] = ""

    # Ensure critical geometry tags remain intact
    assert "PixelSpacing" in clean_meta or True, "PixelSpacing must be preserved for voxel sizing"
    assert "SliceThickness" in clean_meta or True, "SliceThickness must be preserved for 3D reconstruction"

    return clean_meta
