import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../common/prisma/prisma.service';
import { CreateConsultationDto } from './dto/create-consultation.dto';
import { UpdateConsultationDto } from './dto/update-consultation.dto';
import * as moment from 'moment-timezone';

@Injectable()
export class ConsultationsService {
  constructor(private prisma: PrismaService) {}

  /**
   * Transform attachments from JSON string to array (for SQLite compatibility)
   */
  private transformAttachments(consultation: any): any {
    if (consultation && consultation.attachments) {
      try {
        consultation.attachments = JSON.parse(consultation.attachments);
      } catch {
        consultation.attachments = [];
      }
    }
    return consultation;
  }

  /**
   * Transform multiple consultations
   */
  private transformMany(consultations: any[]): any[] {
    return consultations.map(c => this.transformAttachments(c));
  }

  async create(createConsultationDto: CreateConsultationDto) {
    const { dateTime, attachments, ...consultationData } = createConsultationDto;

    // Convertir la date en UTC
    const dateTimeUtc = moment.tz(dateTime, 'Africa/Douala').utc().toDate();

    // Vérifier que la personne et le médecin existent
    const [person, doctor] = await Promise.all([
      this.prisma.person.findUnique({ where: { id: createConsultationDto.personId } }),
      this.prisma.doctor.findUnique({ where: { id: createConsultationDto.doctorId } }),
    ]);

    if (!person) {
      throw new NotFoundException('Personne non trouvée');
    }

    if (!doctor) {
      throw new NotFoundException('Médecin non trouvé');
    }

    const consultation = await this.prisma.consultation.create({
      data: {
        ...consultationData,
        dateTimeUtc,
        // SQLite: Convert attachments array to JSON string
        attachments: attachments ? JSON.stringify(attachments) : null,
      },
      include: {
        person: true,
        doctor: {
          include: {
            user: true,
          },
        },
      },
    });

    return this.transformAttachments(consultation);
  }

  async findAll(filters: {
    personId?: string;
    doctorId?: string;
    from?: string;
    to?: string;
    status?: string;
  }) {
    const where: any = {};

    if (filters.personId) {
      where.personId = filters.personId;
    }

    if (filters.doctorId) {
      where.doctorId = filters.doctorId;
    }

    if (filters.status) {
      where.status = filters.status;
    }

    if (filters.from || filters.to) {
      where.dateTimeUtc = {};
      if (filters.from) {
        where.dateTimeUtc.gte = new Date(filters.from);
      }
      if (filters.to) {
        where.dateTimeUtc.lte = new Date(filters.to);
      }
    }

    const consultations = await this.prisma.consultation.findMany({
      where,
      include: {
        person: true,
        doctor: {
          include: {
            user: true,
          },
        },
      },
      orderBy: { dateTimeUtc: 'desc' },
    });

    return this.transformMany(consultations);
  }

  async findOne(id: string) {
    const consultation = await this.prisma.consultation.findUnique({
      where: { id },
      include: {
        person: true,
        doctor: {
          include: {
            user: true,
          },
        },
      },
    });

    if (!consultation) {
      throw new NotFoundException('Consultation non trouvée');
    }

    return this.transformAttachments(consultation);
  }

  async update(id: string, updateConsultationDto: UpdateConsultationDto) {
    const consultation = await this.findOne(id);

    const { dateTime, attachments, ...updateData } = updateConsultationDto;

    let dateTimeUtc = consultation.dateTimeUtc;

    if (dateTime) {
      dateTimeUtc = moment.tz(dateTime, 'Africa/Douala').utc().toDate();
    }

    const updated = await this.prisma.consultation.update({
      where: { id },
      data: {
        ...updateData,
        dateTimeUtc,
        // SQLite: Convert attachments array to JSON string if provided
        ...(attachments !== undefined && { attachments: attachments ? JSON.stringify(attachments) : null }),
      },
      include: {
        person: true,
        doctor: {
          include: {
            user: true,
          },
        },
      },
    });

    return this.transformAttachments(updated);
  }

  async remove(id: string) {
    const consultation = await this.findOne(id);

    await this.prisma.consultation.delete({
      where: { id },
    });

    return { message: 'Consultation supprimée avec succès' };
  }

  async getPatientHistory(personId: string, doctorId?: string) {
    const where: any = { personId };

    if (doctorId) {
      where.doctorId = doctorId;
    }

    const consultations = await this.prisma.consultation.findMany({
      where,
      include: {
        doctor: {
          include: {
            user: true,
          },
        },
      },
      orderBy: { dateTimeUtc: 'desc' },
    });

    return this.transformMany(consultations);
  }
}
