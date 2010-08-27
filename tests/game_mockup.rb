# Klasse, die einen Buchmacher repr�sentiert, dient eigentlich nur der Zuordnung und braucht
# daher auch nicht viele Methoden, eventuell kann dies besser durch Symbole wie etwa :bet356
# gel�st werden.
class Bookmaker
  def initialize
  end

  def to_symbol
    # gibt sowas wie :bet365 zur�ck o.�.
    # eventuell Namensgebung �berdenken, die Funktion ist evtl. schon belegt.
  end
end

# Klasse zur Verwaltung der Teamnamen, die daf�r sorgt, dass egal von welchem Buchmacher
# (die ja verschiedene Namen f�r die gleichen reell existierenden Teams) intern das gleiche
# Team gemeint ist.
class Team
  def initialize(nameorid, bookmaker=nil)
    # nameorid.is_a? Integer -> das ist die ID
    # nameorid.is_a? String  -> herausfinden was die zugeh�rige ID ist, je nach bookmaker
    # eventuell zur Klarheit in zwei verschiedene Methoden unterteilen (etwa: create_from_id, create_from_name)
  end

  def unique_id
    # Gibt eine ID zur�ck, die das Team repr�sentiert
  end
end

class Game
  # Hier sollte evtl. ein Team-Objekt (bzw. zwei) �bergeben werden...
  # date + time -> timestamp ?
  def initialize(team_home, team_away, date = nil, time = nil)
    # Standardvariablen initialisieren

    @bets = []
  end

  def to_hash
    # generiert aus den Teamnamen und Datum und evtl. Uhrzeit einen Hash, der genau dieses Spiel
    # repr�sentiert, aber keine anderen. (unabh�ngig von Buchmacher!)
    # dadurch kann dann evtl. leicht gepr�ft werden ob das Spiel schon existiert und andere Wetten
    # k�nnen zugeordnet werden
    # eventuell eigene Funktion die nur genau dies generiert aus den genannten Eigenschaften
  end

  # zu einem "Game" geh�ren (und sind f�r uns wichtig):
  # - einzelne Quoten (Odds), die jeweils zu einem Buchmacher zugeordnet werden m�ssen
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
  #   game.bets -> gibt dann irgendwas zur�ck wie:
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
  #   Dann kann man n�mlich einfach �ber dieses Array iterieren und f�r jedes "Subarray" die einzelnen
  #   Quoten in allen Permutationen vergleichen. Sonst muss ja nichts verglichen werden!
  # }

  def bets
    # s.o.
  end
end

module Bet
  # FORMULIERUNG? Wettm�glichkeit f�nde ich treffender... "Bet" ist ja an sich dann schon wenn man
  # konkret gesetzt hat...
  #
  # eine "Bet" oder "Wettm�glichkeit" hat einen bestimmten Typ, in unserem Fall:
  # Moneyline, OverUnder oder Spread
  # unabh�ngig von diesem Typ haben alle Wetten gemeinsam:
  # - es gibt f�r verschiedene Buchmacher verschiedene Quoten
  # - das Ziel dieses Programms ist, diese zu vergleichen, dies w�rde ich als Funktion der einzelnen
  #   Wetttypen anlegen
  # 

  # Braucht man eine Klasse, aus der die einzelnen Arten geerbt werden?
  class Bet
  end

  # OverUnder-Wettm�glichkeit
  class OverUnder < Bet
    def initialize(threshold)
      # Eigenschaften:
      # "threshold" (eventuell Formulierung �ndern), also z.B. 2,5 Tore, 3,5 Tore, etc.
      @threshold = threshold

      # Hier ist ein Hash meiner Meinung nach angebracht, da es ja zu jedem Spiel von jedem Buchmacher nur
      # genau eine Quote gibt, daher kann man diesen mit dem Buchmacher indizieren
      @odds = Hash.new
    end

    # Diese Bet wird dann mit verschiedenen Odds gef�llt, diese haben ja immer die gleiche Form:
    # 
    def add_odd(bookmaker, odd1, odd2)
      # zur Frage ob odds lediglich in einem Array oder als Klasse die sie repr�sentiert abgelegt werden
      # sollen, siehe unten

      
      @odds[bookmaker.to_symbol] = [odd1, odd2]
      # alternativ:
      # @odds[bookmaker.to_symbol] = {:odd1 => odd1, :odd2 => odd2}
    end

    # Gibt in irgendeiner Form (am besten auch ne eigene Klasse) das zur�ck, was wir letztendlich suchen:
    # Die beste Wettm�glichkeit f�r diese, oder alle, sortiert nach ihrer Qualit�t
    def best_bet
      # erstellt zun�chst Permutationen so dass jede Kombinationsm�glichkeit von Buchmachern durchge-
      # gangen wird, speichert die berechneten Werte dann in ein Array
    end
  end

  # Moneyline12-Wettm�glichkeit
  class Moneyline12 < Bet
    def initialize
      # Hier ist ein Hash meiner Meinung nach angebracht, da es ja zu jedem Spiel von jedem Buchmacher nur
      # genau eine Quote gibt, daher kann man diesen mit dem Buchmacher indizieren
      @odds = Hash.new
    end

    # Diese Bet wird dann mit verschiedenen Odds gef�llt, diese haben ja immer die gleiche Form:
    # 
    def add_odd(bookmaker, odd1, odd2)
      # zur Frage ob odds lediglich in einem Array oder als Klasse die sie repr�sentiert abgelegt werden
      # sollen, siehe unten

      
      @odds[bookmaker.to_symbol] = [odd1, odd2]
      # alternativ:
      # @odds[bookmaker.to_symbol] = {:odd1 => odd1, :odd2 => odd2}
    end

    # Gibt in irgendeiner Form (am besten auch ne eigene Klasse) das zur�ck, was wir letztendlich suchen:
    # Die beste Wettm�glichkeit f�r diese, oder alle, sortiert nach ihrer Qualit�t
    def best_bet
      # erstellt zun�chst Permutationen so dass jede Kombinationsm�glichkeit von Buchmachern durchge-
      # gangen wird, speichert die berechneten Werte dann in ein Array
    end
  end

  # Moneyline1X2-Wettm�glichkeit
  class Moneyline1X2 < Bet
    def initialize
      # Hier ist ein Hash meiner Meinung nach angebracht, da es ja zu jedem Spiel von jedem Buchmacher nur
      # genau eine Quote gibt, daher kann man diesen mit dem Buchmacher indizieren
      @odds = Hash.new
    end

    # Diese Bet wird dann mit verschiedenen Odds gef�llt, diese haben ja immer die gleiche Form:
    # 
    def add_odd(bookmaker, odd1, oddX, odd2)
      # zur Frage ob odds lediglich in einem Array oder als Klasse die sie repr�sentiert abgelegt werden
      # sollen, siehe unten

      
      @odds[bookmaker.to_symbol] = [odd1, oddX, odd2]
      # alternativ:
      # @odds[bookmaker.to_symbol] = {:odd1 => odd1, :oddX => oddX, :odd2 => odd2}
    end

    # Gibt in irgendeiner Form (am besten auch ne eigene Klasse) das zur�ck, was wir letztendlich suchen:
    # Die beste Wettm�glichkeit f�r diese, oder alle, sortiert nach ihrer Qualit�t
    def best_bet
      # erstellt zun�chst Permutationen so dass jede Kombinationsm�glichkeit von Buchmachern durchge-
      # gangen wird, speichert die berechneten Werte dann in ein Array
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