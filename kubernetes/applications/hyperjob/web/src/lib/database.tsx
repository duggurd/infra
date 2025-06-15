"use server"

import { Client } from 'pg'

export async function connectToDatabase() {
    const client = new Client(
        {
            host: process.env.POSTGRES_HOST,
            port: parseInt(process.env.POSTGRES_PORT || '5432'),
            user: process.env.POSTGRES_USER,
            password: process.env.POSTGRES_PASSWORD,
            database: process.env.POSTGRES_DB
        }
    )


    await client.connect();

    return client;
}


export async function search(query: string) {
    const client = await connectToDatabase();

    const result = await client.query(`
        WITH search_results AS (
            (SELECT
                id,
                keyword as value,
                'keyword' as type
            FROM keywords
            WHERE keyword ILIKE '%${query}%'
            LIMIT 10)

            UNION

            (SELECT
                id,
                stillingsfunksjon as value,
                'function' as type
            FROM stillingsfunksjon
            WHERE stillingsfunksjon ILIKE '%${query}%'
            LIMIT 10)

            UNION

            (SELECT
                id,
                company_name as value,
                'employer' as type
            FROM employers
            WHERE company_name ILIKE '%${query}%'
            LIMIT 10)

            UNION

            (SELECT
                id,
                words as value,
                'phrase' as type
            FROM ngrams
            WHERE words ILIKE '%${query}%'
            LIMIT 10)
        )
        SELECT * FROM search_results
        ORDER BY id
        LIMIT 10
    `);

    return result.rows;
}