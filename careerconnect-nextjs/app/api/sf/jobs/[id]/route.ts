import { NextRequest, NextResponse } from "next/server";
import { salesforceApex } from "@/lib/salesforce";
import type { JobPosition, SalesforceApiResponse } from "@/lib/types";

export async function GET(_request: NextRequest, context: { params: Promise<{ id: string }> | { id: string } }) {
  try {
    const { id } = await context.params;
    const data = await salesforceApex<SalesforceApiResponse<JobPosition>>(`/careers/jobs/${encodeURIComponent(id)}`);
    return NextResponse.json(data, { status: data.statusCode || 200 });
  } catch (error) {
    return NextResponse.json({ success: false, message: error instanceof Error ? error.message : "Unknown error", data: null, statusCode: 500 }, { status: 500 });
  }
}
