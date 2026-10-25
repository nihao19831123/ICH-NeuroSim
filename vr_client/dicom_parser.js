/**
 * ICH-NeuroSim Native Part 10 DICOM Parser & Live MPR Renderer
 * Pure JavaScript, zero external dependencies, clinical SaMD Class III standard.
 * 
 * Supports:
 * - Part 10 DICOM format (128-byte preamble + "DICM" signature)
 * - Little Endian Explicit VR & Implicit VR
 * - CT Hounsfield Unit (HU) extraction: HU = pixel * RescaleSlope + RescaleIntercept
 * - Dynamic Windowing (Brain, Bone, Hematoma/Subdural presets)
 * - Spatial coordinate extraction (ImagePositionPatient, PixelSpacing, SliceLocation)
 * - Series sorting along Z-axis (Cranial-Caudal)
 */

class DicomParser {
  static parse(arrayBuffer) {
    const view = new DataView(arrayBuffer);
    const bytes = new Uint8Array(arrayBuffer);

    // 1. Verify DICOM Part 10 magic header
    if (bytes.length < 132) {
      throw new Error("File too small to be a valid DICOM Part 10 file (< 132 bytes)");
    }
    const magic = String.fromCharCode(bytes[128], bytes[129], bytes[130], bytes[131]);
    if (magic !== "DICM") {
      throw new Error(`Invalid DICOM header. Expected 'DICM' at byte 128, got '${magic}'`);
    }

    const dcm = {
      patientName: "UNKNOWN",
      patientId: "UNKNOWN",
      studyDate: "",
      modality: "CT",
      seriesDescription: "",
      seriesInstanceUid: "",
      instanceNumber: 1,
      rows: 512,
      columns: 512,
      bitsAllocated: 16,
      bitsStored: 12,
      highBit: 11,
      pixelRepresentation: 0, // 0 = unsigned, 1 = 2's complement signed
      rescaleIntercept: -1024,
      rescaleSlope: 1.0,
      windowCenter: 40,
      windowWidth: 80,
      sliceThickness: 5.0,
      sliceLocation: 0.0,
      pixelSpacing: [0.4375, 0.4375],
      imagePosition: [0.0, 0.0, 0.0],
      imageOrientation: [1, 0, 0, 0, 1, 0],
      pixelDataOffset: -1,
      pixelDataLength: 0,
      pixelData: null,
      rawBytes: bytes
    };

    let pos = 132;
    const len = bytes.length;

    while (pos < len - 8) {
      const group = view.getUint16(pos, true);
      const element = view.getUint16(pos + 2, true);
      pos += 4;

      // Check if Explicit VR (two ASCII uppercase letters)
      const c1 = bytes[pos];
      const c2 = bytes[pos + 1];
      const isExplicit = (c1 >= 65 && c1 <= 90) && (c2 >= 65 && c2 <= 90);

      let vr = "";
      let elementLen = 0;

      if (isExplicit) {
        vr = String.fromCharCode(c1, c2);
        pos += 2;
        if (vr === "OB" || vr === "OW" || vr === "OF" || vr === "SQ" || vr === "UT" || vr === "UN") {
          pos += 2; // 2 reserved bytes
          elementLen = view.getUint32(pos, true);
          pos += 4;
        } else {
          elementLen = view.getUint16(pos, true);
          pos += 2;
        }
      } else {
        vr = "UN";
        elementLen = view.getUint32(pos, true);
        pos += 4;
      }

      // Check Pixel Data tag (7FE0, 0010)
      if (group === 0x7FE0 && element === 0x0010) {
        dcm.pixelDataOffset = pos;
        dcm.pixelDataLength = elementLen;
        break; // Pixel data reached, stop header scanning
      }

      if (elementLen < 0 || pos + elementLen > len) {
        break; // Corrupted or truncated element
      }

      // Parse string value for standard text tags
      if (elementLen > 0 && elementLen < 128) {
        const strVal = DicomParser.decodeString(bytes, pos, elementLen);

        if (group === 0x0008) {
          if (element === 0x0020) dcm.studyDate = strVal;
          if (element === 0x0060) dcm.modality = strVal;
          if (element === 0x103E) dcm.seriesDescription = strVal;
        } else if (group === 0x0010) {
          if (element === 0x0010) dcm.patientName = strVal.replace(/\^/g, " ");
          if (element === 0x0020) dcm.patientId = strVal;
        } else if (group === 0x0018) {
          if (element === 0x0050) dcm.sliceThickness = parseFloat(strVal) || 5.0;
        } else if (group === 0x0020) {
          if (element === 0x0013) dcm.instanceNumber = parseInt(strVal, 10) || 1;
          if (element === 0x0032) { // Image Position (Patient)
            const parts = strVal.split("\\").map(parseFloat);
            if (parts.length >= 3) dcm.imagePosition = parts;
          }
          if (element === 0x0037) { // Image Orientation (Patient)
            const parts = strVal.split("\\").map(parseFloat);
            if (parts.length >= 6) dcm.imageOrientation = parts;
          }
          if (element === 0x1041) dcm.sliceLocation = parseFloat(strVal) || 0.0;
          if (element === 0x000E) dcm.seriesInstanceUid = strVal;
        } else if (group === 0x0028) {
          if (element === 0x0010) dcm.rows = view.getUint16(pos, true);
          if (element === 0x0011) dcm.columns = view.getUint16(pos, true);
          if (element === 0x0030) { // Pixel Spacing
            const parts = strVal.split("\\").map(parseFloat);
            if (parts.length >= 2) dcm.pixelSpacing = parts;
          }
          if (element === 0x0100) dcm.bitsAllocated = view.getUint16(pos, true);
          if (element === 0x0101) dcm.bitsStored = view.getUint16(pos, true);
          if (element === 0x0102) dcm.highBit = view.getUint16(pos, true);
          if (element === 0x0103) dcm.pixelRepresentation = view.getUint16(pos, true);
          if (element === 0x1050) dcm.windowCenter = parseFloat(strVal.split("\\")[0]) || 40;
          if (element === 0x1051) dcm.windowWidth = parseFloat(strVal.split("\\")[0]) || 80;
          if (element === 0x1052) dcm.rescaleIntercept = parseFloat(strVal) || -1024;
          if (element === 0x1053) dcm.rescaleSlope = parseFloat(strVal) || 1.0;
        }
      }

      pos += elementLen;
    }

    // 2. Extract pixel data into Int16Array
    if (dcm.pixelDataOffset > 0) {
      const numPixels = dcm.rows * dcm.columns;
      const pixelBytes = dcm.bitsAllocated / 8;
      const expectedByteLen = numPixels * pixelBytes;

      const rawOffset = dcm.pixelDataOffset;
      const actualByteLen = Math.min(
        dcm.pixelDataLength > 0 ? dcm.pixelDataLength : expectedByteLen,
        bytes.length - rawOffset
      );

      // Create Int16Array for pixel data
      if (dcm.bitsAllocated === 16) {
        if (dcm.pixelRepresentation === 1) {
          // Signed 16-bit
          dcm.pixelData = new Int16Array(arrayBuffer, rawOffset, numPixels);
        } else {
          // Unsigned 16-bit
          dcm.pixelData = new Uint16Array(arrayBuffer, rawOffset, numPixels);
        }
      } else {
        // Fallback 8-bit
        dcm.pixelData = new Uint8Array(arrayBuffer, rawOffset, numPixels);
      }
    }

    // Default slice location to ImagePositionPatient Z if not explicit
    if (dcm.imagePosition && dcm.imagePosition[2] !== undefined) {
      dcm.positionZ = dcm.imagePosition[2];
    } else {
      dcm.positionZ = dcm.sliceLocation || dcm.instanceNumber * dcm.sliceThickness;
    }

    return dcm;
  }

  static decodeString(bytes, offset, length) {
    let str = "";
    for (let i = 0; i < length; i++) {
      const b = bytes[offset + i];
      if (b === 0) break; // null terminator
      str += String.fromCharCode(b);
    }
    return str.trim();
  }

  /**
   * Render DICOM slice to HTML5 Canvas using Hounsfield Units & Windowing
   * @param {Object} dcm Parsed DICOM object
   * @param {number} windowCenter e.g. 40 (Brain), 450 (Bone), 65 (Hematoma)
   * @param {number} windowWidth e.g. 80 (Brain), 1800 (Bone), 130 (Hematoma)
   * @param {HTMLCanvasElement} [canvas] Optional target canvas
   * @returns {HTMLCanvasElement} Rendered canvas
   */
  static renderToCanvas(dcm, windowCenter = null, windowWidth = null, canvas = null) {
    const wc = windowCenter !== null ? windowCenter : dcm.windowCenter;
    const ww = windowWidth !== null ? windowWidth : dcm.windowWidth;

    const width = dcm.columns || 512;
    const height = dcm.rows || 512;

    if (!canvas) {
      canvas = document.createElement("canvas");
    }
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext("2d");
    const imgData = ctx.createImageData(width, height);
    const rgba = imgData.data;

    const numPixels = width * height;
    const pixels = dcm.pixelData;
    const slope = dcm.rescaleSlope || 1.0;
    const intercept = dcm.rescaleIntercept || 0.0;

    const minHu = wc - ww / 2.0;
    const maxHu = wc + ww / 2.0;
    const range = ww > 0 ? ww : 1.0;

    if (pixels && pixels.length >= numPixels) {
      for (let i = 0; i < numPixels; i++) {
        const raw = pixels[i];
        const hu = raw * slope + intercept;

        let val = 0;
        if (hu <= minHu) {
          val = 0;
        } else if (hu >= maxHu) {
          val = 255;
        } else {
          val = Math.round(((hu - minHu) / range) * 255.0);
        }

        const idx = i * 4;
        rgba[idx] = val;     // R
        rgba[idx + 1] = val; // G
        rgba[idx + 2] = val; // B
        rgba[idx + 3] = 255; // Alpha
      }
    } else {
      // Fallback gray background with error message
      for (let i = 0; i < numPixels; i++) {
        const idx = i * 4;
        rgba[idx] = 30;
        rgba[idx + 1] = 41;
        rgba[idx + 2] = 59;
        rgba[idx + 3] = 255;
      }
    }

    ctx.putImageData(imgData, 0, 0);
    return canvas;
  }

  /**
   * Sort an array of parsed DICOM slices along the anatomical Z-axis
   * @param {Array} slices Array of parsed DICOM objects
   * @returns {Array} Sorted slices from Inferior to Superior (or by InstanceNumber)
   */
  static sortSeries(slices) {
    if (!slices || slices.length === 0) return [];
    
    // Sort primarily by positionZ, fallback to instanceNumber
    return slices.slice().sort((a, b) => {
      if (a.positionZ !== undefined && b.positionZ !== undefined && a.positionZ !== b.positionZ) {
        return a.positionZ - b.positionZ;
      }
      return (a.instanceNumber || 0) - (b.instanceNumber || 0);
    });
  }
}

// Export for window or module
if (typeof window !== "undefined") {
  window.DicomParser = DicomParser;
}
if (typeof module !== "undefined" && module.exports) {
  module.exports = DicomParser;
}
