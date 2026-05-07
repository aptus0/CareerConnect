import { NextRequest, NextResponse } from "next/server";
import { salesforceApex } from "@/lib/salesforce";
import type { SalesforceApiResponse } from "@/lib/types";

export async function POST(request: NextRequest) {
  try {
    const body = await request.json().catch(() => ({}));
    const data = await salesforceApex<SalesforceApiResponse<Record<string, number>>>("/careers/sync-external-jobs", {
      method: "POST",
      body: JSON.stringify({
        keywords: body.keywords || "software",
        location: body.location || "London"
      })
    });
    return NextResponse.json(data, { status: data.statusCode || 200 });
  } catch (error) {
    return NextResponse.json({ success: false, message: error instanceof Error ? error.message : "External sync failed", data: null, statusCode: 500 }, { status: 500 });
  }
}
