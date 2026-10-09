#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# number to be guessed 
RANDOM_NUMBER=$(( ($RANDOM % 1000) + 1 ))

# prompt for username 
echo "Enter your username:" 
read USERNAME 

PLAYER_NAME=$($PSQL "SELECT name FROM users WHERE name='$USERNAME'") 

# if the username has not been used before
if [[ -z $PLAYER_NAME ]] 
then 
  echo "Welcome, $USERNAME! It looks like this is your first time here." 
  INSERT_USERNAME=$($PSQL "INSERT INTO users(name) VALUES('$USERNAME')") 
  PLAYER_ID=$($PSQL "SELECT user_id FROM users WHERE name='$USERNAME'") 
else 
  # if that username has been used before
  GAME_DATA=$($PSQL "SELECT users.user_id, 
                            COUNT(game_id), 
                            MIN(number_of_guesses) 
                            FROM users LEFT JOIN games ON 
                            users.user_id = games.user_id 
                            WHERE name = '$PLAYER_NAME'
                            GROUP BY users.user_id")
  IFS="|" read PLAYER_ID GAMES_PLAYED BEST_GAME <<< "$GAME_DATA"
  echo "Welcome back, $PLAYER_NAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses." 
fi 

echo "Guess the secret number between 1 and 1000:" 
read PLAYER_GUESS 

GUESSED_NUMBER=false
COUNT=0 

while [[ $GUESSED_NUMBER = false ]] 
do 
  # increments player guesses 
  COUNT=$(( COUNT + 1 )) 
  # if anything other than an integer is input as a guess
  if [[ ! $PLAYER_GUESS =~ ^[0-9]+$ ]] 
  then 
    echo "That is not an integer, guess again:"
    read PLAYER_GUESS
  # if the previous input was lower than the secret number 
  elif (( $PLAYER_GUESS < $RANDOM_NUMBER ))  
    then
      echo "It's higher than that, guess again:"
      read PLAYER_GUESS
  # if the previous input was higher than the secret number 
  elif (( $PLAYER_GUESS > $RANDOM_NUMBER  )) 
    then
      echo "It's lower than that, guess again:"
      read PLAYER_GUESS 
  else 
    # when the secret number is guessed 
    echo "You guessed it in $COUNT tries. The secret number was $RANDOM_NUMBER. Nice job!"
    GUESSED_NUMBER=true

    # insert game data 
    INSERT_GAME=$($PSQL "INSERT INTO games(user_id, number_of_guesses) VALUES($PLAYER_ID, $COUNT)") 
  fi 
done 
