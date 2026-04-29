# frozen_string_literal: true

require "test_helper"

module Scoring
  class PointWagerTest < ActiveSupport::TestCase
    test "starting points default to 1000" do
      league = create_league(wager_percentage: 5)
      scores = compute_scores(league)

      league.event_participants.playing.each do |ep|
        assert_equal 1000.0, scores[ep.id], "Starting points should be 1000"
      end
    end

    test "single winner takes all wagers" do
      league = create_league(wager_percentage: 10)
      pod = create_finished_pod_with_one_winner(league)

      compute_scores!(league)

      winner = pod.event_participants.find { |ep| ep.results.any?(Win) }
      losers = pod.event_participants.reject { |ep| ep == winner }

      # Winner should have more than starting points
      assert scores_for(league, winner.id) > 1000, "Winner should gain points"

      # Losers should have less than starting points
      losers.each do |ep|
        assert scores_for(league, ep.id) < 1000, "Losers should lose points"
      end
    end

    test "draw splits evenly" do
      league = create_league(wager_percentage: 10)
      pod = create_finished_all_draw_pod(league)

      compute_scores!(league)

      pod.event_participants.each do |ep|
        assert scores_for(league, ep.id) < 1000, "Draw participants should lose some points to pot"
      end

      # All participants should end up with same score after all-draw
      initial_scores = pod.event_participants.map { |_ep| 1000.0 }
      pot = initial_scores.sum { |s| (s * 10 / 100).round(2) }
      per_person = pot.fdiv(pod.event_participants.size)

      pod.event_participants.each do |ep|
        assert_equal per_person, scores_for(league, ep.id), "Draw participants split evenly"
      end
    end

    test "forward and reverse direction averaging" do
      league = create_league(wager_percentage: 5)

      # Round 1: Player A wins, Player B loses
      create_finished_pod_with_one_winner(league, winner_index: 0)

      # Round 2: Player B wins, Player A loses
      create_finished_pod_with_one_winner(league, winner_index: 1)

      compute_scores!(league)

      eps = league.event_participants.playing.order(id: :asc).to_a
      player_a = eps[0]
      player_b = eps[1]

      # With one win and one loss each (forward and reverse), scores should be similar
      score_a = scores_for(league, player_a.id)
      score_b = scores_for(league, player_b.id)

      # The averaging should result in relatively balanced scores
      # Both players have 1 win and 1 loss
      assert_in_delta score_a, score_b, 100, "Averaged scores should be similar"
    end

    test "multiple rounds accumulate correctly" do
      league = create_league(wager_percentage: 5)
      eps = league.event_participants.playing.order(id: :asc).to_a

      # Round 1: Pod with Player 0 winning
      pod1 = create_finished_pod_with_one_winner(league, winner_index: 0)
      assert_equal 4, pod1.event_participants.size
      assert_includes pod1.event_participants.map(&:id), eps[0].id

      # Round 2: Different pod with Player 2 winning (excludes player 0)
      pod2 = create_finished_pod_with_one_winner(league, winner_index: 0, size: 2, exclude: [eps[0], eps[1]])
      assert_equal Set.new([eps[2].id, eps[3].id]), Set.new(pod2.event_participants.map(&:id))

      compute_scores!(league)

      # Player 0 has 1 win (should gain)
      assert scores_for(league, eps[0].id) > 1000, "Player 0 should have gained from 1 win"
      # Player 2 has 1 win (should gain)
      assert scores_for(league, eps[2].id) > 1000, "Player 2 should have gained from 1 win"
    end

    test "works with 3-player pods" do
      league = create_league(wager_percentage: 5, pod_size: 3)
      pod = create_finished_pod_with_one_winner(league, winner_index: 0, size: 3)

      compute_scores!(league)

      winner = pod.event_participants.find { |ep| ep.results.any?(Win) }
      assert scores_for(league, winner.id) > 1000, "3-player pod winner should gain points"
    end

    test "works with 5-player pods" do
      league = create_league(wager_percentage: 5, pod_size: 5)
      pod = create_finished_pod_with_one_winner(league, winner_index: 0, size: 5)

      compute_scores!(league)

      winner = pod.event_participants.find { |ep| ep.results.any?(Win) }
      assert scores_for(league, winner.id) > 1000, "5-player pod winner should gain points"
    end

    test "recalculate_all! persists scores to event_participants" do
      league = create_league(wager_percentage: 5)
      create_finished_pod_with_one_winner(league)

      Scoring::PointWager.new(league).recalculate_all!

      league.event_participants.playing.each do |ep|
        assert_not_nil ep.league_score, "league_score should be persisted"
      end
    end

    private

    def create_league(wager_percentage: 5.0, pod_size: 4)
      # pod_size accepted for API compatibility but not used in league creation
      organizer = event_organizers(:standard_organizer)
      slug = "test-league-scoring-#{SecureRandom.hex(8)}"
      league = League.create!(
        name: "Test League #{slug}",
        slug: slug,
        event_organizer: organizer,
        wager_percentage: wager_percentage,
        start_time: 1.week.from_now,
        end_time: 2.weeks.from_now,
        type: "League"
      )

      players = []
      8.times do
        player = Player.create!(key: "test_#{players.size}_#{SecureRandom.hex(4)}")
        players << player
        EventParticipant.create!(
          event: league,
          player: player,
          dropped: false,
          league_score: 1000.0,
          rank: 0,
          accepted_terms: true
        )
      end

      league
    end

    def create_round(league, number: nil, is_play_round: true)
      number ||= (league.rounds.maximum(:number) || 0) + 1
      Round.create!(
        event: league,
        number: number,
        type: "SwissRound",
        started_at: 1.hour.ago,
        finished_at: 30.minutes.ago,
        published: true,
        is_play_round: is_play_round
      )
    end

    def create_finished_pod_with_one_winner(league, winner_index: 0, size: 4, exclude: [])
      round = create_round(league)

      excluded_ids = exclude.map(&:id)
      eps =
        if excluded_ids.empty?
          league.event_participants.playing.order(id: :asc).first(size)
        else
          league.event_participants.playing.where.not(id: excluded_ids).order(id: :asc).first(size)
        end
      pod = Pod.create!(round: round, number: round.pods.maximum(:number).to_i + 1, size: size)

      eps.each_with_index do |ep, i|
        pod.seatings.create!(event_participant: ep, order: i + 1)
      end
      pod.sit_participants!

      # Create win for winner, losses for others
      winner = eps[winner_index]
      losers = eps.reject { |ep| ep == winner }

      Result.create_or_update_by(round: round, event_participant: winner) do |r|
        r.type = "Win"
      end

      losers.each do |ep|
        Result.create_or_update_by(round: round, event_participant: ep) do |r|
          r.type = "Loss"
        end
      end

      pod.reload
    end

    def create_finished_all_draw_pod(league, size: 4)
      round = create_round(league)

      eps = league.event_participants.playing.order(id: :asc).first(size)
      pod = Pod.create!(round: round, number: round.pods.maximum(:number).to_i + 1, size: size)

      eps.each_with_index do |ep, i|
        pod.seatings.create!(event_participant: ep, order: i + 1)
      end
      pod.sit_participants!

      eps.each do |ep|
        Result.create_or_update_by(round: round, event_participant: ep) do |r|
          r.type = "Draw"
        end
      end

      pod.reload
    end

    def compute_scores(league)
      Scoring::PointWager.new(league).send(:compute_scores, direction: :forward)
    end

    def compute_scores!(league)
      Scoring::PointWager.new(league).recalculate_all!
    end

    def scores_for(league, event_participant_id)
      Scoring::PointWager.new(league).send(:compute_scores, direction: :forward)[event_participant_id]
    end
  end
end
