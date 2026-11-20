# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

# Verwaiste Gruppen (Altdaten): Gruppen, deren parent_id oder layer_group_id auf eine Gruppe
# zeigt, die nicht (mehr) existiert (auch nicht soft-deleted), plus alle Nachfahren solcher
# Gruppen ueber parent_id. Nutzerentscheidung 2026-11-20: koennen geloescht werden.
#
# Aufraeumen (apply!) per update_all statt ueber Modell-Callbacks:
# - Soft-Delete ueber Group#destroy loest Nested-Set-Callbacks aus, die mit fehlendem Parent
#   scheitern koennen.
# - Rollen werden per update_all beendet, weil die Modellvalidierungen (z.B. Gruppe/Layer
#   gueltig) bei verwaisten Gruppen fehlschlagen koennen.
# Kein Hard-Delete. Idempotent: bereits geloeschte Gruppen und beendete Rollen werden nicht
# erneut angefasst.
#
# Abhaengige Objekte (Core 2.11.5 app/models/group.rb:141-170 haengen sie per dependent: :destroy
# an die Gruppe; update_all loest diese Callbacks NICHT aus): Verteiler, Subscriptions auf die
# Gruppe, Kalender, InvoiceConfig, Events der Gruppe, Rechnungen. Der Trockenlauf zaehlt sie je
# Gruppe; apply! bricht ohne Aenderung ab (DependentsFound), wenn solche Objekte existieren,
# ausser force: true. Auch mit force bleiben sie unveraendert bestehen (nicht geloescht).
# Personen mit primary_group_id auf eine verwaiste Gruppe werden immer auf NULL gesetzt (die
# Rollen-Callbacks set_first_primary_group laufen bei update_all nicht); das blockiert nicht.
# deleter_id bleibt bewusst NULL: kein Benutzer fuehrt die Bereinigung aus, ein Systemlauf.
module Kljb
  class OrphanGroups
    DEPENDENT_KEYS = %i[mailing_lists subscriptions calendars invoice_configs events invoices
                        primary_group_people].freeze
    # primary_group_people wird automatisch bereinigt und blockiert apply! nicht.
    BLOCKING_KEYS = (DEPENDENT_KEYS - [:primary_group_people]).freeze

    class DependentsFound < StandardError; end

    Row = Struct.new(:id, :type, :active_roles, :ended_roles, :future_roles, :dependents,
                     keyword_init: true) do
      def blocking_dependents
        BLOCKING_KEYS.sum { |key| dependents[key].to_i }
      end
    end

    def initialize(today: Date.current)
      @today = today
    end

    # Noch nicht soft-geloeschte verwaiste Gruppen (inkl. Nachfahren), sortiert nach id.
    def rows
      ids = orphan_group_ids
      return [] if ids.empty?

      groups = ::Group.unscoped.where(id: ids, deleted_at: nil).order(:id).pluck(:id, :type)
      dependents = dependent_counts(groups.map(&:first))
      groups.map do |id, type|
        Row.new(id: id, type: type, active_roles: count(active_roles, id),
                ended_roles: count(ended_roles, id), future_roles: count(future_roles, id),
                dependents: dependents.transform_values { |counts| counts[id].to_i })
      end
    end

    # Beendet aktive/kuenftige Rollen, setzt primary_group_id betroffener Personen auf NULL und
    # loescht Gruppen weich. +rows+ sind die zuvor gesichteten Zeilen (Standard: frisch
    # ermittelt). Wirft DependentsFound, ohne etwas zu schreiben, wenn abhaengige Objekte
    # existieren und force nicht gesetzt ist. Gibt die Summen zurueck.
    def apply!(rows = self.rows, force: false)
      blocked = rows.select { |row| row.blocking_dependents.positive? }
      if blocked.any? && !force
        raise DependentsFound,
              "#{blocked.size} Gruppen haben abhaengige Objekte (IDs: #{blocked.map(&:id).join(",")}); " \
              "nichts geschrieben. Mit FORCE=1 trotzdem ausfuehren (Objekte bleiben unveraendert)."
      end

      ids = rows.map(&:id)
      now = Time.zone.now
      ended = 0
      deleted = 0
      unset_primary = 0
      ::ActiveRecord::Base.transaction do
        ended = end_roles(ids, now)
        unset_primary = ::Person.where(primary_group_id: ids)
                                .update_all(primary_group_id: nil, updated_at: now)
        # deleter_id bleibt NULL (Systemlauf ohne Benutzer, kein Stamper)
        deleted = ::Group.unscoped.where(id: ids, deleted_at: nil)
                         .update_all(deleted_at: now, updated_at: now)
      end
      {groups: deleted, roles_ended: ended, primary_groups_unset: unset_primary}
    end

    def totals(rows = self.rows)
      {groups: rows.size, active_roles: rows.sum(&:active_roles),
       ended_roles: rows.sum(&:ended_roles), future_roles: rows.sum(&:future_roles)}
        .merge(DEPENDENT_KEYS.index_with { |key| rows.sum { |row| row.dependents[key].to_i } })
    end

    private

    def yesterday
      @today - 1
    end

    # Rollen mit start_on heute oder spaeter wuerden bei end_on = gestern vor ihrem Beginn enden
    # (Core 2.11.5 Role: end_on >= start_on, app/models/role.rb:115-119), bei end_on = start_on
    # aber noch am Beginntag aktiv. Sie werden daher auf start_on = end_on = gestern gesetzt
    # (nie aktiv, end_on >= start_on gilt). Alle uebrigen aktiven Rollen (start_on < heute oder
    # NULL): end_on = gestern. update_all erzeugt keine PaperTrail-Versionen (Rollback nur per
    # Backup).
    def end_roles(group_ids, now)
      not_yet_started = ::Role.with_inactive.where(group_id: group_ids)
                              .where("roles.start_on >= ?", @today)
                              .where("roles.end_on >= :today OR roles.end_on IS NULL", today: @today)
      collapsed = not_yet_started.update_all(start_on: yesterday, end_on: yesterday,
                                             updated_at: now)
      running = active_roles.where(group_id: group_ids)
                            .update_all(end_on: yesterday, updated_at: now)
      collapsed + running
    end

    def active_roles
      ::Role.with_inactive.where("roles.start_on <= :today OR roles.start_on IS NULL", today: @today)
            .where("roles.end_on >= :today OR roles.end_on IS NULL", today: @today)
    end

    def future_roles
      ::Role.with_inactive.where("roles.start_on > ?", @today)
    end

    def ended_roles
      ::Role.with_inactive.where("roles.end_on < ?", @today)
    end

    def count(scope, group_id)
      scope.where(group_id: group_id).count
    end

    # {Schluessel => {group_id => Anzahl}} fuer abhaengige Objekte (je ein Query pro Art)
    def dependent_counts(ids)
      return DEPENDENT_KEYS.index_with { {} } if ids.empty?

      {
        mailing_lists: ::MailingList.where(group_id: ids).group(:group_id).count,
        subscriptions: ::Subscription.where(subscriber_type: ::Group.sti_name, subscriber_id: ids)
                                     .group(:subscriber_id).count,
        calendars: ::Calendar.where(group_id: ids).group(:group_id).count,
        invoice_configs: ::InvoiceConfig.where(group_id: ids).group(:group_id).count,
        events: events_per_group(ids),
        invoices: ::Invoice.where(group_id: ids).group(:group_id).count,
        primary_group_people: ::Person.where(primary_group_id: ids).group(:primary_group_id).count
      }
    end

    # Join-Tabelle events_groups (has_and_belongs_to_many :events der Gruppe)
    def events_per_group(ids)
      sql = ::Group.sanitize_sql_array(
        ["SELECT group_id, COUNT(*) FROM events_groups WHERE group_id IN (?) GROUP BY group_id", ids]
      )
      ::Group.connection.select_rows(sql).to_h { |group_id, n| [group_id.to_i, n.to_i] }
    end

    # Alle Gruppen ohne Soft-Delete-Filter (auch bereits geloeschte): Vorfahrenkette pruefen
    def orphan_group_ids
      all = ::Group.unscoped.pluck(:id, :parent_id, :layer_group_id)
      existing = all.map(&:first).to_set
      children = Hash.new { |h, k| h[k] = [] }
      all.each { |id, parent_id, _| children[parent_id] << id if parent_id }

      queue = all.select { |_, parent_id, layer_id| dangling?(parent_id, existing) || dangling?(layer_id, existing) }
                 .map(&:first)
      result = Set.new
      until queue.empty?
        id = queue.shift
        next unless result.add?(id)

        queue.concat(children[id])
      end
      result.to_a
    end

    def dangling?(ref_id, existing)
      ref_id && !existing.include?(ref_id)
    end
  end
end
