# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

require 'spec_helper'

# Stichtag 01.09., 05:00 (Time.zone): Review H2. Vor dem Stichtag desselben Jahres,
# danach im Folgejahr; nie pauschal "naechstes Jahr".
describe MemberPaymentStatusJob do
  def next_run_at(time)
    travel_to(Time.zone.parse(time)) { described_class.new.send(:next_run) }
  end

  def at_zone(*args)
    Time.zone.local(*args)
  end

  { '2021-01-01 00:00' => 2021, '2021-03-15 12:00' => 2021, '2021-08-31 23:59' => 2021,
    '2021-09-01 00:00' => 2021, '2021-09-01 04:59' => 2021 }.each do |now, year|
    it "plant am #{now} den 01.09.#{year} 05:00" do
      expect(next_run_at(now)).to eq at_zone(year, 9, 1, 5, 0)
    end
  end

  { '2021-09-01 05:00' => 2022, '2021-09-01 05:01' => 2022, '2021-09-02 00:00' => 2022,
    '2021-10-15 12:00' => 2022, '2021-12-31 23:59' => 2022 }.each do |now, year|
    it "plant am #{now} den 01.09.#{year} 05:00" do
      expect(next_run_at(now)).to eq at_zone(year, 9, 1, 5, 0)
    end
  end

  it 'rechnet in Time.zone, nicht in der Systemzeitzone' do
    expect(next_run_at('2021-03-01 12:00').time_zone).to eq Time.zone
    expect(next_run_at('2021-03-01 12:00').hour).to eq 5
  end

  it 'liegt nie in der Vergangenheit' do
    %w[2021-01-01 2021-08-31 2021-09-01 2021-12-31].each do |day|
      travel_to(Time.zone.parse("#{day} 12:00")) do
        expect(described_class.new.send(:next_run)).to be > Time.zone.now
      end
    end
  end
end
