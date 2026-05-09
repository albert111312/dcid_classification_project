# ==============================================================================
# DCID 2.0 Variable Summary and Operationalization Memo
# ==============================================================================

# This document serves two purposes:
# 1. Variable reference table for the DCID 2.0 dataset
# 2. Formal documentation of the dependent variable coding rule

# ==============================================================================
# PART 1: VARIABLE REFERENCE TABLE
# ==============================================================================
#
# | Variable                | Column | Values/Measurement                        | Role in Analysis    |
# |-------------------------|--------|-------------------------------------------|---------------------|
# | Cyber Incident Number   | A      | Numeric ID                                | Identifier (exclude)|
# | Dyad Pair               | B      | Combined COW codes                        | Identifier (exclude)|
# | State A                 | C      | COW country code                          | Identifier (exclude)|
# | State B                 | D      | COW country code                          | Identifier (exclude)|
# | Incident Name           | E      | Text                                      | Identifier (exclude)|
# | Start Date              | F      | Date (Excel serial)                       | Excluded            |
# | End Date                | G      | Date (Excel serial)                       | Excluded            |
# | Method of Interaction   | H      | 1=Vandalism, 2=DoS, 3=Intrusion, 4=Infil | PREDICTOR           |
# | Target Type             | I      | 1=Private, 2=Govt Non-Mil, 3=Govt Mil     | DV COMPONENT        |
# | Initiator               | J      | COW country code                          | Excluded            |
# | Coercive Objective      | K      | 1=Disruption, 2=ST Esp, 3=LT Esp, 4=Deg  | DV COMPONENT        |
# | CIO                     | L      | 0=Absent, 1=Present                       | DV COMPONENT        |
# | Objective Achievement   | M      | 0=No, 1=Yes                               | PREDICTOR           |
# | Concessionary Change    | N      | 0=No, 1=Yes                               | PREDICTOR           |
# | Third Party Involvement | O      | 0=No, 1=Yes                               | PREDICTOR           |
# | Severity                | P      | Ordinal 0-10                              | DV COMPONENT        |
# | Damage Type             | Q      | 1=Dir/Imm, 2=Dir/Del, 3=Ind/Imm, 4=Ind/D | PREDICTOR           |
# | Critical Infrastructure | R      | 1-17 sector codes                         | PREDICTOR           |
# | Supply Chain            | S      | 0=No, 1=Yes                               | PREDICTOR           |
# | Ransomware              | T      | 0=No, 1=Yes                               | PREDICTOR           |
# | Political Objective     | U      | Text                                      | Excluded (text)     |
# | Sources 1-5             | V-Z    | URLs                                      | Excluded            |
# | Justice                 | AA     | Indicator                                 | Excluded            |
# | Cert                    | AB     | Indicator                                 | Excluded            |
# | FBI                     | AC     | Indicator                                 | Excluded            |
#
# ==============================================================================
# PART 2: DEPENDENT VARIABLE OPERATIONALIZATION
# ==============================================================================
#
# CONCEPT:
#   Strategic cyber operations = cyber incidents intended to advance a
#   nation's political objectives through sophisticated, sustained, or
#   destructive means against state-level targets.
#
#   Tactical cyber activity = cyber activity resembling criminal behavior
#   patterns: opportunistic, lower-impact, short-term, and/or targeting
#   private entities without clear political-strategic purpose.
#
# CODING RULE:
#   An incident is STRATEGIC (cyber_type = 1) if it meets TWO OR MORE of:
#     (a) Severity >= 4
#     (b) Coercive objective = 3 (long-term espionage) or 4 (degradation)
#     (c) Target type = 2 (govt non-military) or 3 (govt military)
#     (d) Cyber-enabled information operation = 1 (present)
#
#   Otherwise, the incident is TACTICAL (cyber_type = 0).
#
# RATIONALE:
#   Each indicator captures a distinct dimension of strategic intent:
#     - Severity: operational sophistication and impact
#       (Valeriano, Jensen, & Maness, 2018)
#     - Coercive objective: political purpose and time horizon
#       (Valeriano et al., 2018; DCID codebook)
#     - Target type: state vs. private sector targeting
#       (Peter & Ohakpougwu, 2024)
#     - CIO: information warfare intent
#       (Nakasone, 2019; DCID codebook)
#
#   Requiring >= 2 indicators prevents any single variable from driving
#   the classification and avoids arbitrary weighting schemes.
#
# RESULTING DISTRIBUTION (N = 429):
#   Strategic: 221 (51.5%)
#   Tactical:  208 (48.5%)
#
# VALIDATION (benchmark cases):
#   Stuxnet_A            -> STRATEGIC (3 indicators: severity, objective, target)
#   SUNBURST             -> STRATEGIC (2 indicators: severity, objective)
#   Sony Hack            -> STRATEGIC (4 indicators: all four)
#   NotPetya_A           -> STRATEGIC (2 indicators: severity, objective)
#   WannaCry             -> STRATEGIC (2 indicators: severity, objective)
#   Operation Ababil     -> TACTICAL  (1 indicator: CIO only)
#   GitHub Hack          -> TACTICAL  (1 indicator: severity only)
#   Yahoo breach 1       -> TACTICAL  (1 indicator: objective only)
#
# DATA LEAKAGE NOTE:
#   Because the four indicator variables (severity, cyber_objective,
#   target_type, info_operation) are used to CONSTRUCT the DV, they
#   are NOT used as predictors. The analysis uses only the remaining
#   variables as features.
#
# ==============================================================================
# PART 3: PREDICTOR VARIABLES (strict leakage prevention)
# ==============================================================================
#
# The following variables are used as predictors:
#   1. method_f          — Method of interaction (4-level factor)
#   2. obj_achievement   — Whether objective was achieved (binary)
#   3. concession        — Concessionary behavioral change (binary)
#   4. third_party       — Third party involvement (binary)
#   5. damage_type_f     — Damage type (4-level factor)
#   6. crit_infra_f      — Critical infrastructure sector (17-level factor)
#   7. supply_chain      — Supply chain breach (binary)
#   8. ransomware        — Ransomware present (binary)
#
# Total: 8 predictor variables
# ==============================================================================
