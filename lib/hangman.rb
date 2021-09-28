require 'sorted_set'
require 'yaml'
MAX_INCORRECT_GUESSES = 10

class Hangman
    def load_dictionary
        @dictionary = []
        dictionary_file = File.open('words.txt')
        dictionary_file.readlines.each do |line|
            line.strip!.downcase!
            if line.length.between?(5, 12)
                @dictionary << line
            end
        end
    end
    def initialize
        load_dictionary
        puts "Welcome to Hangman! Press Enter to start a new game or type load to load a previously saved game"
        if gets.chomp == 'load'
            load_game
        else
            new_game
        end
    end
    def load_game
        object_loaded = YAML.load(File.read('save.dump'))
        @secret = object_loaded[:secret]
        @num_incorrect_guesses = object_loaded[:num_incorrect_guesses]
        @guessed_positions = object_loaded[:guessed_positions]
        @used_letters = SortedSet.new(object_loaded[:used_letters])
        game_loop
    end
    def save_game
        object_to_save = {
            :secret => @secret,
            :num_incorrect_guesses => @num_incorrect_guesses,
            :guessed_positions => @guessed_positions,
            :used_letters => @used_letters.to_a
        }
        File.open('save.dump', 'w') {|f| f.write(YAML.dump(object_to_save))}
        exit
    end

    def new_game
        @secret = @dictionary.sample
        @num_incorrect_guesses = 0
        @guessed_positions = Array.new @secret.length, '_'
        @used_letters = SortedSet[]
        game_loop
    end

    def game_loop
        while true
            while @num_incorrect_guesses < MAX_INCORRECT_GUESSES
                play_round
                if check_end
                    break
                end
            end
            return new_game
        end
    end

    def check_end
        if @guessed_positions.none? {|char| char == '_' }
            puts @guessed_positions.join(' ')
            puts "Used letters: #{@used_letters.to_a.join(' ')}"
            puts "You win! Press Enter to start a new game or type exit to exit."
        elsif @num_incorrect_guesses == MAX_INCORRECT_GUESSES
            puts @guessed_positions.join(' ')
            puts "Answer: #{@secret.chars.join(' ')}"
            puts "Used letters: #{@used_letters.to_a.join(' ')}"
            puts "You lose! have used all your guess. Press Enter to start a new game or type exit to exit."
        else
            return false
        end
        if gets.chomp == 'exit'
            exit
        end
        return true
    end

    def play_round
        guess = display_and_input
        @used_letters.add(guess)
        @secret.chars.each_with_index do |char, i|
            if @secret[i] == guess
                @guessed_positions[i] = guess
            end
        end
        if @secret.chars.none? {|char| char == guess}
            @num_incorrect_guesses += 1
        end
    end
    def display_and_input
        puts "You have #{MAX_INCORRECT_GUESSES - @num_incorrect_guesses} guesses left."
        puts @guessed_positions.join(' ')
        puts "Used letters: #{@used_letters.to_a.join(' ')}"
        begin
            puts "Enter your guess, or type save to save game and quit: "
            guess = gets.chomp.downcase
            if guess == 'save'
                save_game
            end
            if guess.length == 0
                raise StandardError.new "No input. Please try again"
            elsif guess.length > 1
                raise StandardError.new "Too many characters. Please try again."
            elsif !(guess >= 'a' && guess <= 'z')
                raise StandardError.new "Input is not a letter. Please try again."
            elsif @used_letters.include?(guess)
                raise StandardError.new "Letter already guessed before. Please try again."
            end
        rescue => e
            puts e
            retry
        end
        return guess
    end
end

game = Hangman.new