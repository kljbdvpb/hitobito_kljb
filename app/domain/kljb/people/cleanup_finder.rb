# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

# Absicherungen fuer das automatische Loeschen von Personen ohne Rolle (People::CleanupJob,
# Nutzerentscheidung 2026-11-20: nach 3 Monaten ohne Rolle). Ersetzt People::CleanupFinder#base_scope
# (Core 2.11.5 app/domain/people/cleanup_finder.rb:24-28), alle weiteren Filter des Core bleiben.
#
# 1. Fehlt die Root-Person (Settings.root_email), wirft der Core NoMethodError (Person.root.id).
# 2. Der Core prueft nur aktive Rollen (start_on <= heute) und MAX(end_on) <= Stichtag; eine
#    Person mit altem beendetem und nur kuenftigem Rollenbeginn wuerde sonst geloescht.
# 3. Frisch angelegte Personen ohne Rolle (z.B. Kursanmeldung) werden erst nach Ablauf der
#    Rollen-Frist beruecksichtigt.
# 4. Personen mit direkter Verteiler-Subscription (Person als Abonnent, nicht excluded) bleiben
#    erhalten, solange protect_direct_subscribers? true ist (Fachfrage F4 offen, vorerst Schutz an).
module Kljb
  module People
    module CleanupFinder
      # Vorerst true: Direkt-Abonnenten von Verteilern werden nicht geloescht (Destroyer wuerde
      # die Subscriptions stillschweigend entfernen). Bei Fachentscheid false setzen.
      PROTECT_DIRECT_SUBSCRIBERS = true

      def self.protect_direct_subscribers?
        PROTECT_DIRECT_SUBSCRIBERS
      end

      private

      def base_scope
        scope = ::Person.where(minimized_at: nil).order(:id)
        root = ::Person.root
        scope = scope.where.not(id: root.id) if root
        scope = scope.where(no_active_or_future_roles_exist)
                     .where("people.created_at <= ?", created_before)
        scope = scope.where.not(id: direct_subscriber_ids) if Kljb::People::CleanupFinder.protect_direct_subscribers?
        scope
      end

      # Personen, die direkt (nicht ueber Gruppe/Rolle) in einem Verteiler eingetragen sind
      def direct_subscriber_ids
        ::Subscription.where(subscriber_type: ::Person.sti_name, excluded: false)
                      .select(:subscriber_id)
      end

      # Keine aktive ODER kuenftige Rolle (end_on >= heute oder NULL, inkl. start_on in Zukunft)
      def no_active_or_future_roles_exist
        ::Role.active_and_future.where("roles.person_id = people.id").arel.exists.not
      end

      def created_before
        Settings.people.cleanup_cutoff_duration.regarding_roles.months.ago
      end
    end
  end
end
