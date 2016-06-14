Feature: Winning the game

  Scenario: Winning the game
    Given a player has exhausted his trains
    And each other player had one more turn
    Then the points are tallied for each player
    And the player or players with the longest route receives 10 additional points
    And the player with the most points wins
