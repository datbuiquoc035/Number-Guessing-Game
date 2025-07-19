#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess --no-align --tuples-only -c"
SECRET=$((RANDOM % 1000 + 1))
echo "Enter your username:"
read USER
USER=${USER:0:22}
DATA=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$USER'")
if [[ -z $DATA ]]; then
  echo "Welcome, $USER! It looks like this is your first time here."
  $PSQL "INSERT INTO users(username) VALUES('$USER')"
else
  IFS="|" read GAMES BEST <<< "$DATA"
  echo "Welcome back, $USER! You have played $GAMES games, and your best game took $BEST guesses."
fi

echo "Guess the secret number between 1 and 1000:"
TRIES=0
while true; do
  read GUESS
  ((TRIES++))
  if ! [[ $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
  elif (( GUESS < SECRET )); then
    echo "It's higher than that, guess again:"
  elif (( GUESS > SECRET )); then
    echo "It's lower than that, guess again:"
  else
    echo "You guessed it in $TRIES tries. The secret number was $SECRET. Nice job!"
    $PSQL "UPDATE users SET games_played = games_played + 1 WHERE username='$USER'"
    CUR_BEST=$($PSQL "SELECT best_game FROM users WHERE username='$USER'")
    if [[ -z $CUR_BEST || $TRIES -lt $CUR_BEST ]]; then
      $PSQL "UPDATE users SET best_game = $TRIES WHERE username='$USER'"
    fi
    break
  fi
done
