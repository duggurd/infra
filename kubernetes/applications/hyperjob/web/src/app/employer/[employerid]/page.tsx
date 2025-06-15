"use client"

import { useState, useEffect } from "react";
import { Employer, getEmployer, getEmployerKeywords, KeywordCounts } from "@/lib/database";



export default function EmployerPage({ params }: { params: { employerid: string } }) {
    const [employer, setEmployer] = useState<Employer | null>(null);
    const [keywords, setKeywords] = useState<KeywordCounts[]>([]);

    useEffect(() => {
        const fetchEmployer = async () => {
            const employer = await getEmployer(params.employerid);
            setEmployer(employer);
        };

        const fetchKeywords = async () => {
            const keywords = await getEmployerKeywords(params.employerid);
            setKeywords(keywords);
        };

        fetchEmployer();
        fetchKeywords();
    }, [params.employerid]);

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