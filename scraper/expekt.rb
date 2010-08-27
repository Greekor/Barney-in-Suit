class ExpektScraper
  def initialize(sports=['Baseball/MLB', 'Football/NFL'])
    @sports = sports
    @sporturls = {
      'Baseball/MLB' => 
      'http://www.expekt.com/odds/eventsodds.jsp?betcategoryId=BSBMENUSAUSAFST&range=1000000&sortby=2'
    }
    
    @reg_expr = {
      'Baseball/MLB' => /<tr class="oddsRow[1,2]">.+?<td align="center"> (\d{1,2}:\d{2}) <\/td>.+?<td align="center">([^-]+)-([^<]+).+?<td align="center">.+?<td align="center">.+?(\d{1,2}.\d{2}).+?<td align="center">.+?<td align="center">.+?(\d{1,2}.\d{2})/m,
    }
    
    @games = {}
  end
  
  
  def get_odds
    
    # Cookies
    headers = {
        'Cookie' => 'expekt_lang=ger'
    }
    
    #fetch each sport-type
    @sports.each do |name|
      puts("Hole #{name}-Daten von Expekt")
      $stdout.flush
      text = ""
      
      get_request(@sporturls[name], headers) { |string|
        text = text + string
      }
      
      # collect data
      #game: time, team1, team2, odd1, odd2
      @games[name] = text.scan(@reg_expr[name])
      if(@games[name].empty?)
        puts("Es konnten keine #{name}-Daten gefunden werden")
        $stdout.flush
      end
    end
  end

  def register_odds
    @games["Baseball/MLB"].each {
      |game|
      game[1].strip!
      game[2].strip!
      # WARUM??? wieso ist das auf der Expekt-Seite anders herum?
      gameobj = Game.find_or_create(game[2], game[1], Date.today)
      gameobj.bet(:moneyline12).add_odd(:expekt, game[4], game[3])
    }
  end
end

es = ExpektScraper.new(['Baseball/MLB'])
es.get_odds
es.register_odds