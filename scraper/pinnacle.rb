class PinnacleScraper
	def initialize(sports)
		@sports = sports
		@sporturls = {
			'Baseball/MLB' => 'http://www.pinnaclesports.com/League/Baseball/MLB/1/Lines.aspx'
		}
		@reg_expr = {
#			'Baseball/MLB' => /<tr class="AD\d">\s+<td>([^<]+)<\/td><td>[^<]+<\/td><td>([^<]+)(?:<BR(?: \/)?><EM>)[^<]+<\/EM><\/td><td>[^<]+<\/td><td>&nbsp;&nbsp;&nbsp;([^<]+)<\/td><td>[^<]+<\/td><td align="center" valign="middle" rowspan="2"><\/td>\s+<\/tr><tr class="AD\d">\s+<td>[^<]+<\/td><td>[^<]+<\/td><td>([^<]+)(?:<BR(?: \/)?><EM>)[^<]+<\/EM><\/td><td>[^<]+<\/td><td>&nbsp;&nbsp;&nbsp;([^<]+)<\/td><td>[^<]+<\/td>\s+<\/tr>/
      'Baseball/MLB' => /<tr class="linesAlt[1|2]">\s+<td class="linesDate">([^<]+)<\/td><td class="linesRotNumBold">(\d+)<\/td><td class="linesTeam">([^<]+)<BR \/><EM>([^<]+)<\/EM><\/td><td class="linesScore"><\/td><td class="linesSpread">([^<]+)<\/td><td class="linesMLine">([^<]+)<\/td><td class="linesTotals">([^<]+)<\/td><td class="linesMore" align="center" valign="middle" rowspan="2"><\/td>\s+<\/tr><tr class="linesAlt[1|2]">\s+<td>([^<]+)<\/td><td class="linesRotNumBold">(\d+)<\/td><td class="linesTeam">([^<]+)<BR><EM>([^<]+)<\/EM><\/td><td class="linesScore"><\/td><td class="linesSpread">([^<]+)<\/td><td class="linesMLine">([^<]+)<\/td><td class="linesTotals">([^<]+)<\/td>/
		}
		@games = {}
	end

	def get_odds
		headers = {
		    'Cookie' => 'PriceStyle=decimal'
  		}

		@sports.each do |name|
			puts("Hole #{name}-Daten von Pinnaclesports")
			$stdout.flush
			text = ""
			post_request(@sporturls[name], "", headers) { |string|
				text = text + string
			}
      matches = text.scan(@reg_expr['Baseball/MLB'])
      matches.map! {
        |match|

        [4,6,11,13].each {
          |x|
          match[x] = match[x].split('&nbsp;'*4)
        }

        [5,12].each {
          |x|
          match[x] = match[x].gsub('&nbsp;', '').strip
        }

        match.flatten!

        # Sieht jetzt so aus:
        # [
        #   0 => "Fri 8/27",
        #   1 => "979",
        #   2 => "Minnesota Twins",
        #   3 => "S. Baker",
        #   4 => "-1.5",
        #   5 => "2.310",
        #   6 => "1.813",
        #   7 => "OVER 7.5",
        #   8 => "2.110",
        #   9 => "07:10 PM",
        #  10 => "980",
        #  11 => "Seattle Mariners",
        #  12 => "J. Vargas",
        #  13 => "+1.5",
        #  14 => "1.704",
        #  15 => "2.160",
        #  16 => "UNDER 7.5",
        #  17 => "1.813"
        # ]

        match
      }
      #game: date, id1, team1, pitcher1, ???, odd1, ???, time, id2, team2, pitcher2, ???, odd2, ???
			@games[name] = matches
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
        gameobj = Game.find_or_create(game[2], game[11], Date.parse(game[0]))
        gameobj.bet(:moneyline12).add_odd(:pinnacle, game[6], game[15])
      }
    }
  end
end

ps = PinnacleScraper.new(['Baseball/MLB'])
ps.get_odds
ps.register_odds