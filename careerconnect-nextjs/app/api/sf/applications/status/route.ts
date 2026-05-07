import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { salesforceApex } from "@/lib/salesforce";
import type { SalesforceApiResponse } from "@/lib/types";

const statusSchema = z.object({
  id: z.string().min(15),
  status: z.enum(["Submitted", "Under Review", "Interview Scheduled", "Technical Assessment", "Offer Extended", "Hired", "Rejected", "Withdrawn"]),
  rejectionReason: z.string().optional(),
  score: z.coerce.number().min(0).max(100).optional()
});

export async function PATCH(request: NextRequest) {
  try {
    const body = statusSchema.parse(await request.json());
    const data = await salesforceApex<SalesforceApiResponse<string>>("/careers/applications", {
      method: "PATCH",
      body: JSON.stringify(body)
    });
    return NextResponse.json(data, { status: data.statusCode || 200 });
  } catch (error) {
    return NextResponse.json({ success: false, message: error instanceof Error ? error.message : "Status güncellenemedi", data: null, statusCode: 400 }, { status: 400 });
  }
}
