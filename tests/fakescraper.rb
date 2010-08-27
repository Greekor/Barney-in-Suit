require "date"


require "game.rb"

#
# "Sammler", der immer die gleichen Daten "sammelt"/anbietet, um das ganze Klassenmodell (oder wie man das nennt) mal zu testen.
#

$data = {
    :moneyline12 => [
    { :team1 => "NO Hornets",
      :team2 => "ORL Magic",
      :odd1 => 5.25,
      :odd2 => 1.18,
      :date => Date.new(2010, 2, 9),
      :bookmaker => :fakescraper
    },

    { :team1 => "SA Spurs",
      :team2 => "LA Lakers",
      :odd1 => 2.65,
      :odd2 => 1.54,
      :date => Date.new(2010, 2, 9),
      :bookmaker => :fakescraper
    },

    { :team1 => "DAL Mavericks",
      :team2 => "GS Warriors",
      :odd1 => 1.57,
      :odd2 => 2.55,
      :date => Date.new(2010, 2, 9),
      :bookmaker => :fakescraper
    },


    { :team1 => "SA Spurs",
      :team2 => "ORL Magic",
      :odd1 => 1.57,
      :odd2 => 2.55,
      :date => Date.new(2010, 2, 9),
      :bookmaker => :fakescraper
    },


    { :team1 => "Test Mavericks",
      :team2 => "GS Warriors",
      :odd1 => 1.57,
      :odd2 => 4.55,
      :date => Date.new(2010, 2, 9),
      :bookmaker => :fakescraper
    },

    { :team1 => "DAL Mavericks",
      :team2 => "GS Warriors",
      :odd1 => 4.57,
      :odd2 => 3.55,
      :date => Date.new(2010, 2, 9),
      :bookmaker => :bet365
    },

    { :team1 => "Test Mavericks",
      :team2 => "GS Warriors",
      :odd1 => 1.07,
      :odd2 => 2.55,
      :date => Date.new(2010, 2, 9),
      :bookmaker => :expekt
    }
    ],

    :overunder => [
    { :team1 => "Test Mavericks",
      :team2 => "GS Warriors",
      :threshold => 2.5,
      :odd1 => 7.3,
      :odd2 => 2.55,
      :date => Date.new(2010, 2, 9),
      :bookmaker => :bet365
    },

    { :team1 => "DAL Mavericks",
      :team2 => "GSA Warriors",
      :threshold => 2.5,
      :odd1 => 5.3,
      :odd2 => 3.55,
      :date => Date.new(2010, 2, 9),
      :bookmaker => :expekt
    },    

    { :team1 => "Test Mavericks",
      :team2 => "GSA Warriors",
      :threshold => 2.5,
      :odd1 => 4.3,
      :odd2 => 7.55,
      :date => Date.new(2010, 2, 9),
      :bookmaker => :betathome
    },    

    { :team1 => "DAL Mavericks",
      :team2 => "GSA Warriors",
      :threshold => 3.5,
      :odd1 => 1.3,
      :odd2 => 8.46,
      :date => Date.new(2010, 2, 9),
      :bookmaker => :bet365
    },    

    { :team1 => "DAL Mavericks",
      :team2 => "GSA Warriors",
      :threshold => 3.5,
      :odd1 => 1.3,
      :odd2 => 7.55,
      :date => Date.new(2010, 2, 9),
      :bookmaker => :bet365
    }    
    ]
}



#
# Ablauf des Programms:
#

$data[:moneyline12].each {
  |bet|
  game = Game.find_or_create(bet[:team1], bet[:team2], bet[:date])
  game.bet(:moneyline12).add_odd(bet[:bookmaker], bet[:odd1], bet[:odd2])
}

$data[:overunder].each {
  |bet|
  game = Game.find_or_create(bet[:team1], bet[:team2], bet[:date])
  game.bet(:overunder, bet[:threshold]).add_odd(bet[:bookmaker], bet[:odd1], bet[:odd2])
}

Game.games.each_pair {
  |hash, game|
  puts game.description
  game.bets.each_pair {
    |type, bet|
    case type
      when :moneyline12
        puts bet.description
      when :overunder
        bet.each_pair { |threshold, overunder| puts overunder.description }
    end
  }
  puts 
}