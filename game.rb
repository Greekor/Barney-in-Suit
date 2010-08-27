# LINKS:  VOM ANBIETER NAME
# RECHTS: WIE SOLL DAS TEAM HEIßEN

module Teamname
  @@index = {}
  @@index_id = {}
  @@c = 0

  @@registered_new = []

  def Teamname.init(folder="teamnames")
    index_reverse = {}
    @@index = {}

    Dir["#{folder}/*.names"].each {
      |namefile|
      list = File.read(namefile)
      list.each {
        |line|
        line.strip!
        next if (line[0] == "#") || (line.empty?)
        left, right = line.split(";")

        index_reverse[right] = [] unless index_reverse.has_key? right
        index_reverse[right].push right
        index_reverse[right].push left
      }
    }

    @@c = 0
    index_reverse.each_pair {
      |k,v|
      @@index_id[@@c] = k
      v.each {
        |name|
        @@index[name] = @@c
      }
      @@c += 1
    }
  end

  def Teamname.lookup(team)
    if @@index.has_key? team
      @@index[team]
    else
      @@c += 1
      @@index[team] = @@c
      @@index_id[@@c] = team
      @@c

      @@registered_new.push team
    end
  end

  def Teamname.find_by_id(id)
    @@index_id[id] || "Unknown Team"
  end

  def Teamname.index
    @@index
  end

  def Teamname.index_id
    @@index_id
  end

  def Teamname.registered_new
    @@registered_new
  end
end

Teamname.init

# Klasse, die einen Buchmacher repräsentiert, dient eigentlich nur der Zuordnung und braucht
# daher auch nicht viele Methoden, eventuell kann dies besser durch Symbole wie etwa :bet356
# gelöst werden.
class Bookmaker
  def initialize
  end

  def to_symbol
    # gibt sowas wie :bet365 zurück o.ä.
    # eventuell Namensgebung überdenken, die Funktion ist evtl. schon belegt.
  end
end

# Klasse zur Verwaltung der Teamnamen, die dafür sorgt, dass egal von welchem Buchmacher
# (die ja verschiedene Namen für die gleichen reell existierenden Teams) intern das gleiche
# Team gemeint ist.
class Team
  @@teams = {}
  @@count = 0
  def initialize(nameorid)
    # nameorid.is_a? Integer -> das ist die ID
    # nameorid.is_a? String  -> herausfinden was die zugehörige ID ist, je nach bookmaker
    # eventuell zur Klarheit in zwei verschiedene Methoden unterteilen (etwa: create_from_id, create_from_name)

    if nameorid.is_a?(Integer)
      @uid = nameorid
    elsif nameorid.is_a?(String)
      @uid = Teamname.lookup(nameorid)
    end

    @name = Teamname.find_by_id(nameorid)
    @@teams[@uid] = self
  end

  def Team.find(team)
    if (team.is_a?(Integer))
      uid = team
    elsif team.is_a?(String)
      uid = Teamname.lookup(team)
    end

    @@teams[uid] || Team.new(uid)
  end

  def uid
    # Gibt eine ID zurück, die das Team repräsentiert
    @uid
  end

  def name
    @name
  end

  def description
    "#{@name} (#{@uid})"
  end
end

class Game
  @@games = {}

  # Hier sollte evtl. ein Team-Objekt (bzw. zwei) übergeben werden...
  # date + time -> timestamp ?
  def initialize(team1, team2, date = nil, time = nil)
    # Standardvariablen initialisieren

    @team1 = Team.find(team1)
    @team2 = Team.find(team2)
    @date = date

    @bets = {}
    @hash = Game.create_hash(@team1, @team2, date)
    @@games[@hash] = self
  end

  attr_reader :hash

  # find Game
  def Game.find_or_create(*args)
    hash = ((args.length == 3) ? Game.create_hash(*args) : args[0])

    @@games[hash] || ((args.length == 3) ? Game.new(*args) : nil)
  end

  def Game.games
    @@games
  end

  def description
    "<#{@team1.description}> vs. <#{@team2.description}> on #{@date.to_s}"
  end

  # generiert aus den Teamnamen und Datum und evtl. Uhrzeit einen Hash, der genau dieses Spiel
  # repräsentiert, aber keine anderen. (unabhängig von Buchmacher!)
  # dadurch kann dann evtl. leicht geprüft werden ob das Spiel schon existiert und andere Wetten
  # können zugeordnet werden
  # eventuell eigene Funktion die nur genau dies generiert aus den genannten Eigenschaften
  def Game.create_hash(team1_arg, team2_arg, date)
    team1 = (team1_arg.is_a?(Team) ? team1_arg : Team.find(team1_arg))
    team2 = (team1_arg.is_a?(Team) ? team2_arg : Team.find(team2_arg))
    "#{team1.uid}-#{team2.uid}-#{date.hash}"
  end

  # zu einem "Game" gehören (und sind für uns wichtig):
  # - einzelne Quoten (Odds), die jeweils zu einem Buchmacher zugeordnet werden müssen
  #   diese sind unterteilt in:
  #   - Over/Under
  #   - Moneyline
  #   - Spread (auch wenn ich das im Moment nicht so zuordnen kann)
  #
  # im weiteren Verlauf des Programms ist das Ziel ja, konkret diese Quoten zu vergleichen und zu verrechnen,
  # deswegen ist es sinnvoll sie direkt so zu gruppieren, dass man nicht alles zehnmal raussuchen muss
  # (kostet Rechenzeit und Nerven).
  #
  # bsp: (Pseudocode)
  # 
  # Games.each { |game|
  #   game.bets -> gibt dann irgendwas zurück wie:
  #   Array [
  #     0 -> Array [  <--- eventuell anders Indexen, direkt mit dem Typ der Wetten, :overunder, :moneyline12, ...          \
  #        0 -> Bet::OverUnder [ 2.5, [ odds -> [ [bookmaker1, q1, q2], [bookmaker2, q1, q2], [bookmaker3, q1, q2] ] ] ],   |
  #        1 -> Bet::OverUnder [ 3.5, [ odds -> [ [bookmaker1, q1, q2], [bookmaker2, q1, q2], [bookmaker3, q1, q2] ] ] ],   |
  #        2 -> Bet::OverUnder [ 4.5, [ odds -> [ [bookmaker1, q1, q2], [bookmaker2, q1, q2], [bookmaker3, q1, q2] ] ] ]    |--------------------.
  #        ...                                                                                                              |                     `
  #     ],                                                                                                                 /                      |
  #     1 -> Array [                                                                                                                              |
  #        0 -> Odds::Moneyline12 [ odds -> [ Quoten für die einzelnen Buchmacher ] ]                                                             |
  #     ],                                                                            .----------------------------------------------------------´
  #     ...                                                                          /
  #   ]                                                                             |
  #   Dann kann man nämlich einfach über dieses Array iterieren und für jedes "Subarray" die einzelnen
  #   Quoten in allen Permutationen vergleichen. Sonst muss ja nichts verglichen werden!
  # }

  def bets
    # s.o.
    @bets
  end

  def bet(bettype, threshold=nil)
    case bettype
    when :moneyline12 then
      @bets[:moneyline12] = Bet::Moneyline12.new unless @bets.has_key? :moneyline12
      @bets[:moneyline12]
    when :moneyline1x2 then
      @bets[:moneyline1x2] = Bet::Moneyline1x2.new unless @bets.has_key? :moneyline1x2
      @bets[:moneyline1x2]
    when :overunder
      @bets[:overunder] = {} unless @bets.has_key? :overunder
      @bets[:overunder][threshold] = Bet::OverUnder.new(threshold) unless @bets[:overunder].has_key? threshold
      @bets[:overunder][threshold]
    end
  end

  def Game.niceout
    @@games.each_pair {
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
  end
end

module Bet
  # FORMULIERUNG? Wettmöglichkeit fände ich treffender... "Bet" ist ja an sich dann schon wenn man
  # konkret gesetzt hat...
  #
  # eine "Bet" oder "Wettmöglichkeit" hat einen bestimmten Typ, in unserem Fall:
  # Moneyline, OverUnder oder Spread
  # unabhängig von diesem Typ haben alle Wetten gemeinsam:
  # - es gibt für verschiedene Buchmacher verschiedene Quoten
  # - das Ziel dieses Programms ist, diese zu vergleichen, dies würde ich als Funktion der einzelnen
  #   Wetttypen anlegen
  # 

  # Braucht man eine Klasse, aus der die einzelnen Arten geerbt werden?
  class Bet
    def odds
      @odds
    end
  end

  # OverUnder-Wettmöglichkeit
  class OverUnder < Bet
    def initialize(threshold)
      # Eigenschaften:
      # "threshold" (eventuell Formulierung ändern), also z.B. 2,5 Tore, 3,5 Tore, etc.
      @threshold = threshold

      # Hier ist ein Hash meiner Meinung nach angebracht, da es ja zu jedem Spiel von jedem Buchmacher nur
      # genau eine Quote gibt, daher kann man diesen mit dem Buchmacher indizieren
      @odds = Hash.new
    end

    # Diese Bet wird dann mit verschiedenen Odds gefüllt, diese haben ja immer die gleiche Form:
    # 
    def add_odd(bookmaker, odd1, odd2)
      # zur Frage ob odds lediglich in einem Array oder als Klasse die sie repräsentiert abgelegt werden
      # sollen, siehe unten

      @odds[bookmaker] = [odd1, odd2]
      # alternativ:
      # @odds[bookmaker.to_symbol] = {:odd1 => odd1, :odd2 => odd2}
    end

    # Gibt in irgendeiner Form (am besten auch ne eigene Klasse) das zurück, was wir letztendlich suchen:
    # Die beste Wettmöglichkeit für diese, oder alle, sortiert nach ihrer Qualität
    def best_bet
      # erstellt zunächst Permutationen so dass jede Kombinationsmöglichkeit von Buchmachern durchge-
      # gangen wird, speichert die berechneten Werte dann in ein Array
    end

    def description
      out = "Over/Under bet with threshold #{@threshold}. Odds:"
      @odds.each_pair {
        |bookmaker, odd|
        out += "\n  #{bookmaker}: #{odd[0]} vs. #{odd[1]}"
      }
      out
    end
  end

  # Moneyline12-Wettmöglichkeit
  class Moneyline12 < Bet
    def initialize
      # Hier ist ein Hash meiner Meinung nach angebracht, da es ja zu jedem Spiel von jedem Buchmacher nur
      # genau eine Quote gibt, daher kann man diesen mit dem Buchmacher indizieren
      @odds = Hash.new
    end

    # Diese Bet wird dann mit verschiedenen Odds gefüllt, diese haben ja immer die gleiche Form:
    # 
    def add_odd(bookmaker, odd1, odd2)
      # zur Frage ob odds lediglich in einem Array oder als Klasse die sie repräsentiert abgelegt werden
      # sollen, siehe unten

      
      @odds[bookmaker] = [odd1, odd2]
      # alternativ:
      # @odds[bookmaker.to_symbol] = {:odd1 => odd1, :odd2 => odd2}
    end

    # Gibt in irgendeiner Form (am besten auch ne eigene Klasse) das zurück, was wir letztendlich suchen:
    # Die beste Wettmöglichkeit für diese, oder alle, sortiert nach ihrer Qualität
    def best_bet
      # erstellt zunächst Permutationen so dass jede Kombinationsmöglichkeit von Buchmachern durchge-
      # gangen wird, speichert die berechneten Werte dann in ein Array
    end

    def description
      out = "Moneyline (1-2) bet. Odds:"
      @odds.each_pair {
        |bookmaker, odd|
        out += "\n  #{bookmaker}: 1: #{odd[0]} - 2: #{odd[1]}"
      }
      out
    end
  end

  # Moneyline1X2-Wettmöglichkeit
  class Moneyline1X2 < Bet
    def initialize
      # Hier ist ein Hash meiner Meinung nach angebracht, da es ja zu jedem Spiel von jedem Buchmacher nur
      # genau eine Quote gibt, daher kann man diesen mit dem Buchmacher indizieren
      @odds = Hash.new
    end

    # Diese Bet wird dann mit verschiedenen Odds gefüllt, diese haben ja immer die gleiche Form:
    # 
    def add_odd(bookmaker, odd1, oddX, odd2)
      # zur Frage ob odds lediglich in einem Array oder als Klasse die sie repräsentiert abgelegt werden
      # sollen, siehe unten

      
      @odds[bookmaker] = [odd1, oddX, odd2]
      # alternativ:
      # @odds[bookmaker.to_symbol] = {:odd1 => odd1, :oddX => oddX, :odd2 => odd2}
    end

    # Gibt in irgendeiner Form (am besten auch ne eigene Klasse) das zurück, was wir letztendlich suchen:
    # Die beste Wettmöglichkeit für diese, oder alle, sortiert nach ihrer Qualität
    def best_bet
      # erstellt zunächst Permutationen so dass jede Kombinationsmöglichkeit von Buchmachern durchge-
      # gangen wird, speichert die berechneten Werte dann in ein Array
    end

    def description
      out = "Moneyline (1X2) bet. Odds:"
      @odds.each_pair {
        |bookmaker, odd|
        out += "\n  #{bookmaker}: 1: #{odd[0]} - X: #{odd[1]} - 2: #{odd[2]}"
      }
      out
    end
  end
end

# Braucht man für die Odds selbst eine eigene Klasse?
# Insofern, dass alles bis jetzt Objekt-Orientiert dargestellt wurde wäre es eventuell sinnvoll, allerdings
# brauchen die Odds selbst ja keine eigenen Funktionen o.ä.


## Verwaltung generell ##

# Da muss ich mich nun Einlesen, wie das aussieht mit Modulen und Singletons, globale Variablen und sowas,
# denn im Endeffekt will ich ja mit dem Scraper das machen können:
# [Pseudocode]
#
# ...
# game = Game.find(team1, team2, timestamp)
# game.bets[:moneyline12].add_odd(:bet365, q1, q2)
# ...


## Wie wird das ganze nun gespeichert und gelesen? ##

#
# Die einzelnen Scraper suchen für die gesammelten Daten zunächst durch den Teamnamen/Timestamp-Hash das passende
# Spiel heraus und fügen ihre Quoten zu den jeweiligen Wetten hinzu
#