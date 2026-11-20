# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

namespace :hitobito_kljb do
  namespace :people_cleanup do
    desc "Trockenlauf fuer den Personen-Cleanup (People::CleanupJob): zaehlt Kandidaten, " \
         "getrennt nach 'wuerde geloescht' / 'wuerde minimiert'. Nur lesend, unabhaengig von " \
         "KLJB_PEOPLE_CLEANUP. Ausgabe nur Zahlen; IDS=1 gibt zusaetzlich Personen-IDs aus."
    task dry_run: :environment do
      result = Kljb::People::CleanupReport.new.call

      puts "PERSONEN-CLEANUP TROCKENLAUF (nichts geschrieben)"
      puts "JOB_AKTIV=#{Settings.people.cleanup_job.enabled}"
      puts "KANDIDATEN gesamt=#{result.candidates}"
      puts "WUERDE_GELOESCHT=#{result.delete_ids.size}"
      puts "WUERDE_MINIMIERT=#{result.minimize_ids.size}"
      puts "DAVON nie_rolle=#{result.never_role} je_angemeldet=#{result.ever_signed_in} " \
           "mit_haushalt=#{result.in_household} mit_rechnungen=#{result.with_invoices}"
      if ENV["IDS"] == "1"
        puts "IDS_GELOESCHT=#{result.delete_ids.join(",")}"
        puts "IDS_MINIMIERT=#{result.minimize_ids.join(",")}"
      end
    end
  end
end
