# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

class MemberPaymentStatusJob < RecurringJob
  private

  def perform_internal
    # Archivierte und geloeschte Ortsgruppen werden nicht mehr gezaehlt (Nutzerentscheidung 2026-11-19);
    # bestehende Werte bleiben unveraendert.
    Group::Ortsgruppe.without_archived_or_deleted.find_each do |group|
      Groups::MemberPaymentStatus.new(group).update
    end
  end

  def next_run
    # Naechster Lauf am Stichtag 01.09., 05:00 in Time.zone (Fachentscheidung, vorher 31.08.).
    # Vor 05:00 am 01.09. ist das der heutige Tag, danach der 01.09. des Folgejahres.
    now = Time.zone.now
    run = Time.zone.local(now.year, 9, 1, 5, 0)
    run > now ? run : run.next_year
  end
end
