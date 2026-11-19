# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'
require 'csv'

describe Export::Tabular::Groups::List do

  let(:group) { groups(:nord) }

  let(:list) { group.self_and_descendants.without_deleted.includes(:contact) }
  let(:data) { described_class.csv(list) }
  let(:data_without_bom) { data.gsub(Regexp.new("^#{Export::Csv::UTF8_BOM}"), '') }
  let(:csv) { CSV.parse(data_without_bom, headers: true, col_sep: Settings.csv.separator) }

  subject { csv }

  it 'has the correct headers' do
    expected = ['Id',
                'Elterngruppe',
                'Name',
                'Kurzname',
                'Gruppentyp',
                'Haupt-E-Mail',
                'PLZ',
                'Ort',
                'Land',
                'Geändert',
                'Ebene',
                'Beschreibung',
                'Link zu Nextcloud',
                'Strasse',
                'Hausnummer',
                'c/o-Adresse',
                'Postfach',
                'Sprache',
                'normale Mitglieder',
                'vergünstigte Mitglieder',
                'Mitglieder gesamt (normal + vergünstigt)',
                'Mitglieder unter 14 Jahre',
                'Mitglieder ab 14 Jahre',
                'Mitglieder bis einschließlich 27 Jahre',
                'Mitglieder ohne Geburtsdatum',
                'Telefonnummern',
                'Anzahl Mitglieder',
                'Social Media']

    expect(subject.headers).to match_array expected
    expect(subject.headers).to eq expected
  end

  it 'has 16 groups plus the sum row' do
    expect(subject.size).to eq(17)
  end

  context 'first row' do
    subject { csv[0] }

    its(['Id']) { should == group.id.to_s }
    its(['Elterngruppe']) { should == group.parent_id&.to_s }
    its(['Name']) { should == group.name }
    its(['Kurzname']) { should == group.short_name }
    its(['Gruppentyp']) { should == 'Regionalverband' }
    its(['Haupt-E-Mail']) { should == group.email }
    its(['c/o-Adresse']) { should == group.address_care_of }
    its(['Strasse']) { should == group.street }
    its(['Hausnummer']) { should == group.housenumber }
    its(['Postfach']) { should == group.postbox }
    its(['PLZ']) { should == group.zip_code.to_s }
    its(['Ort']) { should == group.town }
    its(['Land']) { should == group.country_label }
    its(['Ebene']) { should == group.id.to_s }
    its(['normale Mitglieder']) { should be_blank }
    its(['vergünstigte Mitglieder']) { should be_blank }
  end

  context 'group with members' do
    subject { csv.find { |row| row['Name'] == group_with_members.name } }
    let(:group_with_members) { groups(:paderborn) }

    before do
      group_with_members.update!(
        members_normal: 23,
        members_discounted: 7
      )
    end

    its(['Gruppentyp']) { should == 'Ortsgruppe' }
    its(['normale Mitglieder']) { should == '23' }
    its(['vergünstigte Mitglieder']) { should == '7' }
    its(['Mitglieder gesamt (normal + vergünstigt)']) { should == '30' }
    its(['Mitglieder ab 14 Jahre']) { should be_blank }
  end

  context 'sum row' do
    let(:paderborn) { groups(:paderborn) }
    let(:bonn) { groups(:bonn) }
    let(:sum_row) { csv[csv.size - 1] }

    before do
      paderborn.update!(members_normal: 23, members_discounted: 7, members_under_14: 10,
                        members_from_14: 18, members_up_to_27: 20, members_without_birthday: 2)
      bonn.update!(members_normal: 5, members_discounted: nil, members_under_14: 1,
                   members_from_14: 4, members_up_to_27: 3, members_without_birthday: 0)
    end

    it 'is the last row and labelled' do
      expect(sum_row['Name']).to eq 'Summe'
      expect(sum_row['Id']).to be_blank
    end

    it 'adds up all count columns over all groups, blank counts as 0' do
      expect(sum_row['normale Mitglieder']).to eq '28'
      expect(sum_row['vergünstigte Mitglieder']).to eq '7'
      expect(sum_row['Mitglieder gesamt (normal + vergünstigt)']).to eq '35'
      expect(sum_row['Mitglieder unter 14 Jahre']).to eq '11'
      expect(sum_row['Mitglieder ab 14 Jahre']).to eq '22'
      expect(sum_row['Mitglieder bis einschließlich 27 Jahre']).to eq '23'
      expect(sum_row['Mitglieder ohne Geburtsdatum']).to eq '2'
    end

    it 'age groups add up to the total' do
      expect(sum_row['Mitglieder unter 14 Jahre'].to_i + sum_row['Mitglieder ab 14 Jahre'].to_i +
             sum_row['Mitglieder ohne Geburtsdatum'].to_i)
        .to eq sum_row['Mitglieder gesamt (normal + vergünstigt)'].to_i
    end

    it 'is also the last row for xlsx rows' do
      rows = described_class.new(list).data_rows(:xlsx).to_a
      expect(rows.size).to eq 17
      expect(rows.last[described_class.new(list).attributes.index(:name)]).to eq 'Summe'
    end
  end
end
