
"use server"

import { getEmployerKeywords } from "@/lib/database";
import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
    try {
        const employerid = request.nextUrl.searchParams.get("employerid");
        if (!employerid) {
            return NextResponse.json({ error: "Employer ID is required" }, { status: 400 });
        }
        
        const results = await getEmployerKeywords(employerid);
        return NextResponse.json(results);
    } catch (error) {
        console.error('API employer keywords error:', error);
        return NextResponse.json(
            { error: "Database connection failed" }, 
            { status: 500 }
        );
    }
}

