# Galileo HAS MATLAB — Orbit and Clock Correction Module

Implementation of the Orbit and Clock Correction module for the Galileo High Accuracy Service (HAS), responsible for generating corrected SP3 products by applying HAS orbit and clock corrections to broadcast ephemerides.

This module processes HAS corrections and produces refined satellite orbit and clock information suitable for Precise Point Positioning (PPP) applications.

## Project Overview

This project implements a MATLAB-based toolchain for applying Galileo High Accuracy Service (HAS) orbit and clock corrections to GNSS broadcast navigation data.

The module is part of a broader workflow aimed at evaluating HAS performance, where:

* HAS corrections are decoded and pre-processed
* Orbit and clock corrections are applied to broadcast ephemerides (this module)
* Corrected SP3 products are generated
* Code bias corrections are applied to RINEX observations (separate module)
* Corrected products are used for PPP positioning analysis

This repository focuses specifically on the generation of HAS-corrected SP3 orbit and clock products.

The implementation supports:

* Multi-GNSS processing (Galileo and GPS)
* Application of HAS orbit and clock corrections
* Generation of SP3 files with BRDC + HAS data

## Algorithm / Processing Logic

The orbit and clock correction module performs the following steps:

* Read broadcast ephemerides (BRDC) for GNSS satellites
* Read precise orbit reference (SP3 CNES)
* Read HAS corrections (orbit and clock CSV files)

For each epoch and satellite:
* Compute satellite position and velocity from broadcast ephemerides
* Build NTW reference frame (radial, along-track, cross-track)
* Apply HAS orbit corrections: Transform corrections from NTW to ECEF reference frame and add corrections to broadcast satellite position
* Apply HAS clock corrections: Combine broadcast clock with HAS clock correction and include relativistic effects and system-specific terms
* Convert APC (Antenna Phase Centre) to CoM (Center of Mass) using ANTEX data
* Compare corrected orbit and clock with precise SP3 reference (optional)
* Generate corrected SP3 file (BRDC + HAS)
* Save results and generate logs (availability, differences, etc.)

## Main Scripts

valHAS.m

Main processing script that:

* Loads input data (BRDC, SP3, HAS, DCB, ANTEX)
* Computes satellite position and velocity from broadcast ephemerides
* Applies HAS orbit and clock corrections
* Handles reference frame transformations (NTW ↔ ECEF)
* Generates corrected SP3 products
* Produces logs and optional analysis outputs

## Supporting Functions

Key functions used within the processing pipeline:

* becp.m → satellite position computation from broadcast ephemerides
* calcSSR_ECEF_mod.m → transformation between NTW and ECEF frames
* calc_APC2CoM_t_w.m → APC to CoM correction using ANTEX
* readATXoffsets.m → extraction of antenna offsets
* readSP3.m → reading precise orbit data
* readDCB.m → reading differential code bias data
* overwrite_SP3.m → writing corrected SP3 output
* SAT_disp.m → data selection and filtering
* Time conversion utilities (ToW_to_ToD, ToW_to_UTC, ToD_to_UTC)

## Usage Notes
* Input data must follow expected naming conventions (BRDC, SP3, HAS CSV, etc.)
* HAS corrections must be pre-decoded (e.g., using GHASP)
* Orbit corrections are applied in NTW frame and transformed to ECEF
* Clock corrections include system-specific adjustments (GPS and Galileo)
* Output SP3 files contain corrected satellite positions and clocks
* The workflow assumes familiarity with GNSS data processing

## Limitations
* The current implementation is validated but not fully optimized for external users
* Directory structure and file naming conventions must be respected
* Limited input validation and error handling
* Some assumptions are embedded in the workflow (e.g., signal combinations, data availability)
* Code structure can be further modularized and improved

## Author

* Developed by Francesco Marin
* Postgraduate Researcher — University of Padova
* Period: January 2022 – June 2024

# Galileo-HAS-MATLAB — RINEX Code Bias Correction Module (HAS-CodeBias)

Implementation of MATLAB scripts for generating HAS-corrected RINEX observation files, applying Galileo High Accuracy Service (HAS) code bias corrections to raw GNSS measurements.

This module processes HAS corrections and produces corrected RINEX files suitable for Precise Point Positioning (PPP) applications.

## Project Overview

The Galileo High Accuracy Service (HAS) provides State Space Representation (SSR) corrections, including orbit, clock, and code bias corrections.

This repository implements the code bias correction stage of the HAS processing chain, focusing on:

* Reading HAS code bias corrections (CSV format)
* Applying corrections to RINEX pseudorange observations
* Generating corrected RINEX files for further positioning analysis

The implementation supports:

* Multi-GNSS processing (Galileo + GPS)
* Different signal combinations (e.g. I/NAV for Galileo, L/NAV for GPS)
* Integration with PPP workflows (e.g. Bernese GNSS Software)

This module is part of a larger processing chain including:

* HAS decoding (GHASP)
* HAS product generation (SP3, RINEX)
* PPP positioning and performance assessment
* Algorithm / Processing Logic

The HAS code bias correction workflow performs the following steps:

* Read input RINEX observation file
* Read HAS code bias corrections (CSV files)
* Identify satellites and signals present in the RINEX file
* Map RINEX observations to corresponding HAS signal indices

For each observation epoch:
* Identify the corresponding Time of Week (ToW)
* Search for the closest valid HAS correction
* Verify correction validity interval

Handle multiple or missing corrections:
* Select nearest valid correction
* Discard unavailable or invalid corrections

Apply HAS code bias correction to pseudorange:
* Corrected observation = original observation − code bias
* Generate corrected RINEX observation structure
* Write new RINEX file with HAS-corrected observations
* Repeat for all selected stations and constellations

## Main Scripts
HASCodeBiasCorr2RNX304.m

Main processing script that:

* Loads HAS code bias corrections (CSV format)
* Reads original RINEX observation files
* Applies code bias corrections to selected signals
* Handles time matching and validity checks
* Generates corrected RINEX files

rinex_cbHAS.m

Function responsible for:

* Writing corrected RINEX observation files
* Formatting output according to RINEX standards
* Managing observation fields and corrected values

## Usage Notes
* Input data must follow expected naming conventions (RINEX, HAS CSV, etc.)
* HAS corrections must be pre-decoded (e.g., using GHASP)
* Only code bias corrections are applied in this module
* Output RINEX files are renamed to distinguish HAS-corrected data
* The workflow assumes familiarity with GNSS data structures and formats

## Limitations
The current implementation is validated but not fully optimized for external users
Directory structure and file naming conventions must be respected
Limited input validation and error handling
Some assumptions are hard-coded (e.g., signal selection per station)
Code structure can be further modularized and simplified

## Author

* Developed by Francesco Marin
* Postgraduate Researcher — University of Padova
* Period: January 2022 – June 2024
