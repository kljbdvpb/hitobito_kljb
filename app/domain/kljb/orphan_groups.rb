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
module Kljb
  class OrphanGroups
    Row = Struct.new(:id, :type, :active_roles, :ended_roles, :future_roles, keyword_init: true)

    def initialize(today: Date.current)
      @today = today
    end

    # Noch nicht soft-geloeschte verwaiste Gruppen (inkl. Nachfahren), sortiert nach id.
    def rows
      ids = orphan_group_ids
      return [] if ids.empty?

      groups = ::Group.unscoped.where(id: ids, deleted_at: nil).order(:id).pluck(:id, :type)
      groups.map do |id, type|
        Row.new(id: id, type: type, active_roles: count(active_roles, id),
                ended_roles: count(ended_roles, id), future_roles: count(future_roles, id))
      end
    end

    # Beendet aktive/kuenftige Rollen (end_on = gestern) und loescht Gruppen weich.
    # Gibt die Summen zurueck.
    def apply!
      rows = self.rows
      ids = rows.map(&:id)
      now = Time.zone.now
      ended = 0
      deleted = 0
      ::ActiveRecord::Base.transaction do
        ended = end_roles(ids, now)
        deleted = ::Group.unscoped.where(id: ids, deleted_at: nil)
                         .update_all(deleted_at: now, updated_at: now)
      end
      {groups: deleted, roles_ended: ended}
    end

    def totals(rows = self.rows)
      {groups: rows.size, active_roles: rows.sum(&:active_roles),
       ended_roles: rows.sum(&:ended_roles), future_roles: rows.sum(&:future_roles)}
    end

    private

    def yesterday
      @today - 1
    end

    # Aktive Rollen: end_on = gestern. Kuenftige Rollen (start_on > heute) wuerden danach vor
    # ihrem Beginn enden, daher start_on ebenfalls auf gestern setzen.
    def end_roles(group_ids, now)
      active = active_roles.where(group_id: group_ids)
                           .update_all(end_on: yesterday, updated_at: now)
      future = future_roles.where(group_id: group_ids)
                           .update_all(start_on: yesterday, end_on: yesterday, updated_at: now)
      active + future
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
