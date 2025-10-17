import Link from 'next/link'
export default function Home() {
  return (
    <main style={{padding:16}}>
      <h1>TappPlus — Next.js + SQLite (Docker)</h1>
      <ul>
        <li><Link href="/people">Gestion des patients</Link></li>
        <li><Link href="/api/health">/api/health</Link></li>
      </ul>
    </main>
  )
}
