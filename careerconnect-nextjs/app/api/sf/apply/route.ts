import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { salesforceApex } from "@/lib/salesforce";
import type { SalesforceApiResponse } from "@/lib/types";

const applySchema = z.object({
  jobPositionId: z.string().min(15),
  candidateProfileId: z.string().optional(),
  coverLetter: z.string().max(32768).optional(),
  yearsOfExperience: z.coerce.number().int().min(0).max(80).optional(),
  expectedSalary: z.coerce.number().min(0).optional(),
  cvFileId: z.string().optional(),
  linkedInUrl: z.string().url().optional().or(z.literal("")),
  email: z.string().email(),
  phone: z.string().optional()
});

export async function POST(request: NextRequest) {
  try {
    const parsed = applySchema.parse(await request.json());
    const data = await salesforceApex<SalesforceApiResponse<string>>("/careers/apply", {
      method: "POST",
      body: JSON.stringify(parsed)
    });
    return NextResponse.json(data, { status: data.statusCode || 201 });
  } catch (error) {
    return NextResponse.json({ success: false, message: error instanceof Error ? error.message : "Başvuru gönderilemedi", data: null, statusCode: 400 }, { status: 400 });
  }
}
