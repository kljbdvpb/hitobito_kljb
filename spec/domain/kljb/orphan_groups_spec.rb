# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'

describe Kljb::OrphanGroups do
  let(:rv) { Fabricate(Group::Regionalverband.name.to_sym, parent: groups(:root)) }
  let!(:healthy_og) { Fabricate(Group::Ortsgruppe.name.to_sym, parent: rv) }
  let!(:orphan_og) { Fabricate(Group::Ortsgruppe.name.to_sym, parent: rv) }
  let(:orphan_child) { Group::OrtsgruppeVorstand.find_by(parent_id: orphan_og.id) }
  let(:healthy_child) { Group::OrtsgruppeVorstand.find_by(parent_id: healthy_og.id) }
  let(:missing_id) { Group.unscoped.maximum(:id) + 1000 }

  subject(:orphans) { described_class.new }

  # Elternzeiger ins Leere biegen, ohne Callbacks (so liegen die Altdaten vor)
  def break_parent!(group)
    group.update_columns(parent_id: missing_id)
  end

  def role(group, start_on:, end_on:)
    r = Fabricate(Group::OrtsgruppeVorstand::Mitglied.name.to_sym, group: group, person: Fabricate(:person))
    r.update_columns(start_on: start_on, end_on: end_on)
    r
  end

  context 'ohne verwaiste Gruppen' do
    it 'findet nichts und apply! aendert nichts' do
      expect(orphans.rows).to eq []
      expect(orphans.apply!).to eq(groups: 0, roles_ended: 0)
    end
  end

  context 'mit fehlendem parent' do
    before { break_parent!(orphan_og) }

    it 'findet die Gruppe und alle Nachfahren, aber keine gesunden Gruppen' do
      ids = orphans.rows.map(&:id)
      expect(ids).to include(orphan_og.id, orphan_child.id)
      expect(ids).not_to include(healthy_og.id, healthy_child.id, rv.id)
    end

    it 'findet auch Gruppen mit fehlender layer_group_id' do
      healthy_child.update_columns(layer_group_id: missing_id)
      expect(orphans.rows.map(&:id)).to include(healthy_child.id)
    end

    it 'zaehlt aktive, beendete und kuenftige Rollen getrennt' do
      role(orphan_child, start_on: 1.year.ago.to_date, end_on: nil)
      role(orphan_child, start_on: 2.years.ago.to_date, end_on: 1.year.ago.to_date)
      role(orphan_child, start_on: 1.month.from_now.to_date, end_on: nil)
      row = orphans.rows.find { |r| r.id == orphan_child.id }
      expect([row.active_roles, row.ended_roles, row.future_roles]).to eq [1, 1, 1]
      expect(orphans.totals).to include(active_roles: 1, ended_roles: 1, future_roles: 1)
    end

    it 'apply! beendet aktive Rollen und loescht Gruppen weich' do
      active = role(orphan_child, start_on: 1.year.ago.to_date, end_on: nil)
      ended = role(orphan_child, start_on: 2.years.ago.to_date, end_on: 1.year.ago.to_date)
      result = orphans.apply!

      expect(result[:groups]).to be >= 2
      expect(result[:roles_ended]).to eq 1
      expect(::Role.with_inactive.find(active.id).end_on).to eq Date.current - 1
      expect(::Role.with_inactive.find(ended.id).end_on).to eq 1.year.ago.to_date
      expect(::Group.unscoped.find(orphan_og.id).deleted_at).to be_present
      expect(::Group.unscoped.find(orphan_child.id).deleted_at).to be_present
      expect(::Group.unscoped.find(healthy_og.id).deleted_at).to be_nil
    end

    it 'apply! ist idempotent' do
      role(orphan_child, start_on: 1.year.ago.to_date, end_on: nil)
      orphans.apply!
      expect(orphans.rows).to eq []
      expect(described_class.new.apply!).to eq(groups: 0, roles_ended: 0)
    end

    it 'laesst bereits weich geloeschte Gruppen unveraendert' do
      deleted_at = 1.year.ago.change(usec: 0)
      orphan_child.update_columns(deleted_at: deleted_at)
      expect(orphans.rows.map(&:id)).not_to include(orphan_child.id)
      orphans.apply!
      expect(::Group.unscoped.find(orphan_child.id).deleted_at).to eq deleted_at
    end
  end
end
