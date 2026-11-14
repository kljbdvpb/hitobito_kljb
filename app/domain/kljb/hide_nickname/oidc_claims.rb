# frozen_string_literal: true

#  Copyright (c) 2021, Katholische Landjugendbewegung Paderborn. This file is part of
#  hitobito_kljb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_kljb.

# OIDC: Spitzname nie als Claim ausliefern (Scopes name und with_roles). OidcClaimSetup#run
# laeuft im Core in config.after_initialize, also nach den to_prepare-Callbacks des Wagons;
# der Prepend ist damit rechtzeitig aktiv. Wird auf OidcClaimSetup geprepended.
module Kljb::HideNickname::OidcClaims
  private

  def add_claim(name, **opts, &block)
    return if name.to_s == 'nickname'

    super
  end
end
