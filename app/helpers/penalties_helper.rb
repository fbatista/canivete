# frozen_string_literal: true

module PenaltiesHelper
  def penalty_categories_grouped_by_kind
    Penalty.kinds.transform_keys(&:titleize).transform_values do |kind|
      Penalty.categories.select { |_, v| v / 100 * 100 == kind }.keys.map { |e| [e.titleize, e] }
    end
  end
end
