import { NextRequest, NextResponse } from "next/server";
import { salesforceApex } from "@/lib/salesforce";
import type { JobPosition, SalesforceApiResponse } from "@/lib/types";

export async function GET(request: NextRequest) {
  try {
    const incoming = request.nextUrl.searchParams;
    const params = new URLSearchParams();
    for (const key of ["department", "type", "remote"]) {
      const value = incoming.get(key);
      if (value) params.set(key, value);
    }

    const query = params.toString();
    const data = await salesforceApex<SalesforceApiResponse<JobPosition[]>>(`/careers/jobs${query ? `?${query}` : ""}`);
    return NextResponse.json(data, { status: data.statusCode || 200 });
  } catch (error) {
    return NextResponse.json({ success: false, message: error instanceof Error ? error.message : "Unknown error", data: [], statusCode: 500 }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const data = await salesforceApex<SalesforceApiResponse<string>>("/careers/jobs", {
      method: "POST",
      body: JSON.stringify(body)
    });
    return NextResponse.json(data, { status: data.statusCode || 201 });
  } catch (error) {
    return NextResponse.json({ success: false, message: error instanceof Error ? error.message : "Unknown error", data: null, statusCode: 500 }, { status: 500 });
  }
}
