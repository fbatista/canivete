# frozen_string_literal: true

users = User.create(
  [
    { name: 'Fábio', email: 'Fábio@canivete.com', password: '123qwe' },
    { name: 'Simão', email: 'Simão@canivete.com', password: '123qwe' },
    { name: 'Bandeira', email: 'Bandeira@canivete.com', password: '123qwe' },
    { name: 'Esgaio', email: 'Esgaio@canivete.com', password: '123qwe' },
    { name: 'Nuno', email: 'Nuno@canivete.com', password: '123qwe' },
    { name: 'Pedro', email: 'Pedro@canivete.com', password: '123qwe' },
    { name: 'Joao', email: 'Joao@canivete.com', password: '123qwe' },
    { name: 'Gil', email: 'Gil@canivete.com', password: '123qwe' },
    { name: 'Lucas', email: 'Lucas@canivete.com', password: '123qwe' },
    { name: 'Artur', email: 'Artur@canivete.com', password: '123qwe' },
    { name: 'Brandao', email: 'Brandao@canivete.com', password: '123qwe' },
    { name: 'Chico', email: 'Chico@canivete.com', password: '123qwe' },
    { name: 'Demerson', email: 'Demerson@canivete.com', password: '123qwe' },
    { name: 'Guilherme', email: 'Guilherme@canivete.com', password: '123qwe' },
    { name: 'Olivio', email: 'Olivio@canivete.com', password: '123qwe' },
    { name: 'Tiago', email: 'Tiago@canivete.com', password: '123qwe' },
    { name: 'Jose', email: 'Jose@canivete.com', password: '123qwe' },
    { name: 'Vanessa', email: 'Vanessa@canivete.com', password: '123qwe' },
    { name: 'Virgilio', email: 'Virgilio@canivete.com', password: '123qwe' },
    { name: 'Antonio', email: 'Antonio@canivete.com', password: '123qwe' },
    { name: 'Fernando', email: 'Fernando@canivete.com', password: '123qwe' },
    { name: 'Francisco', email: 'Francisco@canivete.com', password: '123qwe' },
    { name: 'Afonso', email: 'Afonso@canivete.com', password: '123qwe' },
    { name: 'Roberto', email: 'Roberto@canivete.com', password: '123qwe' },
    { name: 'Bonifacio', email: 'Bonifacio@canivete.com', password: '123qwe' },
    { name: 'Carlos', email: 'Carlos@canivete.com', password: '123qwe' },
    { name: 'Joel', email: 'Joel@canivete.com', password: '123qwe' },
    { name: 'Emanuel', email: 'Emanuel@canivete.com', password: '123qwe' },
    { name: 'Vitor', email: 'Vitor@canivete.com', password: '123qwe' },
    { name: 'Hugo', email: 'Hugo@canivete.com', password: '123qwe' },
    { name: 'Mario', email: 'Mario@canivete.com', password: '123qwe' },
    { name: 'Manuel', email: 'Manuel@canivete.com', password: '123qwe' }
  ]
)

players = users.map(&:player)

tournaments = Tournament.create(
  [
    { name: 'cEDH Coimbra XIX', state: :registration_open },
    { name: 'cEDH Lisboa XXI', state: :registration_open }
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
