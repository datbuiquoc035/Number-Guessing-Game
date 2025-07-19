#!/bin/bash

# PostgreSQL command alias
PSQL="psql --username=freecodecamp --dbname=number_guess --no-align --tuples-only -c"

# Random number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# Prompt for username
echo "Enter your username:"
read USERNAME

# Trim username to 22 characters max
USERNAME=${USERNAME:0:22}

# Check if user exists
USER_DATA=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USERNAME';")

if [[ -z $USER_DATA ]]
then
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  $PSQL "INSERT INTO users(username) VALUES('$USERNAME');" > /dev/null
else
  IFS="|" read GAMES_PLAYED BEST_GAME <<< "$USER_DATA"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Start game
echo "Guess the secret number between 1 and 1000:"
NUMBER_OF_GUESSES=0

while true
do
  read GUESS
  (( NUMBER_OF_GUESSES++ ))

  # Check if input is an integer
  if ! [[ $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    continue
  fi

  if [[ $GUESS -lt $SECRET_NUMBER ]]
  then
    echo "It's higher than that, guess again:"
  elif [[ $GUESS -gt $SECRET_NUMBER ]]
  then
    echo "It's lower than that, guess again:"
  else
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    
    # Update database
    $PSQL "UPDATE users SET games_played = games_played + 1 WHERE username='$USERNAME';" > /dev/null

    # Update best_game if this is the best or first game
    CURRENT_BEST=$($PSQL "SELECT best_game FROM users WHERE username='$USERNAME';")
    if [[ -z $CURRENT_BEST || $NUMBER_OF_GUESSES -lt $CURRENT_BEST ]]
    then
      $PSQL "UPDATE users SET best_game = $NUMBER_OF_GUESSES WHERE username='$USERNAME';" > /dev/null
    fi

    break
  fi
done
