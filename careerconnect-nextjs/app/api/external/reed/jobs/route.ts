import { NextRequest, NextResponse } from "next/server";
import { getEnv } from "@/lib/env";

export async function GET(request: NextRequest) {
  try {
    const apiKey = getEnv("REED_API_KEY");
    if (!apiKey) {
      return NextResponse.json({ success: false, message: "REED_API_KEY tanımlı değil", data: [] }, { status: 400 });
    }

    const keywords = request.nextUrl.searchParams.get("keywords") || "software";
    const locationName = request.nextUrl.searchParams.get("location") || "London";
    const resultsToTake = request.nextUrl.searchParams.get("limit") || "20";

    const url = new URL("https://www.reed.co.uk/api/1.0/search");
    url.searchParams.set("keywords", keywords);
    url.searchParams.set("locationName", locationName);
    url.searchParams.set("resultsToTake", resultsToTake);

    const response = await fetch(url.toString(), {
      headers: {
        Accept: "application/json",
        Authorization: `Basic ${Buffer.from(`${apiKey}:`).toString("base64")}`
      },
      cache: "no-store"
    });

    const data = await response.json().catch(() => null);
    if (!response.ok) {
      return NextResponse.json({ success: false, message: `Reed API error: ${response.status}`, data }, { status: response.status });
    }

    return NextResponse.json({ success: true, message: "Success", data });
  } catch (error) {
    return NextResponse.json({ success: false, message: error instanceof Error ? error.message : "Unknown error", data: [] }, { status: 500 });
  }
}
