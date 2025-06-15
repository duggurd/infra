"use server"

import { Client, Pool } from 'pg'

const pool = new Pool({
    host: process.env.POSTGRES_HOST,
    port: parseInt(process.env.POSTGRES_PORT || '5432'),
    user: process.env.POSTGRES_USER,
    password: process.env.POSTGRES_PASSWORD,
    database: process.env.POSTGRES_DB,
    max: 10,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 10000,
})

export async function connectToDatabase() {
    const client = await pool.connect();
    return client;
}

export async function search(query: string) {
    let client;
    
    try {
        client = await connectToDatabase();
        
        const result = await client.query(`
            WITH search_results AS (
                (SELECT
                    id,
                    keyword as value,
                    'keyword' as type
                FROM keywords
                WHERE keyword ILIKE $1 and id is not null
                LIMIT 10)

                UNION

                (SELECT
                    id,
                    stillingsfunksjon as value,
                    'function' as type
                FROM stillingsfunksjon
                WHERE stillingsfunksjon ILIKE $1 and id is not null
                LIMIT 10)

                UNION

                (SELECT
                    id,
                    company_name as value,
                    'employer' as type
                FROM employers
                WHERE company_name ILIKE $1 and id is not null
                LIMIT 10)

                UNION

                (SELECT
                    id,
                    words as value,
                    'phrase' as type
                FROM ngrams
                WHERE words ILIKE $1 and id is not null
                LIMIT 10)
            )
            SELECT * FROM search_results
            ORDER BY id
            LIMIT 10
        `, [`%${query}%`]);

        return result.rows;
    } catch (error) {
        console.error('Database search error:', error);
        throw error;
    } finally {
        if (client) {
            client.release();
        }
    }
}


export interface Employer {
    id: string;
    company_name: string;
    bransje: string;
    sektor: string;
}

export async function getEmployer(employerid: string): Promise<Employer> {
    let client;

    try {
        client = await connectToDatabase();

        const result = await client.query(`
            SELECT * FROM employers
            WHERE id = $1
        `, [employerid]);

        return result.rows[0];
    } catch (error) {
        console.error('Database error:', error);
        throw error;
    } finally {
        if (client) {
            client.release();
        }
    }
}



export interface KeywordCounts {
    count: number;
    id: string;
    keyword: string;
}

export async function getEmployerKeywords(employerid: string): Promise<KeywordCounts[]> {
    let client;

    try {
        client = await connectToDatabase();

        const result = await client.query(`
            SELECT 
                COUNT(*) as count,
                k.id,
                k.keyword

            FROM ads_with_id

            INNER JOIN keyword_ads_bridge as kab
                ON ads_with_id.keyword_bridge_id = kab.id

            INNER JOIN keywords as k
                on kab.keyword_id = k.id

            WHERE ads_with_id.employer_id = $1
            GROUP BY k.id
            ORDER BY COUNT(*) DESC
            LIMIT 10
        `, [employerid]);

        return result.rows;
    } catch (error) {
        console.error('Database error:', error);
        throw error;
    } finally {
        if (client) {
            client.release();
        }
    }
}   