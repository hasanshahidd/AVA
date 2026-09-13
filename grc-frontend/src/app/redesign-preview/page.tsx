'use client';

// Throwaway preview route to view the Compliance Assessments redesign on sample
// data, outside the dashboard layout (no app sidebar/auth). Delete once wired.
import ComplianceAssessmentsModule from '@/components/compliance/_redesign/ComplianceAssessmentsModule';

export default function RedesignPreviewPage() {
  return <ComplianceAssessmentsModule />;
}
