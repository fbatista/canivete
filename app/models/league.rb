# frozen_string_literal: true

class League < Event
  paginates_per 20

  enum :state, {
    draft: 0,
    registration_open: 1,
    registration_closed: 2,
    play: 3,
    finals: 4,
    finished: 5,
    canceled: 6
  }, default: :registration_open

  TRANSITIONS = {
    draft: %i[draft registration_open registration_closed],
    registration_open: %i[registration_open registration_closed canceled],
    registration_closed: %i[registration_closed play canceled],
    play: %i[finals finished canceled],
    finals: %i[finished canceled],
    finished: [:finished],
    canceled: [:canceled]
  }.with_indifferent_access.freeze

  scope :ongoing, -> { where(state: %i[play finals]) }

  def perform_state_based_actions
    return unless TRANSITIONS[state_previously_was.to_sym].include?(state.to_sym)

    case state.to_sym
    when :play
      Leagues::StartPlayRoundJob.perform_now(self)
    when :finals
      Leagues::StartFinalsRoundJob.perform_now(self)
    when :finished
      Leagues::FinishLeagueJob.perform_now(self)
    end
  end
end
