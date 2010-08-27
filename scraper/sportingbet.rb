## Nur zusammengeschustert... wie bis jetzt ziemlich viel bei den Scrapern, aber irgendwo muss man ja mal anfangen... ##

class SportingbetScraper
	def initialize(sports)
		@sports = sports
		@sporturls = {
			'Baseball/MLB' => 'http://de.sportingbet.com/Aktuelle-Spiele/ECMARKET/9/77263/9'
		}
		@reg_expr = {
			'Baseball/MLB' => [
        /<span class="eventStartingTime" id="ec_\d+_time_(\d+)_evTime">([^<]+)<\/span>/,
        /<span id="ec_\d+_row_(\d+)_team_(away|home)">([^<]+)<\/span>/,
        /<a class="price addBetButton" id="ec_\d+_row_(\d+)_ml_(away|home)" href="javascript:;">([^<]+)/
      ]
		}
		@games = {}
	end

	def get_odds
		headers = {
		    'Cookie' => 'PriceStyle=decimal'
  		}

		@sports.each do |name|
			puts("Hole #{name}-Daten von Sportingbets")
			$stdout.flush
			text = ""
			post_request(@sporturls[name], "", headers) { |string|
				text = text + string
			}

      @games[name] = []

      text.scan(@reg_expr['Baseball/MLB'][0]).each {
        |m|
        @games[name][m[0].to_i] = {:time=>m[1]}
      }

      text.scan(@reg_expr['Baseball/MLB'][1]).each {
        |m|
        @games[name][m[0].to_i][("team_"+m[1]).to_sym] = m[2]
      }

      text.scan(@reg_expr['Baseball/MLB'][2]).each {
        |m|
        @games[name][m[0].to_i][("odd_"+m[1]).to_sym] = m[2].strip
      }
#game: tag, id1, team1, odd1, zeit, id2, team2, odd2
			if(text == "")
				puts("Es konnten keine Daten gefunden werden")
				$stdout.flush
			end
		end
	end

  def register_odds
    @games.each_pair {
      |sport, games2|
      games2.each {
        |game|

        # WIESO AUCH HIER ANDERSRUM?? was ist richtig und was ist falsch... unbedingt rausfinden...
        # DATUM -> RICHTIG AUSLESEN, EINHEITLICH MACHEN

        game[:team_home].strip!
        game[:team_away].strip!

        gameobj = Game.find_or_create(game[:team_away], game[:team_home], Date.today)
        gameobj.bet(:moneyline12).add_odd(:sportingbet, game[:odd_away], game[:odd_home])
      }
    }
  end
end

ps = SportingbetScraper.new(['Baseball/MLB'])
ps.get_odds
ps.register_odds