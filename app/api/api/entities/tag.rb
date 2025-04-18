# frozen_string_literal: true

module Api
  module Entities
    class Tag < Base
      expose :label

      unexpose :href

    end
  end
end
