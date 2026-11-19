# frozen_string_literal: true

#  Copyright (c) 2026, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'
require 'csv'

describe Export::SubgroupsExportJob do
  let(:nord) { groups(:nord) }
  let(:paderborn) { groups(:paderborn) }
  let(:bonn) { groups(:bonn) }
  let(:job) { described_class.new(Person.first.id, nord.id, filename: :subgroups_export) }
  let(:entries) { job.send(:entries).to_a }

  it 'exports only groups of type Ortsgruppe' do
    expect(entries).to include(paderborn, bonn)
    expect(entries.map(&:type).uniq).to eq ['Group::Ortsgruppe']
  end

  it 'leaves out the exported Regionalverband and its Vorstand, AG and Kontakte' do
    expect(entries).not_to include(nord)
    expect(entries.map(&:type)).not_to include('Group::Regionalverband',
                                               'Group::RegionalverbandVorstand',
                                               'Group::OrtsgruppeVorstand')
  end

  it 'keeps the order by lft and skips deleted groups' do
    bonn.update_columns(deleted_at: Time.zone.now)
    expect(entries).not_to include(bonn)
    expect(entries.map(&:lft)).to eq entries.map(&:lft).sort
  end

  it 'skips archived Ortsgruppen' do
    bonn.update_columns(archived_at: Time.zone.now)
    expect(entries).to include(paderborn)
    expect(entries).not_to include(bonn)
  end

  it 'sums only the Ortsgruppen in the sum row' do
    paderborn.update!(members_normal: 23, members_discounted: 7)
    bonn.update!(members_normal: 5)
    nord.update_columns(members_normal: 1000) # darf nicht in der Summe landen
    csv = CSV.parse(Export::Tabular::Groups::List.csv(entries)
                      .gsub(Regexp.new("^#{Export::Csv::UTF8_BOM}"), ''),
                    headers: true, col_sep: Settings.csv.separator)
    expect(csv.map { |r| r['Gruppentyp'] }.compact.uniq).to eq ['Ortsgruppe']
    expect(csv[csv.size - 1]['Name']).to eq 'Summe'
    expect(csv[csv.size - 1]['normale Mitglieder']).to eq '28'
    expect(csv[csv.size - 1]['Mitglieder gesamt (normal + vergünstigt)']).to eq '35'
  end
end
