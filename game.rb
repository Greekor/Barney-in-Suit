# LINKS:  VOM ANBIETER NAME
# RECHTS: WIE SOLL DAS TEAM HEI�EN

module Teamname
  # hash stores: bookmaker's teamname -> id
  @@index = {}
  # hash stores: distinctive id -> unique name
  @@index_id = {}
  # number of stores teamnames
  @@c = 0

  # logs "manually" added teamnames
  @@registered_new = []

  # initiates Teamnames
  # reads them from files in "folder" (argument)
  # filenames must be of *.names
  def Teamname.init(folder="teamnames")
    # new hash
    index_reverse = {}
    # XXX: don't think this is really needed
    @@index = {}

    Dir["#{folder}/*.names"].each {
      |namefile|
      list = File.read(namefile)
      list.each {
        |line|
        line.strip!
        # skip comments or empty lines
        next if (line[0] == "#") || (line.empty?)
        left, right = line.split(";")

        # push combination in array
        # new array ?
        index_reverse[right] = [] unless index_reverse.has_key? right
        # XXX: why push right?
        # index_reverse[right].push right
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

  # looks up a bookmaker's teamname / maybe adds it to index
  # returns id
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

  # returns unique name linked with id
  def Teamname.find_by_id(id)
    @@index_id[id] || "Unknown Team"
  end

  # XXX: y is that required?
  def Teamname.index
    @@index
  end

  # XXX: y is that required?
  def Teamname.index_id
    @@index_id
  end

  # XXX: y is that required?
  def Teamname.registered_new
    @@registered_new
  end
end

# initiate Teamnnames
# XXX: Should maybe somewhere else?
Teamname.init

# Klasse, die einen Buchmacher repräsentiert, dient eigentlich nur der Zuordnung und braucht
# daher auch nicht viele Methoden, eventuell kann dies besser durch Symbole wie etwa :bet356
# gelöst werden
# XXX: class Bookmaker needed?
class Bookmaker
  def initialize
  end

  def to_symbol
    # gibt sowas wie :bet365 zurück o.ä.
    # eventuell Namensgebung überdenken, die Funktion ist evtl schon belegt
  end
end

# Klasse zur Verwaltung der Teamnamen, die dafür sorgt, dass egal von welchem Buchmacher
# (die ja verschiedene Namen für die gleichen reell existierenden Teams) intern das gleiche
# Team gemeint ist
class Team
  # hash: id -> Team
  @@teams = {}
  # XXX: not used
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

  # classmethod!!
  # team can either be an integer or a string
  #
  # returns Team-Object, also creates new object if necessary
  def Team.find(team)
    if (team.is_a?(Integer))
      uid = team
    elsif team.is_a?(String)
      uid = Teamname.lookup(team)
    end

    @@teams[uid] || Team.new(uid)
  end

  # Gibt eine ID zurück, die das Team repräsentiert
  def uid
    @uid
  end

  # returns name of team
  def name
    @name
  end

  # returns information string
  def description
    "#{@name} (#{@uid})"
  end
end


=begin
  Class Game
=end
class Game
  # hash: hash -> Game 
  @@games = {}

  # TODO: Hier sollte evtl. ein Team-Objekt (bzw zwei.) übergeben werden...
  # date + time -> timestamp ?
  def initialize(team1, team2, date = nil, time = nil)
    # Standardvariablen initialisieren

    @team1 = Team.find(team1)
    @team2 = Team.find(team2)
    @date = date
    
    # TODO: what about time?

    @bets = {}
    @hash = Game.create_hash(@team1, @team2, date)
    @@games[@hash] = self
  end

  attr_reader :hash

  # find Game
  # XXX: what arguments required?
  def Game.find_or_create(*args)
    hash = ((args.length == 3) ? Game.create_hash(*args) : args[0])

    @@games[hash] || ((args.length == 3) ? Game.new(*args) : nil)
  end

  # class method
  # returns hash including all games
  def Game.games
    @@games
  end

  # return info-string
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
  #        0 -> Odds::Moneyline12 [ odds -> [ Quoten f�r die einzelnen Buchmacher ] ]                                                             |
  #     ],                                                                            .----------------------------------------------------------�
  #     ...                                                                          /
  #   ]                                                                             |
  #   Dann kann man nämlich einfach über dieses Array iterieren und für jedes "Subarray" die einzelnen
  #   Quoten in allen Permutationen vergleichen. Sonst muss ja nichts verglichen werden!
  # }

  # XXX: attr_reader :bets
  def bets
    # s.o.
    @bets
  end

  # creates new bet, adds it to the instance hash/array
  # returns bet
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

  # returns nice print-out
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
  # parent class
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

    # Gibt in irgendeiner Form (am besten auch ne eigene Klasse) das zur�ck, was wir letztendlich suchen:
    # Die beste Wettm�glichkeit f�r diese, oder alle, sortiert nach ihrer Qualit�t
    def best_bet
      # erstellt zun�chst Permutationen so dass jede Kombinationsm�glichkeit von Buchmachern durchge-
      # gangen wird, speichert die berechneten Werte dann in ein Array
    end

    # returns info-string
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
      # hash: bookmaker -> odds-array
      @odds = Hash.new
    end

    # Diese Bet wird dann mit verschiedenen Odds gefüllt, diese haben ja immer die gleiche Form:
    # 
    def add_odd(bookmaker, odd1, odd2)
      # zur Frage ob odds lediglich in einem Array oder als Klasse die sie repr�sentiert abgelegt werden
      # sollen, siehe unten

      
      @odds[bookmaker] = [odd1, odd2]
      # alternativ:
      # @odds[bookmaker.to_symbol] = {:odd1 => odd1, :odd2 => odd2}
    end

    # Gibt in irgendeiner Form (am besten auch ne eigene Klasse) das zur�ck, was wir letztendlich suchen:
    # Die beste Wettm�glichkeit f�r diese, oder alle, sortiert nach ihrer Qualit�t
    def best_bet
      # erstellt zun�chst Permutationen so dass jede Kombinationsm�glichkeit von Buchmachern durchge-
      # gangen wird, speichert die berechneten Werte dann in ein Array
    end

    # returns info-string
    def description
      out = "Moneyline (1-2) bet. Odds:"
      @odds.each_pair {
        |bookmaker, odd|
        out += "\n  #{bookmaker}: 1: #{odd[0]} - 2: #{odd[1]}"
      }
      out
    end
  end

  # Moneyline1X2-Wettm�glichkeit
  class Moneyline1X2 < Bet
    def initialize
     # hash: bookmaker -> odds-array
      @odds = Hash.new
    end

    # Diese Bet wird dann mit verschiedenen Odds gef�llt, diese haben ja immer die gleiche Form:
    # 
    def add_odd(bookmaker, odd1, oddX, odd2)
      # zur Frage ob odds lediglich in einem Array oder als Klasse die sie repr�sentiert abgelegt werden
      # sollen, siehe unten

      
      @odds[bookmaker] = [odd1, oddX, odd2]
      # alternativ:
      # @odds[bookmaker.to_symbol] = {:odd1 => odd1, :oddX => oddX, :odd2 => odd2}
    end

    # Gibt in irgendeiner Form (am besten auch ne eigene Klasse) das zur�ck, was wir letztendlich suchen:
    # Die beste Wettm�glichkeit f�r diese, oder alle, sortiert nach ihrer Qualit�t
    def best_bet
      # erstellt zun�chst Permutationen so dass jede Kombinationsm�glichkeit von Buchmachern durchge-
      # gangen wird, speichert die berechneten Werte dann in ein Array
    end

    # returns info-string
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

# Braucht man f�r die Odds selbst eine eigene Klasse?
# Insofern, dass alles bis jetzt Objekt-Orientiert dargestellt wurde w�re es eventuell sinnvoll, allerdings
# brauchen die Odds selbst ja keine eigenen Funktionen o.�.


## Verwaltung generell ##

# Da muss ich mich nun Einlesen, wie das aussieht mit Modulen und Singletons, globale Variablen und sowas,
# denn im Endeffekt will ich ja mit dem Scraper das machen k�nnen:
# [Pseudocode]
#
# ...
# game = Game.find(team1, team2, timestamp)
# game.bets[:moneyline12].add_odd(:bet365, q1, q2)
# ...


## Wie wird das ganze nun gespeichert und gelesen? ##

#
# Die einzelnen Scraper suchen f�r die gesammelten Daten zun�chst durch den Teamnamen/Timestamp-Hash das passende
# Spiel heraus und f�gen ihre Quoten zu den jeweiligen Wetten hinzu
#