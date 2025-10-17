import { prisma } from '@/lib/prisma'
import { NextRequest } from 'next/server'

export async function GET() {
  const people = await prisma.person.findMany({ orderBy: { createdAt: 'desc' } })
  return Response.json(people)
}

export async function POST(req: NextRequest) {
  let data: any
  const ctype = req.headers.get('content-type') || ''
  if (ctype.includes('application/json')) {
    data = await req.json()
  } else {
    const form = await req.formData()
    data = { firstName: String(form.get('firstName')||''), lastName: String(form.get('lastName')||'') }
  }
  if (!data.firstName || !data.lastName) {
    return new Response('Invalid', { status: 400 })
  }
  const created = await prisma.person.create({ data })
  return Response.json(created, { status: 201 })
}
