# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'

describe Groups::MemberPaymentStatus do
  subject(:nooper) { described_class.new(non_layer) }
  subject(:paderborn_status) { described_class.new(group) }

  let(:group) { groups(:paderborn) }
  let(:non_layer) { groups(:paderborn_vorstand)}

  it 'does nothing if group is not a layer' do
    expect(non_layer).to_not be_layer
    expect(nooper.update).to be_falsey
  end

  context 'with a group that has members without siblings' do
    before do
      10.times do
        Fabricate('Group::Ortsgruppe::Mitglied', group: group)
      end
    end

    it 'has assumptions' do
      expect(group.people.count).to eq 10
    end

    it 'all member are normal members' do
      expect do
        subject.update
      end.to change(group, :members_normal).to(10)
        .and change(group, :members_discounted).to(0)
    end
  end

  context 'with a group of only one family of 3 siblings' do
    before do
      tom   = Fabricate(:person, birthday: 20.years.ago, nickname: 'tom')
      olaf  = Fabricate(:person, birthday: 15.years.ago, nickname: 'olaf')
      peter = Fabricate(:person, birthday: 13.years.ago, nickname: 'peter')

      Fabricate(:family_member, person: tom, other: olaf, kind: 'sibling')
      Fabricate(:family_member, person: tom, other: peter, kind: 'sibling')

      Fabricate('Group::Ortsgruppe::Mitglied', person: tom, group: group)
      Fabricate('Group::Ortsgruppe::Mitglied', person: olaf, group: group)
      Fabricate('Group::Ortsgruppe::Mitglied', person: peter, group: group)

      [tom, olaf, peter].each(&:reload)
    end

    it 'has 3 members in total' do
      expect do
        subject.update
      end.to change { group.members_normal.to_i + group.members_discounted.to_i }.to(3)
    end

    it 'the 2 oldest siblings count as normal members' do
      expect do
        subject.update
      end.to change(group, :members_normal).to(2)
    end

    it 'the 1 youngest siblings counts as discounted member' do
      expect do
        subject.update
      end.to change(group, :members_discounted).to(1)
    end
  end

  context 'with a group of only one family of 2 siblings' do
    before do
      tom = Fabricate(:person)
      peter = Fabricate(:person)

      Fabricate(:family_member, person: tom, other: peter, kind: 'sibling')

      Fabricate('Group::Ortsgruppe::Mitglied', person: tom, group: group)
      Fabricate('Group::Ortsgruppe::Mitglied', person: peter, group: group)
    end

    it 'has assumptions' do
      expect(group.people.count).to eq 2
    end

    it 'all count as normal members' do
      expect do
        subject.update
      end.to change(group, :members_normal).to(2)
        .and change(group, :members_discounted).to(0)
    end
  end

  context 'with a person having two member roles in the layer' do
    before do
      person = Fabricate(:person)
      Fabricate('Group::Ortsgruppe::Mitglied', person: person, group: group)
      Fabricate('Group::Ortsgruppe::Mitglied', person: person, group: group, label: 'zweite')
      Fabricate('Group::Ortsgruppe::Mitglied', group: group)
    end

    it 'counts each person only once' do
      expect do
        subject.update
      end.to change(group, :members_normal).to(2)
    end
  end

  context 'counts only members' do
    before do
      10.times do
        Fabricate('Group::Ortsgruppe::Mitglied', group: group)
      end
      2.times do
        Fabricate('Group::Ortsgruppe::Foerdermitglied', group: group)
      end
      3.times do
        Fabricate('Group::OrtsgruppeVorstand::Mitglied',
                  group: group.children.find_by(type: 'Group::OrtsgruppeVorstand'))
      end
    end

    it 'has assumptions' do
      expect(group.people.count).to eq 12
      all_members = Person.joins(:roles)
        .where(roles: { group: group.layer_group.self_and_descendants })

      expect(all_members.count).to eq 15

      expect(
        all_members.where({
          roles: { type: ['Group::Ortsgruppe::Mitglied']}
        }).count
      ).to eq 10
    end

    it 'all member are normal members' do
      expect do
        subject.update
      end.to change(group, :members_normal).to(10)
        .and change(group, :members_discounted).to(0)
    end
  end

  # Nutzerentscheidung 2026-11-19: Fuer "drittes und weiteres Kind" zaehlen nur Geschwister,
  # die selbst aktive Mitglieder derselben Ortsgruppe (Layer) sind.
  context 'with siblings in other groups' do
    let(:bonn) { groups(:bonn) }
    let(:paderborn) { group }
    subject(:bonn_status) { described_class.new(bonn) }

    let(:tom) { Fabricate(:person, birthday: 20.years.ago, nickname: 'tom') }
    let(:olaf) { Fabricate(:person, birthday: 15.years.ago, nickname: 'olaf') }
    let(:peter) { Fabricate(:person, birthday: 13.years.ago, nickname: 'peter') }

    before do
      Fabricate(:family_member, person: tom, other: olaf, kind: 'sibling')
      Fabricate(:family_member, person: tom, other: peter, kind: 'sibling')

      Fabricate('Group::Ortsgruppe::Mitglied', person: tom, group: paderborn)
      Fabricate('Group::Ortsgruppe::Mitglied', person: olaf, group: paderborn)
      Fabricate('Group::Ortsgruppe::Mitglied', person: peter, group: bonn)

      [tom, olaf, peter].each(&:reload)
    end

    it 'has 2 and 1 members in total' do
      expect do
        paderborn_status.update
      end.to change { paderborn.members_normal.to_i + paderborn.members_discounted.to_i }.to(2)

      expect do
        bonn_status.update
      end.to change { bonn.members_normal.to_i + bonn.members_discounted.to_i }.to(1)
    end

    it 'does not count siblings of another group: no discount anywhere' do
      paderborn_status.update
      bonn_status.update
      expect(paderborn.members_discounted).to eq 0
      expect(paderborn.members_normal).to eq 2
      expect(bonn.members_discounted).to eq 0
      expect(bonn.members_normal).to eq 1
    end
  end

  context 'with siblings without member role in the layer' do
    it 'does not count siblings that have no Mitglied role' do
      tom   = Fabricate(:person, birthday: 20.years.ago)
      olaf  = Fabricate(:person, birthday: 15.years.ago)
      peter = Fabricate(:person, birthday: 13.years.ago)
      Fabricate(:family_member, person: tom, other: olaf, kind: 'sibling')
      Fabricate(:family_member, person: tom, other: peter, kind: 'sibling')
      Fabricate('Group::Ortsgruppe::Mitglied', person: tom, group: group)
      Fabricate('Group::OrtsgruppeVorstand::Mitglied', person: olaf,
                                                       group: groups(:paderborn_vorstand))
      Fabricate('Group::Ortsgruppe::Mitglied', person: peter, group: group)
      [tom, olaf, peter].each(&:reload)

      paderborn_status.update
      expect(group.members_normal).to eq 2
      expect(group.members_discounted).to eq 0
    end
  end

  context 'with a sibling without birthday' do
    it 'ranks the sibling last and does not displace the youngest known child' do
      kids = [20.years.ago, 15.years.ago, nil, 13.years.ago].map do |b|
        Fabricate(:person, birthday: b)
      end
      kids.drop(1).each { |k| Fabricate(:family_member, person: kids[0], other: k, kind: 'sibling') }
      kids.each { |k| Fabricate('Group::Ortsgruppe::Mitglied', person: k, group: group) }
      kids.each(&:reload)

      paderborn_status.update
      expect(group.members_normal).to eq 3
      expect(group.members_discounted).to eq 1
    end
  end

  describe 'age groups' do
    let(:cutoff) { Date.parse('2021-09-01') }

    def member(birthday)
      Fabricate('Group::Ortsgruppe::Mitglied', group: group,
                person: Fabricate(:person, birthday: birthday)).person
    end

    around { |example| travel_to('2021-12-14') { example.run } }

    # Alter am Stichtag 01.09.2021: Grenzfaelle genau am Geburtstag und einen Tag danach
    {
      '2008-09-01' => [13, :members_under_14],
      '2008-09-02' => [12, :members_under_14],
      '2007-09-01' => [14, :members_from_14],
      '2007-09-02' => [13, :members_under_14],
      '1994-09-01' => [27, :members_up_to_27],
      '1994-09-02' => [26, :members_up_to_27],
      '1993-09-02' => [27, :members_up_to_27],
      '1993-09-01' => [28, :members_from_14]
    }.each do |birthday, (age, column)|
      it "person born #{birthday} is #{age} at cutoff and counts in #{column}" do
        member(birthday)
        attrs = paderborn_status.age_attributes
        expect(attrs[column]).to eq 1
        expect(attrs[:members_up_to_27]).to eq(age <= 27 ? 1 : 0)
        expect(attrs[:members_under_14]).to eq(age < 14 ? 1 : 0)
        expect(attrs[:members_from_14]).to eq(age >= 14 ? 1 : 0)
        expect(attrs[:members_without_birthday]).to eq 0
      end
    end

    it 'counts members without birthday separately, sum equals total' do
      member('2010-01-01')
      member('1990-01-01')
      2.times { member(nil) }
      paderborn_status.update
      group.reload
      expect(group.members_without_birthday).to eq 2
      expect(group.members_under_14 + group.members_from_14 + group.members_without_birthday)
        .to eq(group.members_normal + group.members_discounted)
      expect(group.members_up_to_27).to eq 1
    end

    it 'counts a person with two member roles once' do
      person = member('2000-01-01')
      Fabricate('Group::Ortsgruppe::Mitglied', group: group, person: person, label: 'zweite')
      expect(paderborn_status.age_attributes[:members_from_14]).to eq 1
    end

    it 'ignores non member roles' do
      Fabricate('Group::Ortsgruppe::Foerdermitglied', group: group,
                                                      person: Fabricate(:person, birthday: '2000-01-01'))
      expect(paderborn_status.age_attributes.values.sum).to eq 0
    end
  end

  describe 'backfill_age_attributes!' do
    around { |example| travel_to('2021-12-14') { example.run } }

    # start_on explizit setzen: Fabricate setzt start_on auf Date.current (hier 2021-12-14)
    def member_role(birthday, start_on:, end_on: nil)
      role = Fabricate('Group::Ortsgruppe::Mitglied', group: group,
                       person: Fabricate(:person, birthday: birthday))
      role.update_columns(start_on: start_on, end_on: end_on)
      role
    end

    before do
      member_role('2012-01-01', start_on: '2021-01-01')                          # u14, war dabei
      member_role('2000-01-01', start_on: '2021-01-01', end_on: '2021-09-30')    # spaeter beendet
      member_role('2000-01-01', start_on: '2021-01-01', end_on: '2021-08-01')    # vor Stichtag beendet
      member_role('2000-01-01', start_on: '2021-10-01')                          # nach Stichtag neu
      member_role(nil, start_on: '2021-01-01')                                   # ohne Geburtsdatum
      group.update_columns(members_normal: 42, members_discounted: 7,
                           updated_at: Time.zone.parse('2021-09-01 00:00'))
    end

    it 'counts roles on the cutoff boundaries' do
      member_role('2000-01-01', start_on: '2021-09-01')                  # Beginn am Stichtag zaehlt
      member_role('2000-01-01', start_on: '2021-01-01', end_on: '2021-09-01') # Ende am Stichtag zaehlt
      member_role('2000-01-01', start_on: '2021-01-01', end_on: '2021-08-31') # Tag davor beendet nicht
      expect(paderborn_status.backfill_age_attributes!).to include(members_from_14: 3)
    end

    it 'reconstructs the member set at the cutoff date' do
      expect(paderborn_status.backfill_age_attributes!).to eq(
        members_under_14: 1, members_from_14: 1, members_up_to_27: 2, members_without_birthday: 1
      )
    end

    it 'does not touch members_normal, members_discounted or updated_at' do
      updated_at_before = group.reload.updated_at
      paderborn_status.backfill_age_attributes!
      group.reload
      expect(group.updated_at).to eq updated_at_before
      expect(group.members_normal).to eq 42
      expect(group.members_discounted).to eq 7
      expect(group.members_from_14).to eq 1
    end

    it 'does nothing for non layers' do
      expect(nooper.backfill_age_attributes!).to be_falsey
    end
  end

  describe 'cutoff_date' do
    it 'is the first day of september' do
      travel_to '2021-12-14' do
        expect(described_class.cutoff_date).to eq Date.parse('2021-09-01')
      end
    end

    it 'is never in the future' do
      travel_to '2021-08-31' do
        expect(described_class.cutoff_date).to eq Date.parse('2020-09-01')
      end
    end

    it 'may be today' do
      travel_to '2021-09-01' do
        expect(described_class.cutoff_date).to eq Date.parse('2021-09-01')
      end
    end

    it 'may be in the past' do
      travel_to '2021-09-02' do
        expect(described_class.cutoff_date).to eq Date.parse('2021-09-01')
      end
    end

    it 'is the reference date of the payment status job' do
      expect(described_class::AGE_CUTOFF_DATE).to eq [9, 1]
      travel_to '2021-03-01' do
        expect(MemberPaymentStatusJob.new.send(:next_run).to_date).to eq Date.parse('2021-09-01')
      end
    end
  end
end
