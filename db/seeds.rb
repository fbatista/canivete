# frozen_string_literal: true

# Create an initial list of users
users = User.create(
  [
    { name: 'Fábio', email: 'fabio@canivete.com', password: '123qwe' },
    { name: 'Simão', email: 'simao@canivete.com', password: '123qwe' },
    { name: 'Bandeira', email: 'bandeira@canivete.com', password: '123qwe' },
    { name: 'Esgaio', email: 'esgaio@canivete.com', password: '123qwe' },
    { name: 'Nuno', email: 'nuno@canivete.com', password: '123qwe' },
    { name: 'Pedro', email: 'pedro@canivete.com', password: '123qwe' },
    { name: 'Joao', email: 'joao@canivete.com', password: '123qwe' },
    { name: 'Gil', email: 'gil@canivete.com', password: '123qwe' },
    { name: 'Lucas', email: 'lucas@canivete.com', password: '123qwe' },
    { name: 'Artur', email: 'artur@canivete.com', password: '123qwe' },
    { name: 'Brandao', email: 'brandao@canivete.com', password: '123qwe' },
    { name: 'Chico', email: 'chico@canivete.com', password: '123qwe' },
    { name: 'Demerson', email: 'demerson@canivete.com', password: '123qwe' },
    { name: 'Guilherme', email: 'guilherme@canivete.com', password: '123qwe' },
    { name: 'Olivio', email: 'olivio@canivete.com', password: '123qwe' },
    { name: 'Tiago', email: 'tiago@canivete.com', password: '123qwe' },
    { name: 'Jose', email: 'jose@canivete.com', password: '123qwe' },
    { name: 'Vanessa', email: 'vanessa@canivete.com', password: '123qwe' },
    { name: 'Antonio', email: 'antonio@canivete.com', password: '123qwe' },
    { name: 'Fernando', email: 'fernando@canivete.com', password: '123qwe' },
    { name: 'Francisco', email: 'francisco@canivete.com', password: '123qwe' },
    { name: 'Afonso', email: 'afonso@canivete.com', password: '123qwe' },
    { name: 'Roberto', email: 'roberto@canivete.com', password: '123qwe' },
    { name: 'Bonifacio', email: 'bonifacio@canivete.com', password: '123qwe' },
    { name: 'Carlos', email: 'carlos@canivete.com', password: '123qwe' },
    { name: 'Joel', email: 'joel@canivete.com', password: '123qwe' },
    { name: 'Emanuel', email: 'emanuel@canivete.com', password: '123qwe' },
    { name: 'Vitor', email: 'vitor@canivete.com', password: '123qwe' },
    { name: 'Hugo', email: 'hugo@canivete.com', password: '123qwe' },
    { name: 'Mario', email: 'mario@canivete.com', password: '123qwe' },
    { name: 'Manuel', email: 'manuel@canivete.com', password: '123qwe' },
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
      cover: File.open('test/fixtures/files/cover1.jpg'),
      start_time: 2.weeks.from_now,
      end_time: 2.weeks.from_now + 8.hours
    },
    {
      name: 'Last Week Tournament example',
      state: :registration_open,
      tournament_organizer: other_to,
      cover: File.open('test/fixtures/files/cover2.jpg'),
      start_time: 5.minutes.ago,
      end_time: 10.hours.from_now
    },
    {
      name: 'Qualifier for EU Champ',
      state: :registration_open,
      tournament_organizer: to,
      cover: File.open('test/fixtures/files/cover3.jpg'),
      start_time: 1.week.from_now,
      end_time: 1.week.from_now + 1.day
    },
    {
      name: 'FNM Commander',
      state: :registration_open,
      tournament_organizer: to,
      cover: File.open('test/fixtures/files/cover4.jpg'),
      start_time: 1.week.from_now,
      end_time: 1.week.from_now + 1.day
    }
  ]
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

tournaments[1..].each do |tournament|
  users.map(&:player).each do |p|
    next if p.blank?

    TournamentParticipant.create(
      {
        tournament: tournament,
        player: p,
        decklist: "https://moxfield.com/decklist/#{p.user.email.split('@').first}",
        accepted_terms: true
      }
    )
  end
end

tournaments[1].update(state: :registration_closed)
tournaments[1].update(state: :swiss)
