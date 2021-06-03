# frozen_string_literal: true

namespace :app do
  namespace :license do
    task :config do # rubocop:disable Rails/RakeEnvironment
      @licenser = Licenser.new('hitobito_kljb',
                               'Katholische Landjugendbewegung Paderborn',
                               'https://github.com/hitobito/hitobito_kljb')
    end
  end
end
