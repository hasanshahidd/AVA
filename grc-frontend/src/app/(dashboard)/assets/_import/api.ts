// Client for the smart asset-import wizard (isolated). Reuses the configured
// axios instance so auth + baseURL are inherited. Backend: grc/modules/asset_import.
import apiClient from '@/lib/api';

export type MappingSuggestion = { field: string | null; confidence: number; why: string };

export type AnalyzeResult = {
  filename: string;
  header_row: number;
  columns: string[];
  row_count: number;
  sample_rows: Record<string, unknown>[];
  suggested_mapping: Record<string, MappingSuggestion>;
  canonical_fields: { key: string; label: string; required: boolean }[];
};

export type CommitResult = {
  created: number;
  updated: number;
  skipped: number;
  errors: string[];
  total_errors: number;
  row_count: number;
  batch_id: string;
  message: string;
};

export type CommitOptions = { dupe_strategy: 'skip' | 'update'; header_row?: number };

const MULTIPART = { headers: { 'Content-Type': 'multipart/form-data' } };

export const assetImportApi = {
  analyze: (file: File) => {
    const fd = new FormData();
    fd.append('file', file);
    return apiClient.post<AnalyzeResult>('/asset-import/analyze', fd, MULTIPART);
  },
  commit: (file: File, mapping: Record<string, string | null>, options: CommitOptions) => {
    const fd = new FormData();
    fd.append('file', file);
    fd.append('mapping', JSON.stringify(mapping));
    fd.append('options', JSON.stringify(options));
    return apiClient.post<CommitResult>('/asset-import/commit', fd, MULTIPART);
  },
  undo: (batchId: string) =>
    apiClient.post<{ deleted: number; failed: number; batch_id: string; message: string }>(
      `/asset-import/undo/${batchId}`,
    ),
};
