export type SalesforceApiResponse<T> = {
  success: boolean;
  message: string;
  data: T;
  statusCode: number;
};

export type JobPosition = {
  id: string;
  title: string;
  department?: string;
  location?: string;
  employmentType?: string;
  salaryRange?: string;
  description?: string;
  requirements?: string;
  status?: string;
  remoteEligible?: boolean;
  deadline?: string;
  postedDate?: string;
  applicationCount?: number;
  maxApplicants?: number;
};

export type ApplicationRequest = {
  jobPositionId: string;
  candidateProfileId?: string;
  coverLetter?: string;
  yearsOfExperience?: number;
  expectedSalary?: number;
  cvFileId?: string;
  linkedInUrl?: string;
  email: string;
  phone?: string;
};

export type ApplicationSummary = {
  id: string;
  applicationNumber: string;
  jobTitle: string;
  status: string;
  submittedDate?: string;
  score?: number;
  rejectionReason?: string;
};

export type ExternalReedJob = {
  jobId: string;
  jobTitle: string;
  employerName?: string;
  locationName?: string;
  minimumSalary?: string;
  maximumSalary?: string;
  jobDescription?: string;
  jobUrl?: string;
  contractType?: string;
  postedDate?: string;
};
