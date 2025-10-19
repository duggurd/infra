"use client"

import { useState, useEffect, use } from "react";
import { Employer, KeywordCounts } from "@/lib/database";

export default function EmployerPage({ params }: { params: Promise<{ employerid: string }> }) {
    const [employer, setEmployer] = useState<Employer | null>(null);
    const [keywords, setKeywords] = useState<KeywordCounts[]>([]);
    
    // Unwrap the params Promise
    const resolvedParams = use(params);

    useEffect(() => {
        const fetchEmployer = async () => {
            const employer = await fetch(`/api/employer?employerid=${resolvedParams.employerid}`).then(res => res.json());
            setEmployer(employer);
        };

        const fetchKeywords = async () => {
            const keywords = await fetch(`/api/employer/keywords?employerid=${resolvedParams.employerid}`).then(res => res.json());
            setKeywords(keywords);
        };

        fetchEmployer();
        fetchKeywords();
    }, [resolvedParams.employerid]);

    return (
        <div>
            <h1>{employer?.company_name}</h1>
            <p>{employer?.bransje}</p>
            <p>{employer?.sektor}</p>
            <h2>Keywords</h2>
            <ul>
                {keywords.map((keyword) => (
                    <li key={keyword.id}>{keyword.keyword}</li>
                ))}
            </ul>
        </div>
    );
}