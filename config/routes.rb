# frozen_string_literal: true

#  Copyright (c) 2012-2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.


Rails.application.routes.draw do

  extend LanguageRouteScope

  language_scope do
    # Define wagon routes here

    # Dubletten-Vorbeugung: Bericht Vorstand/Leitung ohne Mitgliedsrolle (T75)
    resources :groups, only: [] do
      get 'board_member_check', to: 'board_member_checks#index', as: :board_member_check
    end

  end

end
