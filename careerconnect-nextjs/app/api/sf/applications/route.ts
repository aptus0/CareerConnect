import { NextResponse } from "next/server";
import { salesforceApex } from "@/lib/salesforce";
import type { ApplicationSummary, SalesforceApiResponse } from "@/lib/types";

export async function GET() {
  try {
    const data = await salesforceApex<SalesforceApiResponse<ApplicationSummary[]>>("/careers/applications");
    return NextResponse.json(data, { status: data.statusCode || 200 });
  } catch (error) {
    return NextResponse.json({ success: false, message: error instanceof Error ? error.message : "Unknown error", data: [], statusCode: 500 }, { status: 500 });
  }
}
