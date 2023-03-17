# frozen_string_literal: true

users = User.create(
  [
    { name: 'Fábio', email: 'fbatista@gmail.com', password: '123qwe' },
    { name: 'Simão', email: 'simao@canivete.com', password: '123qwe' },
    { name: 'Bandeira', email: 'bandeira@canivete.com', password: '123qwe' },
    { name: 'Esgaio', email: 'esgaio@canivete.com', password: '123qwe' },
    { name: 'Nuno', email: 'nuno@canivete.com', password: '123qwe' },
    { name: 'Pedro', email: 'pedro@canivete.com', password: '123qwe' },
    { name: 'Joao Pedro', email: 'jpedro@canivete.com', password: '123qwe' },
    { name: 'Gil', email: 'gil@canivete.com', password: '123qwe' },
    { name: 'Lucas', email: 'lucas@canivete.com', password: '123qwe' },
    { name: 'Artur', email: 'artur@canivete.com', password: '123qwe' },
    { name: 'Brandao', email: 'brandao@canivete.com', password: '123qwe' },
    { name: 'Chico', email: 'chico@canivete.com', password: '123qwe' },
    { name: 'Demerson', email: 'demerson@canivete.com', password: '123qwe' },
    { name: 'Guilherme', email: 'guilherme@canivete.com', password: '123qwe' },
    { name: 'Olivio', email: 'olivio@canivete.com', password: '123qwe' },
    { name: 'Tiago', email: 'tiago@canivete.com', password: '123qwe' }
  ]
)

players = users.map(&:player)

tournaments = Tournament.create(
  [
    { name: 'cEDH Coimbra XIX' },
    { name: 'cEDH Lisboa XXI' }
  ]
)

tournaments.each do |t|
  players.each do |p|
    TournamentParticipant.create(
      {
        tournament: t,
        player: p,
        decklist: "https://moxfield.com/decklist/#{p.user.email.split('@').first}"
      }
    )
  end
end
