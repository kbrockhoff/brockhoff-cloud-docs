# Security Controls Documentation

**Framework:** ${framework_name}  
**Module:** ${module_name}  
**Cloud Provider:** ${upper(cloud_provider)}  
**Assessment Date:** ${assessment_date}  
**Framework Reference:** [${framework_name}](${framework_url})

## Overview

This document provides detailed information about the security controls implemented by this Terraform module according to the ${framework_name} security pillar requirements.

## Security Controls Summary

| Control ID | Title | Status | Implementation |
|------------|-------|--------|----------------|
%{ for control_id, control in security_controls ~}
| ${control_id} | ${control.title} | ${control.implemented ? "✅ Implemented" : "❌ Not Implemented"} | ${control.implementation} |
%{ endfor ~}

## Detailed Control Information

%{ for control_id, control in security_controls ~}
### ${control_id}: ${control.title}

**Implementation Status:** ${control.implemented ? "✅ Implemented" : "❌ Not Implemented"}

**Description:** ${control.implementation}

**Evidence Required:**
%{ for field in control.evidence_required ~}
- `${field}`
%{ endfor ~}

**Validation Checks:**
%{ for check in control.validation_checks ~}
- ${check}
%{ endfor ~}

%{ if !control.implemented ~}
**Remediation Required:**
This control is not currently implemented. To achieve compliance:
1. Implement the required security measures as described above
2. Ensure all evidence fields are properly configured
3. Verify that validation checks pass
4. Re-run compliance assessment to confirm implementation

%{ endif ~}
---

%{ endfor ~}

## Compliance Notes

- This documentation is automatically generated based on the current module configuration
- Security controls should be regularly reviewed and updated as requirements evolve
- For production environments, all security controls should be implemented and validated
- Additional security measures may be required based on specific organizational policies

## Next Steps

1. **Review Implementation Status:** Ensure all required security controls are implemented
2. **Validate Configuration:** Run compliance assessment to verify current status
3. **Address Gaps:** Implement any missing security controls identified above
4. **Monitor Compliance:** Set up regular compliance assessments and monitoring
5. **Document Exceptions:** Any accepted risks or control exceptions should be formally documented

## References

- [${framework_name}](${framework_url})
- Module compliance assessment results
- Organizational security policies and standards

---

*This document was automatically generated on ${assessment_date}*