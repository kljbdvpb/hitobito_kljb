# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

# Trockenlauf fuer People::CleanupJob (nur lesend): zaehlt die Kandidaten des (Wagon-)
# CleanupFinders, getrennt nach "wuerde geloescht" und "wuerde minimiert". Die Aufteilung folgt
# People::CleanupJob#event_participation_in_cutoff? (Core 2.11.5 app/jobs/people/cleanup_job.rb:
# 31-36). Gibt nur Zahlen (und optional IDs) zurueck, keine Namen oder E-Mail-Adressen.
module Kljb
  module People
    class CleanupReport
      Result = Struct.new(:delete_ids, :minimize_ids, :never_role, :ever_signed_in,
                          :in_household, :with_invoices, keyword_init: true) do
        def candidates
          delete_ids.size + minimize_ids.size
        end
      end

      def call
        ids = ::People::CleanupFinder.new.run.pluck(:id)
        minimize = ids.select { |id| minimize?(id) }
        Result.new(delete_ids: ids - minimize, minimize_ids: minimize,
                   never_role: count_never_role(ids), ever_signed_in: count_signed_in(ids),
                   in_household: count_household(ids), with_invoices: count_invoices(ids))
      end

      private

      # gleiche Bedingung wie im Core-Job
      def minimize?(person_id)
        ::Event.joins(:participations, :dates)
               .where(participations: {participant_id: person_id,
                                       participant_type: ::Person.sti_name})
               .where("event_dates.start_at > :cutoff OR event_dates.finish_at > :cutoff",
                      cutoff: cutoff)
               .any?
      end

      def cutoff
        @cutoff ||= Settings.people.cleanup_cutoff_duration
                            .regarding_event_participations.months.ago
      end

      def count_never_role(ids)
        sliced(ids) do |slice|
          ::Person.where(id: slice).where.not(id: ::Role.with_inactive.select(:person_id)).count
        end
      end

      def count_signed_in(ids)
        sliced(ids) do |slice|
          ::Person.where(id: slice)
                  .where("people.sign_in_count > 0 OR people.last_sign_in_at IS NOT NULL").count
        end
      end

      def count_household(ids)
        sliced(ids) { |slice| ::Person.where(id: slice).where.not(household_key: nil).count }
      end

      def count_invoices(ids)
        sliced(ids) do |slice|
          ::Person.where(id: slice).where(
            "EXISTS (SELECT 1 FROM invoices WHERE invoices.recipient_type = :type " \
            "AND invoices.recipient_id = people.id) OR " \
            "EXISTS (SELECT 1 FROM invoices WHERE invoices.creator_id = people.id)",
            type: ::Person.sti_name
          ).count
        end
      end

      def sliced(ids)
        ids.each_slice(1000).sum { |slice| yield(slice) }
      end
    end
  end
end
