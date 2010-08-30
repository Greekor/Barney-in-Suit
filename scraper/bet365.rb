=begin
  Scraper Class for Bet365

  contains Bet365 specific scraping tools
=end

class Bet365Scraper

  # class constructor
  def initialize(sports)
    @sports = sports
    @bet365_sportids = {
      'Baseball/MLB' => "16",
      'Football/NFL' => "12",
      'Basketball' => "18"
    }

    @bet365_sportids_rev = {}
    @bet365_sportids.each_pair {
      |k,v|
      @bet365_sportids_rev[v] = k
    }

    @main_post_query = {
      "txtCurrentPageID" => "1020",
      "txtClassID" => "%d",
      "txtNavigationPB" => {},
      "txtSiteNavigationPB" => {},
      "txtSiteNavigationCachePB" => {}
    }

    @league_post_query = {
      "txtNavigationPB" => {},
      "txtSiteNavigationPB" => {
        "dummy" => "0"
      },
      "txtSiteNavigationCachePB" => {}
    }

    @headers = {
      "Cookie" => "aps03=lng=5&cf=N"
    }

    @queryformat = reform_query(@main_post_query)
    @reg = /onclick="javaScript:gPC2\((\d+),'','(\d+)','(\d+)','','(\d+)','(\d+)','','','',(\d+)\);return false;">([^<]+)<\/a>/

    @checkout = []

    @games = {}
  end
  
  def sport2id(sport)
    return @bet365_sportids[sport]
  end
  
  # get odds for each sport contained in @sports  
  def get_odds()
    @sports.each {
      |sport|
      puts("Hole #{sport}-Daten von Bet365")
      sportid = sport2id(sport)
      @games[sportid] = []

      # if sport invalid => next iteration
      next if sportid == -1

      query = @queryformat % sportid

      post_request('http://81.94.208.20/home/mainpage.asp', query, @headers) {
        |text|
        File.open("temp/#{sportid}.html", "w") { |f| f.write(text); f.close }

        text.scan(@reg).each {
          |betmode|
          case sportid
          when "12": # American Footbal / NFL
            @checkout.push betmode if (betmode[4] == "36") # "Alle Spiele"
          when "18": # Basketball
            @checkout.push betmode if (betmode[4] == "36")
          when "16": # Baseball
            @checkout.push betmode if (betmode[4] == "36")
          end
        }
      }
    }

    @checkout.each {
      |league| # Bezeichnung evtl. noch aendern... Nicht direkt Liga, sondern sowas wie ["100000", "20162551", "48", "1", "66", "12", "1-X-2 Wetten"]...

      @league_post_query["txtClassID"] = league[5]
      @league_post_query["txtNPID"] = league[0]
      @league_post_query["txtSiteNavigationPB"]["c1id"] = league[1]
      @league_post_query["txtSiteNavigationPB"]["c1idtable"] = league[2]
      @league_post_query["txtSiteNavigationPB"]["c2idtable"] = league[4]
      @league_post_query["txtSiteNavigationPB"]["c2id"] = league[3]

      query = reform_query(@league_post_query)

      # AUSLAGERN
#      regfnl = /<tr class="rh1">
#<td class="acn gb" rowspan="2">([^<]+)<\/td>
#<td class="ank w">([^<]*)<\/td>
#<td class="ank w">([^<]+)<\/td>
#.+?
#<td class="dcpng cbt bnk"[^>]+>([^<]+)<\/td>
#<td class="dcpngr cbt bcn"[^>]+>([^<]+)<\/td>
#<td class="dcpnl cbt bnk"[^>]+>([^<]+)<\/td>
#<td class="dcpnr cbt bcn"[^>]+>([^<]+)<\/td>
#<td class="dcpng bcn cbt"[^>]+>([^<]+)<\/td>
#.+?
#<tr class="rh1">
#<td class="bnk w">([^<]*)<\/td>
#<td class="bnk w">([^<]+)<\/td>
#<td class="dcpng bnk"[^>]+>([^<]+)<\/td>
#<td class="dcpngr bcn"[^>]+>([^<]+)<\/td>
#<td class="dcpnl bnk"[^>]+>([^<]+)<\/td>
#<td class="dcpnr bcn"[^>]+>([^<]+)<\/td>
#<td class="dcpng bcn"[^>]+>([^<]+)<\/td>/m
      # -------------------- AUSLAGERN -------------------

      regfnl = /<tr class="rh1">
<td class="acn gb" rowspan="2"[^>]+>([^<]+)<\/td>
<td class="ank w">([^<]*)<\/td>
<td class="ank w">([^<]+)<br>([^<]+)<\/td>
.+?
<td class="dcpng cbt bcn"[^>]+>([^<]+)<\/td>
<td class="dcpnl cbt bnk"[^>]+>([^<]+)<\/td>
<td class="dcpnr cbt bcn"[^>]+>([^<]+)<\/td>
.+?
<tr class="c1 rh1">
<td class="bnk w">([^<]*)<\/td>
<td class="bnk w">([^<]+)<br>([^<]+)<\/td>
<td class="dcpng bcn"[^>]+>([^<]+)<\/td>
<td class="dcpnl bnk"[^>]+>([^<]+)<\/td>
<td class="dcpnr bcn"[^>]+>([^<]+)<\/td>/m

      regleague = /<h3 id="cHdr">([^<]+)<\/h3>/

      post_request('http://81.94.208.20/home/mainpage.asp', query, @headers) {
        |text|
        File.open("temp/league#{league[0]}_#{league[1]}_#{league[2]}_#{league[3]}_#{league[4]}_#{league[5]}.html", "w") { |f| f.write(text); f.close }
#        puts "temp/league#{league[0]}_#{league[1]}_#{league[2]}_#{league[3]}_#{league[4]}_#{league[5]}.html created..."
#        league_name = text.scan(regleague)[0][0]
#        next unless /NBA/ =~ league_name
        items = text.scan(regfnl)

        items.map! {
          |item|

          # Aufbau:
          # [
          #   0 => "28 Aug 01:05",
          #   1 => "951",
          #   2 => "STL Cardinals\n\t\t\t\t\t\t\t\t&nbsp;",
          #   3 => "(J Garcia)",
          #   4 => "1.59",
          #   5 => "O 8.0",
          #   6 => "1.83",
          #   7 => "952",
          #   8 => "WAS Nationals",
          #   9 => "(S Olsen)",
          #  10 => "2.53",
          #  11 => "U 8.0",
          #  12 => "2.00"
          # ]
          #

          item[1] = (/^\d+$/ === item[1] ? item[1].to_i : -1) # Zahlen in Integer umwandeln
          item[7] = (/^\d+$/ === item[7] ? item[7].to_i : -1)

          item[2] = item[2].gsub('&nbsp;', '').strip # Namen reinigen
          item[8] = item[8].gsub('&nbsp;', '').strip
          
          item 
        }

#        items.each { |item| p item }        

        @games[league[5]] += items
      }
    }
  end

  def register_odds
    @games.each_pair {
      |sportid, data|
      data.each {
        |game|

        gameobj = Game.find_or_create(game[2], game[8], Date.today())
        gameobj.bet(:moneyline12).add_odd(:bet365, game[4], game[10])
      }
    }
  end

  def write_to_file(filename="output/bet365.xml")
    @games.each {
      |game|
      p game
    }
  end
end

bs = Bet365Scraper.new(['Baseball/MLB'])
bs.get_odds
bs.register_odds