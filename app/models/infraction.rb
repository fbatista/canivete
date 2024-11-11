# frozen_string_literal: true

class Infraction < ApplicationRecord
  belongs_to :player
  belongs_to :tournament, optional: true
  belongs_to :pod, optional: true

  enum :kind, {
    game_play_errors: 200,
    tournament_errors: 300,
    unsporting_conduct: 400
  }, default: :game_play_errors

  enum :category, {
    missed_trigger: 201,
    looking_at_extra_cards: 202,
    hidden_card_error: 203,
    mulligan_procedure_error: 204,
    game_rule_violation: 205,
    failure_to_maintain_game_state: 206,

    tardiness: 301,
    outside_assistance: 302,
    slow_play: 303,
    decklist_problem: 304,
    deck_problem: 305,
    limited_procedure_violation: 306,
    communication_policy_violation: 307,
    marked_cards: 308,
    insufficient_shuffling: 309,

    minor: 401,
    major: 402,
    improperly_determining_a_winner: 403,
    bribery_and_wagering: 404,
    aggressive_behaviour: 405,
    theft_of_tournament_material: 406,
    stalling: 407,
    cheating: 408
  }, default: :game_rule_violation

  enum :penalty, {
    warning: 0,
    game_loss: 1,
    match_loss: 2,
    disqualification: 3,
    priority_skip: 4
  }, default: :warning

  validate :must_match_kind_with_category
  validate :must_have_tournament_or_pod
  validates :description, presence: true

  def must_have_tournament_or_pod
    errors.add(:base, 'Must have tournament or pod') unless tournament.present? || pod.present?
  end

  def must_match_kind_with_category
    errors.add(:category, 'must match penalty type') unless category_for_database / 100 * 100 == kind_for_database
  end
end
