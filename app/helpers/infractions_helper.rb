# frozen_string_literal: true

module InfractionsHelper
  def infraction_categories_grouped_by_kind
    Infraction.kinds.transform_keys(&:titleize).transform_values do |kind|
      Infraction.categories.select { |_, v| v / 100 * 100 == kind }.keys.map { |e| [ e.titleize, e ] }
    end
  end
end
