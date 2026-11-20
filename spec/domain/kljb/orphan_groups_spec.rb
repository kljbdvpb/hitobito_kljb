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
      expect(orphans.apply!).to eq(groups: 0, roles_ended: 0, primary_groups_unset: 0)
    end
  end

  context 'mit fehlendem parent' do
    before do
      break_parent!(orphan_og)
      # Layer-Gruppen legen automatisch eine InvoiceConfig an (abhaengiges Objekt, siehe unten)
      ::InvoiceConfig.where(group_id: orphan_og.id).delete_all
    end

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

      expect(result[:groups]).to eq 4 # Ortsgruppe + Vorstand, Kontakte, Leiterrunde
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
      expect(described_class.new.apply!).to eq(groups: 0, roles_ended: 0, primary_groups_unset: 0)
    end

    it 'laesst bereits weich geloeschte Gruppen unveraendert' do
      deleted_at = 1.year.ago.change(usec: 0)
      orphan_child.update_columns(deleted_at: deleted_at)
      expect(orphans.rows.map(&:id)).not_to include(orphan_child.id)
      orphans.apply!
      expect(::Group.unscoped.find(orphan_child.id).deleted_at).to eq deleted_at
    end

    it 'apply! setzt end_on = start_on bei Rollen, die heute beginnen (end_on >= start_on)' do
      today_role = role(orphan_child, start_on: Date.current, end_on: nil)
      future = role(orphan_child, start_on: 1.month.from_now.to_date, end_on: nil)
      orphans.apply!

      [today_role, future].each do |r|
        reloaded = ::Role.with_inactive.find(r.id)
        expect(reloaded.end_on).to be >= reloaded.start_on
        expect(reloaded.end_on).to be < Date.current
      end
    end

    it 'apply! beendet aktive Rollen mit start_on in der Vergangenheit auf gestern' do
      active = role(orphan_child, start_on: 1.year.ago.to_date, end_on: nil)
      orphans.apply!
      reloaded = ::Role.with_inactive.find(active.id)
      expect([reloaded.start_on, reloaded.end_on]).to eq [1.year.ago.to_date, Date.current - 1]
    end

    it 'apply! setzt primary_group_id betroffener Personen auf NULL, andere bleiben' do
      other = Fabricate(:person)
      member = role(orphan_child, start_on: 1.year.ago.to_date, end_on: nil).person
      member.update_columns(primary_group_id: orphan_child.id)
      other.update_columns(primary_group_id: healthy_child.id)

      result = orphans.apply!

      expect(result[:primary_groups_unset]).to eq 1
      expect(member.reload.primary_group_id).to be_nil
      expect(other.reload.primary_group_id).to eq healthy_child.id
    end

    it 'apply! laesst deleter_id leer (Systemlauf)' do
      orphans.apply!
      expect(::Group.unscoped.find(orphan_og.id).deleter_id).to be_nil
    end

    context 'mit abhaengigen Objekten' do
      let!(:list) { Fabricate(:mailing_list, group: orphan_og) }

      it 'zaehlt sie je Gruppe im Trockenlauf' do
        Fabricate(:calendar, group: orphan_og)
        row = orphans.rows.find { |r| r.id == orphan_og.id }

        expect(row.dependents[:mailing_lists]).to eq 1
        expect(row.dependents[:calendars]).to eq 1
        expect(row.dependents[:invoice_configs]).to eq 0
        expect(orphans.totals[:mailing_lists]).to eq 1
      end

      it 'zaehlt Subscriptions auf die Gruppe, Events und Personen mit primary_group_id' do
        other_list = Fabricate(:mailing_list, group: healthy_og)
        Subscription.create!(mailing_list: other_list, subscriber: orphan_og,
                             related_role_types: [RelatedRoleType.new(role_type: Group::Ortsgruppe::Mitglied.sti_name)])
        event = Fabricate(:event, groups: [orphan_og])
        person = Fabricate(:person)
        person.update_columns(primary_group_id: orphan_og.id)

        row = orphans.rows.find { |r| r.id == orphan_og.id }

        expect(row.dependents).to include(subscriptions: 1, events: 1, primary_group_people: 1)
        expect(event).to be_persisted
      end

      it 'apply! bricht ohne Aenderung ab, wenn abhaengige Objekte existieren' do
        active = role(orphan_child, start_on: 1.year.ago.to_date, end_on: nil)

        expect { orphans.apply! }.to raise_error(described_class::DependentsFound, /#{orphan_og.id}/)

        expect(::Group.unscoped.find(orphan_og.id).deleted_at).to be_nil
        expect(::Role.with_inactive.find(active.id).end_on).to be_nil
        expect(::MailingList.exists?(list.id)).to be true
      end

      it 'apply! mit force fuehrt aus und laesst die Objekte unveraendert bestehen' do
        result = orphans.apply!(force: true)

        expect(result[:groups]).to eq 4
        expect(::Group.unscoped.find(orphan_og.id).deleted_at).to be_present
        expect(::MailingList.exists?(list.id)).to be true
      end

      it 'primary_group_id allein blockiert nicht' do
        ::MailingList.where(id: list.id).delete_all
        Fabricate(:person).update_columns(primary_group_id: orphan_og.id)

        expect { orphans.apply! }.not_to raise_error
      end
    end

    it 'blockiert ueber die automatisch angelegte InvoiceConfig der Layer-Gruppe' do
      ::InvoiceConfig.new(group: orphan_og).save!(validate: false)

      expect(orphans.rows.find { |r| r.id == orphan_og.id }.dependents[:invoice_configs]).to eq 1
      expect { orphans.apply! }.to raise_error(described_class::DependentsFound)
    end
  end
end
