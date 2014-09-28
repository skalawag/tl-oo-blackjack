require 'pry'

# * Blackjack: Game description

# In a game of Blackjack, one or more players each plays against the
# dealer. A round of play goes as follows.  The dealer will shuffle the
# deck (or decks) and deal two cards to each player and to himself.
# When it is a player's turn to act, he must choose whether to take a
# hit (an additional card) or stay with his hand as it is. The player
# can take as many additional cards as he likes until the value of his
# hand exceeds 21 points (or `busts'). If the player's hand exceeds 21
# at this point, he has lost. When the player chooses to stay, his turn
# ends, and the next player goes. When all the players have gone, it is
# then the dealer's turn act. The dealer first checks to see if he has
# Blackjack (a hand with an Ace and a ten or face card. If he does not
# have Blackjack, he takes additional cards until the value of his hand
# is greater than or equal to 17 (the dealer's strategy is usually set
# in advance, but it needn't be.)  Once the dealer's turn has ended, he
# evaluates his hand against each of the players hands. If both dealer
# and a player have Blackjack, or if both have hands with the same
# value, the hand is a tie. Otherwise, the one with higher hand value
# wins.

# * Nouns/Behaviors

# Player
#   - makes choices
# Deck
#   - shuffles itself
# Card
#   - reports its value
#   - has a representation of itself
# Game
#   - keeps track of turns
#   - queries players
#   - determines winner
#   - holds the deck and deals cards

module Scoring

  def total
    self.hand.map { |c| c.value }.reduce(:+)
  end

  def aces
    self.hand.select { |c| c if c.rank == 'A' }.count
  end

  def hand_value(soft=false)
    values, num_of_aces = [total()], aces()
    num_of_aces.times do
      values = values + values.map { |v| v - 10 }
      num_of_aces -= 1
    end
    if not soft
      values.select { |c| c if c < 22 }.max || values.min
    elsif values.min > 21
      values.min.to_s
    elsif values.select { |c| c if c < 22 }.uniq.length == 1
      values.select { |c| c if c < 22 }.uniq.first.to_s
    else
      values.select { |c| c if c < 22 }.uniq.reverse.join("/")
    end
  end
end

class Player
  include Scoring

  attr_reader :name
  attr_accessor :hand

  def initialize(name)
    @name = name
    @hand = []
  end

  def pretty_hand
    cards = ""
    self.hand.each { |c| cards << c.to_s << " " }
    cards
  end

  def to_s
    #{name}
  end
end

class Card
  attr_reader :rank, :suit, :value

  def initialize(rank, suit)
    @rank = rank
    @suit = suit
    @value = get_value(rank)
  end

  def get_value(rank)
    if rank == 'A'
      11
    elsif rank.to_i == 0
      10
    else
      rank.to_i
    end
  end

  def to_s
    "#{rank}#{suit}"
  end
end

class Deck
  attr_reader :new_deck
  attr_accessor :deck

  def initialize
    @deck = []
    new_deck
  end

  def deal_n(n)
    self.deck.pop(n)
  end

  def new_deck
    '23456789TJQKA'.chars.each do |rank|
      'hdsc'.chars.each do |suit|
        self.deck << Card.new(rank, suit)
      end
    end
    self.deck.shuffle!
  end
end

class Game
  attr_reader :human, :dealer, :deck
  attr_accessor :hand_number

  def initialize
    data = greet
    @human = Player.new(data[:name])
    @dealer = Player.new("Dealer")
    @deck = Deck.new()
    @hand_number = 1
  end

  def greet
    puts "** Welcome to Blackjack! **"
    puts ""
    puts "Enter your name:"
    {name: gets.chomp}
  end

  def display(dealer_show=false, soft_values=false)
    system 'clear'
    fmt = "%-8s %-11s %-20s\n"
    hline = "-" * 33 + "Hand: #{hand_number}" + "\n"

    printf(fmt, "Player", "Score", "Hand")
    puts hline

    if dealer_show == true
      printf(fmt, self.dealer.name, self.dealer.hand_value,
             self.dealer.pretty_hand)
    else
      printf(fmt, self.dealer.name, "??", "X X")
    end
    if soft_values == true
      printf(fmt, self.human.name, self.human.hand_value(soft=true),
             self.human.pretty_hand)
    else
      printf(fmt, self.human.name, self.human.hand_value,
             self.human.pretty_hand)
    end
    puts ""
  end

  def handle_round(player, &block)
    if blackjack?(player)
      puts "#{player.name} has Blackjack!"
      sleep 1
    else
      block.call
    end
    if player.hand_value > 21
      puts "#{player.name} has busted out!"
      sleep 1
    end
  end

  def blackjack?(player)
    if player.hand_value == 21 && player.hand.length == 2
      true
    end
  end

  def evaluate_hands
    if blackjack?(self.human) && (not blackjack?(self.dealer)) ||
        self.human.hand_value < 22 &&
        self.human.hand_value > self.dealer.hand_value ||
        self.human.hand_value < 22 && self.dealer.hand_value > 21
      puts "#{human.name} has won!"
    elsif self.human.hand_value == self.dealer.hand_value
      puts "Tie!"
    else
      puts "Dealer has won!"
    end
  end

  def run_game
    while
      self.human.hand = deck.deal_n(2)
      self.dealer.hand = deck.deal_n(2)
      display(dealer_show=false, soft_values=true)

      handle_round self.human do
        begin
          puts "Hit or Stay? (h/s)"
          choice = gets.chomp
          if choice == 's'
            display(dealer_show=false, soft_values=true)
            break
          end
          while choice != 's' && choice != 'h'
            puts "Eh? Hit or Stay? (h/s)"
            choice = gets.chomp
          end
          self.human.hand += deck.deal_n(1)
          display(dealer_show=false, soft_values=true)
        end until choice == 's' || self.human.hand_value > 21
      end

      if self.human.hand_value < 22
        handle_round self.dealer do
          while self.dealer.hand_value < 17
            self.dealer.hand += self.deck.deal_n(1)
          end
        end
      end

      display(dealer_show=true)

      evaluate_hands()

      puts "Press Enter to continue"
      gets
      self.hand_number += 1
      self.deck.new_deck
    end
  end
end

Game.new().run_game()
