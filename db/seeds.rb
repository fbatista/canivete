# frozen_string_literal: true

# Create an initial list of users
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
    { name: 'Manuel', email: 'Manuel@canivete.com', password: '123qwe' },
    { name: 'Max', email: 'max@canivete.com', password: '123qwe' }
  ]
)

users.each(&:initialize_player)

# Create an initial tournament organizer
to = TournamentOrganizer.create!(
  user: User.create({ name: 'Kakah', email: 'kakah@canivete.com', password: '123qwe' })
)

other_to = TournamentOrganizer.create!(
  user: User.create({ name: 'Virgilio', email: 'virgilio@canivete.com', password: '123qwe' })
)

# Create a couple of example tournaments
tournaments = Tournament.create!(
  [
    {
      name: 'Uneven Pods Tournament',
      state: :registration_open,
      prizes:
        <<~PRIZES,
          - 1st: Timetwister
          - 2nd: Gaea's Cradle
          - 3rd: Mox Diamond
          - 4th: Volcanic Island
        PRIZES
      tournament_organizer: to,
      address: 'Rua Princesa Cindazunda, 61, Coimbra',
      schedule:
        <<~SCHEDULE,
          **Day One**

          - 8:00am Checkin
          - 9:00am Player meeting
          - 9:15am Round 1
          - Round 2
          - Lunch Break
          - Round 3
          - Round 4
          - Round 5
          - Round 6

          **Day two**

          - 8:45 Player meeting
          - 9:00 Round 7
          - Top 40
          - Top 16
          - Top 4
        SCHEDULE
      participants_range: 10..256,
      price: 35,
      currency: :euro,
      rules:
        <<~RULES,
          Format: Commander
          REL: Competitive
          Multiplayer Addendum: https://juizes-mtg-portugal.github.io
          Playtest cards: Allowed, no limit.
        RULES
      cover: File.open('test/fixtures/files/cover.jpg'),
      start_time: 2.weeks.from_now,
      end_time: 2.weeks.from_now + 8.hours
    },
    {
      name: 'Even Pods Tournament',
      state: :registration_open,
      tournament_organizer: to,
      cover: File.open('test/fixtures/files/banner.png'),
      start_time: 1.week.from_now,
      end_time: 1.week.from_now + 1.day
    }
  ]
)

empty_tournaments = Tournament.create!(
  (1..52).map do |w|
    {
      name: 'FNM',
      state: :registration_open,
      tournament_organizer: other_to,
      cover: File.open('test/fixtures/files/banner.png'),
      start_time: w.week.from_now,
      end_time: w.week.from_now + 5.hours
    }
  end
)

# Add players to the tournaments

users.map(&:player)[0...21].each do |p|
  next if p.blank?

  TournamentParticipant.create(
    {
      tournament: tournaments.first,
      player: p,
      decklist: "https://moxfield.com/decklist/#{p.user.email.split('@').first}",
      accepted_terms: true
    }
  )
end

users.map(&:player).each do |p|
  next if p.blank?

  TournamentParticipant.create(
    {
      tournament: tournaments.last,
      player: p,
      decklist: "https://moxfield.com/decklist/#{p.user.email.split('@').first}",
      accepted_terms: true
    }
  )
end
