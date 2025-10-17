export const dynamic = 'force-dynamic'
import { prisma } from '@/lib/prisma'
export default async function PeoplePage() {
  const people = await prisma.person.findMany({ orderBy: { createdAt: 'desc' } })
  return (
    <main style={{padding:16}}>
      <h2>Patients ({people.length})</h2>
      <ul>
        {people.map(p => <li key={p.id}>{p.firstName} {p.lastName}</li>)}
      </ul>
      <form action="/api/people" method="post" style={{marginTop:16}}>
        <input name="firstName" placeholder="Prénom" required />
        <input name="lastName" placeholder="Nom" required style={{marginLeft:8}}/>
        <button type="submit" style={{marginLeft:8}}>Ajouter</button>
      </form>
    </main>
  )
}
