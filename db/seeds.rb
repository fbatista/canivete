# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
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

tournament_participants = TournamentParticipant.create(
  players.first(4).map{ |p| { player: p, decklist: "https://moxfield.com/decklist/#{p.user.email.split("@").first}" } }
)