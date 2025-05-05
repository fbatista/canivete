# frozen_string_literal: true

# Create an initial list of users
users = User.create(
  [
    { name: 'Fábio', email_address: 'fabio@canivete.com', password: '123qwe' },
    { name: 'Simão', email_address: 'simao@canivete.com', password: '123qwe' },
    { name: 'Bandeira', email_address: 'bandeira@canivete.com', password: '123qwe' },
    { name: 'Esgaio', email_address: 'esgaio@canivete.com', password: '123qwe' },
    { name: 'Nuno', email_address: 'nuno@canivete.com', password: '123qwe' },
    { name: 'Pedro', email_address: 'pedro@canivete.com', password: '123qwe' },
    { name: 'Joao', email_address: 'joao@canivete.com', password: '123qwe' },
    { name: 'Gil', email_address: 'gil@canivete.com', password: '123qwe' },
    { name: 'Lucas', email_address: 'lucas@canivete.com', password: '123qwe' },
    { name: 'Artur', email_address: 'artur@canivete.com', password: '123qwe' },
    { name: 'Brandao', email_address: 'brandao@canivete.com', password: '123qwe' },
    { name: 'Chico', email_address: 'chico@canivete.com', password: '123qwe' },
    { name: 'Demerson', email_address: 'demerson@canivete.com', password: '123qwe' },
    { name: 'Guilherme', email_address: 'guilherme@canivete.com', password: '123qwe' },
    { name: 'Olivio', email_address: 'olivio@canivete.com', password: '123qwe' },
    { name: 'Tiago', email_address: 'tiago@canivete.com', password: '123qwe' },
    { name: 'Jose', email_address: 'jose@canivete.com', password: '123qwe' },
    { name: 'Vanessa', email_address: 'vanessa@canivete.com', password: '123qwe' },
    { name: 'Antonio', email_address: 'antonio@canivete.com', password: '123qwe' },
    { name: 'Fernando', email_address: 'fernando@canivete.com', password: '123qwe' },
    { name: 'Francisco', email_address: 'francisco@canivete.com', password: '123qwe' },
    { name: 'Afonso', email_address: 'afonso@canivete.com', password: '123qwe' },
    { name: 'Roberto', email_address: 'roberto@canivete.com', password: '123qwe' },
    { name: 'Bonifacio', email_address: 'bonifacio@canivete.com', password: '123qwe' },
    { name: 'Carlos', email_address: 'carlos@canivete.com', password: '123qwe' },
    { name: 'Joel', email_address: 'joel@canivete.com', password: '123qwe' },
    { name: 'Emanuel', email_address: 'emanuel@canivete.com', password: '123qwe' },
    { name: 'Vitor', email_address: 'vitor@canivete.com', password: '123qwe' },
    { name: 'Hugo', email_address: 'hugo@canivete.com', password: '123qwe' },
    { name: 'Mario', email_address: 'mario@canivete.com', password: '123qwe' },
    { name: 'Manuel', email_address: 'manuel@canivete.com', password: '123qwe' },
    { name: 'Max', email_address: 'max@canivete.com', password: '123qwe' }
  ]
)

users.each(&:initialize_player)

# Create an initial tournament organizer
to = TournamentOrganizer.create!(
  user: User.create({ name: 'Kakah', email_address: 'kakah@canivete.com', password: '123qwe' })
)

other_to = TournamentOrganizer.create!(
  user: User.create({ name: 'Virgilio', email_address: 'virgilio@canivete.com', password: '123qwe' })
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
      decklist: "https://moxfield.com/decklist/#{p.user.email_address.split('@').first}",
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
        decklist: "https://moxfield.com/decklist/#{p.user.email_address.split('@').first}",
        accepted_terms: true
      }
    )
  end
end

tournaments[1].update(state: :registration_closed)
tournaments[1].update(state: :swiss)
