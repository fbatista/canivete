users = User.create([
  {name: "Fábio", email: "fbatista@gmail.com"},
  {name: "Simão", email: "simao@canivete.com"},
  {name: "Bandeira", email: "bandeira@canivete.com"},
  {name: "Esgaio", email: "esgaio@canivete.com"},
  {name: "Nuno", email: "nuno@canivete.com"},
])

players = users.map(&:player)

tournaments = Tournament.create([
  { name: "cEDH Coimbra XIX" },
  { name: "cEDH Lisboa XXI" }
])

tournament_participant_params = players.first(4).map do |p|
  {
    tournament: tournaments.first,
    player: p,
    decklist: "https://moxfield.com/decklist/#{p.user.email.split("@").first}"
  }
end
tournament_participants = TournamentParticipant.create(tournament_participant_params)
