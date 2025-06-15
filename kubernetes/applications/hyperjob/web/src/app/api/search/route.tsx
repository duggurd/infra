"use server"

import { search } from "@/lib/database";
import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
    try {
        const query = request.nextUrl.searchParams.get("query");
        if (!query) {
            return NextResponse.json({ error: "Query is required" }, { status: 400 });
        }
        
        const results = await search(query);
        return NextResponse.json(results);
    } catch (error) {
        console.error('API search error:', error);
        return NextResponse.json(
            { error: "Database connection failed" }, 
            { status: 500 }
        );
    }
}

