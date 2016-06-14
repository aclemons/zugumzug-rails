Feature: Beginning the game
  Scenario: Beginning the game
    When the players have logged in
    Then each player can choose a colour
    And each player receives 3 destination tickets
    And each player must keep at least 2 of the cards
    And then normal play begins
