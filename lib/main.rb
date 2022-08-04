
class Hangman
require 'yaml'
require 'raspell'

def initialize()
  displayInstructions()
  unless play?()
    puts "Thanks for playing!"
    exit
  end
  savedGames? ? (playSavedGame() ? savedGame() : newGame()) : newGame()
end

def newGame()
  generateWord()
  @filename = generateFileName
  @guesses = Array.new()
  @guessCount = 10
  @displayWord = "_" * @secretWord.length
  @gameOver = false
  play()
end

def playSavedGame()
  puts "Do you want to play a saved game? Y / N"
  puts "If N, a new game will start."
  until ["y","yes","n","no"].include?(userInput = gets.chomp.downcase()) do
    puts "Incorrect input, please try again.\nDo you want to play a saved game? Y / N"  
  end
  return false if ["n","no"].include?(userInput)
  return true if ["y","yes"].include?(userInput)
end

def savedGame()
  gameNum = ""
  loop do
    gameArr = []
    puts "Please choose your game by name or number."
    Dir['saved_games/*'].each do |game|
      puts game[(12..-5)]
      gameArr.push("#{game[(12..-5)]}.yml")
    end
    gameNum = gets.chomp.to_s.downcase.capitalize
    gameNum = "Game##{gameNum}" unless gameNum.include?("Game")
    if gameArr.include?("#{gameNum}.yml")
      @filename = "saved_games/#{gameNum}.yml"
      break
    end
  end
  from_yaml(@filename)
  play()
end

def saveGame()
  Dir.mkdir('saved_games') unless Dir.exists?('saved_games')
  File.open(@filename, 'w') {|file| file.write(self.to_yaml())}
end

def to_yaml()
  YAML.dump ({
    :guesses => @guesses,
    :guessCount => @guessCount,
    :displayWord => @displayWord,
    :gameOver => @gameOver,
    :secretWord => @secretWord
  })
end

def from_yaml(filename)
  data = YAML.load(File.read(filename))
  @guesses = data[:guesses]
  @guessCount = data[:guessCount]
  @displayWord = data[:displayWord]
  @gameOver = data[:gameOver]
  @secretWord = data[:secretWord]
end

def generateFileName(number = 1)
  File.exist?("saved_games/Game##{number}.yml") ? generateFileName(number += 1) : "saved_games/Game##{number}.yml"
end

def display()
  puts ""
  puts "Incorrect Guesses Remaining: #{@guessCount}"
  puts "Incorrect letters: #{@guesses.select { |guess| guess.length == 1}}"
  puts "Incorrect words: #{@guesses.select { |guess| guess.length != 1}}"
  puts ""
  puts @displayWord.gsub(""," ")
end

def play()
  until @gameOver do
    userInput = ""
    loop do
      display()
      puts "Guess a letter or the word:"
      userInput = gets.chomp.downcase()
      break if validGuess?(userInput) unless userInput == ""
    end
    if userInput == "save"
      saveGame()
      break
    else
      validGuess?(userInput)
      if win?(userInput)
        win()
        break
      end
      checkGuess?(userInput) ? reveal(userInput) : incorrectGuess(userInput)
      saveGame() if !@gameOver
    end
  end
  playAgain = ""
  puts "Press any button to continue..."
  gets
  game = Hangman.new()
end

def reveal(guess)
  @secretWord.split("").each_with_index do |letter, index|
    @displayWord[index] = letter if guess == letter 
  end
  win() unless @displayWord.include?("_")
end

def incorrectGuess(guess)
  @guesses.push(guess)
  if @guessCount > 1 
    @guessCount -= 1  
  else
    return lose()
  end
end

def lose()
  @gameOver = true
  deleteGame()
  puts "Better luck next time!"
end

def deleteGame()
  puts @filename
  File.open(@filename, 'r')
  File.delete(@filename)
end

def win?(guess)
  if @secretWord == guess 
    return true
  else
    return false
  end
end

def win()
  deleteGame()
  @gameOver = true
  puts "Congratulations! You guessed the word correctly: #{@secretWord}"
  #delete yaml file
end

def checkGuess?(guess)
  @secretWord.include?(guess)
end

def validGuess?(userInput)
  speller = Aspell.new("en_US")
  speller.suggestion_mode = Aspell::NORMAL
  if userInput == "save"
    return true
  elsif userInput.length > 1 and userInput.length != @secretWord.length
    puts "That word is not #{@secretWord.length} letters long."
    return false
  elsif @guesses.include?(userInput) || @displayWord.include?(userInput)
    puts "That guess has already been made."
    return false
  elsif (!speller.check(userInput) && userInput.length > 1) || userInput.length == 0
    puts "That is not a word or letter."
    return false
  else
    return true
  end
end

def generateWord()
  speller = Aspell.new("en_US")
  speller.suggestion_mode = Aspell::NORMAL
  #generates random word from word_list.txt
  @secretWord = IO.read('word_list.txt').split("\n")[rand(IO.read('word_list.txt').split("\n").length)].downcase
  generateWord() if @secretWord == "save" || !speller.check(@secretWord)
end

def savedGames?()
  Dir['saved_games/*'].length > 0
end

def displayInstructions()
  puts IO.read('lib/instructions.txt')
end

def play?()
  puts "\nDo you want to play hangman? Y / N"  
  until ["y","yes"].include?(userInput = gets.chomp.downcase()) do
    return false if ["n","no"].include?(userInput)
    puts "Incorrect input, please try again.\nDo you want to play hangman? Y / N"  
  end
  true
end

end

game = Hangman.new()